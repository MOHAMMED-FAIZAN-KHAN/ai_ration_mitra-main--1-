# Gemini Firebase AI Integration Guide

This document explains how to integrate and use Google's Generative AI (Gemini) with Firebase in your Flutter app.

## ✅ Setup Complete

The following components have been added to your project:

### 1. **Dependencies** (pubspec.yaml)
- `firebase_ai: ^2.3.0` - Firebase AI Logic plugin for Flutter

### 2. **Service Layer** (lib/services/gemini_ai_service.dart)
- `GeminiAIService` - Core service for Gemini API interactions
- Handles initialization, text generation, streaming, multimodal content, and token counting

### 3. **State Management** (lib/providers/gemini_ai_provider.dart)
- `GeminiAIProvider` - Provider for managing Gemini AI service state
- Integrates with Flutter's Provider package for easy app-wide access

### 4. **Example Implementation** (lib/screens/chat/gemini_ai_example_screen.dart)
- Complete example screen showing all Gemini AI features
- Text generation, streaming, token counting, and error handling

---

## 📖 How to Use

### Basic Setup in Your Widgets

```dart
class MyWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GeminiAIProvider>(
      builder: (context, geminiProvider, _) {
        return Center(
          child: Column(
            children: [
              Text(geminiProvider.isInitialized 
                ? 'Ready' 
                : 'Initializing...'),
              ElevatedButton(
                onPressed: () => geminiProvider.initialize(),
                child: const Text('Initialize AI'),
              ),
            ],
          ),
        );
      },
    );
  }
}
```

### 1. Initialize the Service

Call this once when your app starts or when the user navigates to a feature that uses AI:

```dart
final geminiProvider = context.read<GeminiAIProvider>();
await geminiProvider.initialize();

// Check if initialized
if (geminiProvider.isInitialized) {
  print('Gemini AI is ready!');
}
```

### 2. Generate Text from a Prompt

Simple text generation for queries:

```dart
final response = await geminiProvider.generateText(
  'Write a story about a magic backpack in 50 words.',
);

print(response); // Output: Your generated text
```

### 3. Stream Responses (Real-time)

For better UX with long responses, use streaming:

```dart
final stream = await geminiProvider.generateTextStream(
  'Explain quantum physics in simple terms.',
);

if (stream != null) {
  await for (final chunk in stream) {
    setState(() {
      _text += chunk; // Update UI with each chunk
    });
  }
}
```

### 4. Generate Multimodal Content (Text + Images)

```dart
final response = await geminiProvider.generateMultimodalContent(
  'What is in this image? Describe it in detail.',
  imageFilePaths: ['/path/to/image.png'],
);

print(response); // Description of the image
```

### 5. Count Tokens (Cost Estimation)

Before sending a prompt, estimate the token cost:

```dart
final tokenCount = await geminiProvider.countTokens(
  'Your prompt here',
);

print('This prompt uses $tokenCount tokens');
// Use this to estimate API costs
```

### 6. Error Handling

```dart
// Check for errors
if (geminiProvider.error != null) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: ${geminiProvider.error}')),
  );
  
  // Clear the error
  geminiProvider.clearError();
}

// Handle async errors
try {
  final response = await geminiProvider.generateText(prompt);
} catch (e) {
  print('Error: $e');
}
```

---

## 💡 Use Cases

### Chat Assistant
```dart
// User asks: "How do I apply for ration?"
final response = await geminiProvider.generateText(
  'How do I apply for ration in the AI Ration Mitra app?'
);
// Returns helpful guidance based on Gemini's knowledge
```

### Content Generation
```dart
// Generate grievance response templates
final template = await geminiProvider.generateText(
  'Generate a professional grievance resolution message for issue: $issueDetails'
);
```

### Document Analysis
```dart
// Analyze uploaded documents/images
final analysis = await geminiProvider.generateMultimodalContent(
  'Analyze this document and extract key information',
  imageFilePaths: [documentPath],
);
```

### FAQ Generator
```dart
// Generate FAQ based on your app
final faqs = await geminiProvider.generateText(
  'Generate 10 common questions users have about public distribution system'
);
```

