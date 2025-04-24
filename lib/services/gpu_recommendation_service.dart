import 'package:http/http.dart' as http;
import 'package:html/parser.dart' as parser;
import '../models/gpu_model.dart';

class GPURecommendationService {
  static const String _baseUrl = 'https://bestvaluegpu.com';
  
  /// Fetches the best value GPUs based on current market data
  Future<List<GPU>> fetchBestValueGPUs({bool newOnly = true}) async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch GPU data: ${response.statusCode}');
      }
      
      final document = parser.parse(response.body);
      final gpuTable = document.querySelector('.comparison-table table');
      
      if (gpuTable == null) {
        return [];
      }
      
      final rows = gpuTable.querySelectorAll('tr');
      // Skip the header row
      final gpus = <GPU>[];
      
      for (var i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          final cells = row.querySelectorAll('td');
          
          if (cells.length < 6) continue;
          
          // Extract data from cells
          final nameCell = cells[0];
          final nameLink = nameCell.querySelector('a');
          final name = nameLink?.text.trim() ?? '';
          final url = nameLink?.attributes['href'] ?? '';
          
          final wattage = cells[1].text.trim();
          final vram = cells[2].text.trim();
          
          // Parse benchmark score
          final benchmarkText = cells[3].text.trim();
          final benchmark = int.tryParse(benchmarkText.replaceAll(',', '')) ?? 0;
          
          // Parse price from the text
          final priceLink = cells[4].querySelector('a');
          final priceText = priceLink?.text.trim() ?? '';
          final priceMatch = RegExp(r'\$\s*(\d+(?:\.\d+)?)').firstMatch(priceText);
          final price = priceMatch != null ? 
              double.tryParse(priceMatch.group(1) ?? '0') ?? 0.0 : 0.0;
              
          // Parse value score
          final valueText = cells[5].text.trim();
          final value = int.tryParse(valueText) ?? 0;
          
          if (name.isNotEmpty && price > 0) {
            gpus.add(GPU(
              name: name,
              wattage: wattage,
              vram: vram,
              benchmark: benchmark,
              price: price,
              value: value,
              url: url.startsWith('/') ? '$_baseUrl$url' : url,
            ));
          }
        } catch (e) {
          print('Error parsing row: $e');
          continue;
        }
      }
      
      return gpus;
    } catch (e) {
      print('Error fetching best value GPUs: $e');
      return [];
    }
  }
  
  /// Fetches GPU recommendations by budget (under $200, $300, $400, $500)
  Future<List<GPURecommendation>> fetchRecommendationsByBudget({bool newOnly = true}) async {
    try {
      final response = await http.get(Uri.parse(_baseUrl));
      if (response.statusCode != 200) {
        throw Exception('Failed to fetch recommendations: ${response.statusCode}');
      }
      
      final document = parser.parse(response.body);
      final recommendations = <GPURecommendation>[];
      
      // Get the top picks section
      final section = newOnly ? 
          document.querySelector("h2:contains('Today\\'s Top Picks (New)')") :
          document.querySelector("h2:contains('Today\\'s Top Picks (Used)')");
      
      if (section == null) {
        return [];
      }
      
      // Find the table after this section
      final table = section.nextElementSibling;
      if (table == null || table.localName != 'table') {
        return [];
      }
      
      // Process rows in the table
      final rows = table.querySelectorAll('tr');
      
      // Skip header row
      for (var i = 1; i < rows.length; i++) {
        try {
          final row = rows[i];
          final cells = row.querySelectorAll('td');
          
          if (cells.length < 4) continue;
          
          // Extract budget
          final budgetCell = cells[0];
          final budgetLink = budgetCell.querySelector('a');
          final budget = budgetLink?.text.trim() ?? '';
          
          // Extract GPU name
          final nameCell = cells[1];
          final nameLink = nameCell.querySelector('a');
          final name = nameLink?.text.trim() ?? '';
          final url = nameLink?.attributes['href'] ?? '';
          
          // Extract price
          final priceCell = cells[2];
          final priceLink = priceCell.querySelector('a');
          final priceText = priceLink?.text.trim() ?? '';
          final priceMatch = RegExp(r'\$\s*(\d+(?:\.\d+)?)').firstMatch(priceText);
          final price = priceMatch != null ? 
              double.tryParse(priceMatch.group(1) ?? '0') ?? 0.0 : 0.0;
              
          // Extract value score
          final valueText = cells[3].text.trim();
          final value = int.tryParse(valueText) ?? 0;
          
          if (name.isNotEmpty && price > 0) {
            recommendations.add(GPURecommendation(
              budget: budget,
              gpu: GPU(
                name: name,
                wattage: 'N/A', // These details aren't in the recommendation table
                vram: 'N/A',
                benchmark: 0,
                price: price,
                value: value,
                url: url.startsWith('/') ? '$_baseUrl$url' : url,
              ),
            ));
          }
        } catch (e) {
          print('Error parsing recommendation row: $e');
          continue;
        }
      }
      
      return recommendations;
    } catch (e) {
      print('Error fetching recommendations by budget: $e');
      return [];
    }
  }
  
  /// Gets GPU recommendations based on a budget amount
  Future<List<GPU>> getRecommendationsForBudget(double budget) async {
    final allGpus = await fetchBestValueGPUs();
    
    // Filter GPUs based on price
    final affordableGpus = allGpus.where((gpu) => gpu.price <= budget).toList();
    
    // Sort by value score (higher is better)
    affordableGpus.sort((a, b) => b.value.compareTo(a.value));
    
    // Return top 3 recommendations or fewer if not enough available
    return affordableGpus.take(3).toList();
  }
  
  /// Finds GPUs similar to a specific model
  Future<List<GPU>> findSimilarGPUs(String gpuModel) async {
    final allGpus = await fetchBestValueGPUs();
    
    // First try to find the exact GPU
    final targetGpu = allGpus.where(
      (gpu) => gpu.name.toLowerCase().contains(gpuModel.toLowerCase())
    ).toList();
    
    if (targetGpu.isEmpty) {
      return [];
    }
    
    // Find similar GPUs based on benchmark score (within 15% range)
    final benchmark = targetGpu.first.benchmark;
    final lowerBound = benchmark * 0.85;
    final upperBound = benchmark * 1.15;
    
    final similarGpus = allGpus.where((gpu) => 
      gpu.name != targetGpu.first.name && 
      gpu.benchmark >= lowerBound && 
      gpu.benchmark <= upperBound
    ).toList();
    
    // Sort by value score
    similarGpus.sort((a, b) => b.value.compareTo(a.value));
    
    return similarGpus.take(3).toList();
  }
} 