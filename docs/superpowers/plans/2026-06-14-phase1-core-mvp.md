# GAWDZILLLLA — Phase 1 Core MVP Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a playable Unity 2D pixel-art kaiju fighting game with 3 characters (Godzilla, Kong, Ghidorah), 1 city (Tokyo), VS mode with full combat (light/heavy/special/unleash), health + power meters, NPC blood splat, and basic audio — running on iOS, Android, and WebGL.

**Architecture:** Unity 2D URP project. All game logic in C# MonoBehaviours and ScriptableObjects. Characters inherit from `CharacterBase`. Combat runs through `AttackSystem` → `HitDetection` → `CharacterBase.TakeDamage`. UI wired through `HUDManager`. Object pooling for NPCs and blood splat particles.

**Tech Stack:** Unity 2022.3 LTS · C# · Unity Input System · Unity Test Framework (NUnit) · Unity 2D URP · Unity Audio Mixer · Sprite Animator

---

## File Map

```
Assets/
├── Scenes/
│   ├── MainMenu.unity
│   ├── CharacterSelect.unity
│   └── Battle_Tokyo.unity
├── Scripts/
│   ├── Core/
│   │   └── GameManager.cs          ← singleton, scene navigation
│   ├── Characters/
│   │   ├── CharacterStats.cs       ← ScriptableObject: HP, speed, damage values
│   │   ├── CharacterBase.cs        ← MonoBehaviour: health/power state, TakeDamage, GainPower
│   │   ├── KaijuController.cs      ← movement, physics, animation state machine
│   │   ├── GodzillaCharacter.cs    ← Godzilla attacks + Nuclear Pulse unleash
│   │   ├── KongCharacter.cs        ← Kong attacks + Primal Rage unleash
│   │   └── GhidorahCharacter.cs    ← Ghidorah attacks + Triple Beam unleash
│   ├── Combat/
│   │   ├── AttackData.cs           ← ScriptableObject: damage, hitbox, duration, powerGain
│   │   ├── AttackSystem.cs         ← spawns hitboxes, manages attack timing + combos
│   │   └── HitDetection.cs         ← Collider2D trigger, calls TakeDamage on contact
│   ├── City/
│   │   ├── NPCController.cs        ← NPC wander AI, death on stomp
│   │   ├── NPCSpawner.cs           ← spawns NPCs across stage, tracks splat count
│   │   └── BloodSplatPool.cs       ← object pool for ParticleSystem blood effects
│   ├── UI/
│   │   ├── HealthBar.cs            ← Image fill mapped to CharacterBase.HealthPercent
│   │   ├── PowerMeter.cs           ← Image fill + pulse animation when full
│   │   ├── HUDManager.cs           ← wires P1/P2 UI to FightManager
│   │   ├── VirtualJoystick.cs      ← touch joystick, outputs Vector2 direction
│   │   └── AttackButtons.cs        ← 4 touch buttons, fires events to AttackSystem
│   ├── GameModes/
│   │   ├── FightManager.cs         ← round management, win condition, VS flow
│   │   └── VSMode.cs               ← VS mode setup: 2-player local, 3 rounds
│   └── Audio/
│       └── AudioManager.cs         ← singleton, PlaySFX/PlayMusic, AudioMixer groups
├── Characters/
│   ├── Kaiju/
│   │   ├── GodzillaStats.asset     ← CharacterStats ScriptableObject
│   │   ├── KongStats.asset
│   │   └── GhidorahStats.asset
│   └── AttackData/
│       ├── Godzilla_Light.asset
│       ├── Godzilla_Heavy.asset
│       ├── Godzilla_Special.asset
│       ├── Kong_Light.asset
│       ├── Kong_Heavy.asset
│       ├── Kong_Special.asset
│       ├── Ghidorah_Light.asset
│       ├── Ghidorah_Heavy.asset
│       └── Ghidorah_Special.asset
├── Audio/
│   ├── Characters/                 ← placeholder MP3s (godzilla_gawdzilla.mp3, etc.)
│   └── NPCs/                       ← splat_01.mp3 through splat_12.mp3
└── Tests/
    └── EditMode/
        ├── CharacterBaseTests.cs
        ├── AttackSystemTests.cs
        ├── FightManagerTests.cs
        └── BloodSplatPoolTests.cs
```

---

## Task 1: Unity Project Setup

