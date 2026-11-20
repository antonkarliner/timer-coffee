import 'package:cached_network_image/cached_network_image.dart';
import 'package:coffee_timer/config/supabase_endpoint_resolver.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AccountAvatarInline extends StatefulWidget {
  final double size;

  const AccountAvatarInline({super.key, this.size = 24});

  @override
  State<AccountAvatarInline> createState() => _AccountAvatarInlineState();
}

class _AccountAvatarInlineState extends State<AccountAvatarInline> {
  String? _imageUrl;

  @override
  void initState() {
    super.initState();
    _loadImageUrl();
  }

  Future<void> _loadImageUrl() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final user = Supabase.instance.client.auth.currentUser;

      if (user == null) return;
      final key = 'user_profile_picture_url_${user.id}';
      final cachedUrl = prefs.getString(key);
      if (cachedUrl != null && cachedUrl.isNotEmpty) {
        if (mounted) setState(() => _imageUrl = cachedUrl);
        return;
      }

      final response = await Supabase.instance.client
          .from('user_public_profiles')
          .select('profile_picture_url')
          .eq('user_id', user.id)
          .maybeSingle();

      if (response != null) {
        final url = response['profile_picture_url'] as String?;
        if (url != null && url.isNotEmpty) {
          await prefs.setString(key, url);
          if (Supabase.instance.client.auth.currentUser?.id != user.id) return;
          if (mounted) setState(() => _imageUrl = url);
        }
      }
    } catch (_) {
      // Silently ignore errors here; we fall back to the icon.
    }
  }

  @override
  Widget build(BuildContext context) {
    final iconColor =
        IconTheme.of(context).color ??
        Theme.of(context).colorScheme.onSurface.withAlpha((255 * 0.6).round());
    final size = widget.size;

    if (_imageUrl == null) {
      return Icon(Icons.person, size: size, color: iconColor);
    }

    return ClipOval(
      child: SizedBox(
        width: size,
        height: size,
        child: CachedNetworkImage(
          imageUrl: SupabaseEndpointResolver.localizeStorageUrl(_imageUrl!),
          fit: BoxFit.cover,
          placeholder: (context, url) =>
              Icon(Icons.person, size: size, color: iconColor),
          errorWidget: (context, url, error) =>
              Icon(Icons.person, size: size, color: iconColor),
        ),
      ),
    );
  }
}
