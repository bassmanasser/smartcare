class ApiConfig {
  static const String arrhythmiaBaseUrl =
      'https://mariam2112-smartheart-api.hf.space';

  static const String arrhythmiaPredictEndpoint = '/predict';

  // حط هنا لينك الـ Firebase Function بعد deploy
  // مثال:
  // https://us-central1-YOUR_PROJECT_ID.cloudfunctions.net/aiChat
  static const String aiChatEndpoint =
      'https://YOUR_REGION-YOUR_PROJECT_ID.cloudfunctions.net/aiChat';

  static get baseUrl => null;

  static get analyzeEndpoint => null;
}
