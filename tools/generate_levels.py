"""Generates assets/data/levels.json: 10 hand-made intro levels (tools/levels_intro.json)
followed by procedurally varied levels up to TOTAL.

Run from the project root:  python3 tools/generate_levels.py
Every level mixes: a challenge type (archetype), a map theme, mine layout,
starting resources, enemy composition, rush timing, wave schedule and fortress
strength, so neighbouring levels feel clearly different. The numbers are
starting values and still need playtesting."""
import json
import random

TOTAL = 320
SEED = 20260315
rng = random.Random(SEED)

S, G, A, M, T = "ember_squire", "iron_guard", "ash_archer", "flame_adept", "ember_titan"
ALL_COMBAT = [S, G, A, M, T]

CHAPTERS = [
    "Ember Plains", "Frostbound Reach", "Sunscorched Dunes", "Cinder Highlands",
    "Twilight Wilds", "Stormcrag Fields", "Ashen Frontier", "The Crown Wars",
]
# map themes: 0 night field, 1 snow, 2 desert, 3 volcano, 4 twilight forest, 5 storm
CHAPTER_THEMES = [
    [0, 1, 2], [1, 4, 5], [2, 3, 0], [3, 5, 2], [4, 1, 5], [5, 3, 4], [3, 2, 5], [0, 3, 4, 5],
]

ADJ = ["Broken", "Silent", "Crimson", "Ashen", "Frozen", "Burning", "Hollow", "Iron", "Golden", "Shattered",
       "Forgotten", "Howling", "Bitter", "Sunken", "Wicked", "Rusted", "Gilded", "Twisted", "Savage", "Restless",
       "Ancient", "Bloodied", "Cursed", "Dying", "Emerald", "Fallen", "Grim", "Haunted", "Jagged", "Lonely",
       "Molten", "Northern", "Pale", "Quiet", "Ragged", "Scarred", "Thorned", "Untamed", "Veiled", "Withered"]
NOUN = ["Ridge", "Hollow", "Crossing", "Bastion", "Outpost", "Canyon", "Quarry", "Barrows", "Gate", "Marsh",
        "Causeway", "Watchtower", "Mines", "Ford", "Pass", "Keep", "Fields", "Bluffs", "Cairn", "Spire",
        "Basin", "Trench", "Reach", "Vale", "Ruins", "Summit", "Garrison", "Steppe", "Moor", "Delta",
        "Overlook", "Wastes", "Refuge", "Forge", "Rampart", "Lowlands", "Citadel", "Thicket", "Mesa", "Landing"]
names = [f"{a} {n}" for a in ADJ for n in NOUN]
rng.shuffle(names)

