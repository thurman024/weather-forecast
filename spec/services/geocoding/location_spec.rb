require 'rails_helper'

RSpec.describe Geocoding::Location do
  let(:street) { '401 S 8th St' }
  let(:input_city) { 'boise' }
  let(:input_state) { 'id' }
  let(:geocoded_city) { 'Boise' }
  let(:geocoded_state) { 'ID' }
  let(:zip_code) { '83702' }
  let(:latitude) { 43.6147 }
  let(:longitude) { -116.2015 }

  describe '.from_address' do
    let(:mock_geocoder_result) do
      double(
        'GeocoderResult',
        postal_code: zip_code,
        latitude: latitude,
        longitude: longitude,
        coordinates: [latitude, longitude],
        city: geocoded_city,
        state: geocoded_state
      )
    end

    context 'when geocoding is successful' do
      before do
        allow(Geocoder).to receive(:search)
          .with("#{street}, #{input_city}, #{input_state}")
          .and_return([mock_geocoder_result])
      end

      it 'creates a location with geocoded city and state details' do
        location = described_class.from_address(street: street, city: input_city, state: input_state)

        expect(location).to be_a(described_class)
        expect(location.street).to eq(street)
        expect(location.city).to eq(geocoded_city)
        expect(location.state).to eq(geocoded_state)
        expect(location.zip_code).to eq(zip_code)
        expect(location.latitude).to eq(latitude)
        expect(location.longitude).to eq(longitude)
      end
    end

    context 'when geocoding returns no results' do
      before do
        allow(Geocoder).to receive(:search).and_return([])
      end

      it 'returns nil' do
        location = described_class.from_address(city: input_city, state: input_state)
        expect(location).to be_nil
      end
    end

    context 'when postal code is missing from initial geocoding' do
      let(:mock_geocoder_result_without_zip) do
        double(
          'GeocoderResult',
          postal_code: nil,
          latitude: latitude,
          longitude: longitude,
          coordinates: [latitude, longitude],
          city: geocoded_city,
          state: geocoded_state
        )
      end

      let(:mock_reverse_geocoder_result) do
        double(
          'GeocoderResult',
          postal_code: zip_code
        )
      end

      before do
        allow(Geocoder).to receive(:search)
          .with("#{street}, #{input_city}, #{input_state}")
          .and_return([mock_geocoder_result_without_zip])

        allow(Geocoder).to receive(:search)
          .with([latitude, longitude])
          .and_return([mock_reverse_geocoder_result])
      end

      it 'performs reverse geocoding to get zip code' do
        location = described_class.from_address(street: street, city: input_city, state: input_state)

        expect(location.zip_code).to eq(zip_code)
        expect(location.city).to eq(geocoded_city)
        expect(location.state).to eq(geocoded_state)
        expect(Geocoder).to have_received(:search).with([latitude, longitude])
      end
    end
  end

  describe '#coordinates' do
    it 'returns an array of latitude and longitude' do
      location = described_class.new(
        latitude: latitude,
        longitude: longitude
      )

      expect(location.coordinates).to eq([latitude, longitude])
    end
  end

  describe '#valid?' do
    it 'returns true when latitude, longitude, and zip_code are present' do
      location = described_class.new(
        latitude: latitude,
        longitude: longitude,
        zip_code: zip_code
      )

      expect(location).to be_valid
    end

    it 'returns false when any required attribute is missing' do
      locations = [
        described_class.new(latitude: nil, longitude: longitude, zip_code: zip_code),
        described_class.new(latitude: latitude, longitude: nil, zip_code: zip_code),
        described_class.new(latitude: latitude, longitude: longitude, zip_code: nil)
      ]

      locations.each do |location|
        expect(location).not_to be_valid
      end
    end
  end

  describe '#to_s' do
    context 'with street address' do
      it 'returns full address with street' do
        location = described_class.new(
          street: street,
          city: geocoded_city,
          state: geocoded_state,
          zip_code: zip_code
        )

        expect(location.to_s).to eq('401 S 8th St, Boise, ID, 83702')
      end
    end

    context 'without street address' do
      it 'returns address without street' do
        location = described_class.new(
          city: geocoded_city,
          state: geocoded_state,
          zip_code: zip_code
        )

        expect(location.to_s).to eq('Boise, ID, 83702')
      end
    end

    context 'with missing components' do
      it 'skips nil values in the address string' do
        location = described_class.new(
          city: geocoded_city,
          zip_code: zip_code
        )

        expect(location.to_s).to eq('Boise, 83702')
      end
    end
  end
end
