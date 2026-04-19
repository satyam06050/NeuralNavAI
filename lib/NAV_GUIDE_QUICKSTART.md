# Navigation Guide - Quick Start Guide

## 🎯 What is This?

The **Navigation Guide** feature converts Arduino radar sensor data into voice navigation instructions for visually impaired users. It tells you where obstacles are and which direction to move.

---

## 📱 How to Use

### Step 1: Connect Hardware
1. Connect Arduino to your Android phone via **USB OTG cable**
2. Wait for the app to detect the device (green indicator = connected)

### Step 2: Open Navigation Guide
1. Tap **"GUIDE"** in the bottom navigation bar (2nd icon)
2. You'll see the navigation screen with 5 zones

### Step 3: Activate Guidance
1. Tap the **PLAY button** (▶️) in top-right corner
2. Button turns green = **ACTIVE**
3. App will announce: *"Navigation guidance activated"*

### Step 4: Listen & Follow
The app will speak instructions through your earphones:

| Voice Message | Meaning | Action |
|---------------|---------|--------|
| **"Path clear — safe to move"** | No obstacles | Walk forward |
| **"Bear left — obstacle ahead"** | Obstacle in center, left is clear | Steer left |
| **"Bear right — obstacle ahead"** | Obstacle in center, right is clear | Steer right |
| **"Stop — obstacle ahead. Move left"** | Danger ahead, left is safe | Stop, then move left |
| **"Danger! Stop — obstacle directly ahead"** | Very close obstacle | STOP immediately |
| **"STOP IMMEDIATELY! Sudden obstacle!"** | Emergency | FREEZE in place |
| **"Move away from left"** | Danger on left side | Move right |
| **"Move away from right"** | Danger on right side | Move left |
| **"Obstacles all around — stand still"** | Surrounded by obstacles | Don't move |

---

## 🎨 Screen Layout

```
┌─────────────────────────────────────┐
│  NAVIGATION GUIDE         [▶️]     │
├─────────────────────────────────────┤
│  🔴 ARDUINO RADAR    CONNECTED      │
│                      [ACTIVE]       │
├─────────────────────────────────────┤
│  ZONE VISUALIZATION                 │
│  ┌──┐ ┌──┐ ┌──┐ ┌──┐ ┌──┐        │
│  │HL│ │ L│ │ C│ │ R│ │HR│        │
│  └──┘ └──┘ └──┘ └──┘ └──┘        │
│   HARD LEFT CENTER RIGHT HARD      │
│    LEFT                   RIGHT    │
├─────────────────────────────────────┤
│  ZONE DISTANCES                     │
│  ┌─┐┌─┐┌─┐┌─┐┌─┐                  │
│  │✓││✓││⚠││✓││✓│  (example)       │
│  └─┘└─┘└─┘└─┘└─┘                  │
│  CLR CLR 85cm CLR CLR              │
├─────────────────────────────────────┤
│  🧭 NAVIGATION INSTRUCTION          │
│                                     │
│     "Warning — obstacle ahead.      │
│          Slow down"                 │
│                                     │
├─────────────────────────────────────┤
│  ZONE MAPPING (0°-180°)             │
│  Hard Left:  0° - 30°               │
│  Left:      35° - 70°               │
│  Center:    75° - 105°              │
│  Right:    110° - 145°              │
│  Hard Right: 150° - 180°            │
│                                     │
│  DISTANCE THRESHOLDS                │
│  Safe:     > 250 cm  🟢            │
│  Warning:  100-250 cm 🟡           │
│  Danger:   < 100 cm   🔴           │
└─────────────────────────────────────┘
```

---

## 🔔 Vibration Patterns

You'll feel different vibration patterns through your phone:

| Pattern | Meaning |
|---------|---------|
| **Long continuous** | DANGER / STOP |
| **3 quick pulses** | WARNING / Caution |
| **1 soft tick** | Path clear / Safe |

---

## 🎛️ Zone System Explained

The 180° arc in front of you is divided into 5 zones:

```
        YOU ARE HERE
             ↓
    ┌────────┴────────┐
    │   Front View    │
    │                 │
 HL │   L   │   C   │   R   │ HR │
    │                 │
    └─────────────────┘
    
HL = Hard Left (0°-30°)
L  = Left (35°-70°)
C  = Center (75°-105°)
R  = Right (110°-145°)
HR = Hard Right (150°-180°)
```

**Example:** If an obstacle is at 90°, it's in the **Center** zone.

---

## 💡 Tips for Best Experience

1. **Use earphones** - Voice instructions are clearer and private
2. **Hold phone steadily** - For better haptic feedback
3. **Keep app active** - Green PLAY button means guidance is ON
4. **Check battery** - GPS + radar scanning uses power
5. **Test in safe area first** - Practice before real-world use

---

## ⚠️ Troubleshooting

### Problem: No voice announcements
**Solution:** 
- Check if PLAY button is green (ACTIVE)
- Increase TTS volume in Settings
- Ensure phone isn't on silent mode

### Problem: Zones show 999cm or CLEAR
**Solution:**
- Check Arduino is connected (green indicator)
- Verify Arduino is powered on
- Check USB OTG connection

### Problem: Wrong directions
**Solution:**
- The sensor might be mounted backwards
- Test by waving hand in front of sensor
- Check if left/right are swapped

### Problem: Too many repeated messages
**Solution:**
- This is normal for changing environments
- App has 2-second cooldown for same message
- Move to a different area

---

## 🧪 Testing Mode

Before using in real environment:

1. **Static Test**: Place obstacles at known positions
   - 2 meters ahead (center)
   - 1 meter to left
   - 1 meter to right
   - Verify app announces correctly

2. **Dynamic Test**: Have someone walk across your path
   - Should trigger "Warning" or "Stop" depending on distance

3. **Emergency Test**: Suddenly place obstacle very close
   - Should trigger immediate "STOP IMMEDIATELY!"

---

## 📊 Understanding the Display

### Color Codes

| Color | Status | Distance |
|-------|--------|----------|
| 🟢 **Green** | SAFE | > 250 cm |
| 🟡 **Yellow** | WARNING | 100-250 cm |
| 🔴 **Red** | DANGER | < 100 cm |

### Icons

- ✅ **Check mark** = Clear path (999cm)
- ⚠️ **Warning triangle** = Caution needed
- 🛑 **Stop sign** = Danger, stop required

---

## 🔒 Safety Notes

⚠️ **IMPORTANT**: This is an assistive device, not a replacement for:
- Guide dogs
- Human guides  
- White canes
- Personal judgment

**Always:**
- Use in conjunction with other mobility aids
- Exercise caution in unfamiliar environments
- Have a backup plan if technology fails

---

## 🆘 Emergency Situations

If the app says **"STOP IMMEDIATELY!"**:
1. **FREEZE** in place
2. **DON'T MOVE** until you verify surroundings
3. Use cane or ask for assistance
4. Only proceed when safe

---

## 📞 Support

For technical issues or questions:
- Check `NAV_GUIDE_IMPLEMENTATION.md` for developer details
- Review `guide.md` for full specification
- Contact development team

---

*Remember: Technology is a tool, not a guarantee. Always prioritize safety!*
