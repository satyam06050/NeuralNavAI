// ============================================================
//  SMART RADAR — Blind Person Navigation Cap v2.0
//  Hardware : HC-SR04 (TRIG=D9, ECHO=D10) + SG90 (D6)
//             Buzzer=D11, LED_GREEN=D4, LED_RED=D5
//  Output   : USB Serial at 9600 baud
//  Protocol : Human-readable lines + structured APP: lines
//  Sweep    : 0–180° in 5° steps (precise mode)
// ============================================================

#include <Servo.h>

// ── Pin Definitions ─────────────────────────────────────────
#define TRIG_PIN     9
#define ECHO_PIN     10
#define SERVO_PIN    6
#define BUZZER_PIN   11
#define LED_GREEN    4
#define LED_RED      5

// ── Detection Zones (cm) ─────────────────────────────────────
const int ZONE_SUDDEN  = 100;   // Sudden appearance → quick beep + CRITICAL alert
const int ZONE_DANGER  = 100;   // Big warning + beep
const int ZONE_WARNING = 250;   // 2nd warning (caution)
const int ZONE_NOTICE  = 500;   // 1st notice (object in range)
const int ZONE_MAX     = 500;   // Beyond = open space

// ── Sweep Settings ───────────────────────────────────────────
const int ANGLE_STEP         = 5;    // Degrees per step (precise)
const int READINGS_PER_ANGLE = 3;    // Pings averaged per position
const int SERVO_SETTLE_MS    = 50;   // Wait after servo move (ms)
const int PING_INTERVAL_MS   = 15;   // Between pings (ms)
const int PULSE_TIMEOUT_US   = 30000;// ~5.1 m max range

// ── Object Grouping (stops 144/158 cm false multi-count) ─────
// Two detections within this many degrees = same object
const int  SAME_OBJECT_ANGLE_GAP = 20;
// Distance must differ by this much to count as a new object
const int  SAME_OBJECT_DIST_GAP  = 40;
// Object exits when distance goes this far past its zone threshold
const int  HYSTERESIS_CM         = 20;

// ── State ────────────────────────────────────────────────────
Servo radarServo;

struct DetectedObject {
  int   angle;
  float distance;
  int   zone;       // 1=NOTICE 2=WARNING 3=DANGER
};

const int MAX_OBJECTS = 20;
DetectedObject objects[MAX_OBJECTS];
int objectCount = 0;

// Tracks last seen object to avoid re-counting same one
int   lastObjectAngle = -999;
float lastObjectDist  = -999;

// ════════════════════════════════════════════════════════════
void setup() {
  Serial.begin(9600);
  pinMode(TRIG_PIN,   OUTPUT);
  pinMode(ECHO_PIN,   INPUT);
  pinMode(BUZZER_PIN, OUTPUT);
  pinMode(LED_GREEN,  OUTPUT);
  pinMode(LED_RED,    OUTPUT);

  radarServo.attach(SERVO_PIN);
  radarServo.write(0);
  delay(800);

  allClear();
  Serial.println(F("============================================"));
  Serial.println(F("  SMART RADAR v2.0 — Blind Navigation Cap  "));
  Serial.println(F("============================================"));
  Serial.println(F("ZONES: NOTICE=500cm | WARNING=250cm | DANGER=100cm"));
  Serial.println(F("APP:READY"));
  Serial.println();
}

