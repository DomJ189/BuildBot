// Represents a graphics card with performance and pricing details
class GPU {
  final String name;      // Full model name
  final String wattage;   // Power consumption
  final String vram;      // Video memory capacity
  final int benchmark;    // Performance benchmark score
  final double price;     // Current market price
  final int value;        // Price-to-performance ratio
  final String url;       // Link to more details

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

// Pairs a GPU with a budget category for recommendations
class GPURecommendation {
  final String budget;    // Budget category (e.g. "Under $300")
  final GPU gpu;          // Recommended GPU for this budget
  
  GPURecommendation({
    required this.budget,
    required this.gpu,
  });
} 