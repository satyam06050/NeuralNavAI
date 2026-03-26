// ============================================================
//  SMART RADAR SYSTEM — Arduino Nano
//  Hardware : HC-SR04 Ultrasonic Sensor + SG90 Servo Motor
//  Optional : Passive Buzzer (D11), Green LED (D4), Red LED (D5)
//  Author   : Generated for Arduino Nano (ATmega328P)
//  Baud     : 9600
// ============================================================

#include <Servo.h>

// ── Pin Definitions ─────────────────────────────────────────
#define TRIG_PIN      9     // HC-SR04 trigger
#define ECHO_PIN      10    // HC-SR04 echo
#define SERVO_PIN     6     // SG90 signal
#define BUZZER_PIN    11    // Passive buzzer  (bonus)
#define LED_GREEN     4     // Safe indicator  (bonus)
#define LED_RED       5     // Danger indicator(bonus)

// ── User-Configurable Parameters ────────────────────────────
const int   DETECTION_THRESHOLD_CM = 150;  // Object detection range (cm)
const int   CLOSE_ALERT_CM         = 50;   // Buzzer/red-LED threshold (cm)
const int   ANGLE_STEP             = 5;    // Scan resolution in degrees (1–10)
const int   READINGS_PER_ANGLE     = 5;    // Samples averaged per position
const int   SERVO_SETTLE_MS        = 30;   // Delay after each servo move (ms)
const int   PULSE_TIMEOUT_US       = 30000;// pulseIn() timeout (≈ 5 m max range)
const int   MIN_VALID_CM           = 2;    // Ignore readings below this (cm)
const int   MAX_VALID_CM           = 400;  // Ignore readings above this (cm)

// ── Object Detection State ───────────────────────────────────
// Tracks whether we are currently "inside" an object region so we
// don't count the same object at every adjacent angle.
bool  objectPresent = false;   // true while servo sweeps past an object
int   objectCount   = 0;       // unique objects counted in this scan cycle

// ── Servo Instance ───────────────────────────────────────────
Servo radarServo;

// ════════════════════════════════════════════════════════════
//  SETUP
// ════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(9600);

  // Pin modes
  pinMode(TRIG_PIN,   OUTPUT);
  pinMode(ECHO_PIN,   INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_GREEN,  OUTPUT);
  pinMode(LED_RED,    OUTPUT);

  // Attach servo and move to home position
  radarServo.attach(SERVO_PIN);
  radarServo.write(0);
  delay(500);   // Allow servo to reach home before first sweep

  Serial.println(F("============================================"));
  Serial.println(F("       SMART RADAR SYSTEM — ONLINE          "));
  Serial.println(F("============================================"));
  Serial.print(F("Detection threshold : "));
  Serial.print(DETECTION_THRESHOLD_CM);
  Serial.println(F(" cm"));
  Serial.print(F("Close-alert range   : "));
  Serial.print(CLOSE_ALERT_CM);
  Serial.println(F(" cm"));
  Serial.print(F("Angle step          : "));
  Serial.print(ANGLE_STEP);
  Serial.println(F(" deg"));
  Serial.println(F("--------------------------------------------"));
}

// ════════════════════════════════════════════════════════════
//  MAIN LOOP  –  One full sweep per iteration
// ════════════════════════════════════════════════════════════
void loop() {
  objectCount   = 0;
  objectPresent = false;

  // ── Forward sweep : 0° → 180° ──────────────────────────
  for (int angle = 0; angle <= 180; angle += ANGLE_STEP) {
    performScan(angle);
  }

  // ── End-of-cycle summary ────────────────────────────────
  Serial.println(F("--------------------------------------------"));
  Serial.print(F(">>> Total Objects Detected: "));
  Serial.println(objectCount);
  Serial.println(F("============================================"));

  // ── Snap back to 0° instantly (full speed, no scanning) ─
  radarServo.write(0);
  delay(600);   // Wait for servo to physically reach 0° before next sweep
}

