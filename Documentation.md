ElTorqiro_AegisHUD - User Documentation
=======================================
User Documentation for the AegisHUD UI mod
   
   
Manipulating the HUD
--------------------
Instructions for manipulating the HUD are found in the configuration icon tooltip.  Hover the mouse over the icon to bring up the tooltip.

   
   
Configuration Window
====================
Apart from the general movement and scaling of the HUD, every configuration setting is available in the Configuration Window.  This can be opened by left-clicking on the configuration icon.
   
   
Options
-------
* **Hide default AEGIS swap buttons** When on, will remove the default AEGIS swap buttons from the UI.
* **Enable HUD visibility memory in each playfield** When on, will remember whether you have the HUD visible or hidden on a per playfield basis.  For example, if you hide the HUD in Agartha, when you return there it will be automatically hidden.
* **Enable in-combat indicator** When on, an in-combat indicator (similar to the default) will be displayed above the HUD bars when you are in combat.  If your HUD is hidden at the time, the indicator will appear just above the passive ability bar.
   
   
Dual-Select
-----------
* **...with Right-Click** Enables dual-selecting AEGIS controllers when right-clicking one of the selector buttons.
* **...with Shift-Click** Enables dual-selecting AEGIS controllers when shift-left-clicking one of the selector buttons.
* **Dual-by-Default** Enables dual-select as the default behaviour when left-clicking one of the selector buttons.  This inverts the above settings such that a right-click or shift-left-click will do a _single_ select instead.
 * **also when using default hotkeys** If Dual-by-Default is enabled, enabling this setting will perform a dual-select when you use the default in-game hotkeys to rotate AEGIS controllers.
   
   
Position
--------
* **[Reset to default position]** Clicking this button will position the HUD in its default position just above the passive ability bar.
* **Lock bar position and scale** Prevents the HUD from being moved or scaled.  Recommended to enable once you have positioned the HUD where you want it, so there are no accidental moves during combat etc.
* **Attach and lock HUD to PassiveBar** Attaches the HUD directly to the passive ability bar, in precisely the same position as the default swap buttons.  HUD will not be moveable, but will follow the slide in/out of the passive ability bar.
 * **Animate HUD during PassiveBar open/close** If the HUD is attached to the passive ability bar, this will animate the HUD movement when the passive bar is opened or closed.
   
   
Bar Layout
----------
* **Bar Layout** Selects Horizontal (default) or Vertical layout for the bars.
   
   
Bar Backgrounds
---------------
* **Show** Enables the semi-transparent background behind each of the AegisHUD bars.
* **Tint per active AEGIS type** Tints each bar background with its corresponding selected AEGIS controller type.  For example, if the Primary bar has a Demonic AEGIS controller selected, the bar background will be tinted red (by default).
   
   
Weapon Slots
------------
* **Show** Shows the slotted weapon in each AegisHUD bar.
* **On Primary bar, weapon placed first** On the Primary bar, the weapon will be placed first in the list.  If the Bar Layout is Horizontal, it will be to the left, and if Vertical, it will be at the top.
* **On Secondary bar, weapon placed first** On the Secondary bar, the weapon will be placed first in the list.  If the Bar Layout is Horizontal, it will be to the left, and if Vertical, it will be at the top.
* **Show Background** Setting for the weapon slot background visibility behaviour.  _Never_: the weapon slot background will never be shown.  _Always_: the weapon slot background will always be shown.  _Only when slotted_: the weapon slot background will be hidden except when a weapon is slotted.
* **Tint background per active AEGIS type** Tints weapon slot backgrounds according to their corresponding active AEGIS type.
* **Tint icon per active AEGIS type** Directly tints the weapon icons according to their corresponding active AEGIS type.
   
   
AEGIS Slots
-----------
* **Show Background** Setting for the AEGIS controller slot background visibility behaviour.  This applies to inactive controllers only, there is a separate section for active AEGIS controller behaviour.  _Never_: slot backgrounds will never be shown.  _Always_: slot backgrounds will always be shown.  _Only when slotted_: slot backgrounds will be hidden except when an AEGIS controller is slotted.
* **Tint background per AEGIS type** Tints AEGIS controller slot backgrounds according to their corresponding AEGIS type.
* **Tint icon per AEGIS type** Directly tints the controller icons according to their corresponding AEGIS type.
* **Show XP indicator** Enables an AEGIS XP (i.e. "Analysis %") meter on each of the AEGIS controller selector buttons.
 * **Style** The style of XP meter to use.  _Progress Bar_: A simple progress bar.  _Numbers_: A numeric readout in percent.
 * **Show background in Progress Bar** If the Progress Bar style is selected, this option toggles the progress bar background visibility.
 * **Hide when Full** By default, the XP meter will change colours when it reaches 100%.  This option will hide the meter instead, on a per button basis.
* **Show Tooltips** Enables bringing up the AEGIS controller tooltip when hovering the mouse over its button in the HUD.
 * **Suppress in combat** Suppress the tooltips when in combat, which is handy if you typically use the mouse to select AEGIS controllers.
   
   
Active AEGIS Slot
-----------------
* **Show background** Displays the background on the currently active AEGIS controller buttons.
* **Tint background** Setting for the active AEGIS slot tint behaviour.  _Never_: will never tint the active AEGIS controller background.  _Standard_: tints the active AEGIS controller background with a standard default colour (the _Default Active Highlight_ colour in the _Tints_ section).  _Per Active AEGIS_: tints the active AEGIS controller background according to the AEGIS type.
   
   
NeonFX
------
The NeonFX section controls the coloured glow effects that can be applied to the HUD.  This is always based off the currently active AEGIS type, per bar.

* **Enable NeonFX per active AEGIS type** A global toggle for enabling NeonFX features.
 * **Overall HUD** Enables a glow which wraps around all HUD elements.
 * **Bar background** Emits a glow from each bar background.  This will override the _Bar Backgrounds->Tint per active AEGIS type_ setting.
 * **Weapon slot** Emits a glow from the weapon slot background, or icon, whichever is visible.
 * **Active AEGIS** Emits a glow from the currently active AEGIS controller.
   
   
Tints
-----
This section allows each colour used in the HUD to be customised.

* **[Reset to default tints]** If you made some colour changes and don't like them, click this button to reset the values to their defaults.
