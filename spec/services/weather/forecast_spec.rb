require 'rails_helper'

RSpec.describe Weather::Forecast do
  let(:zip_code) { '83702' }
  let(:weather_data) { JSON.parse(File.read(Rails.root.join('spec/fixtures/weather_api_response.json'))) }
  let(:location) { double('Location', zip_code: zip_code) }

  describe '.for_location' do
    before do
      allow(described_class).to receive(:fetch_forecast).and_return(weather_data)
    end

    it 'returns nil when location is nil' do
      expect(described_class.for_location(nil)).to be_nil
    end

    it 'returns nil when location has no zip code' do
      location = double('Location', zip_code: nil)
      expect(described_class.for_location(location)).to be_nil
    end

    it 'fetches and caches weather data for a valid location' do
      expect(Rails.cache).to receive(:fetch)
        .with("weather_forecast/#{zip_code}", expires_in: 30.minutes)
        .and_yield

      forecast = described_class.for_location(location)

      expect(forecast).to be_a(described_class)
      expect(forecast.zip_code).to eq(zip_code)
      expect(forecast.data).to eq(weather_data)
      expect(forecast.fresh).to be true
    end

    it 'returns cached data when available' do
      allow(Rails.cache).to receive(:fetch)
        .with("weather_forecast/#{zip_code}", expires_in: 30.minutes)
        .and_return(weather_data)

      forecast = described_class.for_location(location)

      expect(forecast).to be_a(described_class)
      expect(forecast.fresh).to be false
      expect(described_class).not_to have_received(:fetch_forecast)
    end
  end

  describe '.fetch_forecast' do
    let(:api_url) { "#{described_class::BASE_URL}/forecast.json?key=#{described_class::WEATHER_API_KEY}&q=#{zip_code}&days=#{described_class::DAYS}" }

    it 'makes an API request to fetch weather data' do
      expect(HTTParty).to receive(:get)
        .with(api_url)
        .and_return(double('Response', parsed_response: weather_data))

      result = described_class.fetch_forecast(zip_code)
      expect(result).to eq(weather_data)
    end
  end

  describe 'data accessors' do
    let(:forecast) { described_class.new(zip_code: zip_code, data: weather_data, fresh: true) }

    describe '#current_temp' do
      it 'returns the current temperature in Fahrenheit' do
        expect(forecast.current_temp).to eq(75.9)
      end
    end

    describe '#high_temp_for_day' do
      it 'returns the high temperature for the specified day' do
        expect(forecast.high_temp_for_day(0)).to eq(77.4)
      end
    end

    describe '#low_temp_for_day' do
      it 'returns the low temperature for the specified day' do
        expect(forecast.low_temp_for_day(0)).to eq(45.1)
      end
    end

    describe '#conditions_for_day' do
      it 'returns the weather conditions for the specified day' do
        expect(forecast.conditions_for_day(0)).to eq('Sunny')
      end
    end

    describe '#date_for_day' do
      it 'returns the date for the specified day' do
        expect(forecast.date_for_day(0)).to eq('2025-06-04')
      end
    end
  end
end
