```
╔═══════════════════════════════════════════════════════════════════════════╗
║                    🤖 AI COPILOT ARCHITECTURE                            ║
╚═══════════════════════════════════════════════════════════════════════════╝

┌─────────────────────────────────────────────────────────────────────────┐
│                          USER INTERFACE LAYER                           │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  AIAssistantScreen                                               │  │
│  │  ├─ Chat messages (user ↔ assistant)                            │  │
│  │  ├─ Quick action chips (5 common tasks)                         │  │
│  │  ├─ Status indicator (Ready/Initializing)                       │  │
│  │  ├─ Step-by-step display (numbered list)                        │  │
│  │  └─ Route suggestions (Open Screen buttons)                     │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                     STATE MANAGEMENT LAYER (Provider)                   │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  GeminiAssistantProvider (ChangeNotifier)                        │  │
│  │  ├─ isInitialized: bool                                          │  │
│  │  ├─ isLoadingResponse: bool                                      │  │
│  │  ├─ error: String?                                               │  │
│  │  ├─ getResponse()        → Returns structured reply              │  │
│  │  ├─ troubleshootIssue()  → For problem solving                  │  │
│  │  ├─ generateFAQ()        → Creates Q&A                           │  │
│  │  └─ clearError()         → Error handling                        │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                      BUSINESS LOGIC LAYER (Service)                     │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  GeminiAIAssistantService                                        │  │
│  │                                                                   │  │
│  │  Core Methods:                                                   │  │
│  │  ├─ getAssistantResponse()      Main method                      │  │
│  │  │  ├─ Finds related knowledge entries                           │  │
│  │  │  ├─ Builds system prompt (knows app features)                 │  │
│  │  │  ├─ Calls Gemini API                                          │  │
│  │  │  ├─ Extracts steps from response                              │  │
│  │  │  └─ Returns GeminiAssistantReply                              │  │
│  │  │                                                                │  │
│  │  ├─ getAssistantResponseStream()  For long responses             │  │
│  │  │  └─ Streams text as it's generated                            │  │
│  │  │                                                                │  │
│  │  ├─ troubleshootIssue()         Problem solving                  │  │
│  │  │  └─ Creates diagnostic prompt                                 │  │
│  │  │                                                                │  │
│  │  ├─ generateFAQ()               FAQ creation                     │  │
│  │  │  └─ Creates Q&A pairs                                         │  │
│  │  │                                                                │  │
│  │  └─ Helper Methods:                                              │  │
│  │     ├─ _buildSystemPrompt()   Comprehensive app knowledge        │  │
│  │     ├─ _buildKnowledgeContext()  All features as context         │  │
│  │     ├─ _findRelatedEntries()  Match to knowledge base            │  │
│  │     └─ _extractSteps()        Parse numbered steps               │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                        LOW-LEVEL LAYER (API)                            │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  GeminiAIService                                                 │  │
│  │  ├─ initialize()              Initialize Gemini                  │  │
│  │  ├─ generateText()            Basic text generation              │  │
│  │  ├─ generateTextStream()      Streaming text                    │  │
│  │  └─ countTokens()             Cost estimation                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Support Services                                                │  │
│  │  └─ ai_support_knowledge.dart   Knowledge base of app features   │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘
                                    ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                        EXTERNAL APIs & DATA                             │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Google Generative AI API (Gemini)                               │  │
│  │  ├─ Model: gemini-3-flash-preview                                │  │
│  │  ├─ Provides: generateContent(), generateContentStream()         │  │
│  │  └─ Features: Text generation, streaming, token counting         │  │
│  └──────────────────────────────────────────────────────────────────┘  │
│                                                                           │
│  ┌──────────────────────────────────────────────────────────────────┐  │
│  │  Firebase Services (existing)                                    │  │
│  │  ├─ Firebase Auth          User authentication                  │  │
│  │  ├─ Cloud Firestore        Data persistence                     │  │
│  │  └─ Firebase Console       Monitoring & logs                    │  │
│  └──────────────────────────────────────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════

DATA FLOW:

User Types Message
       ↓
AIAssistantScreen receives input
       ↓
_onSend() → GeminiAssistantProvider.getResponse()
       ↓
GeminiAIAssistantService processes
       ├─ Finds related knowledge entries
       ├─ Builds AI prompt with app context
       ├─ Calls GeminiAIService.generateText()
       └─ Extracts steps from response
       ↓
Response: GeminiAssistantReply
  ├─ text: Complete response
  ├─ steps: [List of numbered steps]
  ├─ suggestedRoute: Route to relevant screen
  └─ fromGemini: true
       ↓
AIAssistantScreen displays
  ├─ Formats response nicely
  ├─ Shows numbered steps
  ├─ Adds "Open Screen" button
  └─ Updates UI with reply

═══════════════════════════════════════════════════════════════════════════

COMPONENT RELATIONSHIPS:

    AIAssistantScreen
         ↑ ↓
         │ (uses)
         ↓
    GeminiAssistantProvider ←════════╗
         ↑                           ║
         │ (contains)                ║
         ↓                           ║
  GeminiAIAssistantService           ║
         ↑                           ║
         │ (uses)                    ║
         ↓                           ║
  GeminiAIService ←── Firebase AI ←══╝
         │
         ├─ Uses: ai_support_knowledge.dart (knowledge base)
         └─ Uses: Firebase Authentication (user context)

═══════════════════════════════════════════════════════════════════════════

KEY FEATURES BY COMPONENT:

┌─────────────────────────────────────────────────────────────────────────┐
│ SERVICE                               RESPONSIBILITY                     │
├─────────────────────────────────────────────────────────────────────────┤
│ GeminiAIAssistantService              Intelligent responses             │
│                                        Step extraction                   │
│                                        Context awareness                 │
│                                        Knowledge integration             │
├─────────────────────────────────────────────────────────────────────────┤
│ GeminiAIService                        Gemini API interaction            │
│                                        Model management                  │
│                                        Initialization                    │
│                                        Token counting                    │
├─────────────────────────────────────────────────────────────────────────┤
│ GeminiAssistantProvider                State management                  │
│                                        Error handling                    │
│                                        Loading states                    │
│                                        Provider pattern                  │
├─────────────────────────────────────────────────────────────────────────┤
│ AIAssistantScreen                     User interface                    │
│                                        Chat display                      │
│                                        Message formatting                │
│                                        Navigation                        │
└─────────────────────────────────────────────────────────────────────────┘

═══════════════════════════════════════════════════════════════════════════
```

**SUMMARY**: A clean, layered architecture with clear separation of concerns:
- **UI Layer**: Handles display and user interaction
- **State Layer**: Manages application state with Provider
- **Business Logic**: Intelligence and decision-making
- **Service Layer**: Low-level API interactions
- **Data Layer**: Know knowledge base and user context

All components work together seamlessly to deliver intelligent, contextual
assistance to users through a natural conversation interface.
