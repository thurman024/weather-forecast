module Geocoding
  class Location
    attr_reader :street, :city, :state, :zip_code, :latitude, :longitude

    def initialize(street: nil, city: nil, state: nil, zip_code: nil, latitude: nil, longitude: nil)
      @street = street
      @city = city
      @state = state
      @zip_code = zip_code
      @latitude = latitude
      @longitude = longitude
    end

    def self.from_address(street: nil, city:, state: nil)
      address = [ street, city, state ].compact.join(", ")
      results = Geocoder.search(address).first

      return nil unless results

      # A zip code is needed for the cache key.
      # If a specific address is not input (e.g. just a city and state),
      # find a zip code from a reverse lookup.
      zip_code = results.postal_code
      if zip_code.blank? && results.coordinates.present?
        reverse_results = Geocoder.search(results.coordinates).first
        zip_code = reverse_results&.postal_code
      end

      new(
        street: street,
        city: results.city,
        state: results.state,
        zip_code: zip_code,
        latitude: results.latitude,
        longitude: results.longitude
      )
    end

    def to_s
      if street.present?
        [ street, city, state, zip_code ].compact.join(", ")
      else
        [ city, state, zip_code ].compact.join(", ")
      end
    end
  end
end
