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

  // 👇 Constructor para ubicación vacía (strings vacíos y coordenadas 0.0)
  factory LocationDTO.empty() {
    return LocationDTO(
      country: '',
      state: '',
      city: '',
      lat: 0.0,
      lng: 0.0,
    );
  }

  // 👇 Método para verificar si la ubicación está vacía
  bool get isEmpty =>
      country.isEmpty &&
      state.isEmpty &&
      city.isEmpty &&
      lat == 0.0 &&
      lng == 0.0;

  // 👇 Método para verificar si tiene datos válidos
  bool get hasData => !isEmpty;

  // 👇 Ubicación usable para confirmación (mínimo: ciudad + país)
  bool get hasCityAndCountry => city.trim().isNotEmpty && country.trim().isNotEmpty;

  // 👇 Getter para mostrar la ubicación de forma legible
  String get displayName {
    if (isEmpty) return 'Sin ubicación';
    final parts = <String>[];
    if (city.isNotEmpty) parts.add(city);
    if (state.isNotEmpty) parts.add(state);
    if (country.isNotEmpty) parts.add(country);
    return parts.join(', ');
  }

  Map<String, dynamic> toMap() => {
    'country': country,
    'state': state,
    'city': city,
    'lat': lat,
    'lng': lng,
  };

  factory LocationDTO.fromMap(Map<String, dynamic> map) => LocationDTO(
    country: map['country'] ?? '',
    state: map['state'] ?? '',
    city: map['city'] ?? '',
    lat: (map['lat'] as num?)?.toDouble() ?? 0.0,
    lng: (map['lng'] as num?)?.toDouble() ?? 0.0,
  );

  // 👇 Para debugging
  @override
  String toString() {
    if (isEmpty) return 'LocationDTO(empty)';
    return 'LocationDTO(city: $city, state: $state, country: $country)';
  }

  // 👇 CopyWith para facilitar actualizaciones
  LocationDTO copyWith({
    String? country,
    String? state,
    String? city,
    double? lat,
    double? lng,
  }) {
    return LocationDTO(
      country: country ?? this.country,
      state: state ?? this.state,
      city: city ?? this.city,
      lat: lat ?? this.lat,
      lng: lng ?? this.lng,
    );
  }
}