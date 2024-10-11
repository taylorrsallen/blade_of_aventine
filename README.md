# BLADE OF AVENTINE
Orcus brings Commodus back to life and tasks him with defending the Roman culture from the various degenerate groups like the Germans (barbarians), Christians,

## Models
- Player
    - Commodus
- Gods
    - Orcus
    - Minerva
    - Owl of Minerva

## Plot
- Orcus gives you his speech the first time you launch the game
- Orcus takes you to defend Romes food supplies from the rabble that are trying to profit off the chaos
- You are instructed on movement (WASD, shift to sprint)
- You are instructed on how to look around (mouse, scroll to zoom)
- You are instructed on how to destroy things with your scepter to get materials
- You are instructed on how to move around objects to build things
- You are instructed on how to build something once it matches a recipe
- A senatorae shows up to try to kill you
- He drops an Aureus
- Play the level, defeat the giant rat

- ! Room for more fighting with Unwashed Masses here

- Meet up with general to get the German barbarians out of Rome
- Defeat the German Knight

- ! Room for more German levels here

- General betrays you, sending his forces against yours
- Defeat the Roman General

- Hunt down the Scotts in the forests
- Defeat the Scottish Berserker

- Hunt down the Germans in the forests
- Defeat the German ?

- Return to Rome to fight off the invading vandals
- Die to the vandals

## Dialogue
- Orcus Resurrection
    - Didst thou thinketh thine toils wouldst end, having passed drunk on thine degeneracy?
    - Thinketh thine oaths free to be broken?
    - Thou shalt suffer more false Heracles

##
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

## Factions
- Unwashed Masses
    - [x] Filler: Peasant
    - Tank: Deserter
    - Fast: Rat
    - Flyer: N/A
    - Boss: Giant Rat
    - Unique: Senatorae
        - Low health, lots of money, high damage, medium speed, goes after player instead of bread
- Franks
    - Filler: Peasant
    - Tank: Soldier
    - Fast: Berserker
    - Flyer: Hawk/Vulture
    - Boss: Knight
- Roman Revolt
    - Filler: Soldier
    - Tank: Centurion
    - Fast: Scout (on horse)
    - Flyer: N/A
    - Boss: Roman General
    - Unique: Senatorae
- Scotts
    - s
- Vandals

## TODO
### !!!!! IMPORTANT START !!!!!
- Varying coin values are spawned based on the Roman currency
- Special shiny effect for when an Aureus is dropped

- Faction units
    - RAT BOSS
    - ??? BOSS
    - GERMAN KNIGHT BOSS

- Towers have targeting priorities on which type of enemy they target first (TANK, FAST, NORMAL, FLYING)
- Graphic to signify current tower level
- Graphic to signify current tower exp
- Graphic to signify current tower hp

- Volume in settings menu

- Splitscreen
    - Menu for adding/removing local players

- Orcus
    - Underworld gates which lead to levels
    - Some NPCS that whine about their fate
    - Orcus in his throne
    - A rack that you can select different scepters from

- Tutorial
    - [Left Click / X (Sony) / A (XBOX)] to INTERACT
        - Use it to LIFT and PLACE objects!
    - [Right click / Circle (Sony) / B (XBOX)] to ATTACK
        - Use it to break down that OLD TOWER!
    - [E / Square (SONY) / X (XBOX)] to USE
        - Use it to craft a tower once you have the correct combination of ingredients!

- Models
    - Characters
        - [x] Emperor
        - Merchant
        - Orcus
        - Athena
        - General ? (who betrays you)
    - Items
        - Bread
        - Coin
    - Blocks
        - Bronze
        - [x] Marble
        - Sinew
        - Oil
        - Magic
    - Tiles
        - Shop kiosk/cart
        - Bread Pile
        - [x] Pillars
        - Harvestable
            - Crate
        - Temple
            - [x] Roofing
            - Walls
            - Ceiling
            - Door
        - Peasant Buildings
            - Roofing
            - Walls
            - Ceiling
            - Door
        - Roman flags
    - Towers
        - [x] Gun: Arbalest
        - [ ] Gun: Catapult
        - [ ] Gun: Dart
        - [ ] Gun: Flamethrower
        - [ ] Gun: 
        - [x] Wood tall yaw pivot
        - [ ] Wood short yaw pivot
        - [ ] Bronze short yaw pivot
        - [x] Wood large foundation
        - [ ] Wood small foundation
        - [ ] Marble large foundation
        - [ ] Marble small foundation
        - [ ] Bronze small foundation

