require 'rails_helper'

RSpec.describe "Forecasts", type: :request do
  describe 'GET /forecasts/new' do
    it 'returns a successful response' do
      get new_forecast_path
      expect(response).to have_http_status(:success)
    end
  end

  describe 'POST /forecasts/search' do
    let(:street) { '401 S 8th St' }
    let(:city) { 'boise' }
    let(:state) { 'id' }
    let(:search_params) { { street: street, city: city, state: state } }

    let(:mock_location) do
      instance_double(Geocoding::Location,
        street: '401 S 8th St',
        city: 'Boise',
        state: 'ID',
        zip_code: '83702'
      )
    end

    let(:mock_forecast) do
      instance_double(Weather::Forecast,
        current_temp: 75.9,
        high_temp_for_day: 77.4,
        low_temp_for_day: 45.1,
        conditions_for_day: 'Sunny',
        date_for_day: '2025-06-04'
      )
    end

    context 'with valid address' do
      before do
        allow(Geocoding::Location).to receive(:from_address)
          .with(street: street, city: city, state: state)
          .and_return(mock_location)

        allow(Weather::Forecast).to receive(:for_location)
          .with(mock_location)
          .and_return(mock_forecast)

        allow(mock_forecast).to receive(:error?).and_return(false)
        allow(mock_forecast).to receive(:fresh?).and_return(true)
      end

      it 'returns a successful turbo stream response' do
        get search_forecasts_path, params: search_params, as: :turbo_stream

        expect(response).to have_http_status(:success)
      end
    end

    context 'with invalid address' do
      before do
        allow(Geocoding::Location).to receive(:from_address)
          .with(street: street, city: city, state: state)
          .and_return(nil)
      end

      it 'returns a turbo stream response with empty forecast' do
        get search_forecasts_path, params: search_params, as: :turbo_stream

        expect(response).to have_http_status(:success)
      end
    end
  end
end
