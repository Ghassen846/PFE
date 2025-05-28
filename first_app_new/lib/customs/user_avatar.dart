import 'package:flutter/material.dart';
import '../models/chat_model/chat_user.dart';

class UserAvatar extends StatelessWidget {
  final ChatUser user;
  final double size;
  final VoidCallback? onTap;

  const UserAvatar({super.key, required this.user, this.size = 40.0, this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          CircleAvatar(
            radius: size / 2,
            backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
            backgroundImage:
                user.avatar != null && user.avatar!.isNotEmpty
                    ? NetworkImage(user.avatar!)
                    : null,
            child:
                user.avatar == null || user.avatar!.isEmpty
                    ? Text(
                      user.name.isNotEmpty
                          ? user.name.substring(0, 1).toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: size / 2,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).primaryColor,
                      ),
                    )
                    : null,
          ),
          if (user.isOnline)
            Positioned(
              right: 0,
              bottom: 0,
              child: Container(
                width: size / 4,
                height: size / 4,
                decoration: BoxDecoration(
                  color: Colors.green,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Theme.of(context).scaffoldBackgroundColor,
                    width: 2,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