- Base Character Animations
    - [x] Eat (eating 1 bread)
    - [x] Walk
    - [x] Attack
    - [-] Hands up (grabbing)
    - Stagger (damaged)
    - [x] Die
    - (If Time Allows): 'Damaged' Walk
    - Dance (victory state)

- Player Character Animations
    - [x] Walk
    - Sprint
    - Attack
    - Build (swing hammer)
    - [x] Hands up (grabbing)
    - [x] Place grabbed object
    - Stagger (knocked back by contact with enemies)
    - [x] Die (from tower friendly fire)
    - Dance (leveling up towers)

- Tower Animations
    - Fire
    - Reload
    - [x] Damage

- Sprites
    - "Build with E" animated sprite
    - [x] Generic button
    - [x] Generic menu frame
    - HUD icons
    - [x] Generic font
    - Opening splash screen

- Particles
    - Character death (blood splatter?)
    - Object placed (subtle dust scatter)
    - Tower building (heavy dust that covers up the tower rising from the ground)
    - Dust from sprinting
    - Coin get
    - Bread get
    - Fire
### !!!!! IMPORTANT END !!!!!

### LESS IMPORTANT
- Hit sfx
- Firing sfx (for towers)
- Reload sfx (for towers)
- Random callouts
- Action callouts ("Stop!" from centurions)

- Broken towers
    - Non-functional towers on maps at the start, break down for materials and space

- Happy dance for allied units upon victory

- Skybox models

- Debuffs
    - Oiled: slow + bonus fire damage, used up by fire
    - Fire: damage over time

### IF I HAVE TIME
- Tower States
    - Pristine
    - Damaged

- Multiple scepters with different effects to choose from
- Multiple dances with different effects to choose from

- Barracks that spawn centurions
- Horn that when interacted signals all ally units to attack enemy bread
- Interact with horn again to signal retreat
- Horn to interact with to bring enemy wave early
  
- Not sure
    - Put held exp into towers by standing next to them and holding E
    - Take exp out of towers by hitting them with your scepter
    - No tower friendly fire? (On second thought, maybe we keep it, it's kind of funny)

- Book that shows discovered tower recipes and hints at non-secret recipes

- Difficulty

## TODO NO MORE
### 10/11/24
+ Towers now have range indicators when they are highlighted
+ Towers now get a range bonus the higher up they are placed

---

+ Hitting building sound
+ Death sfx

### 10/10/24
+ Added footstep sfx for the player character
+ Made the shop a placeable entity
+ Changed the shop to fit the data/base/database format
+ Waves can now be composed of multiple units that spawn at the same time
+ Interactables now each have unique interact, lift, place, hit, and break sounds
+ You can throw most things you are carrying!!!!
+ Wood tower base large, wood tower yaw pivot, arbalest, and arbalest bolt modelled
+ Towers now display their loaded projectile when they are ready to fire

### 10/09/24
+ Towers are now entirely data based and can be made from generic parts, which will be great since I need to add a lot of towers
+ You can now place entities on top of terrain with non-zero height
+ Fixed a bug with block piles creating super blocks that survive reloads
+ Fixed an issue with GUI button visuals not lining up with their hitbox due to shaders
+ GUI buttons now have sounds
+ Created animation framework for characters so that it is easy to add new characters and animations
+ Added player character with unique animations

### 10/08/24
+ Added ability to have hidden levels that don't show up in level select
+ There is now a defeat level which will act as a hub and level select (though you can use the menu based level select too)

---

+ The game now tracks and saves/loads the levels you have beaten
+ Levels can now be locked until a specific level has been beaten

---

+ HUD
    + Coin count
    + Wave indicator
    + Bread count
+ UI frames
+ UI buttons

---

+ Grass tiles
+ Grass gets squished when things are put down on top of it

---

+ Orcus now rises from the ground in a central location once you have beaten a level, speaks his dialogue, and once the dialogue is exhausted, he will move you to the next level if interacted with
+ NPCs in general are now capable of all the things Orcus is capable of, though I don't know if I will have time to do anything with that. We will see! Maybe a secret wizard that teleports you to a bonus level.

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
