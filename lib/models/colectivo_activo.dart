class ColectivoActivo {
  final String idVehiculo;
  final double latitud;
  final double longitud;

  const ColectivoActivo({
    required this.idVehiculo,
    required this.latitud,
    required this.longitud,
  });

  factory ColectivoActivo.fromJson(Map<String, dynamic> json) {
    return ColectivoActivo(
      idVehiculo: json['idVehiculo'] as String,
      latitud: (json['latitud'] as num).toDouble(),
      longitud: (json['longitud'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'idVehiculo': idVehiculo,
      'latitud': latitud,
      'longitud': longitud,
    };
  }

  ColectivoActivo copyWith({
    String? idVehiculo,
    double? latitud,
    double? longitud,
  }) {
    return ColectivoActivo(
      idVehiculo: idVehiculo ?? this.idVehiculo,
      latitud: latitud ?? this.latitud,
      longitud: longitud ?? this.longitud,
    );
  }
}
