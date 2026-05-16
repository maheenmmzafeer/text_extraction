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

## Known Limitations

- Urdu OCR requires an active internet connection and valid Gemini API key
- English OCR works 100% offline
- Rate limiting applies per device (client-side throttling)
- Gemini free tier has usage caps; consider upgrading for production use

## Future Improvements

- [ ] Support for additional languages
- [ ] Local Urdu model fallback when API quota is exceeded
- [ ] Batch processing for multiple images
- [ ] Text translation and dictionary lookup
- [ ] Export results to PDF/Word

## Disclaimer

> This app was created for **demonstration purposes and personal use**. It showcases Flutter development, local ML integration, and secure API key management. Use responsibly and within the Gemini API's terms of service.
