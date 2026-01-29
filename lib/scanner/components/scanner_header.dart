import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:mobile_scanner/mobile_scanner.dart' as state;

class ScannerHeader extends StatelessWidget {
  final MobileScannerController controller;
  const ScannerHeader({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsetsGeometry.symmetric(horizontal: 20, vertical: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            InkWell(
              onTap: () => Navigator.pop(context),
              child: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(50)
                ),
                child: Icon(Icons.arrow_back_ios_new_rounded, ),
              ),
          ),
          Text(
            "scanner",
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.bold
            ),
          ),
          // flash light button
          ValueListenableBuilder(
            valueListenable: controller,
            builder: (context, value, child) {
              // ignore: unrelated_type_equality_checks
              final isOn = state.TorchState == TorchState.on;
              return InkWell(
                onTap: () => controller.toggleTorch(),
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isOn ? Colors.yellowAccent.withValues(alpha: 0.8) : Colors.white24,
                    borderRadius: BorderRadius.circular(50)
                  ),
                  child: Icon(
                    isOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                     color: isOn ? Colors.black : Colors.white,
                  ),
                ),
              );
            },
          )
          ],
        ),
      ), 
    );
  }
}