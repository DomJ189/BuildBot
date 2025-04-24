class GPU {
  final String name;
  final String wattage;
  final String vram;
  final int benchmark;
  final double price;
  final int value;
  final String url;

  GPU({
    required this.name,
    required this.wattage,
    required this.vram,
    required this.benchmark,
    required this.price,
    required this.value,
    required this.url,
  });

  @override
  String toString() {
    return '$name ($vram) - \$$price - $wattage';
  }
}

class GPURecommendation {
  final String budget;
  final GPU gpu;
  
  GPURecommendation({
    required this.budget,
    required this.gpu,
  });
} 