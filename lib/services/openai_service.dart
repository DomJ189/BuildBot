import 'dart:convert';
import 'package:http/http.dart' as http;

// Handles communication with the OpenAI API for generating responses
class OpenAiService {
  final String apiKey; // API key for authenticating requests to OpenAI

  // Constructor to initialize the OpenAiService with the provided API key
  OpenAiService(this.apiKey);

  // Fetches a response from the OpenAI API based on the provided prompt
  Future<String> fetchResponse(String prompt) async {
    try {
      // Define the URL for the OpenAI chat completions endpoint
      final url = Uri.parse('https://api.openai.com/v1/chat/completions');
      
      // Send a POST request to the OpenAI API
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json', // Specify the content type
          'Authorization': 'Bearer $apiKey', // Include the API key in the authorization header
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini', // Specify the model to use
          'messages': [
            {
              'role': 'system',
              'content': 'You are a helpful PC-building maintenance and configuration assistant.' // System message to set the assistant's behavior
            },
            {
              'role': 'user',
              'content': prompt // User's prompt for the assistant
            }
          ],
          'temperature': 0.7, // Controls the randomness of the output
          'max_tokens': 1000, // Maximum number of tokens in the response
        }),
      );

      // Check if the response status is OK (200)
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body); // Decode the JSON response
        return data['choices'][0]['message']['content'].toString().trim(); // Extract and return the assistant's response
      } else {
        // Log error details if the response is not successful
        print('Error: ${response.statusCode}');
        print('Response body: ${response.body}');
        throw Exception('Failed to fetch response: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      // Log any exceptions that occur during the fetch process
      print('Error in fetchResponse: $e');
      throw Exception('Failed to fetch response: $e'); // Rethrow the exception for further handling
    }
  }
}
