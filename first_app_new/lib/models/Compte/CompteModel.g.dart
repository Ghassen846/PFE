// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'CompteModel.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Compte _$CompteFromJson(Map<String, dynamic> json) => Compte(
      email: json['email'] as String,
      motDePasse: json['motDePasse'] as String,
      name: json['name'] as String,
    );

Map<String, dynamic> _$CompteToJson(Compte instance) => <String, dynamic>{
      'name': instance.name,
      'email': instance.email,
      'motDePasse': instance.motDePasse,
    };
