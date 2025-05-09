import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/svg.dart';
import 'package:line_icons/line_icons.dart';
import 'package:tiwee/presentation/screens/home/home_page.dart';
import 'package:tiwee/business_logic/provider/channel_provider.dart';

final forwardProvider = StateNotifierProvider<ForwardNotifier, bool>((ref) {
  return ForwardNotifier();
});

class ForwardNotifier extends StateNotifier<bool> {
  ForwardNotifier() : super(true);

  void toggle() => state = !state;
}

class MainAppBar extends StatelessWidget implements PreferredSizeWidget {
  const MainAppBar({super.key});

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 1, horizontal: 7),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(9),
              color: Colors.red,
            ),
            child: const Text(
              "Live",
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Text(
            "TV",
            style: TextStyle(
              fontSize: 23,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class MainAppbar extends ConsumerWidget {
  final Widget widget;
  final bool havSettingBtn;

  const MainAppbar({
    super.key,
    required this.widget,
    this.havSettingBtn = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      height: 60,
      decoration: const BoxDecoration(
        color: Colors.black,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          widget,
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  ref.read(channelProvider.notifier).refreshChannels();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Atualizando listas...'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
              ),
              if (havSettingBtn)
                IconButton(
                  icon: const Icon(Icons.settings, color: Colors.white),
                  onPressed: () {
                    // TODO: Implement settings
                  },
                          ),
            ],
          ),
        ],
      ),
    );
  }
}
