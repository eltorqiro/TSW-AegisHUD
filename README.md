ElTorqiro_AegisHUD
==================
AegisHUD UI mod for the MMORPG "The Secret World"
   
   
What is this?
-------------
ElTorqiro_AegisHUD is an Aegis system management module. It includes a customisable HUD for visualising and interacting with your Aegis layout, an advanced multi-swap hotkey override feature, and an AutoSwap option that can be tailored to your preferences.

Feedback, updates and community forum can be found at http://forums.thesecretworld.com/showthread.php?t=80429
   
   
User Configuration
------------------
The mod provides an interactive on-screen icon which can be used to bring up a comprehensive configuration panel.  Hover the mouse over the icon for instructions.  If you have Viper's Topbar Information Overload (VTIO) installed, or an equivalent handler, the icon will be available in a VTIO slot.
   
You can also toggle the configuration window with the option ElTorqiro_AegisHUD_ShowConfigWindow, which can be set via a chat command as follows:
/setoption ElTorqiro_AegisHUD_ShowConfigWindow 1
(1 = open, 0 = closed)
   
   
Known Issues and Gotchas
------------------------
* On some rare occasions, the "XP gain" trigger event is not fired by the game API when consuming bulk Aegis XP cannisters.  This leaves the XP display on the AegisHUD on the old value.  Re-equipping the affected controller, doing a /reloadui, or waiting for a regular XP gain event will fetch the new value.

* If you change shields in a PvP zone, the game treats it like all other gear changes and resets your Equal Footing buff.  This will drop your health down to unbuffed levels (e.g. 13k down to 3k).  If you have AutoSwap enabled, by default it will try to swap shields every time you're out of combat, which will reset the buff and you will die very quickly as a result :)  To avoid this, there is an AutoSwap option to prevent PvP opponents from being treated as "enemies" for the purposes of AutoSwap behaviour.  However, since there is no need for Aegis mechanics in PvP zones, the simplest thing to do is to toggle the AegisHUD off when you are in a PvP zone, as the fewer things you have running in PvP the better.

* The AutoSwap feature in AegisHUD is not compatible with any other mod that also performs AutoSwap. Due to the way swapping of Aegis is done through the game API, no two or more mods that do AutoSwap can ever work together. You can disable AegisHUD's AutoSwap feature if you prefer a different AutoSwap mod for some reason. Note: As far as I know, the autoswapping mod "Auto_Aegis" needs to be completely deleted to stop it trying to swap Aegis.
  
   
Installation
------------
Extract the contents of the zip file into: YOUR_TSW_DIRECTORY\Data\Gui\Customized\Flash
This will add the appropriate directory and put the files in the right place.

Uninstallation
--------------
Delete the directory: YOUR_TSW_DIRECTORY\Data\Gui\Customized\Flash\ElTorqiro_AegisHUD
   
   
Order of Aegis controllers on the bars
--------------------------------------
On the server side, each Aegis slot for your character is numbered 1-3 for each side (left/right). It's not obvious in the character panel because of the way the default UI is built, but when you rotate an active Aegis it doesn't actually move items around in slots. The whole "rotating" concept is quite misleading. All the rotation actually does is update an internal "active Aegis" pointer which points to one of the Aegis slots, no equipment is moved. Additionally, the foreground slot in the character panel is not "SLOT #1" -- it shows the current "active" slot.  This is a new way of representing gear, as no other equipment in TSW works this way.
   
In the AegisHUD bars, the slots are laid out in order, 1-3, for each side. This gives you the ultimate freedom to slot your Aegis in whatever order best makes sense to you. To get the order you want, open up your character panel and remove all your Aegis controllers.  Now drag a controller into one of the character panel slots and you can see in realtime where it appears in the AegisHUD.  If it's not in the right position, remove it and try a different character panel slot.  Did you know you can drag controllers onto the "rear" slots in the character panel? Now you do! Repeat the process until your controllers are all in your preferred order in the AegisHUD. Because the layout in AegisHUD is always 1-2-3, next time you login the order will still be the same.
  
An exception to this is the Shield bar. Because Aegis shields could be anywhere in your backpack, or equipped as the active shield, there is no UI-supported ordering that would make any sense. Thus, the order of shields is set to the shield priority ordering, i.e. Psychic => Cybernetic => Demonic.
   
   
Source Code
-----------
You can get the source from GitHub at https://github.com/eltorqiro/TSW-AegisHUD