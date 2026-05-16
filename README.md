# TextSnap OCR 📸

> A hybrid OCR Flutter application combining offline English text recognition with cloud-powered Urdu OCR for superior accuracy.

**TextSnap OCR** is a lightweight Flutter application designed for extracting text from images. It was built both for personal use and as a demonstration of integrating on-device Machine Learning with Cloud AI in a mobile environment. 

## Features

*   **⚡ Blazing Fast English OCR:** Utilizes **Google ML Kit** for 100% offline, on-device text recognition. Your English documents never leave your phone.
*   **🌍 High-Accuracy Urdu OCR:** Integrates Google's **Gemini 2.5 Flash Vision API** to handle the complexities of cursive Nastaliq Urdu script, delivering production-grade accuracy where offline models fail.
*   **📸 Native Camera & Cropping:** Capture images directly from your device camera with an intuitive native crop editor to frame exactly what you need.
*   **🛡️ Abuse Prevention:** Built-in rate limiting (15 requests/min) and 4-second cooldown between consecutive requests to prevent accidental API spamming.
*   **🎨 Clean Material 3 UI:** Beautiful turquoise-themed Material 3 interface with smooth animations and responsive feedback.
*   **🔤 Language Selection:** Toggle between English and Urdu recognition modes with a simple language picker widget.

## Getting Started

### Prerequisites

- Flutter SDK (3.0+)
- Dart SDK (3.0+)
- Android device or emulator (API 21+)
- Google Gemini API Key (free tier available)

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/maheenmmzafeer/text_extraction.git
   cd text_extraction
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure your API key:**
   - Get a free Gemini API key from [Google AI Studio](https://aistudio.google.com/apikey)
   - Create a `.env` file in the project root:
     ```
     GEMINI_API_KEY=your_actual_gemini_api_key_here
     ```

4. **Run the app:**
   ```bash
   flutter run
   ```

## Why this architecture?

This project was built to demonstrate a hybrid OCR approach:
1.  **Speed & Privacy First:** For Latin-based text (English), ML Kit delivers instant, fully offline processing. No cloud dependency = no data transmission.
2.  **Power When Needed:** Urdu script is notoriously difficult for lightweight offline models. By offloading Urdu to Gemini 2.5 Flash, the app achieves production-grade accuracy without significantly increasing app size.

## How It Works

### English OCR (Offline)
- Powered by Google ML Kit's text recognition
- Fully local processing—zero API calls
- Instant results

### Urdu OCR (Cloud)
- Powered by Gemini 2.5 Flash with vision capabilities
- Sends base64-encoded image to Google's generative API
- Returns extracted Urdu text with minimal latency
- Subject to Gemini's free tier quota (rate limiting enforced on client)

## Rate Limiting & Usage Limits

To prevent accidental spamming of the Gemini Free Tier, the application enforces strict rate limiting:
- **Maximum 15 requests per minute** across all Urdu extraction calls
- **4-second cooldown** between consecutive requests
- Users are notified when quota limits are reached

> **Note:** Urdu processing uses the Gemini API free tier. Overuse may trigger temporary quota suspension.

## Project Structure

```
lib/
├── main.dart                 # App entry point
├── screens/
│   └── home_screen.dart     # Main UI with camera & text display
├── services/
│   └── ocr_service.dart     # OCR logic (ML Kit + Gemini)
└── widgets/
    └── language_selector.dart # Language toggle widget

assets/
├── tessdata/                 # Tesseract data files
└── dictionaries/             # Urdu word lists
```

## Technologies Used

- **Flutter** — Cross-platform mobile UI framework
- **Google ML Kit** — Offline text recognition (English)
- **Google Gemini API** — Cloud-based vision & text extraction (Urdu)
- **image_picker** — Camera integration
- **image_cropper** — Native image cropping UI
- **flutter_dotenv** — Environment variable management
- **Google Fonts** — Noto Nastaliq Urdu font for display

## Environment & Configuration

The app reads its Gemini API key from a `.env` file in the project root:

```env
GEMINI_API_KEY=your_key_here
```

> ⚠️ **Security:** Never commit `.env` to version control. The repository's `.gitignore` excludes this file by default.

## Build & Release

### Building a Release APK

```bash
flutter build apk --release --no-tree-shake-icons
```

The resulting APK will be at: `build/app/outputs/flutter-apk/app-release.apk`

## Known Limitations

- Urdu OCR requires an active internet connection and valid Gemini API key
- English OCR works 100% offline
- Rate limiting applies per device (client-side throttling)
- Gemini free tier has usage caps; consider upgrading for production use

## Future Improvements

- [ ] Support for additional languages (Arabic, Persian, Hindi)
- [ ] Local Urdu model fallback when API quota is exceeded
- [ ] Batch processing for multiple images
- [ ] Text translation and dictionary lookup
- [ ] Dark mode support
- [ ] Export results to PDF/Word

## License

This project is open source and available under the [MIT License](LICENSE).

## Disclaimer

> This app was created for **demonstration purposes and personal use**. It showcases Flutter development, local ML integration, and secure API key management. Use responsibly and within the Gemini API's terms of service.
