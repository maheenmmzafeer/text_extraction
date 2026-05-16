# TextSnap OCR

> A fast, privacy-focused offline English OCR and high-accuracy Urdu OCR application.

**TextSnap OCR** is a lightweight Flutter application designed for extracting text from images. It was built both for personal use and as a demonstration of integrating on-device Machine Learning with Cloud AI in a mobile environment. 

## Features

*   **⚡ Blazing Fast English OCR:** Utilizes **Google ML Kit** for 100% offline, on-device text recognition. Your English documents never leave your phone.
*   **🌍 High-Accuracy Urdu OCR:** Integrates the **Gemini 1.5 Flash API** to handle the complexities of cursive Nastaliq Urdu script, delivering superior accuracy where standard local models often fail.
*   **📸 Native Camera & Cropping:** Capture images directly. Built-in cropping (via `image_cropper`) ensures you only scan what you need.
*   **🛡️ Abuse Prevention:** Built-in rate limiting and cooldown mechanisms to prevent API spamming.
*   **🎨 Clean Material 3 UI:** A gorgeous, user-friendly turquoise-themed interface with smooth animations and haptic feedback.

## Why this architecture?

This project was built to demonstrate a hybrid OCR approach:
1.  **Speed & Privacy First:** For standard Latin-based scripts (English), ML Kit provides instant, fully offline processing.
2.  **Power When Needed:** Urdu script is notoriously difficult for lightweight offline models to read accurately. By offloading Urdu processing to Google's Gemini API, the app achieves production-grade accuracy for complex languages without bloating the app size.

> **Note:** This app was created for **demonstration purposes and personal use**. It showcases Flutter UI development, local ML integration and secure API key management via `.env`.

## Rate Limiting

To prevent accidental spamming of the Gemini Free Tier, the application has an internal rate limiter:
*   Maximum 15 requests per minute.
*   4-second cooldown between consecutive requests.