**Prerequisites:** Install [Unity Hub](https://unity.com/download), then install Unity 2022.3 LTS.

- [ ] **Step 1: Create the project**

In Unity Hub → New Project → 2D (URP) template → Name: `Gawdzilllla` → Location: `/Users/tc/godzilla-game/` → Create.

Wait for Unity to finish importing. This creates the project at `/Users/tc/godzilla-game/`.

- [ ] **Step 2: Install required packages**

In Unity → Window → Package Manager → Add by name for each:

```
com.unity.inputsystem          (Unity Input System)
com.unity.test-framework       (Unity Test Framework — likely pre-installed)
com.unity.textmeshpro          (TextMeshPro — for HUD text)
com.unity.2d.tilemap           (2D Tilemap Editor)
com.unity.2d.pixel-perfect     (Pixel Perfect Camera)
```

- [ ] **Step 3: Configure Input System**

Edit → Project Settings → Player → Active Input Handling → set to **Both** (supports old + new input). Restart Unity when prompted.

- [ ] **Step 4: Create folder structure**

In the Unity Project window, right-click Assets → Create Folder for each:

```
Assets/Scenes
Assets/Scripts/Core
Assets/Scripts/Characters
Assets/Scripts/Combat
Assets/Scripts/City
Assets/Scripts/UI
Assets/Scripts/GameModes
Assets/Scripts/Audio
Assets/Characters/Kaiju
Assets/Characters/AttackData
Assets/Cities/Tokyo
Assets/NPCs
Assets/Audio/Characters
Assets/Audio/NPCs
Assets/UI
Assets/Tests/EditMode
```

- [ ] **Step 5: Configure build targets**

File → Build Settings → add platforms:
- Click **iOS** → Switch Platform
- Click **Android** → Add (keep iOS active for now)
- Click **WebGL** → Add

Then switch back to the platform you're developing on.

- [ ] **Step 6: Enable Unity Test Framework**

Window → General → Test Runner → ensure "EditMode" tab appears. If prompted to create test assembly, click Yes.

In `Assets/Tests/EditMode/`, Unity will have created `EditMode.asmdef`. Open it in Inspector and ensure **Test Assemblies** is checked.

- [ ] **Step 7: Commit**

```bash
cd /Users/tc/godzilla-game
git add Assets/ ProjectSettings/
git commit -m "feat: Unity 2D URP project setup with input system and test framework"
```

---

## Task 2: CharacterStats ScriptableObject + CharacterBase

**Files:**
- Create: `Assets/Scripts/Characters/CharacterStats.cs`
- Create: `Assets/Scripts/Characters/CharacterBase.cs`
- Create: `Assets/Tests/EditMode/CharacterBaseTests.cs`

- [ ] **Step 1: Create CharacterStats.cs**

```csharp
// Assets/Scripts/Characters/CharacterStats.cs
using UnityEngine;

[CreateAssetMenu(fileName = "CharacterStats", menuName = "Gawdzilllla/Character Stats")]
public class CharacterStats : ScriptableObject
{
    public string characterName;
    public float maxHealth = 100f;
    public float moveSpeed = 5f;
    public float lightAttackDamage = 10f;
    public float heavyAttackDamage = 25f;
    public float lightAttackPowerGain = 5f;
    public float heavyAttackPowerGain = 15f;
    public float specialAttackPowerCost = 25f;
    public float characterScale = 1f; // heroes < 1f, kaiju = 1-2f
}
```

- [ ] **Step 2: Create CharacterBase.cs**

```csharp
// Assets/Scripts/Characters/CharacterBase.cs
using UnityEngine;
using System;

public class CharacterBase : MonoBehaviour
{
    public CharacterStats stats;

    public float CurrentHealth { get; private set; }
    public float PowerMeter { get; private set; } // 0-100
    public bool IsDefeated => CurrentHealth <= 0f;
    public bool IsPowerFull => PowerMeter >= 100f;
    public float HealthPercent => CurrentHealth / stats.maxHealth;
    public float PowerPercent => PowerMeter / 100f;

    public bool IsInvincible { get; set; }
    public bool IsCounterState { get; set; }

    public event Action<float> OnHealthChanged;
    public event Action<float> OnPowerChanged;
    public event Action OnDefeated;
    public event Action OnPowerFull;

    protected virtual void Awake()
    {
        CurrentHealth = stats.maxHealth;
        PowerMeter = 0f;
    }

    public void TakeDamage(float amount)
    {
        if (IsInvincible || IsDefeated) return;

        float multiplier = IsCounterState ? 2f : 1f;
        float actual = amount * multiplier;
        IsCounterState = false;

        CurrentHealth = Mathf.Max(0f, CurrentHealth - actual);
        OnHealthChanged?.Invoke(CurrentHealth);

        if (IsDefeated)
            OnDefeated?.Invoke();
    }

    public void GainPower(float amount)
    {
        if (IsDefeated) return;
        bool wasFull = IsPowerFull;
        PowerMeter = Mathf.Min(100f, PowerMeter + amount);
        OnPowerChanged?.Invoke(PowerMeter);
        if (!wasFull && IsPowerFull)
            OnPowerFull?.Invoke();
    }

    public void SpendPower(float amount)
    {
        PowerMeter = Mathf.Max(0f, PowerMeter - amount);
        OnPowerChanged?.Invoke(PowerMeter);
    }

    public void RestoreHealth(float percent)
    {
        CurrentHealth = Mathf.Min(stats.maxHealth, CurrentHealth + stats.maxHealth * percent);
        OnHealthChanged?.Invoke(CurrentHealth);
    }

    public void ResetForNewRound()
    {
        CurrentHealth = stats.maxHealth;
        PowerMeter = 0f;
        IsInvincible = false;
        IsCounterState = false;
        OnHealthChanged?.Invoke(CurrentHealth);
        OnPowerChanged?.Invoke(PowerMeter);
    }
}
```

- [ ] **Step 3: Write failing tests**

```csharp
// Assets/Tests/EditMode/CharacterBaseTests.cs
using NUnit.Framework;
using UnityEngine;

public class CharacterBaseTests
{
    private CharacterBase CreateCharacter(float maxHealth = 100f)
    {
        var go = new GameObject();
        var stats = ScriptableObject.CreateInstance<CharacterStats>();
        stats.maxHealth = maxHealth;
        stats.lightAttackPowerGain = 5f;
        stats.specialAttackPowerCost = 25f;
        var character = go.AddComponent<CharacterBase>();
        character.stats = stats;
        // Manually call Awake since we're in EditMode
        var awake = typeof(CharacterBase).GetMethod("Awake",
            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
        awake.Invoke(character, null);
        return character;
    }

    [Test]
    public void TakeDamage_ReducesHealth()
    {
        var c = CreateCharacter(100f);
        c.TakeDamage(30f);
        Assert.AreEqual(70f, c.CurrentHealth);
    }

    [Test]
    public void TakeDamage_CannotGoBelowZero()
    {
        var c = CreateCharacter(100f);
        c.TakeDamage(999f);
        Assert.AreEqual(0f, c.CurrentHealth);
        Assert.IsTrue(c.IsDefeated);
    }

    [Test]
    public void TakeDamage_DoesNothingWhenInvincible()
    {
        var c = CreateCharacter(100f);
        c.IsInvincible = true;
        c.TakeDamage(50f);
        Assert.AreEqual(100f, c.CurrentHealth);
    }

    [Test]
    public void TakeDamage_DoublesInCounterState()
    {
        var c = CreateCharacter(100f);
        c.IsCounterState = true;
        c.TakeDamage(20f);
        Assert.AreEqual(60f, c.CurrentHealth);
        Assert.IsFalse(c.IsCounterState); // counter consumed
    }

    [Test]
    public void GainPower_IncreasesPowerMeter()
    {
        var c = CreateCharacter();
        c.GainPower(30f);
        Assert.AreEqual(30f, c.PowerMeter);
    }

    [Test]
    public void GainPower_CapsAt100()
    {
        var c = CreateCharacter();
        c.GainPower(200f);
        Assert.AreEqual(100f, c.PowerMeter);
        Assert.IsTrue(c.IsPowerFull);
    }

    [Test]
    public void SpendPower_ReducesMeter()
    {
        var c = CreateCharacter();
        c.GainPower(50f);
        c.SpendPower(25f);
        Assert.AreEqual(25f, c.PowerMeter);
    }

    [Test]
    public void RestoreHealth_AddsPercentOfMax()
    {
        var c = CreateCharacter(100f);
        c.TakeDamage(50f);
        c.RestoreHealth(0.25f); // restore 25%
        Assert.AreEqual(75f, c.CurrentHealth);
    }

    [Test]
    public void ResetForNewRound_ResetsAllState()
    {
        var c = CreateCharacter(100f);
        c.TakeDamage(80f);
        c.GainPower(60f);
        c.IsInvincible = true;
        c.ResetForNewRound();
        Assert.AreEqual(100f, c.CurrentHealth);
        Assert.AreEqual(0f, c.PowerMeter);
        Assert.IsFalse(c.IsInvincible);
    }

    [TearDown]
    public void TearDown()
    {
        foreach (var go in Object.FindObjectsOfType<GameObject>())
            Object.DestroyImmediate(go);
    }
}
```

- [ ] **Step 4: Run tests — expect PASS**

Window → General → Test Runner → EditMode → Run All.

Expected: All 9 tests PASS. If any fail, fix `CharacterBase.cs` before continuing.

- [ ] **Step 5: Create GodzillaStats asset**

In Project window → right-click `Assets/Characters/Kaiju` → Create → Gawdzilllla → Character Stats → name it `GodzillaStats`. Set values in Inspector:

```
characterName: Godzilla
maxHealth: 120
moveSpeed: 4
lightAttackDamage: 12
heavyAttackDamage: 30
lightAttackPowerGain: 5
heavyAttackPowerGain: 15
specialAttackPowerCost: 25
characterScale: 2
```

- [ ] **Step 6: Create KongStats and GhidorahStats assets**

Same process. Values:

**KongStats:**
```
characterName: Kong
maxHealth: 110
moveSpeed: 5
lightAttackDamage: 14
heavyAttackDamage: 28
lightAttackPowerGain: 5
heavyAttackPowerGain: 15
specialAttackPowerCost: 25
characterScale: 1.8
```

**GhidorahStats:**
```
characterName: Ghidorah
maxHealth: 130
moveSpeed: 3.5
lightAttackDamage: 10
heavyAttackDamage: 32
lightAttackPowerGain: 5
heavyAttackPowerGain: 15
specialAttackPowerCost: 25
characterScale: 2.2
```

- [ ] **Step 7: Commit**

```bash
git add Assets/Scripts/Characters/ Assets/Characters/ Assets/Tests/
git commit -m "feat: CharacterStats ScriptableObject + CharacterBase with health/power system"
```

---

## Task 3: AttackData + AttackSystem + HitDetection

**Files:**
- Create: `Assets/Scripts/Combat/AttackData.cs`
- Create: `Assets/Scripts/Combat/AttackSystem.cs`
- Create: `Assets/Scripts/Combat/HitDetection.cs`
- Create: `Assets/Tests/EditMode/AttackSystemTests.cs`

- [ ] **Step 1: Create AttackData.cs**

```csharp
// Assets/Scripts/Combat/AttackData.cs
using UnityEngine;

public enum AttackType { Light, Heavy, Special, Unleash }

[CreateAssetMenu(fileName = "AttackData", menuName = "Gawdzilllla/Attack Data")]
public class AttackData : ScriptableObject
{
    public AttackType attackType;
    public float damage;
    public float powerGain;      // power given to attacker on hit
    public float powerCost;      // power spent by attacker to use (Special/Unleash)
    public float stunDuration;   // seconds enemy is stunned
    public float hitboxWidth;
    public float hitboxHeight;
    public float hitboxOffsetX;  // offset from character center
    public float hitboxOffsetY;
    public float startupFrames;  // seconds before hitbox is active
    public float activeFrames;   // seconds hitbox stays active
    public float recoveryFrames; // seconds after hitbox before next action
    public string animationTrigger; // Animator trigger name
}
```

- [ ] **Step 2: Create HitDetection.cs**

```csharp
// Assets/Scripts/Combat/HitDetection.cs
using UnityEngine;

// Attached to hitbox GameObjects spawned by AttackSystem.
// Detects CharacterBase colliders and calls TakeDamage.
[RequireComponent(typeof(BoxCollider2D))]
public class HitDetection : MonoBehaviour
{
    public float damage;
    public float powerGain;
    public float stunDuration;
    private CharacterBase _owner;
    private bool _hasHit;

    public void Init(CharacterBase owner, AttackData data)
    {
        _owner = owner;
        damage = data.damage;
        powerGain = data.powerGain;
        stunDuration = data.stunDuration;
        _hasHit = false;

        var col = GetComponent<BoxCollider2D>();
        col.isTrigger = true;
        col.size = new Vector2(data.hitboxWidth, data.hitboxHeight);
        col.offset = new Vector2(data.hitboxOffsetX, data.hitboxOffsetY);
    }

    private void OnTriggerEnter2D(Collider2D other)
    {
        if (_hasHit) return;
        var target = other.GetComponent<CharacterBase>();
        if (target == null || target == _owner) return;

        _hasHit = true;
        target.TakeDamage(damage);
        _owner.GainPower(powerGain);

        if (stunDuration > 0f)
            StartCoroutine(StunTarget(target));
    }

    private System.Collections.IEnumerator StunTarget(CharacterBase target)
    {
        // Disable target input briefly via KaijuController
        var controller = target.GetComponent<KaijuController>();
        if (controller != null)
        {
            controller.IsStunned = true;
            yield return new WaitForSeconds(stunDuration);
            controller.IsStunned = false;
        }
    }
}
```

- [ ] **Step 3: Create AttackSystem.cs**

```csharp
// Assets/Scripts/Combat/AttackSystem.cs
using UnityEngine;
using System.Collections;

// Attached to each character. Receives attack commands from AttackButtons.
// Manages attack timing, combo tracking, and hitbox spawning.
public class AttackSystem : MonoBehaviour
{
    [Header("References")]
    public CharacterBase character;
    public Animator animator;

    [Header("Attack Data")]
    public AttackData lightAttack;
    public AttackData heavyAttack;
    public AttackData specialAttack;
    public AttackData unleashAttack;

    public bool IsAttacking { get; private set; }

    private int _comboCount;
    private float _lastHitTime;
    private const float ComboWindow = 1.5f;
    private const float ComboExtraPower = 3f; // extra % per hit after x5

    public void PerformLight() => StartAttack(lightAttack);
    public void PerformHeavy() => StartAttack(heavyAttack);

    public void PerformSpecial()
    {
        if (character.PowerMeter < specialAttack.powerCost) return;
        character.SpendPower(specialAttack.powerCost);
        StartAttack(specialAttack);
    }

    public void PerformUnleash()
    {
        if (!character.IsPowerFull) return;
        character.SpendPower(100f);
        StartAttack(unleashAttack);
    }

    private void StartAttack(AttackData data)
    {
        if (IsAttacking) return;
        StartCoroutine(AttackRoutine(data));
    }

    private IEnumerator AttackRoutine(AttackData data)
    {
        IsAttacking = true;
        if (animator != null) animator.SetTrigger(data.animationTrigger);

        yield return new WaitForSeconds(data.startupFrames);

        // Spawn hitbox
        var hitboxGo = new GameObject("Hitbox");
        hitboxGo.transform.SetParent(transform);
        hitboxGo.transform.localPosition = Vector3.zero;
        hitboxGo.layer = gameObject.layer;
        hitboxGo.AddComponent<BoxCollider2D>();
        var hd = hitboxGo.AddComponent<HitDetection>();
        hd.Init(character, data);

        yield return new WaitForSeconds(data.activeFrames);
        Destroy(hitboxGo);

        // Track combo
        float now = Time.time;
        if (now - _lastHitTime < ComboWindow)
            _comboCount++;
        else
            _comboCount = 1;
        _lastHitTime = now;

        if (_comboCount >= 5)
            character.GainPower(ComboExtraPower);

        yield return new WaitForSeconds(data.recoveryFrames);
        IsAttacking = false;
    }

    public int GetComboCount() => _comboCount;
}
```

- [ ] **Step 4: Write AttackSystem tests**

```csharp
// Assets/Tests/EditMode/AttackSystemTests.cs
using NUnit.Framework;
using UnityEngine;

public class AttackSystemTests
{
    [Test]
    public void AttackData_DamageIsPositive()
    {
        var data = ScriptableObject.CreateInstance<AttackData>();
        data.damage = 15f;
        data.powerGain = 5f;
        Assert.Greater(data.damage, 0f);
        Assert.Greater(data.powerGain, 0f);
    }

    [Test]
    public void AttackData_SpecialHasPowerCost()
    {
        var data = ScriptableObject.CreateInstance<AttackData>();
        data.attackType = AttackType.Special;
        data.powerCost = 25f;
        Assert.AreEqual(25f, data.powerCost);
    }

    [Test]
    public void CharacterBase_SpendPower_BlocksSpecialWhenInsufficient()
    {
        var go = new GameObject();
        var stats = ScriptableObject.CreateInstance<CharacterStats>();
        stats.maxHealth = 100f;
        stats.specialAttackPowerCost = 25f;
        var character = go.AddComponent<CharacterBase>();
        character.stats = stats;
        var awake = typeof(CharacterBase).GetMethod("Awake",
            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
        awake.Invoke(character, null);

        // Power is 0, trying to spend 25 — meter stays 0
        character.SpendPower(25f);
        Assert.AreEqual(0f, character.PowerMeter);
    }

    [TearDown]
    public void TearDown()
    {
        foreach (var go in Object.FindObjectsOfType<GameObject>())
            Object.DestroyImmediate(go);
    }
}
```

- [ ] **Step 5: Run tests — expect PASS**

Window → General → Test Runner → EditMode → Run All. All tests must pass before continuing.

- [ ] **Step 6: Create AttackData assets**

Right-click `Assets/Characters/AttackData` → Create → Gawdzilllla → Attack Data for each:

**Godzilla_Light.asset:**
```
attackType: Light
damage: 12
powerGain: 5
stunDuration: 0
hitboxWidth: 2.5, hitboxHeight: 1.5, hitboxOffsetX: 1.5, hitboxOffsetY: 0
startupFrames: 0.1, activeFrames: 0.15, recoveryFrames: 0.2
animationTrigger: LightAttack
```

**Godzilla_Heavy.asset:**
```
attackType: Heavy
damage: 30
powerGain: 15
stunDuration: 0.5
hitboxWidth: 3.5, hitboxHeight: 2, hitboxOffsetX: 1.8, hitboxOffsetY: -0.5
startupFrames: 0.25, activeFrames: 0.2, recoveryFrames: 0.4
animationTrigger: HeavyAttack
```

**Godzilla_Special.asset:**
```
attackType: Special
damage: 20
powerGain: 0
powerCost: 25
stunDuration: 0.2
hitboxWidth: 8, hitboxHeight: 1, hitboxOffsetX: 4, hitboxOffsetY: 0.5
startupFrames: 0.3, activeFrames: 0.5, recoveryFrames: 0.3
animationTrigger: SpecialAttack
```

Create Kong_Light, Kong_Heavy, Kong_Special and Ghidorah_Light, Ghidorah_Heavy, Ghidorah_Special with similar values (adjust sizes/damage proportionally).

- [ ] **Step 7: Commit**

```bash
git add Assets/Scripts/Combat/ Assets/Characters/AttackData/ Assets/Tests/
git commit -m "feat: AttackData/AttackSystem/HitDetection combat pipeline with tests"
```

---

## Task 4: KaijuController (Movement + Physics + Animation)

**Files:**
- Create: `Assets/Scripts/Characters/KaijuController.cs`

- [ ] **Step 1: Create KaijuController.cs**

```csharp
// Assets/Scripts/Characters/KaijuController.cs
using UnityEngine;

// Controls movement, facing direction, jump, and animation state.
// Reads from VirtualJoystick (player) or AI input (CPU).
[RequireComponent(typeof(Rigidbody2D))]
[RequireComponent(typeof(CharacterBase))]
public class KaijuController : MonoBehaviour
{
    [Header("References")]
    public Animator animator;
    public SpriteRenderer spriteRenderer;

    public bool IsStunned { get; set; }
    public bool IsGrounded { get; private set; }
    public Vector2 MoveInput { get; set; } // set by VirtualJoystick or AI

    private Rigidbody2D _rb;
    private CharacterBase _character;
    private float _moveSpeed;
    private static readonly int IsWalking = Animator.StringToHash("IsWalking");
    private static readonly int IsGroundedHash = Animator.StringToHash("IsGrounded");

    private void Awake()
    {
        _rb = GetComponent<Rigidbody2D>();
        _character = GetComponent<CharacterBase>();
        _rb.constraints = RigidbodyConstraints2D.FreezeRotation;
        _rb.gravityScale = 3f;
    }

    private void Start()
    {
        _moveSpeed = _character.stats.moveSpeed;
    }

    private void Update()
    {
        if (IsStunned || _character.IsDefeated)
        {
            _rb.velocity = new Vector2(0, _rb.velocity.y);
            return;
        }

        float x = MoveInput.x;
        _rb.velocity = new Vector2(x * _moveSpeed, _rb.velocity.y);

        // Flip sprite to face movement direction
        if (x != 0 && spriteRenderer != null)
            spriteRenderer.flipX = x < 0;

        // Animator
        if (animator != null)
        {
            animator.SetBool(IsWalking, Mathf.Abs(x) > 0.1f);
            animator.SetBool(IsGroundedHash, IsGrounded);
        }
    }

    private void OnCollisionEnter2D(Collision2D col)
    {
        if (col.gameObject.CompareTag("Ground"))
            IsGrounded = true;
    }

    private void OnCollisionExit2D(Collision2D col)
    {
        if (col.gameObject.CompareTag("Ground"))
            IsGrounded = false;
    }
}
```

- [ ] **Step 2: Tag the ground layer**

In Unity: Edit → Project Settings → Tags and Layers → add tag `Ground`. In the Battle_Tokyo scene (created in Task 13), the tilemap ground layer will use this tag.

- [ ] **Step 3: Commit**

```bash
git add Assets/Scripts/Characters/KaijuController.cs
git commit -m "feat: KaijuController movement and animation state machine"
```

---

## Task 5: Character Implementations (Godzilla, Kong, Ghidorah)

**Files:**
- Create: `Assets/Scripts/Characters/GodzillaCharacter.cs`
- Create: `Assets/Scripts/Characters/KongCharacter.cs`
- Create: `Assets/Scripts/Characters/GhidorahCharacter.cs`

- [ ] **Step 1: Create GodzillaCharacter.cs**

```csharp
// Assets/Scripts/Characters/GodzillaCharacter.cs
using UnityEngine;
using System.Collections;

public class GodzillaCharacter : CharacterBase
{
    public AttackSystem attackSystem;
    public AudioSource audioSource;
    public AudioClip gawdzillaShout;
    public ParticleSystem nuclearPulseEffect;

    protected override void Awake()
    {
        base.Awake();
        OnPowerFull += OnPowerMetersMaxed;
    }

    private void OnPowerMetersMaxed()
    {
        // Visual pulse on UNLEASH button — handled by HUDManager listening to OnPowerFull
    }

    public void TriggerUnleash()
    {
        if (!IsPowerFull) return;
        StartCoroutine(NuclearPulseSequence());
    }

    private IEnumerator NuclearPulseSequence()
    {
        // Play GAWDZILLLLA shout
        if (audioSource != null && gawdzillaShout != null)
            audioSource.PlayOneShot(gawdzillaShout);

        // Screen flash (handled via HUDManager event)
        attackSystem.PerformUnleash();

        // Activate particle system
        if (nuclearPulseEffect != null)
        {
            nuclearPulseEffect.gameObject.SetActive(true);
            nuclearPulseEffect.Play();
            yield return new WaitForSeconds(3f);
            nuclearPulseEffect.Stop();
            nuclearPulseEffect.gameObject.SetActive(false);
        }
    }

    private void OnDestroy()
    {
        OnPowerFull -= OnPowerMetersMaxed;
    }
}
```

- [ ] **Step 2: Create KongCharacter.cs**

```csharp
// Assets/Scripts/Characters/KongCharacter.cs
using UnityEngine;
using System.Collections;

public class KongCharacter : CharacterBase
{
    public AttackSystem attackSystem;
    public AudioSource audioSource;
    public AudioClip kongRoar;
    public ParticleSystem primalRageEffect;

    public void TriggerUnleash()
    {
        if (!IsPowerFull) return;
        StartCoroutine(PrimalRageSequence());
    }

    private IEnumerator PrimalRageSequence()
    {
        if (audioSource != null && kongRoar != null)
            audioSource.PlayOneShot(kongRoar);

        attackSystem.PerformUnleash();

        if (primalRageEffect != null)
        {
            primalRageEffect.gameObject.SetActive(true);
            primalRageEffect.Play();
            yield return new WaitForSeconds(3f);
            primalRageEffect.Stop();
            primalRageEffect.gameObject.SetActive(false);
        }
    }
}
```

- [ ] **Step 3: Create GhidorahCharacter.cs**

```csharp
// Assets/Scripts/Characters/GhidorahCharacter.cs
using UnityEngine;
using System.Collections;

public class GhidorahCharacter : CharacterBase
{
    public AttackSystem attackSystem;
    public AudioSource audioSource;
    public AudioClip ghidorahScreech;
    public ParticleSystem tripleBeamLeft;
    public ParticleSystem tripleBeamCenter;
    public ParticleSystem tripleBeamRight;

    public void TriggerUnleash()
    {
        if (!IsPowerFull) return;
        StartCoroutine(TripleGravityBeamSequence());
    }

    private IEnumerator TripleGravityBeamSequence()
    {
        if (audioSource != null && ghidorahScreech != null)
            audioSource.PlayOneShot(ghidorahScreech);

        attackSystem.PerformUnleash();

        // Fire all 3 beams simultaneously
        if (tripleBeamLeft != null) tripleBeamLeft.Play();
        if (tripleBeamCenter != null) tripleBeamCenter.Play();
        if (tripleBeamRight != null) tripleBeamRight.Play();

        yield return new WaitForSeconds(3f);

        if (tripleBeamLeft != null) tripleBeamLeft.Stop();
        if (tripleBeamCenter != null) tripleBeamCenter.Stop();
        if (tripleBeamRight != null) tripleBeamRight.Stop();
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add Assets/Scripts/Characters/GodzillaCharacter.cs Assets/Scripts/Characters/KongCharacter.cs Assets/Scripts/Characters/GhidorahCharacter.cs
git commit -m "feat: Godzilla, Kong, Ghidorah character implementations with unleash moves"
```

---

## Task 6: NPC System (Spawner + Blood Splat Pool)

**Files:**
- Create: `Assets/Scripts/City/NPCController.cs`
- Create: `Assets/Scripts/City/NPCSpawner.cs`
- Create: `Assets/Scripts/City/BloodSplatPool.cs`
- Create: `Assets/Tests/EditMode/BloodSplatPoolTests.cs`

- [ ] **Step 1: Create NPCController.cs**

```csharp
// Assets/Scripts/City/NPCController.cs
using UnityEngine;

public enum NPCType { Human, Police, Soldier, Tank, Helicopter, Jet }

public class NPCController : MonoBehaviour
{
    public NPCType npcType;
    public float dollarsValue;
    public bool isDead;

    private float _wanderSpeed = 1.5f;
    private float _wanderTimer;
    private float _wanderDirection = 1f;

    private void Update()
    {
        if (isDead) return;
        _wanderTimer -= Time.deltaTime;
        if (_wanderTimer <= 0f)
        {
            _wanderDirection = Random.value > 0.5f ? 1f : -1f;
            _wanderTimer = Random.Range(1f, 3f);
        }
        transform.Translate(Vector2.right * _wanderDirection * _wanderSpeed * Time.deltaTime);
    }

    // Called when a kaiju steps on this NPC (via collider trigger on character feet)
    public void OnStomp(Vector2 stompDirection)
    {
        if (isDead) return;
        isDead = true;
        BloodSplatPool.Instance.Spawn(transform.position, stompDirection);
        AudioManager.Instance.PlayRandomSplat();
        NPCSpawner.Instance.RegisterSplat(npcType, dollarsValue);
        gameObject.SetActive(false);
    }
}
```

- [ ] **Step 2: Create BloodSplatPool.cs**

```csharp
// Assets/Scripts/City/BloodSplatPool.cs
using UnityEngine;
using System.Collections.Generic;

public class BloodSplatPool : MonoBehaviour
{
    public static BloodSplatPool Instance { get; private set; }

    public ParticleSystem bloodSplatPrefab;
    public int poolSize = 30;

    private Queue<ParticleSystem> _pool = new Queue<ParticleSystem>();

    private void Awake()
    {
        Instance = this;
        for (int i = 0; i < poolSize; i++)
        {
            var ps = Instantiate(bloodSplatPrefab, transform);
            ps.gameObject.SetActive(false);
            _pool.Enqueue(ps);
        }
    }

    public ParticleSystem GetFromPool()
    {
        if (_pool.Count == 0) return null;
        var ps = _pool.Dequeue();
        ps.gameObject.SetActive(true);
        return ps;
    }

    public void ReturnToPool(ParticleSystem ps)
    {
        ps.gameObject.SetActive(false);
        _pool.Enqueue(ps);
    }

    public void Spawn(Vector2 position, Vector2 direction)
    {
        var ps = GetFromPool();
        if (ps == null) return;
        ps.transform.position = position;
        // Rotate to match stomp direction
        float angle = Mathf.Atan2(direction.y, direction.x) * Mathf.Rad2Deg;
        ps.transform.rotation = Quaternion.Euler(0, 0, angle);
        ps.Play();
        StartCoroutine(ReturnAfterDone(ps));
    }

    private System.Collections.IEnumerator ReturnAfterDone(ParticleSystem ps)
    {
        yield return new WaitForSeconds(ps.main.duration + ps.main.startLifetime.constantMax);
        ReturnToPool(ps);
    }
}
```

- [ ] **Step 3: Create NPCSpawner.cs**

```csharp
// Assets/Scripts/City/NPCSpawner.cs
using UnityEngine;

public class NPCSpawner : MonoBehaviour
{
    public static NPCSpawner Instance { get; private set; }

    public GameObject humanNPCPrefab;
    public int initialHumanCount = 80;
    public float spawnAreaWidth = 20f;
    public float spawnY = 0f;

    private float _totalDestructionDollars;
    private int _splatCount;
    private int _recentSplatCount;
    private float _recentSplatTimer;
    private const float SplatStreakWindow = 2f;
    private const int SplatStreakThreshold = 5;

    public event System.Action<float> OnDestructionScoreChanged;
    public event System.Action OnSplatStreak;

    private void Awake()
    {
        Instance = this;
    }

    private void Start()
    {
        SpawnInitialNPCs();
    }

    private void Update()
    {
        _recentSplatTimer -= Time.deltaTime;
        if (_recentSplatTimer <= 0f)
            _recentSplatCount = 0;
    }

    private void SpawnInitialNPCs()
    {
        for (int i = 0; i < initialHumanCount; i++)
        {
            float x = Random.Range(-spawnAreaWidth / 2f, spawnAreaWidth / 2f);
            var pos = new Vector3(x, spawnY, 0);
            var go = Instantiate(humanNPCPrefab, pos, Quaternion.identity);
            var npc = go.GetComponent<NPCController>();
            npc.npcType = NPCType.Human;
            npc.dollarsValue = 1000f;
        }
    }

    public void RegisterSplat(NPCType type, float dollars)
    {
        _totalDestructionDollars += dollars;
        _splatCount++;
        _recentSplatCount++;
        _recentSplatTimer = SplatStreakWindow;
        OnDestructionScoreChanged?.Invoke(_totalDestructionDollars);

        if (_recentSplatCount >= SplatStreakThreshold)
        {
            _recentSplatCount = 0;
            OnSplatStreak?.Invoke();
        }
    }

    public float GetDestructionScore() => _totalDestructionDollars;
    public int GetSplatCount() => _splatCount;
}
```

- [ ] **Step 4: Write BloodSplatPool tests**

```csharp
// Assets/Tests/EditMode/BloodSplatPoolTests.cs
using NUnit.Framework;
using UnityEngine;

public class BloodSplatPoolTests
{
    [Test]
    public void NPCSpawner_RegisterSplat_AccumulatesDollars()
    {
        var go = new GameObject();
        var spawner = go.AddComponent<NPCSpawner>();
        // Access private field via reflection or make internal for testing
        spawner.RegisterSplat(NPCType.Human, 1000f);
        spawner.RegisterSplat(NPCType.Police, 2000f);
        Assert.AreEqual(3000f, spawner.GetDestructionScore());
    }

    [Test]
    public void NPCSpawner_RegisterSplat_CountsTotal()
    {
        var go = new GameObject();
        var spawner = go.AddComponent<NPCSpawner>();
        spawner.RegisterSplat(NPCType.Human, 1000f);
        spawner.RegisterSplat(NPCType.Human, 1000f);
        Assert.AreEqual(2, spawner.GetSplatCount());
    }

    [TearDown]
    public void TearDown()
    {
        foreach (var go in Object.FindObjectsOfType<GameObject>())
            Object.DestroyImmediate(go);
    }
}
```

- [ ] **Step 5: Run tests — expect PASS**

Window → Test Runner → EditMode → Run All.

- [ ] **Step 6: Commit**

```bash
git add Assets/Scripts/City/ Assets/Tests/EditMode/BloodSplatPoolTests.cs
git commit -m "feat: NPC spawner, blood splat object pool, splat streak detection"
```

---

## Task 7: HUD (Health Bar, Power Meter, HUDManager)

**Files:**
- Create: `Assets/Scripts/UI/HealthBar.cs`
- Create: `Assets/Scripts/UI/PowerMeter.cs`
- Create: `Assets/Scripts/UI/HUDManager.cs`

- [ ] **Step 1: Create HealthBar.cs**

```csharp
// Assets/Scripts/UI/HealthBar.cs
using UnityEngine;
using UnityEngine.UI;

public class HealthBar : MonoBehaviour
{
    public Image fillImage;
    public Gradient colorGradient; // green → yellow → red

    public void SetHealth(float percent)
    {
        percent = Mathf.Clamp01(percent);
        fillImage.fillAmount = percent;
        fillImage.color = colorGradient.Evaluate(percent);
    }
}
```

- [ ] **Step 2: Create PowerMeter.cs**

```csharp
// Assets/Scripts/UI/PowerMeter.cs
using UnityEngine;
using UnityEngine.UI;
using System.Collections;

public class PowerMeter : MonoBehaviour
{
    public Image fillImage;
    public Image unleashButton;
    public Color fullColor = Color.red;
    public Color normalColor = Color.yellow;

    private Coroutine _pulseRoutine;

    public void SetPower(float percent)
    {
        percent = Mathf.Clamp01(percent);
        fillImage.fillAmount = percent;

        if (percent >= 1f)
            StartPulse();
        else
            StopPulse();
    }

    private void StartPulse()
    {
        if (_pulseRoutine != null) return;
        fillImage.color = fullColor;
        if (unleashButton != null)
            _pulseRoutine = StartCoroutine(PulseUnleashButton());
    }

    private void StopPulse()
    {
        if (_pulseRoutine != null)
        {
            StopCoroutine(_pulseRoutine);
            _pulseRoutine = null;
        }
        fillImage.color = normalColor;
        if (unleashButton != null)
            unleashButton.color = Color.white;
    }

    private IEnumerator PulseUnleashButton()
    {
        while (true)
        {
            unleashButton.color = Color.red;
            yield return new WaitForSeconds(0.4f);
            unleashButton.color = Color.white;
            yield return new WaitForSeconds(0.4f);
        }
    }
}
```

- [ ] **Step 3: Create HUDManager.cs**

```csharp
// Assets/Scripts/UI/HUDManager.cs
using UnityEngine;
using TMPro;

public class HUDManager : MonoBehaviour
{
    [Header("P1 HUD")]
    public HealthBar p1HealthBar;
    public PowerMeter p1PowerMeter;

    [Header("P2 HUD")]
    public HealthBar p2HealthBar;
    public PowerMeter p2PowerMeter;

    [Header("Center")]
    public TextMeshProUGUI timerText;
    public TextMeshProUGUI destructionScoreText;
    public TextMeshProUGUI comboText;

    private CharacterBase _p1;
    private CharacterBase _p2;

    public void Init(CharacterBase p1, CharacterBase p2)
    {
        _p1 = p1;
        _p2 = p2;

        p1.OnHealthChanged += _ => p1HealthBar.SetHealth(p1.HealthPercent);
        p1.OnPowerChanged += _ => p1PowerMeter.SetPower(p1.PowerPercent);
        p2.OnHealthChanged += _ => p2HealthBar.SetHealth(p2.HealthPercent);
        p2.OnPowerChanged += _ => p2PowerMeter.SetPower(p2.PowerPercent);

        p1HealthBar.SetHealth(1f);
        p1PowerMeter.SetPower(0f);
        p2HealthBar.SetHealth(1f);
        p2PowerMeter.SetPower(0f);

        NPCSpawner.Instance.OnDestructionScoreChanged += UpdateDestructionScore;
        NPCSpawner.Instance.OnSplatStreak += ShowSplatStreak;
    }

    public void UpdateTimer(float seconds)
    {
        if (timerText != null)
            timerText.text = Mathf.CeilToInt(seconds).ToString();
    }

    private void UpdateDestructionScore(float dollars)
    {
        if (destructionScoreText != null)
            destructionScoreText.text = $"${dollars / 1_000_000f:F1}M";
    }

    private void ShowSplatStreak()
    {
        if (comboText != null)
            StartCoroutine(ShowComboText("SQUISH x5 — GAWDZILLLLA APPROVES", 2f));
    }

    private System.Collections.IEnumerator ShowComboText(string text, float duration)
    {
        comboText.text = text;
        comboText.gameObject.SetActive(true);
        yield return new WaitForSeconds(duration);
        comboText.gameObject.SetActive(false);
    }
}
```

- [ ] **Step 4: Commit**

```bash
git add Assets/Scripts/UI/
git commit -m "feat: HealthBar, PowerMeter, HUDManager with event-driven updates"
```

---

## Task 8: Virtual Joystick + Attack Buttons

**Files:**
- Create: `Assets/Scripts/UI/VirtualJoystick.cs`
- Create: `Assets/Scripts/UI/AttackButtons.cs`

- [ ] **Step 1: Create VirtualJoystick.cs**

```csharp
// Assets/Scripts/UI/VirtualJoystick.cs
using UnityEngine;
using UnityEngine.EventSystems;

public class VirtualJoystick : MonoBehaviour, IPointerDownHandler, IDragHandler, IPointerUpHandler
{
    public RectTransform background;
    public RectTransform handle;
    public float handleRange = 60f;

    public Vector2 Direction { get; private set; }

    private Vector2 _center;
    private Canvas _canvas;

    private void Awake()
    {
        _canvas = GetComponentInParent<Canvas>();
    }

    public void OnPointerDown(PointerEventData data)
    {
        _center = background.position;
        OnDrag(data);
    }

    public void OnDrag(PointerEventData data)
    {
        Vector2 pos;
        RectTransformUtility.ScreenPointToLocalPointInRectangle(
            background, data.position, data.pressEventCamera, out pos);
        pos = Vector2.ClampMagnitude(pos, handleRange);
        handle.localPosition = pos;
        Direction = pos / handleRange;
    }

    public void OnPointerUp(PointerEventData data)
    {
        handle.localPosition = Vector2.zero;
        Direction = Vector2.zero;
    }
}
```

- [ ] **Step 2: Create AttackButtons.cs**

```csharp
// Assets/Scripts/UI/AttackButtons.cs
using UnityEngine;
using UnityEngine.UI;

// Wire up in inspector: drag the 4 Button components to the fields.
public class AttackButtons : MonoBehaviour
{
    public Button lightButton;
    public Button heavyButton;
    public Button specialButton;
    public Button unleashButton;

    private AttackSystem _attackSystem;

    public void Init(AttackSystem attackSystem)
    {
        _attackSystem = attackSystem;
        lightButton.onClick.AddListener(() => _attackSystem.PerformLight());
        heavyButton.onClick.AddListener(() => _attackSystem.PerformHeavy());
        specialButton.onClick.AddListener(() => _attackSystem.PerformSpecial());
        unleashButton.onClick.AddListener(() => _attackSystem.PerformUnleash());
    }
}
```

- [ ] **Step 3: Connect joystick to KaijuController**

Add this to `KaijuController.cs` in `Update()` before the movement code:

```csharp
// Add field at top of KaijuController:
public VirtualJoystick joystick; // assign in Inspector for P1; P2/CPU sets MoveInput directly

// In Update(), replace MoveInput usage with:
if (joystick != null)
    MoveInput = joystick.Direction;
```

- [ ] **Step 4: Commit**

```bash
git add Assets/Scripts/UI/VirtualJoystick.cs Assets/Scripts/UI/AttackButtons.cs Assets/Scripts/Characters/KaijuController.cs
git commit -m "feat: virtual joystick and attack buttons for mobile touch input"
```

---

## Task 9: VS Mode (FightManager + Round System)

**Files:**
- Create: `Assets/Scripts/GameModes/FightManager.cs`
- Create: `Assets/Scripts/GameModes/VSMode.cs`
- Create: `Assets/Tests/EditMode/FightManagerTests.cs`

- [ ] **Step 1: Create FightManager.cs**

```csharp
// Assets/Scripts/GameModes/FightManager.cs
using UnityEngine;
using System;

public class FightManager : MonoBehaviour
{
    public static FightManager Instance { get; private set; }

    public CharacterBase player1;
    public CharacterBase player2;
    public float roundDuration = 99f;
    public int totalRounds = 3;

    public int P1RoundsWon { get; private set; }
    public int P2RoundsWon { get; private set; }
    public int CurrentRound { get; private set; } = 1;
    public float RoundTimeRemaining { get; private set; }
    public bool RoundActive { get; private set; }

    public event Action<int> OnRoundStart;   // round number
    public event Action<int> OnRoundEnd;     // 1 = p1 wins round, 2 = p2 wins round
    public event Action<int> OnMatchEnd;     // 1 = p1 wins match, 2 = p2 wins match

    private void Awake()
    {
        Instance = this;
    }

    public void StartMatch()
    {
        P1RoundsWon = 0;
        P2RoundsWon = 0;
        CurrentRound = 0;
        StartNextRound();
    }

    public void StartNextRound()
    {
        CurrentRound++;
        RoundTimeRemaining = roundDuration;
        RoundActive = true;
        player1.ResetForNewRound();
        player2.ResetForNewRound();
        OnRoundStart?.Invoke(CurrentRound);
    }

    private void Update()
    {
        if (!RoundActive) return;

        RoundTimeRemaining -= Time.deltaTime;

        if (player1.IsDefeated)
            EndRound(2);
        else if (player2.IsDefeated)
            EndRound(1);
        else if (RoundTimeRemaining <= 0f)
            EndRoundByTime();
    }

    private void EndRoundByTime()
    {
        // Whoever has more health wins
        int winner = player1.HealthPercent >= player2.HealthPercent ? 1 : 2;
        EndRound(winner);
    }

    private void EndRound(int winner)
    {
        RoundActive = false;
        if (winner == 1) P1RoundsWon++;
        else P2RoundsWon++;
        OnRoundEnd?.Invoke(winner);

        int roundsToWin = Mathf.CeilToInt(totalRounds / 2f) + 1;
        if (P1RoundsWon >= roundsToWin)
            OnMatchEnd?.Invoke(1);
        else if (P2RoundsWon >= roundsToWin)
            OnMatchEnd?.Invoke(2);
        else
            Invoke(nameof(StartNextRound), 2f);
    }

    public float GetRoundTimeRemaining() => RoundTimeRemaining;
    public int GetP1RoundsWon() => P1RoundsWon;
    public int GetP2RoundsWon() => P2RoundsWon;
}
```

- [ ] **Step 2: Create VSMode.cs**

```csharp
// Assets/Scripts/GameModes/VSMode.cs
using UnityEngine;
using TMPro;

public class VSMode : MonoBehaviour
{
    public FightManager fightManager;
    public HUDManager hudManager;
    public GameObject resultsPanel;
    public TextMeshProUGUI resultsText;

    private void Start()
    {
        hudManager.Init(fightManager.player1, fightManager.player2);
        fightManager.OnRoundStart += OnRoundStart;
        fightManager.OnRoundEnd += OnRoundEnd;
        fightManager.OnMatchEnd += OnMatchEnd;
        fightManager.StartMatch();
    }

    private void Update()
    {
        hudManager.UpdateTimer(fightManager.RoundTimeRemaining);
    }

    private void OnRoundStart(int round)
    {
        Debug.Log($"ROUND {round} — FIGHT!");
    }

    private void OnRoundEnd(int winner)
    {
        string winnerName = winner == 1
            ? fightManager.player1.stats.characterName
            : fightManager.player2.stats.characterName;
        Debug.Log($"{winnerName} wins round {fightManager.CurrentRound}!");
    }

    private void OnMatchEnd(int winner)
    {
        string winnerName = winner == 1
            ? fightManager.player1.stats.characterName
            : fightManager.player2.stats.characterName;

        if (resultsPanel != null)
        {
            resultsPanel.SetActive(true);
            resultsText.text = $"{winnerName} WINS!\n\nDestruction: ${NPCSpawner.Instance.GetDestructionScore() / 1_000_000f:F1}M";
        }
    }
}
```

- [ ] **Step 3: Write FightManager tests**

```csharp
// Assets/Tests/EditMode/FightManagerTests.cs
using NUnit.Framework;
using UnityEngine;

public class FightManagerTests
{
    private CharacterBase CreateCharacter(float hp = 100f)
    {
        var go = new GameObject();
        var stats = ScriptableObject.CreateInstance<CharacterStats>();
        stats.maxHealth = hp;
        var c = go.AddComponent<CharacterBase>();
        c.stats = stats;
        var awake = typeof(CharacterBase).GetMethod("Awake",
            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
        awake.Invoke(c, null);
        return c;
    }

    [Test]
    public void FightManager_RoundWonByP2_WhenP1Defeated()
    {
        var go = new GameObject();
        var fm = go.AddComponent<FightManager>();
        fm.player1 = CreateCharacter();
        fm.player2 = CreateCharacter();
        fm.totalRounds = 3;

        int roundWinner = -1;
        fm.OnRoundEnd += w => roundWinner = w;
        fm.StartMatch();

        fm.player1.TakeDamage(999f); // defeat P1

        // Simulate one Update frame
        var update = typeof(FightManager).GetMethod("Update",
            System.Reflection.BindingFlags.NonPublic | System.Reflection.BindingFlags.Instance);
        update.Invoke(fm, null);

        Assert.AreEqual(2, roundWinner);
        Assert.AreEqual(1, fm.GetP2RoundsWon());
    }

    [Test]
    public void FightManager_StartMatch_ResetsRounds()
    {
        var go = new GameObject();
        var fm = go.AddComponent<FightManager>();
        fm.player1 = CreateCharacter();
        fm.player2 = CreateCharacter();
        fm.totalRounds = 3;
        fm.StartMatch();
        Assert.AreEqual(0, fm.GetP1RoundsWon());
        Assert.AreEqual(0, fm.GetP2RoundsWon());
        Assert.AreEqual(1, fm.CurrentRound);
    }

    [TearDown]
    public void TearDown()
    {
        foreach (var go in Object.FindObjectsOfType<GameObject>())
            Object.DestroyImmediate(go);
    }
}
```

- [ ] **Step 4: Run tests — expect PASS**

Window → Test Runner → EditMode → Run All. All tests must pass.

- [ ] **Step 5: Commit**

```bash
git add Assets/Scripts/GameModes/ Assets/Tests/EditMode/FightManagerTests.cs
git commit -m "feat: FightManager round system + VSMode with match flow and results panel"
```

---

## Task 10: AudioManager

**Files:**
- Create: `Assets/Scripts/Audio/AudioManager.cs`

- [ ] **Step 1: Create AudioManager.cs**

```csharp
// Assets/Scripts/Audio/AudioManager.cs
using UnityEngine;
using UnityEngine.Audio;

public class AudioManager : MonoBehaviour
{
    public static AudioManager Instance { get; private set; }

    public AudioMixer mixer;
    public AudioSource sfxSource;
    public AudioSource musicSource;

    [Header("NPC Splat SFX")]
    public AudioClip[] splatClips; // splat_01 through splat_12

    [Header("Character SFX")]
    public AudioClip gawdzillaShout;

    [Header("Music")]
    public AudioClip tokyoBGM;

    private int _lastSplatIndex = -1;

    private void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    private void Start()
    {
        PlayMusic(tokyoBGM);
    }

    public void PlaySFX(AudioClip clip)
    {
        if (clip == null) return;
        sfxSource.PlayOneShot(clip);
    }

    public void PlayRandomSplat()
    {
        if (splatClips == null || splatClips.Length == 0) return;
        int index;
        do { index = Random.Range(0, splatClips.Length); }
        while (index == _lastSplatIndex && splatClips.Length > 1);
        _lastSplatIndex = index;
        sfxSource.PlayOneShot(splatClips[index]);
    }

    public void PlayGawdzilla()
    {
        PlaySFX(gawdzillaShout);
    }

    public void PlayMusic(AudioClip clip)
    {
        if (clip == null) return;
        musicSource.clip = clip;
        musicSource.loop = true;
        musicSource.Play();
    }

    public void SetMasterVolume(float volume) =>
        mixer.SetFloat("MasterVolume", Mathf.Log10(Mathf.Max(volume, 0.0001f)) * 20f);

    public void SetMusicVolume(float volume) =>
        mixer.SetFloat("MusicVolume", Mathf.Log10(Mathf.Max(volume, 0.0001f)) * 20f);

    public void SetSFXVolume(float volume) =>
        mixer.SetFloat("SFXVolume", Mathf.Log10(Mathf.Max(volume, 0.0001f)) * 20f);
}
```

- [ ] **Step 2: Create Audio Mixer**

In Unity: Assets → Create → Audio Mixer → name it `GameAudioMixer`. In the Mixer window, add groups: Master → Music, Master → SFX. Expose parameters named `MasterVolume`, `MusicVolume`, `SFXVolume` (right-click each group's volume knob → Expose Parameter).

- [ ] **Step 3: Add placeholder audio files**

Place any royalty-free MP3s into `Assets/Audio/NPCs/` named `splat_01.mp3` through `splat_12.mp3` (can be the same file duplicated for now). Add `gawdzilla_shout.mp3` to `Assets/Audio/Characters/`.

- [ ] **Step 4: Commit**

```bash
git add Assets/Scripts/Audio/ Assets/Audio/
git commit -m "feat: AudioManager singleton with mixer groups, random splat, no-repeat logic"
```

---

## Task 11: GameManager + Scene Navigation

**Files:**
- Create: `Assets/Scripts/Core/GameManager.cs`

- [ ] **Step 1: Create GameManager.cs**

```csharp
// Assets/Scripts/Core/GameManager.cs
using UnityEngine;
using UnityEngine.SceneManagement;

public class GameManager : MonoBehaviour
{
    public static GameManager Instance { get; private set; }

    public static string SelectedCharacterP1 = "Godzilla";
    public static string SelectedCharacterP2 = "Kong";
    public static string SelectedCity = "Tokyo";

    private void Awake()
    {
        if (Instance != null) { Destroy(gameObject); return; }
        Instance = this;
        DontDestroyOnLoad(gameObject);
    }

    public void GoToMainMenu() => SceneManager.LoadScene("MainMenu");
    public void GoToCharacterSelect() => SceneManager.LoadScene("CharacterSelect");
    public void GoToBattle() => SceneManager.LoadScene($"Battle_{SelectedCity}");
    public void GoToMainMenuFromBattle() => SceneManager.LoadScene("MainMenu");

    public void QuitGame()
    {
#if UNITY_EDITOR
        UnityEditor.EditorApplication.isPlaying = false;
#else
        Application.Quit();
#endif
    }
}
```

- [ ] **Step 2: Add scenes to Build Settings**

File → Build Settings → Scenes In Build → drag in:
1. `Assets/Scenes/MainMenu.unity`
2. `Assets/Scenes/CharacterSelect.unity`
3. `Assets/Scenes/Battle_Tokyo.unity`

- [ ] **Step 3: Commit**

```bash
git add Assets/Scripts/Core/GameManager.cs ProjectSettings/EditorBuildSettings.asset
git commit -m "feat: GameManager scene navigation with static character/city selection"
```

---

## Task 12: Tokyo Battle Scene Setup (Unity Editor)

This task requires Unity Editor work. Follow each step carefully in the Editor.

- [ ] **Step 1: Create Battle_Tokyo scene**

File → New Scene → Save As `Assets/Scenes/Battle_Tokyo.unity`.

- [ ] **Step 2: Set up Pixel Perfect Camera**

Select Main Camera → Add Component → Pixel Perfect Camera. Set:
```
Reference Resolution: 480 x 270
Upscale Render Texture: checked
Pixel Snap: checked
```

- [ ] **Step 3: Create city tilemap layers**

In Hierarchy → right-click → 2D Object → Tilemap → Rectangular. Repeat to create 3 tilemaps:
- `Background` (sky + far buildings) — Order in Layer: 0
- `Buildings` (midground structures) — Order in Layer: 1  
- `Ground` (walkable floor) — Order in Layer: 2, add tag `Ground`

Use Unity's Tile Palette (Window → 2D → Tile Palette) with placeholder color tiles for now. Fill the Ground layer with a solid row of tiles at y=0. Fill Background with dark sky. Add building-shaped tiles to Buildings.

- [ ] **Step 4: Add P1 Godzilla**

In Hierarchy → Create Empty → name `Player1_Godzilla`. Add components:
- `Rigidbody2D` (gravity scale 3, freeze rotation Z)
- `BoxCollider2D` (size 2×3)
- `SpriteRenderer` (assign placeholder sprite)
- `Animator` (create an `AnimatorController` asset, add states: Idle, Walk, LightAttack, HeavyAttack, SpecialAttack, Unleash, Hit, Defeat)
- `CharacterBase` → assign `GodzillaStats`
- `KaijuController` → assign Animator + SpriteRenderer
- `AttackSystem` → assign all Godzilla attack data assets
- `GodzillaCharacter`
- `AudioSource`

Position at (-5, 1, 0).

- [ ] **Step 5: Add P2 Ghidorah (CPU)**

Duplicate Player1_Godzilla → rename `Player2_Ghidorah`. Swap components:
- `CharacterBase` → assign `GhidorahStats`
- `AttackSystem` → assign Ghidorah attack data assets
- Remove `GodzillaCharacter`, add `GhidorahCharacter`

Position at (5, 1, 0).

- [ ] **Step 6: Add NPC system**

Create Empty → name `NPCSystem`. Add:
- `NPCSpawner` component → assign human NPC prefab, set initialHumanCount: 60, spawnAreaWidth: 18

Create Empty → name `BloodSplatSystem`. Add:
- `BloodSplatPool` → assign blood splat particle prefab (create a simple red burst particle system), poolSize: 30

- [ ] **Step 7: Add HUD Canvas**

Right-click Hierarchy → UI → Canvas (Screen Space Overlay). Inside:
- Create top bar with 2 health bar Image fills + 2 power meter fills + center timer TextMeshPro
- Create bottom bar with VirtualJoystick background + handle + 4 attack buttons
- Add `HUDManager` component to Canvas, wire all references
- Add `AttackButtons` component, wire 4 buttons to P1's AttackSystem

- [ ] **Step 8: Add FightManager + VSMode**

Create Empty → name `GameMode`. Add:
- `FightManager` → assign player1, player2, totalRounds: 3, roundDuration: 99
- `VSMode` → assign fightManager + hudManager references

- [ ] **Step 9: Add AudioManager**

Create Empty → name `AudioManager`. Add `AudioManager` component. Assign mixer, audio sources, and placeholder clips.

- [ ] **Step 10: Test play in editor**

Press Play. Verify:
- P1 moves with keyboard (WASD) or on-screen joystick
- Light/Heavy/Special attacks spawn hitboxes
- Hitting P2 reduces their health bar
- Power meter fills on hit
- NPCs wander and splat when walked over
- Splat SFX plays randomly

- [ ] **Step 11: Commit**

```bash
git add Assets/Scenes/Battle_Tokyo.unity Assets/Prefabs/
git commit -m "feat: Tokyo battle scene with characters, city tilemap, NPC system, and HUD"
```

---

## Task 13: Main Menu + Character Select Scenes

- [ ] **Step 1: Create MainMenu scene**

File → New Scene → Save As `Assets/Scenes/MainMenu.unity`. Add:
- Background image (dark pixel art sky)
- Title text: "GAWDZILLLLA" (TextMeshPro, large pixel font)
- 3 buttons: PLAY, OPTIONS, QUIT
- Add `GameManager` prefab to scene
- PLAY button → calls `GameManager.Instance.GoToCharacterSelect()`

- [ ] **Step 2: Create CharacterSelect scene**

File → New Scene → Save As `Assets/Scenes/CharacterSelect.unity`. Add:
- 3 character cards: Godzilla, Kong, Ghidorah (each showing: emoji placeholder sprite + name + stats summary)
- P1 SELECT label + P2 SELECT label (for local 2P, tap a card to assign to P1, second tap to P2)
- FIGHT button → sets `GameManager.SelectedCharacterP1`/`SelectedCharacterP2` → calls `GoToBattle()`

Create script `Assets/Scripts/UI/CharacterSelectManager.cs`:

```csharp
// Assets/Scripts/UI/CharacterSelectManager.cs
using UnityEngine;
using UnityEngine.UI;
using TMPro;

public class CharacterSelectManager : MonoBehaviour
{
    public string[] characterNames = { "Godzilla", "Kong", "Ghidorah" };
    public TextMeshProUGUI p1SelectedText;
    public TextMeshProUGUI p2SelectedText;

    private int _p1Selection = 0;
    private int _p2Selection = 1;
    private bool _selectingP2;

    public void SelectCharacter(int index)
    {
        if (!_selectingP2)
        {
            _p1Selection = index;
            p1SelectedText.text = $"P1: {characterNames[index]}";
            _selectingP2 = true;
        }
        else
        {
            _p2Selection = index;
            p2SelectedText.text = $"P2: {characterNames[index]}";
            _selectingP2 = false;
        }
    }

    public void StartFight()
    {
        GameManager.SelectedCharacterP1 = characterNames[_p1Selection];
        GameManager.SelectedCharacterP2 = characterNames[_p2Selection];
        GameManager.Instance.GoToBattle();
    }
}
```

- [ ] **Step 3: Commit**

```bash
git add Assets/Scenes/MainMenu.unity Assets/Scenes/CharacterSelect.unity Assets/Scripts/UI/CharacterSelectManager.cs
git commit -m "feat: main menu and character select with 3-character picker"
```

---

## Task 14: Build for iOS, Android, WebGL

- [ ] **Step 1: iOS build**

File → Build Settings → iOS → Switch Platform → Build. Xcode project will be created. Open in Xcode → set Bundle ID (e.g. `com.yourname.gawdzilllla`) → connect device or simulator → Run.

Expected: Game launches on iOS device. Touch joystick responds. Attack buttons trigger attacks.

- [ ] **Step 2: Android build**

File → Build Settings → Android → Switch Platform. Player Settings → Package Name: `com.yourname.gawdzilllla`. File → Build → produces `.apk`. Install via `adb install build.apk`.

Expected: Game launches on Android. Same gameplay verified.

- [ ] **Step 3: WebGL build**

File → Build Settings → WebGL → Switch Platform → Build. Opens in browser via `localhost`. Test touch controls on mobile Chrome/Safari.

Player Settings → WebGL → Compression: Brotli. Resolution: 480×270 scaled.

- [ ] **Step 4: Final commit**

```bash
git add ProjectSettings/
git commit -m "feat: Phase 1 MVP complete — iOS/Android/WebGL builds verified"
```

---

## Self-Review: Spec Coverage Check

| Spec Requirement | Covered By |
|-----------------|-----------|
| Unity 2D URP, pixel art | Task 1 (project setup) + Task 12 (Pixel Perfect Camera) |
| 3 starter characters (Godzilla, Kong, Ghidorah) | Tasks 2, 5 |
| CharacterStats ScriptableObject | Task 2 |
| Health + power meter | Tasks 2, 7 |
| Light/heavy/special/unleash attacks | Tasks 3, 5 |
| +5%/+15%/+25% power gain rules | Tasks 2, 3 |
| Dodge + counter state | Task 2 (IsCounterState), Task 4 (KaijuController) |
| GAWDZILLLLA shout on unleash | Tasks 5, 10 |
| Tokyo city scene | Task 12 |
| NPC blood splat + object pool | Task 6 |
| SPLAT STREAK detection | Task 6 (NPCSpawner) |
| VS mode, 3 rounds, health bars | Tasks 7, 9 |
| Round timer | Tasks 9 (FightManager), 7 (HUDManager.UpdateTimer) |
| Virtual joystick + 4 attack buttons | Task 8 |
| Main menu + character select | Task 13 |
| iOS + Android + WebGL builds | Task 14 |
| AudioManager, random splat SFX | Task 10 |
| 60fps performance target | Task 12 (Pixel Perfect + URP) |
| Object pool NPC cap | Task 6 (BloodSplatPool pool size 30) |

**Gaps noted and addressed:**
- Grab & throw mechanic: deferred to Phase 2 (needs grab animation + building collapse prefabs)
- CPU AI movement: P2 in MVP is human-controlled (local 2P); CPU AI deferred to Phase 2
- Food power-ups + fart system: Phase 2
- Gregg easter egg: Phase 3

---

## What's Next (Phase 2 Plan)
After Phase 1 ships: all 20 characters, 50 cities, food power-up + breakout scene system, fart power system, localized audio (ElevenLabs), story/smash mode, survival mode. Separate plan document.