---

## ⚙️ Configuration

### Change the Gemini Model

Edit `lib/services/gemini_ai_service.dart`:

```dart
// Current model (recommended for most use cases)
_model = FirebaseAI.googleAI()
    .generativeModel(model: 'gemini-3-flash-preview');

// Or use other available models:
// - 'gemini-1.5-pro' (more powerful, higher cost)
// - 'gemini-1.5-flash' (faster, lower cost)
// - 'gemini-2-flash' (latest model)
```

### Use Remote Config (Recommended for Production)

Instead of hardcoding the model, use Firebase Remote Config:

```dart
import 'package:firebase_remote_config/firebase_remote_config.dart';

final remoteConfig = FirebaseRemoteConfig.instance;
await remoteConfig.ensureInitialized();
final modelName = remoteConfig.getString('gemini_model_name');

_model = FirebaseAI.googleAI()
    .generativeModel(model: modelName);
```

This allows you to change models without updating your app!

---

## 🔑 Important Notes

### 1. Firebase Setup

Your Firebase project needs:
- ✅ Blaze pricing plan (pay-as-you-go)
- ✅ Generative AI API enabled in Cloud Console
- ✅ Proper authentication configured

### 2. API Costs

Check the [Firebase Pricing](https://firebase.google.com/pricing/generative-ai) page:
- Text generation costs are calculated per token
- Streaming uses the same pricing as non-streaming
- Use `countTokens()` to estimate costs before requests

### 3. Rate Limiting

Be aware of API rate limits:
- Have error handling for rate limit errors
- Implement exponential backoff for retries
- Monitor token usage in Firebase Console

### 4. Security

- Never hardcode API keys in your app
- Use Firebase Authentication rules
- Validate user permissions before generating content
- Use Remote Config to disable features if needed

---

## 🧪 Testing

Run the example screen to test everything:

```dart
// In your main.dart navigation:
case '/test-gemini-ai':
  return MaterialPageRoute(
    builder: (_) => const GeminiAIExampleScreen(),
  );
```

Then navigate to that route in your app.

---

## 📚 Full API Reference

### GeminiAIService Methods

| Method | Description |
|--------|-------------|
| `initialize()` | Initialize the Gemini AI service |
| `generateText(prompt)` | Generate text from a prompt |
| `generateTextStream(prompt)` | Stream text response |
| `generateMultimodalContent(prompt, imageFilePaths)` | Generate response with images |
| `countTokens(prompt)` | Count tokens in a prompt |

### GeminiAIProvider State

| Property | Type | Description |
|----------|------|-------------|
| `isInitialized` | bool | Service is initialized |
| `isInitializing` | bool | Service is currently initializing |
| `error` | String? | Current error message (if any) |
| `service` | GeminiAIService | Access to underlying service |

---

## 🚀 Next Steps

1. **Test the example screen** - Navigate to GeminiAIExampleScreen and test features
2. **Integrate into your existing screens** - Use the Console widget patterns shown
3. **Add production features** - Implement Remote Config and analytics
4. **Monitor usage** - Check Firebase Console for API usage and costs
5. **Optimize prompts** - Test and refine prompts for better responses

---

## 🐛 Troubleshooting

### "Gemini AI Service is not initialized"
- Call `initialize()` first: `await geminiProvider.initialize();`
- Check that Firebase is properly initialized in `main.dart`

### "Firebase project not set up with Blaze pricing"
- Go to Firebase Console → Usage and billing
- Switch to Blaze (Pay as you go) plan

### "No response received"
- Check internet connection
- Verify Firebase credentials in `android/app/google-services.json`
- Check token limits and API quotas in Firebase Console

### "Token count returns null"
- Ensure the service is initialized
- Check network connectivity
- Verify Firebase permissions

---

## 📞 Support

For issues with:
- **Firebase AI**: [Firebase AI Docs](https://firebase.google.com/docs/generative-ai)
- **Gemini API**: [Google AI Studio](https://aistudio.google.com/)
- **Flutter Integration**: Check `lib/screens/chat/gemini_ai_example_screen.dart`

---

**Integration completed on: March 13, 2026**
