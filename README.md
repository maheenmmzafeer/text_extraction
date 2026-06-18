# TextSnap OCR 📸

> A hybrid OCR Flutter application combining offline English text recognition with cloud-powered Urdu OCR for superior accuracy.

**TextSnap OCR** is a lightweight Flutter application designed for extracting text from images. It was built both for personal use and as a demonstration of integrating on-device Machine Learning with Cloud AI in a mobile environment. 

## Features

*   ** Fast English OCR:** Utilizes **Google ML Kit** for 100% offline, on-device text recognition. Your English documents never leave your phone.
*   ** High-Accuracy Urdu OCR:** Uses **Gemini 2.5 Flash Lite** first for faster Urdu extraction, with **Gemini 2.5 Flash** as the fallback model when needed.
*   ** Native Camera & Cropping:** Capture images directly from your device camera with an intuitive native crop editor to frame exactly what you need.
*   ** PDF OCR Support:** Import PDFs, select a page range and extract text from the chosen pages instead of the full document by default.
*   ** Abuse Prevention:** Built-in conservative rate limiting with a 4-second minimum cooldown and model-specific request caps to reduce quota issues.
*   ** Quota-Aware Fallback:** Urdu OCR falls back from **Gemini 2.5 Flash Lite** to **Gemini 2.5 Flash** when the primary model hits quota limits.
*   ** Clean Material 3 UI:** Beautiful turquoise-themed Material 3 interface with smooth animations, reusable action buttons and responsive feedback.
*   ** Language Selection:** Toggle between English and Urdu recognition modes with a simple language picker widget.

## Why this architecture?

This project was built to demonstrate a hybrid OCR approach:
1.  **Speed & Privacy First:** For Latin-based text (English), ML Kit delivers instant, fully offline processing. No cloud dependency = no data transmission.
2.  **Power When Needed:** Urdu script is notoriously difficult for lightweight offline models. By offloading Urdu to Gemini 2.5 Flash, the app achieves production-grade accuracy without significantly increasing app size.

## How It Works

### English OCR (Offline)
- Powered by Google ML Kit's text recognition
- Fully local processing. Zero API calls.
- Instant results

### Urdu OCR (Cloud)
- Powered by Gemini 2.5 Flash Lite with vision capabilities, then Gemini 2.5 Flash as fallback
- Sends base64-encoded image to Google's generative API
- Returns extracted Urdu text with minimal latency
- Subject to Gemini's free tier quota (rate limiting enforced on client)

### PDF OCR
- Imports local PDF files through the native file picker
- Renders each page to a bitmap image with `pdfx`
- English PDFs stay fully local and use Google ML Kit on the selected pages only
- Urdu PDFs use Gemini OCR in fixed 3-page batches to improve accuracy while still reducing request count

## Rate Limiting & Usage Limits

To prevent accidental spamming of the Gemini Free Tier, the application enforces strict rate limiting:
- **Gemini 2.5 Flash:** up to **5 requests per minute**
- **Gemini 2.5 Flash Lite:** up to **10 requests per minute**
- **4-second cooldown** between consecutive requests per model
- Users are notified when quota limits are reached
- If the primary Gemini model is rate-limited, the app retries with **Gemini 2.5 Flash** using the same API key

> **Note:** Urdu processing uses the Gemini API free tier. Overuse may trigger temporary quota suspension.

## Technologies Used

- **Flutter**: Cross-platform mobile UI framework
- **Google ML Kit**: Offline text recognition (English)
- **Google Gemini API**: Cloud-based vision & text extraction (Urdu)
- **image_picker**: Camera integration
- **file_picker**: PDF file selection
- **image_cropper**: Native image cropping UI
- **pdfx**: PDF page rendering for OCR
- **flutter_dotenv**: Environment variable management
- **Google Fonts**: Noto Nastaliq Urdu font for display

## Environment & Configuration

The app reads its Gemini API key from a `.env` file in the project root:

```env
GEMINI_API_KEY=your_key_here
```

> ⚠️ **Security:** Never commit `.env` to version control. The repository's `.gitignore` excludes this file by default.

## Known Limitations

- Urdu OCR requires an active internet connection and valid Gemini API key
- English OCR works 100% offline
- English PDF OCR also works 100% offline through Google ML Kit
- Rate limiting applies per device (client-side throttling)
- Gemini free tier has usage caps that vary by project and tier; the app uses a conservative client-side cap to stay within limits
- Batch PDF OCR applies only to Urdu/Gemini processing; English PDFs are not subject to Gemini quotas

## Future Improvements

- [ ] Support for additional languages
- [ ] Local Urdu model fallback when API quota is exceeded
- [ ] Batch processing for multiple images
- [ ] Text translation and dictionary lookup
- [ ] Export results to PDF/Word

## Disclaimer

> This app was created for **demonstration purposes and personal use**. It showcases Flutter development, local ML integration and secure API key management. Use responsibly and within the Gemini API's terms of service.
