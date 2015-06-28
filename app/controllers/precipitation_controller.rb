include ERB::Util

WUNDERGROUND_KEY = "b16ca5cc88fa195c"
BASE_URI = "http://api.wunderground.com/api/#{WUNDERGROUND_KEY}"

CITY = "Durham"
STATE = "NC"

FORECAST_CACHE_TIME = 12.hours
MAX_SATURATION = 0.5
MIN_SATURATION = MAX_SATURATION * 0.2
EVAPORATION_DAYS = 5

class PrecipitationController < ApplicationController
  def index
    if params[:location].blank?
      location = "#{CITY}, #{STATE}"
    else
      location = params[:location]
    end

    loc = Geokit::Geocoders::GoogleGeocoder.geocode(location)
    @location = "#{loc.city}, #{loc.state}"
    wunderground = Wunderground.new(loc)
    @today = wunderground.today
    last_day = EVAPORATION_DAYS - 1

    # Examine the precipitation for the past few days
    @total_precipitation = 0
    saturation = 0
    1.upto(last_day) do |offset|
      precip = wunderground.get_precipitation(@today - offset.days)

      saturation_factor = 1 - offset.to_f / EVAPORATION_DAYS
      @total_precipitation += precip
      saturation += [precip, MAX_SATURATION].min * saturation_factor
    end

    # Examine the forecast for the next few days
    @forecast = {}
    @today.upto(@today + last_day.days) do |date|
      @forecast[date] = wunderground.get_precipitation(date)
    end

    # Interpret the results
    rain_today = @forecast[@today]
    rain_tomorrow = @forecast[@today + 1.days]
    if saturation > MIN_SATURATION
      @status = "No"
      @long_status = "You've had plenty of rain."
    elsif saturation + rain_today > MIN_SATURATION
      @status = "No"
      @long_status = "Looks like rain today."
    elsif saturation + rain_today + rain_tomorrow > MIN_SATURATION
      @status = "Probably not"
      @long_status = "There's rain in the forecast."
    elsif rain_today > 0 or rain_tomorrow > 0
      @status = "Probably"
      @long_status = "There's rain in the forecast, but not much."
    else
      @status = "Yes"
      @long_status = "Your lawn is looking a bit dry."
    end

    @EVAPORATION_DAYS = EVAPORATION_DAYS
    @total_precipitation = format_precip(@total_precipitation)
    @forecast.each { |date, precip| @forecast[date] = format_precip(precip) }
  end

  private
    def format_precip(precip)
      sprintf('%0.2f', precip)
    end
end

class Wunderground
  attr_reader :today

  def initialize(location)
    @forecasts = {}
    @city = location.city
    @state = location.state

    timezone = Timezone::Zone.new :latlon =>location.ll.split(',')
    @today = timezone.time(Time.now).to_date
  end

  def get_precipitation(date)
    last_forecast_day = @today + 9.days
    precip = get_cached_precipitation(date)

    if not precip
      if date < @today
        precip = get_precipitation_historical(date)
        cache_precipitation(date, precip, false)
      elsif date <= last_forecast_day
        precip = get_precipitation_forecast(date)
        cache_precipitation(date, precip, true)
      end
    end

    precip
  end

  private
    def request(query)
      url = URI.parse("#{BASE_URI}/#{query}.json")
      req = Net::HTTP::Get.new(url.to_s)
      res = Net::HTTP.start(url.host, url.port) {|http|
        http.request(req)
      }

      JSON.parse(res.body)
    end

    def cache_precipitation(date, precip, forecast)
      p = Precipitation.find_or_create_by(city: @city, state: @state, date: date)
      p.precipitation = precip
      p.forecast = forecast
      p.save
    end

    def get_cached_precipitation(date)
      p = Precipitation.find_by(city: @city, state: @state, date: date)
      if not p
        nil
      elsif p.forecast and date < @today or p.updated_at < FORECAST_CACHE_TIME.ago
        nil
      else
        p.precipitation
      end
    end

    def get_forecast(date)
      if @forecasts.has_key?(date)
        return @forecasts[date]
      end

      city = url_encode(@city)
      state = url_encode(@state)

      resp = request("forecast10day/q/#{state}/#{city}")
      forecasts = resp['forecast']['simpleforecast']['forecastday']
      for forecast in forecasts
        year = forecast['date']['year']
        month = forecast['date']['month']
        day = forecast['date']['day']
        date = Date.new(year, month, day)

        @forecasts[date] = forecast
      end

      @forecasts[date]
    end

    def get_precipitation_forecast(date)
      forecast = get_forecast(date)
      forecast['qpf_allday']['in'].to_f
    end

    def get_precipitation_historical(date)
      fmt_date = date.strftime("%Y%m%d")
      city = url_encode(@city)
      state = url_encode(@state)

      resp = request("history_#{fmt_date}/q/#{state}/#{city}")
      resp['history']['dailysummary'][0]['precipi'].to_f
    end
end