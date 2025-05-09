import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tiwee/presentation/screens/home/menu.dart';
import 'package:tiwee/presentation/screens/home/setting.dart';

final pageControllerProvider = Provider<PageController>((ref) {
  return PageController();
});

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(pageControllerProvider);
    return PageView.builder(
      itemCount: 2,
      controller: controller,
      scrollDirection: Axis.horizontal,
      physics: const NeverScrollableScrollPhysics(),
      itemBuilder: (context, index) => index == 0 
        ? const Menu() 
        : const Setting(),
    );
  }
}