# --- challenge types -----------------------------------------------------------
# keys: minN, w (selection weight), miners, mines, gmul, gold0, rush, gap, mix, ehp, php, hm, dm,
#       recruit, epop, einc, par, reward, survive, army0, spread, limit
ARCH = {
    "Balanced Siege": dict(minN=11, w=4, miners=(2, 3), mines=(3, 4), gmul=1.0, gold0=(0, 60), rush=(45, 65), gap=(35, 55),
        mix={S: 3, G: 2, A: 2, M: 1, T: 0.4}, ehp=1.0, php=1.0, hm=0.0, dm=1.0, recruit=1.0, epop=1.0, einc=1.0, par=1.0, reward=1.0,
        text="A classic fight: dig gold, build a mixed army, break the enemy statue."),
    "Early Rush": dict(minN=11, w=3, miners=(2, 3), mines=(3, 4), gmul=1.0, gold0=(0, 50), rush=(22, 34), gap=(22, 34),
        mix={S: 6, A: 2, G: 0.5}, ehp=0.85, php=1.0, hm=0.0, dm=1.0, recruit=0.7, epop=1.0, einc=1.0, par=0.8, reward=1.0,
        text="The enemy storms in almost immediately. Build defenders before you build economy."),
    "Gold Famine": dict(minN=12, w=3, miners=(1, 2), mines=(2, 2), gmul=0.45, gold0=(60, 100), rush=(55, 80), gap=(45, 70),
        mix={S: 3, G: 2, A: 2, M: 1}, ehp=0.9, php=1.0, hm=0.0, dm=1.0, recruit=1.2, epop=0.9, einc=0.7, par=1.2, reward=1.15,
        text="Only two small ore piles. Every trip counts, so protect your miners."),
    "Gold Rush": dict(minN=11, w=2, miners=(2, 3), mines=(5, 6), gmul=1.3, gold0=(0, 40), rush=(60, 90), gap=(30, 45),
        mix={S: 3, G: 2, A: 2, M: 2, T: 0.6}, ehp=1.1, php=1.0, hm=0.05, dm=1.0, recruit=0.9, epop=1.2, einc=1.3, par=1.0, reward=0.9,
        text="Gold everywhere, but the enemy grows rich too. Out-build them."),
    "Archer Nest": dict(minN=11, w=3, miners=(2, 3), mines=(3, 4), gmul=1.0, gold0=(0, 60), rush=(40, 60), gap=(30, 45),
        mix={A: 8, S: 2, G: 1}, ehp=1.0, php=1.0, hm=-0.1, dm=0.9, recruit=0.9, epop=1.1, einc=1.0, par=1.0, reward=1.0,
        text="Waves of enemy archers. Use shields and a spear volley to break their line."),
    "Iron Wall": dict(minN=13, w=2, miners=(2, 3), mines=(3, 4), gmul=1.1, gold0=(0, 80), rush=(70, 100), gap=(50, 70),
        mix={G: 7, S: 2, A: 1}, ehp=1.6, php=1.0, hm=0.2, dm=0.9, recruit=1.3, epop=1.0, einc=1.0, par=1.5, reward=1.1,
        text="A slow, armoured enemy and a very tough statue. Bring ranged damage."),
    "Giant Hunt": dict(minN=18, w=2, miners=(2, 3), mines=(4, 5), gmul=1.2, gold0=(0, 60), rush=(60, 85), gap=(60, 80),
        mix={T: 3, G: 2, S: 2, A: 1}, ehp=1.1, php=1.1, hm=0.1, dm=1.0, recruit=1.4, epop=0.8, einc=1.1, par=1.3, reward=1.2,
        text="Giants walk the field. Kite them with archers and mages."),
    "Mage Storm": dict(minN=14, w=2, miners=(2, 3), mines=(3, 4), gmul=1.0, gold0=(0, 60), rush=(50, 70), gap=(35, 50),
        mix={M: 5, A: 2, S: 2}, ehp=1.0, php=1.0, hm=0.0, dm=1.1, recruit=1.1, epop=0.9, einc=1.1, par=1.0, reward=1.1,
        text="Enemy fire mages blast your clusters. Spread out and strike first."),
    "Survival": dict(minN=12, w=3, miners=(2, 3), mines=(3, 4), gmul=1.1, gold0=(0, 100), rush=(30, 45), gap=(16, 26),
        mix={S: 3, G: 2, A: 2, M: 1, T: 0.5}, ehp=3.0, php=1.2, hm=0.0, dm=1.0, recruit=0.8, epop=1.3, einc=1.2, par=1.0, reward=1.2,
        survive=(150, 420),
        text="Hold the line until the timer ends. The enemy statue is too strong to topple quickly."),
    "Last Stand": dict(minN=16, w=2, miners=(1, 1), mines=(2, 3), gmul=0.8, gold0=(0, 0), rush=(25, 38), gap=(18, 28),
        mix={S: 3, G: 2, A: 2, M: 1, T: 0.7}, ehp=3.0, php=0.85, hm=0.05, dm=1.0, recruit=0.8, epop=1.4, einc=1.2, par=1.0, reward=1.4,
        survive=(120, 300), army0=True,
        text="You start with a small army and one miner. Survive the onslaught."),
    "Swarm": dict(minN=11, w=2, miners=(2, 3), mines=(3, 4), gmul=1.0, gold0=(0, 60), rush=(35, 50), gap=(20, 32),
        mix={S: 9, A: 1}, ehp=0.9, php=1.0, hm=-0.3, dm=0.7, recruit=0.5, epop=1.9, einc=1.2, par=1.0, reward=1.0,
        text="Endless weak enemies. Area damage and walls of guards win this one."),
    "Siege Breaker": dict(minN=15, w=2, miners=(3, 3), mines=(4, 5), gmul=1.2, gold0=(0, 60), rush=(70, 100), gap=(40, 60),
        mix={G: 3, S: 2, A: 2, M: 1}, ehp=2.6, php=1.0, hm=0.0, dm=1.0, recruit=1.0, epop=1.0, einc=1.0, par=2.2, reward=1.3,
        text="A colossal enemy statue. Build a sustained assault and keep the gold flowing."),
    "Defender": dict(minN=13, w=2, miners=(2, 2), mines=(3, 3), gmul=1.0, gold0=(150, 250), rush=(22, 36), gap=(20, 30),
        mix={S: 4, A: 3, G: 2, M: 1}, ehp=0.9, php=0.55, hm=0.0, dm=1.1, recruit=0.8, epop=1.1, einc=1.1, par=1.0, reward=1.2,
        text="Your statue is fragile and the enemy is already on the way. Protect it."),
    "Quick Strike": dict(minN=12, w=2, miners=(2, 3), mines=(3, 4), gmul=1.0, gold0=(60, 160), rush=(55, 80), gap=(35, 55),
        mix={G: 5, S: 3, A: 1}, ehp=0.45, php=1.0, hm=0.0, dm=1.0, recruit=1.0, epop=1.0, einc=1.0, par=0.6, reward=1.1,
        text="A weak statue guarded by shields. Strike fast for the time star."),
    "Elite Guard": dict(minN=26, w=2, miners=(2, 3), mines=(3, 4), gmul=1.1, gold0=(0, 80), rush=(45, 65), gap=(28, 42),
        mix={G: 3, M: 2, A: 2, T: 1, S: 1}, ehp=1.2, php=1.0, hm=0.25, dm=1.1, recruit=0.9, epop=1.1, einc=1.2, par=1.2, reward=1.3,
        text="Veteran troops with stronger bodies and sharper blades."),
    "Rich Start": dict(minN=11, w=2, miners=(1, 2), mines=(3, 4), gmul=1.0, gold0=(300, 600), rush=(50, 70), gap=(32, 48),
        mix={S: 3, G: 2, A: 2, M: 1, T: 0.4}, ehp=1.0, php=1.0, hm=0.1, dm=1.0, recruit=1.0, epop=1.1, einc=1.0, par=0.9, reward=0.9,
        text="A full treasury but few miners. Spend wisely before the rush."),
    "Long Road": dict(minN=14, w=2, miners=(2, 3), mines=(3, 4), gmul=1.15, gold0=(0, 60), rush=(70, 100), gap=(40, 60),
        mix={S: 3, G: 2, A: 3, M: 1}, ehp=1.0, php=1.0, hm=0.0, dm=1.0, recruit=1.0, epop=1.0, einc=1.0, par=1.3, reward=1.15,
        spread=(430, 560),
        text="The ore piles are far from your statue. Escort your miners out and back."),
    "Limited Arsenal": dict(minN=14, w=3, miners=(2, 3), mines=(3, 4), gmul=1.0, gold0=(0, 60), rush=(45, 65), gap=(32, 48),
        mix={S: 3, G: 2, A: 2, M: 1, T: 0.4}, ehp=1.0, php=1.0, hm=0.0, dm=1.0, recruit=1.0, epop=1.0, einc=1.0, par=1.0, reward=1.25,
        limit=True,
        text="You may only train a few unit types. Make them count."),
}
BOSS = dict(minN=20, w=0, miners=(2, 3), mines=(4, 5), gmul=1.4, gold0=(0, 80), rush=(40, 55), gap=(35, 50),
    mix={T: 4, M: 3, G: 2, S: 1}, ehp=2.0, php=1.3, hm=0.5, dm=1.15, recruit=0.8, epop=1.1, einc=1.3, par=1.5, reward=2.0,
    text="A boss army with giants and mages marches on your statue.")

