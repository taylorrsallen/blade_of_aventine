# BLADE OF AVENTINE
Orcus brings Commodus back to life and tasks him with defending the Roman culture from the various degenerate groups like the Germans (barbarians), Christians,

## Models
- Player
    - Commodus
- Gods
    - Orcus
    - Minerva
    - Owl of Minerva

## Dialogue
- Orcus Resurrection
    - Didst thou thinketh thine toils wouldst end, having passed drunk on thine degeneracy?
    - Thinketh thine oaths free to be broken?
    - Thou shalt suffer more false Heracles

## Factions
- Unwashed Masses
    - Filler: Peasant
    - Tank: Farmer
    - Fast: Rat
    - Flyer: N/A
    - Boss: Giant Rat
- Franks
    - Filler: Peasant
    - Tank: Soldier
    - Fast: Barbarian
    - Flyer: Evil Bird
    - Boss: Knight
- Scotts
    - s
- Vandals

## TILE IDS
0. temple_roof_border_corner
6. temple_roof_border_wall_01
7. temple_roof_border_wall_00
8. temple_roof_border_end_00
9. temple_roof_border_end_01
10. temple_roof_border_inner
11. temple_roof_border_inner_wall
12. temple_roof_border_center
13. temple_roof
14. temple_roof_end
15. temple_roof_center
16. temple_roof_border_end_00_inverse
17. temple_roof_border_end_01_inverse
18. temple_roof_border_inner_inverse
19. temple_roof_inverse
20. temple_roof_end_inverse


## TODO
- HUD
    - Coin count
    - Wave indicator
    - Bread count

- Barracks that spawn centurions
- Horn that when interacted signals all ally units to attack enemy bread
- Interact with horn again to signal retreat
- Gong to interact with to bring enemy wave early

- Graphic to signify current tower level
- Graphic to signify current tower exp
- Graphic to signify current tower hp
  
