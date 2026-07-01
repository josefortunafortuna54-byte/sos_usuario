class Ocorrencia {
  final String id;
  final String userId;
  final String tipo;
  final String status;
  final String? descricao;
  final double? latitude;
  final double? longitude;
  final String createdAt;
  final String? updatedAt;
  final String? agentId;

  Ocorrencia({
    required this.id,
    required this.userId,
    required this.tipo,
    required this.status,
    this.descricao,
    this.latitude,
    this.longitude,
    required this.createdAt,
    this.updatedAt,
    this.agentId,
  });

  factory Ocorrencia.fromMap(Map<String, dynamic> map) {
    return Ocorrencia(
      id: map['id'] as String? ?? '',
      userId: map['user_id'] as String? ?? '',
      tipo: map['tipo'] as String? ?? '',
      status: map['status'] as String? ?? 'Pendente',
      descricao: map['descricao'] as String?,
      latitude: (map['latitude'] as num?)?.toDouble(),
      longitude: (map['longitude'] as num?)?.toDouble(),
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String?,
      agentId: map['agent_id'] as String?,
    );
  }

  bool get estaActiva => status != 'Finalizado';

  bool get temCoordenadas => latitude != null && longitude != null;
}
