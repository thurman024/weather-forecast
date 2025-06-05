module Weather
  class Forecast
    # In a production app, this would be stored in an environment variable or rails credentials
    WEATHER_API_KEY = "11bf08a681e14745a73214852250406"
    BASE_URL = "https://api.weatherapi.com/v1"
    DAYS = 3
    CACHE_EXPIRY = 30.minutes

    attr_reader :zip_code, :data, :fresh

    def initialize(zip_code:, data:, fresh: false)
      @zip_code = zip_code
      @data = data
      @fresh = fresh
    end

    def self.for_location(location)
      return nil unless location&.zip_code

      was_fresh = false
      cached_data = Rails.cache.fetch("weather_forecast/#{location.zip_code}", expires_in: CACHE_EXPIRY) do
        was_fresh = true
        fetch_forecast(location.zip_code)
      end

      new(zip_code: location.zip_code, data: cached_data, fresh: was_fresh)
    end

    def self.fetch_forecast(zip_code)
      response = HTTParty.get("#{BASE_URL}/forecast.json?key=#{WEATHER_API_KEY}&q=#{zip_code}&days=#{DAYS}")
      response.parsed_response
    end

    def current_temp
      data["current"]["temp_f"]
    end

    def high_temp_for_day(n)
      data["forecast"]["forecastday"][n]["day"]["maxtemp_f"]
    end

    def low_temp_for_day(n)
      data["forecast"]["forecastday"][n]["day"]["mintemp_f"]
    end

    def conditions_for_day(n)
      data["forecast"]["forecastday"][n]["day"]["condition"]["text"]
    end

    def date_for_day(n)
      data["forecast"]["forecastday"][n]["date"]
    end

    def fresh?
      fresh
    end

    def fetched_at
      DateTime.parse(data["current"]["last_updated"])
    end

    def success?
      data["current"].is_a?(Hash) && data["forecast"].is_a?(Hash)
    end

    def error?
      !success?
    end
  end
end
