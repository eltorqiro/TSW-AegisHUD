TSW-AegisHUD
============
AegisHUD UI mod for the MMORPG The Secret World
  
  
User Configuration
------------------
The mod is integrated with Viper's Topbar Information Overload (VTIO), so if you have that installed you can click on the little "shield" icon to open the configuration window.
Otherwise, there will be an icon placed on your screen, which you can move (CTRL + LeftButton) or scale (CTRL + MouseWheel) to put in an unobtrusive place on your screen.
You can also toggle the configuration window with the option ElTorqiro_AegisHUD_ShowConfig, which can be set via a chat command as follows:
/setoption ElTorqiro_AegisHUD_ShowConfig 1
(1 = open, 2 = closed)

   
   
Dragging / Scaling Bars
-----------------------
Drag both bars with CTRL + LeftButton.  Drag an individual bar with CTRL + RightButton.  A glowing outline will indicate which bar(s) you are dragging.  To reset the bar positions to their defaults, use the button inside the configuration window.
Scale the HUD with CTRL + MouseWheel roll.

   
   
Order of AEGIS controllers on the bars
--------------------------------------
On the server side, each AEGIS slot for your character is numbered 1-3 for each side (left/right). It's not obvious in the character panel because of the way the default UI is built, but when you rotate an active AEGIS it doesn't actually move items around in slots. The whole "rotating" concept is quite misleading. All the rotation actually does is update an internal "active AEGIS" pointer which points to one of the AEGIS slots, no equipment is moved. In another misleading , the foreground slot in the character panel is not "SLOT #1" -- it is just showing you the slot that the active pointer currently points to. This is a brand new thing for TSW, as none of your other equipment works this way.

For example, if you have AEGIS 2 selected and you rotate to AEGIS 1, in the character panel it will look like the AEGISs have shifted around. But all that has really happened is the internal "active" pointer has shifted to AEGIS 1 and the UI has been redrawn.

In the AegisHUD bars, the slots are laid out in order, 1-3, for each side. This gives you the ultimate freedom to slot your AEGIS in whatever order best makes sense to you. To get the order you want, open up your character panel and remove all your AEGIS controllers. Now drag a controller into one of the character panel slots and you can see in realtime where it appears in the AegisHUD. If it's not in the right position, remove it and try a different character panel slot. Did you know you can drag controllers into the "rear" slots in the character panel? Now you do! Repeat the process until your controllers are all in your preferred order in the AegisHUD. Because the layout in AegisHUD is always 1-2-3, next time you login the order will still be the same.
   
   
Installation
------------
Extract the contents of the zip file into: YOUR_TSW_DIRECTORY\Data\Gui\Customized\Flash
This will add the appropriate directory and put the files in the right place.

Uninstallation
--------------
Delete the directory: YOUR_TSW_DIRECTORY\Data\Gui\Customized\Flash\ElTorqiro_AegisHUD
   
   
Source Code
-----------
You can get the source from GitHub at https://github.com/eltorqiro/TSW-AegisHUD
To compile, you will also need my TSW addon utils package, which is also on GitHub at https://github.com/eltorqiro/TSW-Utils