// ════════════════════════════════════════════════════════════
void loop() {
  objectCount      = 0;
  lastObjectAngle  = -999;
  lastObjectDist   = -999;

  Serial.println(F("--- NEW SWEEP STARTED ---"));
  Serial.println(F("APP:SWEEP_START"));

  // Forward sweep: 0° → 180°
  for (int angle = 0; angle <= 180; angle += ANGLE_STEP) {
    performScan(angle);
  }

  // ── Cycle Summary ──
  Serial.println();
  Serial.print(F("SWEEP COMPLETE | Objects detected this cycle: "));
  Serial.println(objectCount);

  // Send structured summary to app
  Serial.print(F("APP:CYCLE_END,objects="));
  Serial.println(objectCount);

  // List each object for AI model
  for (int i = 0; i < objectCount; i++) {
    Serial.print(F("APP:OBJ,id="));
    Serial.print(i + 1);
    Serial.print(F(",angle="));
    Serial.print(objects[i].angle);
    Serial.print(F(",dist="));
    Serial.print(objects[i].distance, 1);
    Serial.print(F(",zone="));
    Serial.println(objects[i].zone);
  }
  Serial.println();

  // Snap back fast
  radarServo.write(0);
  delay(700);
}

// ════════════════════════════════════════════════════════════
void performScan(int angle) {
  radarServo.write(angle);
  delay(SERVO_SETTLE_MS);

  float distance = getFilteredDistance();
  bool  valid    = (distance >= 2 && distance <= ZONE_MAX);

  // Classify zone
  int zone = 0;
  if (valid) {
    if      (distance <= ZONE_DANGER)  zone = 3;
    else if (distance <= ZONE_WARNING) zone = 2;
    else if (distance <= ZONE_NOTICE)  zone = 1;
  }

  // ── Human-Readable Serial Monitor Output ──────────────────
  Serial.print(F("Angle: "));
  Serial.print(angle);
  Serial.print(F("°  | Dist: "));
  if (valid) {
    Serial.print(distance, 1);
    Serial.print(F(" cm | "));
  } else {
    Serial.print(F(">500cm  | "));
  }

  switch (zone) {
    case 3:
      Serial.println(F("Status: !!DANGER!! OBJECT VERY CLOSE"));
      break;
    case 2:
      Serial.println(F("Status: ⚠ WARNING — Object nearby"));
      break;
    case 1:
      Serial.println(F("Status: NOTICE — Object in range"));
      break;
    default:
      Serial.println(F("Status: SAFE / CLEAR"));
      break;
  }

  // ── Structured App Output (parsed by mobile app) ──────────
  // Format: APP:DATA,angle,distance_cm,zone
  // zone: 0=clear 1=notice(500cm) 2=warning(250cm) 3=danger(100cm)
  Serial.print(F("APP:DATA,"));
  Serial.print(angle);
  Serial.print(F(","));
  Serial.print(valid ? distance : 999.0, 1);
  Serial.print(F(","));
  Serial.println(zone);

  // ── Object Detection with Grouping ────────────────────────
  if (zone > 0) {
    bool isNewObject = isDistinctObject(angle, distance);

    if (isNewObject && objectCount < MAX_OBJECTS) {
      // Store it
      objects[objectCount].angle    = angle;
      objects[objectCount].distance = distance;
      objects[objectCount].zone     = zone;
      objectCount++;

      lastObjectAngle = angle;
      lastObjectDist  = distance;

      // ── Human-readable alert ──
      Serial.print(F("  >>> OBJECT #"));
      Serial.print(objectCount);
      Serial.print(F(" DETECTED at "));
      Serial.print(angle);
      Serial.print(F("° | "));
      Serial.print(distance, 1);
      Serial.print(F(" cm | "));

      // ── APP alert with tier label ──
      Serial.print(F("APP:ALERT,id="));
      Serial.print(objectCount);
      Serial.print(F(",angle="));
      Serial.print(angle);
      Serial.print(F(",dist="));
      Serial.print(distance, 1);
      Serial.print(F(",type="));

      if (zone == 3) {
        Serial.println(F("BIG_WARNING → Object within 100cm! STOP!"));
        Serial.println(F("DANGER"));
        triggerBuzzer(3);   // Long urgent beep
        setLED(false);
      } else if (zone == 2) {
        Serial.println(F("2ND_WARNING → Object within 250cm. Caution!"));
        Serial.println(F("WARNING"));
        triggerBuzzer(2);   // Medium beep
        setLED(false);
      } else {
        Serial.println(F("1ST_NOTICE → Object in range within 500cm."));
        Serial.println(F("NOTICE"));
        triggerBuzzer(1);   // Short soft beep
        setLED(true);
      }

      // Sudden close-range detection
      if (distance <= ZONE_SUDDEN && zone == 3) {
        Serial.println(F("  !!! SUDDEN CLOSE OBJECT — QUICK ALERT !!!"));
        Serial.println(F("APP:SUDDEN_ALERT,dist="));
        Serial.print(distance, 1);
        Serial.println(F(",action=STOP_IMMEDIATELY"));
        quickBeep();
      }
    }
  } else {
    // Clear — green LED, no buzzer
    noTone(BUZZER_PIN);
    setLED(true);
  }
}

