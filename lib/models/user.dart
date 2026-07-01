class AppUser {
  final String authId;
  final String nome;
  final String telefone;
  final String provincia;
  final String dataNascimento;
  final String role;
  final bool ativo;

  AppUser({
    required this.authId,
    required this.nome,
    this.telefone = '',
    this.provincia = 'Luanda',
    this.dataNascimento = '2000-01-01',
    this.role = 'user',
    this.ativo = true,
  });

  factory AppUser.fromMap(Map<String, dynamic> map) {
    return AppUser(
      authId: map['auth_id'] as String? ?? '',
      nome: map['nome'] as String? ?? '',
      telefone: map['telefone'] as String? ?? '',
      provincia: map['provincia'] as String? ?? 'Luanda',
      dataNascimento: map['data_nascimento'] as String? ?? '2000-01-01',
      role: map['role'] as String? ?? 'user',
      ativo: map['ativo'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() => {
    'auth_id': authId,
    'nome': nome,
    'telefone': telefone,
    'provincia': provincia,
    'data_nascimento': dataNascimento,
    'role': role,
    'ativo': ativo,
  };

  AppUser copyWith({
    String? nome,
    String? telefone,
    String? provincia,
    String? dataNascimento,
  }) => AppUser(
    authId: authId,
    nome: nome ?? this.nome,
    telefone: telefone ?? this.telefone,
    provincia: provincia ?? this.provincia,
    dataNascimento: dataNascimento ?? this.dataNascimento,
    role: role,
    ativo: ativo,
  );
}