TIPS = {
    "Survival": "SURVIVAL: you win when the countdown at the top reaches zero (or if you destroy the enemy statue first). Keep your statue and miners alive.",
    "Last Stand": "LAST STAND: you start with an army but almost no gold. Survive until the timer ends.",
    "Boss": "BOSS BATTLE: strong giants and mages. Use Spear Volley and Ember Burst when they bunch up.",
    "Limited Arsenal": "LIMITED ARSENAL: only some unit buttons are available on this level.",
    "Gold Famine": "GOLD FAMINE: the ore piles are small. Do not lose miners.",
    "Long Road": "LONG ROAD: your ore piles are far from the statue. Escort miners with troops.",
}


def pick_mix(mix, n):
    pool = []
    for u, w in mix.items():
        if u == T and n < 15:
            continue
        if u == M and n < 12:
            continue
        pool.append((u, w))
    return pool


def sample(pool):
    total = sum(w for _, w in pool)
    r = rng.random() * total
    for u, w in pool:
        r -= w
        if r <= 0:
            return u
    return pool[-1][0]


def mmss(s):
    return f"{int(s) // 60}:{int(s) % 60:02d}"


intro = json.load(open("tools/levels_intro.json"))["levels"]
tags = ["Tutorial", "Defend", "Archers", "Iron Gate", "Abilities", "Mixed Arms", "Waves", "Big Statue", "Elite Army", "Finale"]
for i, l in enumerate(intro):
    l["tag"] = tags[i] if i < len(tags) else "Campaign"
    l["chapter"] = CHAPTERS[0]
