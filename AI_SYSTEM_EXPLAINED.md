# AI System Q&A

## Overview

The AI uses a **finite state machine** with three states, combined with a **physics prediction system** (ghost simulation) to anticipate where the puck will be.

---

## Student: How does the AI decide where to move?

**Teacher:** The AI runs a simulation! It creates a "ghost puck" that copies the real puck's position and velocity, then steps it forward frame by frame. This predicts where the puck will be when it reaches the AI's side.

The simulation stops when:
- The puck reaches the AI's defensive line
- The puck would hit the paddle
- The puck bounces too many times (we limit bounces based on speed)

The final position of the ghost puck becomes the **prediction target**.

---

## Student: What are the three states?

**Teacher:** 

### 1. DEFEND (Default)
The AI holds its ground at the defensive center. It only moves from this position if:
- The ball is approaching its defensive zone (tracks the prediction)
- The ball is far away (stays at center)
- The ball is moving away (returns to center)

### 2. ATTACK (Ball in AI's half)
When the ball enters the AI's territory, it switches to attack mode:
- **Wind-up phase**: Pulls back slightly (8 frames) - makes it feel human-like
- **Strike phase**: Charges forward to hit the prediction point
- After hitting the ball, returns to DEFEND

### 3. RECOVER (Ball behind paddle)
If the ball somehow gets behind the paddle, the AI chases it directly. Once caught up, returns to DEFEND.

---

## Student: Why does the AI have a "wind-up" phase?

**Teacher:** Without it, the AI would snap instantly to the ball, which feels robotic and unfair. The wind-up:
- Takes 8 frames (about 133ms at 60fps)
- Starts slow, accelerates with an ease-in curve
- Visually pulls back slightly before striking

This mimics how real humans need a moment to react and wind up a shot.

---

## Student: How does the bounce prediction work?

**Teacher:** The AI is smarter about fast vs slow pucks:

| Puck Speed | Max Bounces | Why |
|------------|-------------|-----|
| < 100 px/s | 3 bounces | Slow puck, can predict multiple wall hits |
| 100-250 px/s | 1 bounce | Medium speed, one bounce is reliable |
| > 250 px/s | 0 bounces | Too fast! Pure reaction mode |

This prevents the "bounce paradox" - where predicting too many bounces on a fast puck makes the AI chase phantom predictions.

---

## Student: Why doesn't the AI just hit the ball toward the opponent's goal every time?

**Teacher:** It does aim! When the paddle hits the ball, `calculateStrikeTarget()` analyzes where the opponent is:

- **Opponent on left** → Aim right corner
- **Opponent on right** → Aim left corner  
- **Opponent centered** → Pick a random corner

The physics engine handles the actual ball deflection, but the AI tries to exploit open space.

---

## Student: Why does the AI go back to the center after hitting?

**Teacher:** Positioning! In air hockey, you want to:
1. Hit the ball toward the opponent's open side
2. **Immediately get back to your defensive position**
3. Be ready for the return shot

The AI prioritizes defense over chasing. Once the ball is hit away (moving up toward player 1), the AI returns to its defensive center rather than following the ball.

---

## Student: How does the AI physics work?

**Teacher:** It uses proper acceleration constraints:

1. Calculate direction to target
2. Determine desired speed (varies by state)
3. Calculate velocity difference (desired - current)
4. Clamp acceleration to max (450 px/s²)
5. Apply friction when close to target

This creates smooth, weighty movement instead of instant snapping.

Speed varies by state:
- **DEFEND**: 70% max speed (controlled)
- **ATTACK (wind-up)**: 0% → 100% (ease-in curve)
- **ATTACK (strike)**: 100% max speed
- **RECOVER (chasing)**: 100% max speed
- **RECOVER (returning)**: 60% max speed

---

## State Transition Diagram

```
                    ┌─────────────┐
                    │   DEFEND    │
                    │   (center)  │
                    └──────┬──────┘
                           │
         ┌─────────────────┼─────────────────┐
         │                 │                 │
         ▼                 │                 ▼
┌─────────────────┐        │      ┌─────────────────┐
│     ATTACK      │        │      │    RECOVER      │
│ (hit the ball)  │        │      │ (chase behind)  │
└────────┬────────┘        │      └────────┬────────┘
         │                 │               │
         │    hit ball     │               │
         └────────────────►│               │
                           │               │ caught up
                           │               │
                           ▼               │
                    ┌─────────────┐        │
                    │   DEFEND    │◄───────┘
                    └─────────────┘
```

---

## Key Design Decisions

1. **Prediction limits**: Prevent infinite bounce calculations
2. **Reaction delay**: 5-frame think interval simulates human reaction time
3. **Smooth acceleration**: No instant direction changes
4. **Defensive priority**: Always return to center after action
5. **Adaptive bounce depth**: Fast pucks = pure reaction
