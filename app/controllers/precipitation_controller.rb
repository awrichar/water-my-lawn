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
    city = loc.city
    state = loc.state
    @location = "#{city}, #{state}"

    # Get the current date and 4 days on each side
    wunderground = Wunderground.new
    @today = wunderground.get_date_for_location(loc)
    date = @today - 4.days
    end_date = @today + 4.days

    @days = []
    while date <= end_date do
      precipitation = wunderground.get_precipitation(city, state, date, @today)
      @days.push({ date: date, precipitation: precipitation })
      date += 1.days
    end
  end
end

class Wunderground
  def initialize
    @forecasts = {}
  end

  def get_forecast(city, state, date)
    if @forecasts.has_key?(date)
      return @forecasts[date]
    end

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

  def cache_precipitation(city, state, date, precip, forecast)
    p = Precipitation.find_or_create_by(city: city, state: state, date: date)
    p.precipitation = precip
    p.forecast = forecast
    p.save
  end

  def get_cached_precipitation(city, state, date)
    p = Precipitation.find_by(city: city, state: state, date: date)
    if not p or (p.forecast and p.updated_at < FORECAST_CACHE_TIME.ago)
      nil
    else
      p.precipitation
    end
  end

  def get_precipitation_forecast(city, state, date)
    forecast = get_forecast(city, state, date)
    forecast['qpf_allday']['in']
  end

  def get_precipitation_historical(city, state, date)
    fmt_date = date.strftime("%Y%m%d")
    resp = request("history_#{fmt_date}/q/#{state}/#{city}")
    resp['history']['dailysummary'][0]['precipi']
  end

  def get_precipitation(city, state, date, today)
    last_forecast_day = today + 9.days
    precip = get_cached_precipitation(city, state, date)

    if not precip
      if date < today
        precip = get_precipitation_historical(city, state, date)
        cache_precipitation(city, state, date, precip, false)
      elsif date <= last_forecast_day
        precip = get_precipitation_forecast(city, state, date)
        cache_precipitation(city, state, date, precip, true)
      end
    end

    precip ? sprintf('%0.2f', precip) : nil
  end

  def get_date_for_location(loc)
    timezone = Timezone::Zone.new :latlon =>loc.ll.split(',')
    timezone.time(Time.now).to_date
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
end