ElTorqiro_AegisHUD
==================
Aegis system management and HUD for the MMORPG "The Secret World"
   
   
What is this?
-------------
ElTorqiro_AegisHUD is an Aegis system management module.  Feature highlights:

* customisable visual HUD for tracking and interacting with your Aegis controllers
* advanced AutoSwap module that can be configured with a range of different rulesets for various roles
* show Aegis xp percentage directly on each controller's icon, no need to tooltip anymore
* hotkey override feature, with multi-select support
* can hide+disable on a per-zone basis, or according to rules such as when out of combat or when AutoSwap is on
* replaces the default Aegis swap UI, without modifying or overriding any game files

Join the conversation with feedback, bug reports, and update information on the official TSW forums at http://forums.thesecretworld.com/showthread.php?t=80429
  
  
Important Notes
---------------
* It is recommended to disable AutoSwap in PvP zones, or the entire HUD since Aegis doesn't apply in PvP.  This will avoid the "Equal Footing" buff from being toggled off/on, which happens whenever you change gear in a PvP zone, and will be triggered by the AutoSwap module trying to change your shield.

* It is not possible to use two mods that perform Aegis AutoSwap at the same time, due to the way the game handles controller selection.  You can disable AegisHUD's AutoSwap if you prefer to use a different AutoSwap mod, while still being able to use the rest of AegisHUD's features.  Note: some other AutoSwap mods need to be deleted completely to stop them from swapping, rather than just "disabling" them.

* On some _extremely rare_ occasions, the "Aegis XP changed" trigger event is not fired by the game, which leaves the XP display in AegisHUD on out of date values.  Re-equipping the affected controllers, doing a /reloadui, or waiting for another Aegis XP gain event will fetch the new value (e.g. killing a mob or opening another cannister).
  
  
Donations
---------
I don't accept real-money donations for my mods.  If you would like to show your support, you can do so by sending in-game pax to my character Tufenuf.  I will use it to buy the in-game items I would otherwise have been able to grind out myself, if I weren't spending time writing mods.
  
  
Configuration
-------------
The mod includes an on-screen icon which can be clicked to bring up a comprehensive configuration panel, and to quickly toggle the HUD and AutoSwap features.  If you have Viper's Topbar Information Overload (VTIO) installed, or an equivalent handler, the icon will be available in a VTIO slot.
   
Manipulating the HUD bars and the icon is done via TSW's Gui Edit Mode, which is toggled in the game by clicking the padlock symbol in the top right corner of the screen.  Left-button drags a single bar, right-button drags all bars together, and mouse wheel adjusts scale.  These instructions are repeated in the config window.
  
  
Installation
------------
The mod is released with CurseMod support, so you can use the Curse client to handle adding and removing it from the game.  Manual installation can also be done, as follows:
  
Manual Installation
Ensure the game is closed, then extract only the Flash folder from the zip file into TSW_GAME_FOLDER\Data\Gui\Customized
  
Manual Uninstallation
Ensure the game is closed, then delete the folder TSW_GAME_FOLDER\Data\Gui\Customized\Flash\ElTorqiro_AegisHUD
   
   
Order of Aegis controllers
--------------------------
TSW stores equipped Aegis disruptors on the server in regular equipment inventory slots, just like your talismans and weapons, which are numbered 1-3 for both primary and secondary groups (i.e. "left" and "right" side).  The game keeps a track of which disruptor is "active" in each group by creating a separate pointer to the active slot number.  This isn't obvious in the default character sheet, as the slots are laid out in a triangular pattern, and when you rotate them they all move around on the screen as if they were moving around in the equipment inventory as well.  However, all that is happening is that the active pointer is being updated, with the foreground slot showing the disruptor that is active, *not* slot #1.  There is no way to tell just by looking at the character sheet which slot matches which number, although under the hood there is some logic to it.

AegisHUD lays out the disruptors in their numbered order on the bars, from 1-3.  Rather than moving the disruptors around on the bars when a new one is selected, it shows the active slot by adding some highlight effects to it (e.g. a background box, or a glow etc, it's customisable).  So, to get the disruptors to show up in a specific order in AegisHUD, just re-equip them in the character sheet until they show up in the order you want.

Shields work differently to disruptors.  There is only one server-side slot for shields, and selecting a new shield means equipping a new item, just like equipping a new talisman.  The "inactive" (i.e. not equipped) shields just float around in your backpack like regular items.  Therefore, the shields are shown in AegisHUD in their priority order, Psychic => Cybernetic => Demonic, and the ordering cannot be changed.
   
   
Source Code
-----------
You can get the source from GitHub at https://github.com/eltorqiro/TSW-AegisHUD