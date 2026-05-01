# 👁️ Aural Sight

**Aural Sight** is an AI-powered assistive mobile application developed as a **Final Year Project** to support visually impaired users through a fully offline voice-controlled smart assistant.

The application combines computer vision, speech recognition, OCR, and gesture recognition to provide real-time accessibility features without requiring an internet connection.

---

## ✨ Key Features

### 🎯 Object Detection Mode
Detects surrounding objects in real time using **SSD MobileNet** trained on the **COCO Dataset**. Helps users identify common objects such as bottles, chairs, people, doors, and more.

### 📖 OCR Reading Mode
Reads printed text aloud from books, labels, medicine boxes, menus, and documents using **Google ML Kit OCR**.

### ✋ Gesture Recognition Mode
Recognizes hand gestures for touch-free interaction using **MediaPipe**.

### 🎙️ Full Voice Control
The application can be controlled through voice commands for complete hands-free accessibility.

### 🧠 Custom Wake Word Detection
A custom-trained lightweight AI model continuously listens for:

**"Hey Luna"**

Once detected, the system enters command mode.

### 🎤 Supported Voice Commands

- Object Detection  
- OCR Mode  
- Gesture Mode  
- Go Back  
- Open Settings  
- Change Theme  
- Font Bigger  
- Font Smaller  

### 🔒 Fully Offline System
Core features run locally on-device, ensuring:

- Privacy  
- Fast Response Time  
- Reliable Performance  
- Accessibility Anywhere  

### 💾 On-Device Storage
Uses **Hive Database** for lightweight local data storage and settings management.

---

## 🛠️ Technologies Used

- Flutter  
- TensorFlow Lite  
- SSD MobileNet  
- COCO Dataset  
- Google ML Kit OCR  
- MediaPipe  
- Hive Database  
- Python  
- Google Colab  
- Custom CNN Audio Models  

---

## 📁 Project Structure

```text
aural_sight/
├── android/
├── ios/
├── lib/
│   ├── models/
│   ├── providers/
│   ├── screens/
│   ├── services/
│   ├── theme/
│   ├── utils/
│   └── widgets/
├── assets/
│   ├── images/
│   ├── model/
│   ├── models/
│   ├── tessdata/
│   └── vosk-model/
├── windows/
├── linux/
├── macos/
├── web/
├── test/
├── pubspec.yaml
└── README.md