// ════════════════════════════════════════════════════════════
// Returns true if this reading is a NEW distinct object
// (not the same object already counted at a nearby angle)
// ════════════════════════════════════════════════════════════
bool isDistinctObject(int angle, float distance) {
  if (lastObjectAngle == -999) return true;  // First object always new

  int   angleDiff = abs(angle - lastObjectAngle);
  float distDiff  = abs(distance - lastObjectDist);

  // Same object = close in angle AND close in distance
  if (angleDiff <= SAME_OBJECT_ANGLE_GAP && distDiff <= SAME_OBJECT_DIST_GAP) {
    return false;  // Same object, skip
  }
  return true;     // New distinct object
}

// ════════════════════════════════════════════════════════════
float getFilteredDistance() {
  float readings[10];
  int   count = 0;

  for (int i = 0; i < READINGS_PER_ANGLE; i++) {
    float d = singlePing();
    if (d >= 2 && d <= ZONE_MAX) readings[count++] = d;
    delay(PING_INTERVAL_MS);
  }

  if (count == 0) return ZONE_MAX + 1;

  // Sort, drop highest spike, average rest
  for (int i = 1; i < count; i++) {
    float key = readings[i];
    int   j   = i - 1;
    while (j >= 0 && readings[j] > key) {
      readings[j + 1] = readings[j];
      j--;
    }
    readings[j + 1] = key;
  }
  int   use = (count >= 3) ? count - 1 : count;
  float sum = 0;
  for (int i = 0; i < use; i++) sum += readings[i];
  return sum / use;
}

// ════════════════════════════════════════════════════════════
float singlePing() {
  digitalWrite(TRIG_PIN, LOW);
  delayMicroseconds(2);
  digitalWrite(TRIG_PIN, HIGH);
  delayMicroseconds(10);
  digitalWrite(TRIG_PIN, LOW);
  long dur = pulseIn(ECHO_PIN, HIGH, PULSE_TIMEOUT_US);
  if (dur == 0) return 0;
  return (dur * 0.0343f) / 2.0f;
}

// ════════════════════════════════════════════════════════════
// zone 1 = short beep, zone 2 = medium, zone 3 = long urgent
// ════════════════════════════════════════════════════════════
void triggerBuzzer(int level) {
  if (level == 1) {
    tone(BUZZER_PIN, 800);  delay(80);  noTone(BUZZER_PIN);
  } else if (level == 2) {
    tone(BUZZER_PIN, 1200); delay(180); noTone(BUZZER_PIN);
  } else {
    // Three rapid beeps for danger
    for (int i = 0; i < 3; i++) {
      tone(BUZZER_PIN, 2000); delay(120);
      noTone(BUZZER_PIN);     delay(60);
    }
  }
}

void quickBeep() {
  for (int i = 0; i < 5; i++) {
    tone(BUZZER_PIN, 2500); delay(60);
    noTone(BUZZER_PIN);     delay(40);
  }
}

void setLED(bool green) {
  digitalWrite(LED_GREEN, green ? HIGH : LOW);
  digitalWrite(LED_RED,   green ? LOW  : HIGH);
}

void allClear() {
  noTone(BUZZER_PIN);
  setLED(true);
}