class ForecastsController < ApplicationController
  def new
  end

  def search
    @location = Geocoding::Location.from_address(street: params[:street], city: params[:city], state: params[:state])
    @forecast = Weather::Forecast.for_location(@location)

    respond_to do |format|
      format.turbo_stream do
        render turbo_stream: turbo_stream.update("forecast_results", 
          partial: "forecasts/forecast", 
          locals: { location: @location, forecast: @forecast }
        )
      end
    end
  end
end