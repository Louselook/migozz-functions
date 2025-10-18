class LocationDTO {
  final String country;
  final String state;
  final String city;
  final double lat;
  final double lng;

  LocationDTO({
    required this.country,
    required this.state,
    required this.city,
    required this.lat,
    required this.lng,
  });

  Map<String, dynamic> toMap() => {
    'country': country,
    'state': state,
    'city': city,
    'lat': lat,
    'lng': lng,
  };

  factory LocationDTO.fromMap(Map<String, dynamic> map) => LocationDTO(
    country: map['country'],
    state: map['state'],
    city: map['city'],
    lat: (map['lat'] as num).toDouble(),
    lng: (map['lng'] as num).toDouble(),
  );
}
