WUNDERGROUND_KEY = "b16ca5cc88fa195c"
BASE_URI = "http://api.wunderground.com/api/#{WUNDERGROUND_KEY}"

CITY = "Durham"
STATE = "NC"

FORECAST_CACHE_TIME = 12.hours

class PrecipitationController < ApplicationController
  def index
    if params[:location].blank?
      location = "#{CITY}, #{STATE}"
    else
      location = params[:location]
    end

    loc = Geokit::Geocoders::GoogleGeocoder.geocode(location)
    @location = "#{loc.city}, #{loc.state}"

    # Get the current date and 4 days on each side
    wunderground = Wunderground.new(loc)
    @today = wunderground.today
    date = @today - 4.days
    end_date = @today + 4.days

    @days = []
    while date <= end_date do
      precip = wunderground.get_precipitation(date)
      @days.push({ date: date, precipitation: sprintf('%0.2f', precip) })
      date += 1.days
    end
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
      if not p or (p.forecast and p.updated_at < FORECAST_CACHE_TIME.ago)
        nil
      else
        p.precipitation
      end
    end

    def get_forecast(date)
      if @forecasts.has_key?(date)
        return @forecasts[date]
      end

      resp = request("forecast10day/q/#{@state}/#{@city}")
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
      forecast['qpf_allday']['in']
    end

    def get_precipitation_historical(date)
      fmt_date = date.strftime("%Y%m%d")
      resp = request("history_#{fmt_date}/q/#{@state}/#{@city}")
      resp['history']['dailysummary'][0]['precipi']
    end
end