import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async{
  final response = await http.post(
    Uri.parse('https://openai-proxy.dmj08bot.workers.dev/openaiproxy'),
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode({
      "model": "gpt-4o-mini",
      "messages": [
        {
          "role": "system",
          "content": "Does the definition fit the official word definition? YES or NO only."
        },
        {
          "role": "user",
          "content": "Word: ball\nDefinition: a solid or hollow spherical or egg-shaped object"
        }
      ]
    }),
  );
  print(response.body);

  // Parse and print the JSON response
  final data = jsonDecode(response.body);
  print(data);

  // To get the assistant's reply:
  print(data['choices'][0]['message']['content']);
}