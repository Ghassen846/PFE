import 'package:json_annotation/json_annotation.dart';

part 'CompteModel.g.dart';

@JsonSerializable()
class Compte {
  @JsonKey(name: 'name')
  final String name;

  @JsonKey(name: 'email')
  final String email;

  @JsonKey(name: 'motDePasse')
  final String motDePasse;

  Compte({required this.email, required this.motDePasse, required this.name});

  factory Compte.fromJson(Map<String, dynamic> json) => _$CompteFromJson(json);
  Map<String, dynamic> toJson() => _$CompteToJson(this);
}
