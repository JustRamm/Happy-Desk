import 'package:flutter/material.dart';

class BackgroundCardStack extends StatelessWidget {
  const BackgroundCardStack({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment.topCenter,
          minHeight: 0,
          maxHeight: 1600,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              const SizedBox(height: 120),
              // Top subtle background card silhouette
              _buildSubtleCard(scale: 0.88, opacity: 0.25),
              const SizedBox(height: 16),
              // Middle background card silhouette
              _buildSubtleCard(scale: 0.92, opacity: 0.35),
              const SizedBox(height: 16),
              // Bottom background card silhouette
              _buildSubtleCard(scale: 0.96, opacity: 0.45),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSubtleCard({required double scale, required double opacity}) {
    return Transform.scale(
      scale: scale,
      child: Opacity(
        opacity: opacity,
        child: Container(
          width: 260,
          height: 340,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.8),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 20,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Subtle abstract logo placeholder inside card
              Icon(
                Icons.spa_outlined,
                size: 32,
                color: Colors.grey.withValues(alpha: 0.2),
              ),
              const SizedBox(height: 8),
              Text(
                'AURA',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 3,
                  color: Colors.grey.withValues(alpha: 0.25),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Connecting Minds',
                style: TextStyle(
                  fontSize: 9,
                  letterSpacing: 1.5,
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  4,
                  (index) => Container(
                    margin: const EdgeInsets.all(2),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
