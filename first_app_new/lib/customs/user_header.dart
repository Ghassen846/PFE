import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class UserHeader extends StatelessWidget {
  final String name;
  final String email;
  final double rating;
  final String avatarUrl;

  const UserHeader({
    super.key,
    required this.name,
    required this.email,
    required this.rating,
    required this.avatarUrl,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 1,
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 10.0),
      margin: const EdgeInsets.symmetric(vertical: 10.0, horizontal: 16.0),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundImage: AssetImage(avatarUrl),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                Text(email,
                    style: const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
          RatingBarIndicator(
            rating: rating,
            itemBuilder: (context, index) =>
                const Icon(Icons.star, color: Colors.amber),
            itemCount: 5,
            itemSize: 20.0,
            direction: Axis.horizontal,
          ),
          const SizedBox(width: 10),
        ],
      ),
    );
  }
}