// ════════════════════════════════════════════════════════════
//  performScan()
//  Moves servo to 'angle', measures distance, and reports.
// ════════════════════════════════════════════════════════════
void performScan(int angle) {
  // 1. Move servo smoothly to target angle
  moveServo(angle);

  // 2. Measure distance (averaged, noise-filtered)
  float distance = getFilteredDistance();

  // 3. Classify the reading
  bool validReading = (distance >= MIN_VALID_CM && distance <= MAX_VALID_CM);
  bool danger       = validReading && (distance <= DETECTION_THRESHOLD_CM);
  bool veryClose    = validReading && (distance <= CLOSE_ALERT_CM);

  // 4. State-based unique object counting
  //    Rising edge  → new object enters threshold → increment counter
  //    Falling edge → object leaves threshold     → reset flag
  if (danger && !objectPresent) {
    objectPresent = true;
    objectCount++;
    Serial.print(F("  *** OBJECT #"));
    Serial.print(objectCount);
    Serial.println(F(" DETECTED! ***"));
  } else if (!danger) {
    objectPresent = false;
  }

  // 5. Serial output
  printStatus(angle, distance, validReading, danger);

  // 6. Bonus indicators
  updateIndicators(veryClose, danger);
}

// ════════════════════════════════════════════════════════════
//  moveServo()
//  Writes the target angle and waits for mechanical settle.
// ════════════════════════════════════════════════════════════
void moveServo(int targetAngle) {
  radarServo.write(targetAngle);
  delay(SERVO_SETTLE_MS);   // Let servo reach position before measuring
}

// ════════════════════════════════════════════════════════════
//  getFilteredDistance()
//  Takes READINGS_PER_ANGLE samples, discards invalids, returns
//  the average in cm.  Returns MAX_VALID_CM + 1 on full failure.
// ════════════════════════════════════════════════════════════
float getFilteredDistance() {
  float   sum   = 0;
  int     valid = 0;

  for (int i = 0; i < READINGS_PER_ANGLE; i++) {
    float d = singlePing();
    if (d >= MIN_VALID_CM && d <= MAX_VALID_CM) {
      sum += d;
      valid++;
    }
    delay(10);  // Small gap between pings prevents echo interference
  }

  if (valid == 0) return (float)(MAX_VALID_CM + 1);  // All readings invalid
  return sum / (float)valid;
}

// ════════════════════════════════════════════════════════════
//  singlePing()
//  Fires one ultrasonic pulse and returns the measured distance.
//  Returns 0 on timeout or if echo never arrives.
// ════════════════════════════════════════════════════════════
float singlePing() {
  // Ensure trigger is low before pulse
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);

  // Send 10 µs HIGH pulse to trigger
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);

  // Measure echo duration with timeout
  long duration = pulseIn(ECHO_PIN, HIGH, PULSE_TIMEOUT_US);

  // Convert to cm: speed of sound ≈ 0.0343 cm/µs, round-trip → ÷ 2
  if (duration == 0) return 0;  // Timeout — no echo received
  return (duration * 0.0343f) / 2.0f;
}

// ════════════════════════════════════════════════════════════
//  printStatus()
//  Outputs one structured line per angle to Serial Monitor.
// ════════════════════════════════════════════════════════════
void printStatus(int angle, float distance, bool valid, bool danger) {
  Serial.print(F("Angle: "));
  Serial.print(angle);
  if (angle < 100) Serial.print(F(" "));   // Align columns
  if (angle < 10)  Serial.print(F(" "));

  Serial.print(F(" | Distance: "));
  if (valid) {
    Serial.print(distance, 1);
    Serial.print(F(" cm"));
    // Pad for alignment (distances up to 400 cm = 6 chars + " cm")
    if (distance < 100) Serial.print(F(" "));
    if (distance < 10)  Serial.print(F(" "));
  } else {
    Serial.print(F("--- cm  "));   // Invalid / out-of-range
  }

  Serial.print(F(" | Status: "));
  if (!valid) {
    Serial.println(F("INVALID"));
  } else if (danger) {
    Serial.println(F("⚠ WARNING ⚠"));
  } else {
    Serial.println(F("SAFE"));
  }
}

// ════════════════════════════════════════════════════════════
//  updateIndicators()  [Bonus]
//  Controls buzzer, green LED, and red LED based on proximity.
// ════════════════════════════════════════════════════════════
void updateIndicators(bool veryClose, bool danger) {
  if (veryClose) {
    // Audible alert for very close objects
    tone(BUZZER_PIN, 1000);     // 1 kHz beep
    digitalWrite(LED_RED,   HIGH);
    digitalWrite(LED_GREEN, LOW);
  } else if (danger) {
    // Silent visual warning only
    noTone(BUZZER_PIN);
    digitalWrite(LED_RED,   HIGH);
    digitalWrite(LED_GREEN, LOW);
  } else {
    // All clear
    noTone(BUZZER_PIN);
    digitalWrite(LED_RED,   LOW);
    digitalWrite(LED_GREEN, HIGH);
  }
}
