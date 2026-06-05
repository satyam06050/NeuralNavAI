# Neuro-Nav-AI 🚶‍♂️🤖

### AI-Powered Smart Navigation System for Visually Impaired

> A low-cost, real-time assistive navigation system that combines Arduino-based obstacle sensing with on-device AI object detection in a Flutter mobile application.

---

## 📌 Overview

Neuro-Nav-AI is a hybrid hardware-software solution designed to improve independent mobility for visually impaired users.

The system combines:

* 📡 Ultrasonic distance sensing using Arduino Nano + HC-SR04
* 🔄 180° environment scanning using an SG90 Servo Motor
* 📱 Flutter mobile application
* 🧠 YOLOv8 object detection running locally via TensorFlow Lite
* 🔊 Real-time voice feedback using Text-to-Speech
* 🔌 USB OTG communication between Arduino and Android

Unlike traditional white canes, Neuro-Nav-AI can identify both the presence and type of obstacles, providing intelligent audio guidance in real time.

---

## ✨ Features

* Real-time obstacle detection
* AI-powered object recognition
* Offline operation (No Internet Required)
* Voice-based navigation alerts
* USB OTG communication
* Low-cost hardware (< ₹2000)
* Lightweight and portable
* Modular architecture for future upgrades

---

## 🏗️ System Architecture

```text
HC-SR04 Sensor
       │
       ▼
Arduino Nano
       │
 USB OTG Serial
       │
       ▼
Flutter Mobile App
       │
 ┌──────────────┐
 │ YOLOv8 TFLite│
 └──────────────┘
       │
       ▼
 Fusion Logic Engine
       │
       ▼
 Voice Alerts (TTS)
```

The system uses two independent data sources:

1. Ultrasonic Sensor

   * Measures distance to nearby obstacles.

2. YOLOv8 AI Model

   * Detects and classifies objects through the smartphone camera.

The Fusion Engine combines both inputs to generate intelligent navigation decisions.

---

## 🧰 Hardware Components

| Component                 | Quantity |
| ------------------------- | -------- |
| Arduino Nano              | 1        |
| HC-SR04 Ultrasonic Sensor | 1        |
| SG90 Servo Motor          | 1        |
| Mini Breadboard           | 1        |
| Jumper Wires              | 20       |
| USB OTG Adapter           | 1        |
| USB Cable                 | 1        |
| 5V Battery Pack           | 1        |
| Sensor Mounting Bracket   | 1        |

**Estimated Cost:** ₹1,250 – ₹2,000

---

## 💻 Software Stack

### Mobile Application

* Flutter
* Dart

### AI/ML

* YOLOv8
* TensorFlow Lite
* Python

### Embedded System

* Arduino IDE
* C/C++

### Communication

* USB OTG Serial Communication
* flutter_libserialport

---

## 📂 Project Structure

```text
Neuro-Nav-AI/
│
├── arduino/
│   └── neuro_nav_firmware.ino
│
├── flutter_app/
│   ├── lib/
│   │   ├── screens/
│   │   ├── services/
│   │   ├── fusion_engine/
│   │   ├── models/
│   │   └── widgets/
│   │
│   ├── assets/
│   │   └── yolov8n.tflite
│   │
│   └── pubspec.yaml
│
├── ai_model/
│   ├── yolov8n.pt
│   ├── convert_to_tflite.py
│   └── yolov8n.tflite
│
├── docs/
│   └── project_report.pdf
│
└── README.md
```

---

## ⚙️ How It Works

### 1. Environment Scanning

The servo motor rotates from:

```text
0° → 180°
```

At each angle:

* HC-SR04 measures distance
* Arduino processes readings
* Data is sent to Flutter via USB OTG

Example:

```text
Angle:90|Dist:42|Status:DANGER
```

---

### 2. AI Object Detection

The mobile camera continuously captures frames.

YOLOv8 detects objects such as:

* Person
* Car
* Truck
* Motorcycle
* Bicycle
* Chair
* Table
* Dog
* Cat

The model runs entirely on-device using TensorFlow Lite.

---

### 3. Fusion Logic

```text
Distance < 50 cm
        ↓
     DANGER
        ↓
 "STOP! Obstacle very close"

Distance 50–100 cm
        ↓
    WARNING
        ↓
 "Obstacle nearby"

Person/Vehicle Detected
        ↓
    CAUTION
        ↓
 "Person ahead"

Otherwise
        ↓
      SAFE
        ↓
  "Path Clear"
```

---

## 📱 Flutter Dependencies

```yaml
dependencies:
  camera:
  tflite_flutter:
  flutter_libserialport:
  flutter_tts:
  permission_handler:
```

---

## 🔧 Arduino Connections

| Component       | Arduino Pin |
| --------------- | ----------- |
| HC-SR04 Trigger | D9          |
| HC-SR04 Echo    | D10         |
| SG90 Signal     | D6          |
| VCC             | 5V          |
| GND             | GND         |

---

## 🚀 Getting Started

### Clone Repository

```bash
git clone https://github.com/yourusername/neuro-nav-ai.git
cd neuro-nav-ai
```

### Arduino Setup

1. Open Arduino IDE
2. Connect Arduino Nano
3. Upload firmware

```cpp
Serial.begin(115200);
```

### Flutter Setup

```bash
flutter pub get
flutter run
```

### AI Model Setup

```bash
pip install ultralytics
pip install tensorflow
pip install tf2onnx
```

Convert model:

```python
from ultralytics import YOLO

model = YOLO("yolov8n.pt")
model.export(format="onnx")
```

---

## 📊 Performance

| Metric             | Value      |
| ------------------ | ---------- |
| Total Latency      | 113–179 ms |
| Ultrasonic Error   | < 4%       |
| Offline Support    | Yes        |
| Hardware Cost      | < ₹2000    |
| Android Compatible | Yes        |

---

## 🔮 Future Enhancements

* Bluetooth Low Energy (BLE)
* Wireless communication
* Smart wearable glasses
* GPS route navigation
* LiDAR integration
* Raspberry Pi deployment
* Custom-trained object detection model
* Multi-sensor fusion

---

## 👨‍💻 Team

| Name               | Role                         |
| ------------------ | ---------------------------- |
| Dhruv              | Hardware & AI       |
| Satyam Kumar       | Flutter App & AI  |
| Madhurima Talukder | UI/UX & Documentation        |
| Shashank Ranjan    | Ideation & Presentation      |

---

## 📜 License

This project is developed for academic and research purposes. Feel free to use, modify, and extend it for educational and assistive technology applications.

---

## ❤️ Vision

**Making navigation safer, smarter, and more accessible through the fusion of AI and embedded systems.**