levels = list(intro)

history = []
seen_tags = set(["Tutorial"])
prev_theme = intro[-1]["theme"]
for n in range(len(intro) + 1, TOTAL + 1):
    chapter_idx = (n - 1) // 40
    boss = n % 10 == 0 and n >= 20
    if boss:
        key, a = "Boss", BOSS
    else:
        while True:
            options = [(k, v) for k, v in ARCH.items() if v["minN"] <= n]
            total = sum(v["w"] for _, v in options)
            r = rng.random() * total
            key = options[-1][0]
            for k, v in options:
                r -= v["w"]
                if r <= 0:
                    key = k
                    break
            if key not in history[-2:]:
                break
        a = ARCH[key]
    history.append(key)

    # --- map ---------------------------------------------------------------
    pool = [t for t in CHAPTER_THEMES[chapter_idx] if t != prev_theme] or CHAPTER_THEMES[chapter_idx]
    theme = rng.choice(pool)
    prev_theme = theme

    # --- difficulty scaling -------------------------------------------------
    if n <= 25:
        diff = "easy"
    elif n <= 90:
        diff = "normal"
    else:
        diff = "hard"
    if key in ("Survival", "Last Stand", "Boss", "Elite Guard") and diff == "easy":
        diff = "normal"

    survive = 0
    if "survive" in a:
        lo, hi = a["survive"]
        survive = int(round(rng.uniform(lo, hi) / 10) * 10)

    # --- economy -------------------------------------------------------------
    miners = rng.randint(*a["miners"])
    mine_count = rng.randint(*a["mines"])
    base_gold = 1200 + 40 * n
    spread_lo, spread_hi = a.get("spread", (250, 390))
    spread = rng.uniform(spread_lo, spread_hi)
    start_x = 330 if "spread" not in a else rng.uniform(380, 420)
    mines = []
    for i in range(mine_count):
        x = start_x + (spread * i / max(1, mine_count - 1) if mine_count > 1 else 0) + rng.uniform(-18, 18)
        gold = int(base_gold * a["gmul"] * rng.uniform(0.8, 1.2) / 10) * 10
        mines.append({"x": int(min(x, 800)), "gold": max(200, gold)})
    gold0 = rng.randint(*a["gold0"]) // 10 * 10

    # --- player ----------------------------------------------------------------
    unlocked = ["miner"] + ALL_COMBAT
    limited_note = ""
    if a.get("limit"):
        melee = rng.choice([S, G])
        extra = rng.sample([x for x in ALL_COMBAT if x != melee], 2)
        combat = [u for u in ALL_COMBAT if u in [melee] + extra]
        unlocked = ["miner"] + combat
        names_short = {S: "Swordsmen", G: "Spearmen", A: "Archers", M: "Mages", T: "Giants"}
        limited_note = " Available: " + ", ".join(names_short[u] for u in combat) + "."
    army = []
    if a.get("army0"):
        army = [S] * rng.randint(2, 3) + [G] + [A] * rng.randint(1, 2)
        if n > 60:
            army += [M]
        army = [u for u in army if u in unlocked]
    abilities = ["spear_volley", "ember_burst", "royal_rally", "stone_ward"]

    # --- enemy -----------------------------------------------------------------
    pool_units = pick_mix(a["mix"], n)
    build = [sample(pool_units) for _ in range(6)]
    rush = int(rng.randint(*a["rush"]) // 5 * 5)
    gap_lo, gap_hi = a["gap"]
    t = rush
    waves = []
    horizon = survive + 20 if survive else int((150 + n * 0.9) * a["par"] * 1.5)
    base_size = 2 + n // 28 + (1 if key in ("Swarm", "Early Rush") else 0) + (2 if key == "Swarm" else 0)
    count = 0
    while t < horizon and count < 14:
        size = max(2, min(9, base_size + rng.randint(-1, 2)))
        comp = [sample(pool_units) for _ in range(size)]
        waves.append({"at": int(t), "units": comp})
        t += rng.randint(gap_lo, gap_hi)
        count += 1
    if boss:
        waves.append({"at": int(rush + 70), "units": [T] + ([M] * 2)})
    waves.sort(key=lambda w: w["at"])

    hmult = round(max(0.55, 1 + n / 420 + a["hm"]), 2)
    dmult = round(max(0.5, (1 + n / 700) * a["dm"]), 2)
    enemy = {
        "startingGold": int((100 + 1.2 * n) * a["einc"]) // 10 * 10,
        "passiveIncome": max(2, int(round((5 + n / 14) * a["einc"]))),
        "incomeIntervalSeconds": 5,
        "populationLimit": int(min(48, (10 + n / 9) * a["epop"])),
        "recruitIntervalSeconds": round(max(3.0, (12 - n / 45) * a["recruit"]), 1),
        "buildOrder": build,
        "attackThreshold": max(2, min(8, 2 + n // 40)),
        "retreatBelow": 1 + n // 80,
        "firstAttackAfterSeconds": rush,
        "healthMultiplier": hmult,
        "damageMultiplier": dmult,
        "waves": waves,
    }

    # --- statues, par, reward ---------------------------------------------------
    p_hp = int(round((1000 + 12 * n) * a["php"] / 10) * 10)
    e_hp = int(round((600 + 16 * n) * a["ehp"] / 10) * 10)
    par = int(round((150 + n * 0.9) * a["par"] / 10) * 10)
    if survive:
        par = survive + 5
    reward = int(round((100 + 3 * n) * a["reward"] / 10) * 10)

    name = names[(n - len(intro) - 1) % len(names)]
    mines_txt = f"{mine_count} ore pile{'s' if mine_count != 1 else ''}"
    desc = f"{a['text']} {mines_txt}, enemy rush at {mmss(rush)}." + (f" Survive {mmss(survive)}." if survive else "") + limited_note

    level = {
        "id": n, "name": name, "tag": key if key != "Boss" else "Boss Battle", "chapter": CHAPTERS[chapter_idx],
        "description": desc, "difficulty": diff, "theme": theme,
        "startingGold": gold0, "passiveIncome": 0, "incomeIntervalSeconds": 5,
        "playerFortressHealth": p_hp, "enemyFortressHealth": e_hp, "populationLimit": 30,
        "unlockedUnits": unlocked, "availableAbilities": abilities,
        "rewardCoins": reward, "parTimeSeconds": par, "starFortressThreshold": 0.5 if survive else 0.6,
        "startingMiners": miners, "mines": mines, "enemy": enemy, "tutorial": [],
    }
    if survive:
        level["surviveSeconds"] = survive
    if army:
        level["startingArmy"] = army
    tip_key = "Boss" if boss else key
    if tip_key in TIPS and tip_key not in seen_tags:
        seen_tags.add(tip_key)
        level["tutorial"] = [{"id": "intro", "text": TIPS[tip_key], "advance": "tap"}]
    levels.append(level)

json.dump({"levels": levels}, open("assets/data/levels.json", "w"), separators=(",", ":"))
print(f"wrote {len(levels)} levels")
from collections import Counter
print(Counter(l["tag"] for l in levels).most_common())