- Not sure
    - Put held exp into towers by standing next to them and holding E
    - Take exp out of towers by hitting them with your scepter
    - No tower friendly fire? (On second thought, maybe we keep it, it's kind of funny)

- Final boss

- Book that shows discovered tower recipes and hints at non-secret recipes

- Victory screen
- Defeat screen

- Difficulty

- Footstep sfx
- Death sfx
- Hit sfx
- Firing sfx (for towers)
- Reload sfx (for towers)
- Random callouts
- Action callouts ("Stop!" from centurions)

- Happy dance for allied units upon victory

- Skybox models

- Debuffs
    - Oiled: slow + bonus fire damage, used up by fire
    - Fire: damage over time
    - 

- Towers
    - Basic
        - Arbalest
            - Mid range, mid fire, mid damage, single target
            - Ground & Air
            - ~100 Value
            - Wood/Bronze/Sinew
        - Trebuchet
            - Short range, slow fire, high damage, large AOE
            - Ground only
            - ~200 Value
            - Wood/Wood/Sinew/Sinew/Marble
        - Watch Tower
            - Fast firing, but chooses targets randomly, mid range
            - Slightly higher DPS than Arbalest, but no focus
            - ~100 Value
        - 
    - Fire Arbalest
        - Wood/Bronze/Sinew/Oil
    - Greek Fire (flamethrower, short range, very fast fire, low damage, AOE and DOT)
        - Bronze/Bronze/Oil
    - Oil Hurler
        - Medium Range, causes slow and bonus damage from fire
        - Wood/Oil
  
    - Magic Missile (Arbalest with longer range & homing arrows)
        - Wood/Bronze/Sinew/Magic
    - Magic Beam
        - Marble/Magic
    - 

- Models
    - Characters
        - Emperor
        - Merchant
        - Orcus
        - Athena
        - General ? (who betrays you)
    - Items
        - Bread
        - Coin
    - Blocks
        - Bronze
        - Marble
        - Sinew
        - Oil
        - Magic
    - Tiles
        - Shop kiosk/cart
        - Bread Pile
        - Pillars
        - Temple Walls
        - Peasant Building Walls
        - Roman flags

- Base Character Animations
    - Eat (eating 1 bread)
    - Walk
    - Attack
    - Hands up (grabbing)
    - Stagger (damaged)
    - Die
    - (If Time Allows): 'Damaged' Walk
    - Dance (victory state)

- Player Character Animations
    - Walk
    - Sprint
    - Attack
    - Build (swing hammer)
    - Hands up (grabbing)
    - Place grabbed object
    - Stagger (knocked back by contact with enemies)
    - Die (from tower friendly fire)
    - Dance (leveling up towers)

- Tower Animations
    - Fire
    - Reload
    - Movement (gears turning, etc.)
    - Damage

- Tower States
    - Pristine
    - Damaged

- Sprites
    - "Build with E" animated sprite
    - Generic button
    - Generic menu frame
    - HUD icons
    - Generic font
    - Opening splash screen

- Particles
    - Character death (blood splatter?)
    - Object placed (subtle dust scatter)
    - Tower building (heavy dust that covers up the tower rising from the ground)
    - Dust from sprinting
    - Coin get
    - Bread get
    - Fire



## TODO NO MORE
### 10/07/24
+ Added temple tileset
+ Added Cypress trees and functionality for spawning 'scenery' entities
+ Added building assembler, which uses the tile sets to assemble buildings in a rectangular shape

### 10/06/24
+ Added marble walls, built with 2 marble
+ Enemies can destroy blocks in block piles (full ingredients left when a tower is destroyed), so it is very dangerous to leave towers undefended

---

+ Your damage to turn a tower back into ingredients is now separate from enemy damage to towers, and all towers take only 3 hits from the player to destroy, regardless of their health
+ Towers now start at 0 hp and reach their max hp when they are fully built
+ Enemies can now attack towers that are still building
+ Fixed bug where the shopkeeper was giving you more coins than the sell price for blocks
+ Fixed crash that occurred if you tried to change levels while music was fading in or out (oops)
+ Added support for projectiles to travel in arcs, deal area damage, and have pierce
+ Projectiles are now (mostly) data based and should be (mostly) easy to make many different kinds

---

+ Added trebuchet tower, which absolutely wrecks because there are no tanky enemies yet
+ There are now 'large' and 'small' towers, all towers can be moved but large towers slow you down more and only small towers can fire while being moved

### 10/05/24
+ Spent time with fam 👌
+ Towers now slowly gain exp when you stand next to them
+ Towers prioritize targets with bread based on distance from point to protect, and they prioritize them over all other targets

### 10/04/24
+ Music
    + Level
    + Boss
    + Victory

+ Smooth fades for background tracks

+ Random callouts can be set on a per character basis
+ Drops can be set on a per character basis

+ Each faction can have its own base, spawner, pathing, and units (including your own)
+ You can win still while having allied units alive (previously victory only allowed when all units were dead)

+ Bread pile that must be defended
+ Enemies that reach the bread pile take 1 bread and attempt to leave the map with it
+ Lose when all bread has left the map
+ Enemies carrying bread drop the bread as a pickup (like coins) when they die
+ Dropped bread can only be picked up by the player, but will despawn after 15 seconds if not picked up (thus counting as having lost the bread)
+ Non-player factions can have a bread pile, and are destroyed when their bread pile is empty (even if it has not all left the map yet)

+ Pickups now despawn after 20 seconds so that bread can't be left on the ground to make the player invincible

+ Dialogue readers in world space and GUI, but no dialogue system to make use of them (that's next)

---

+ Towers are now data based and can level up from getting kills
+ Units now attack towers/walls that they walk into, and different towers have different max hp and hp regen rates

+ Enemies taking bread from the pile but not being able to pick up fallen bread was making the game far too easy unfortunately... Now they eat a certain amount of bread and die (?) once they are finished eating.

---

+ Coins can now be used at the shop to buy blocks used for making towers
+ Blocks can also be sold at the shop
+ Shop sells at markup and buys at markdown, amount can change per shop
+ Shop has a shopkeeper that announces prices (but he is invisible right now because I haven't done the art)

### 10/03/24
+ Peasant
    + Random peasant callouts

+ Enemies drop resource for getting blocks (coins)

+ Right click on towers multiple times to break them down into pieces again

+ Interact button to build a tower from a blockpile, instead of it happening automatically
+ Sprite that shows up when a blockpile is a valid recipe and it is highlighted

+ Last wave gets special boss music
+ Main Menu
+ Mission Select menu
+ After killing all enemies in last wave, victory state
+ Enemies come in premade waves (resource)
