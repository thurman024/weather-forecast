# Weather Forecast

A weather forecast application.

## Dependencies

* Ruby version: 3.3.5
* Rails version: 8.0.2

### Setup

1. Clone the repository:
```bash
git clone https://github.com/thurman024/weather-forecast.git
cd weather-forecast
```

2. Install dependencies:
```bash
bundle install
```

3. Start the server:
```bash
rails server
```

The application will be available at `http://localhost:3000`

## Usage

Enter a location to search for the weather forecast. A full address is not required. Location lookup is performed using a free service from the [geocoder gem](https://github.com/alexreisner/geocoder). The first result for the provided search params will be used. If the desired result is not returned, try entering more specific search params.

Weather forecasts are provided by [WeatherAPI](https://www.weatherapi.com/docs/). Data is cached by zip code for a duration of 30 minutes.

## Specs

To run the Rspec test suite:
```bash
bundle exec rspec
```
