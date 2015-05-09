import com.Components.FCSlider;
import com.Components.WindowComponentContent;
import flash.geom.Point;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Button;
import gfx.controls.Slider;
import gfx.controls.TextInput;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;
import com.GameInterface.DistributedValue;

import com.GameInterface.Tooltip.TooltipManager;
import com.GameInterface.Tooltip.TooltipData;
import com.GameInterface.Tooltip.TooltipInterface;

import com.ElTorqiro.AegisHUD.AddonUtils.AddonUtils;


class com.ElTorqiro.AegisHUD.Config.WindowContent extends com.Components.WindowComponentContent
{
	private var _uiControls:Object = {};
	private var _uiInitialised:Boolean = false;
	
	private var m_ContentSize:MovieClip;
	private var m_Content:MovieClip;
	
	private var _layoutCursor:Point;
	
	private var _hud:MovieClip;
	
	private var _tooltip:TooltipInterface;
	
	public function WindowContent() {
		
		// get a handle on the hud instance
		_hud = _root["eltorqiro_aegishud\\hud"].g_HUD;
	}

	private function configUI() : Void {
		super.configUI();

		_layoutCursor = new Point(0, 0);
		
		m_Content = createEmptyMovieClip("m_Content", getNextHighestDepth() );

		_uiControls.VisitForums = {
			ui:	AddButton("VisitForums", "Visit the AegisHUD forum thread"),
			tooltip: "Clicking this button will open the in-game browser and visit the AegisHUD forum thread.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				DistributedValue.SetDValue("web_browser", false);
				DistributedValue.SetDValue("WebBrowserStartURL", "https://forums.thesecretworld.com/showthread.php?80429-MOD-ElTorqiro_AegisHUD");
				DistributedValue.SetDValue("web_browser", true);
			}
		};
		

		// options section
		AddHeading("Options");
		_uiControls.hudEnabled = {
			ui:	AddCheckbox( "hudEnabled", "HUD enabled (per playfield)" ),
			tooltip: "Enables the AegisHUD.  It may not be visible on the screen, depending on other settings, but it will still be active.<br><br>This setting is remembered on a per-playfield basis.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.hudEnabled = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.hudEnabled;
			}
		};
		_uiControls.enableDefaultHotkeysWhenHUDInactive = {
			ui:	AddCheckbox( "enableDefaultHotkeysWhenHUDInactive", "Enable default hotkey behaviour when HUD inactive" ),
			tooltip: "Enables the default AEGIS Disruptor swap hotkey behaviour when the AegisHUD is not active.<br><br>This setting is best left <i>off</i>, as it helps prevent accidental hotkey-swap events in playfields that do not have AEGIS mobs, thus avoiding the ability lockout period.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.enableDefaultHotkeysWhenHUDInactive = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.enableDefaultHotkeysWhenHUDInactive;
			}
		};
		
		
		AddVerticalSpace(10);
		_uiControls.autoSwapEnabled = {
			ui:	AddCheckbox( "autoSwapEnabled", "AutoSwap system enabled" ),
			tooltip: "When on, the AutoSwap system will swap AEGIS controllers based on your offensive target.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.autoSwapEnabled = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.autoSwapEnabled;
			}
		};
		AddIndent(10);
		_uiControls.autoSwapPrimaryEnabled = {
			ui:	AddCheckbox( "autoSwapPrimaryEnabled", "Primary AEGIS Disruptor" ),
			tooltip: "When on, the AutoSwap system will handle swapping of the Primary AEGIS Disruptor.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.autoSwapPrimaryEnabled = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.autoSwapPrimaryEnabled;
			}
		};
		_uiControls.autoSwapSecondaryEnabled = {
			ui:	AddCheckbox( "autoSwapSecondaryEnabled", "Secondary AEGIS Disruptor" ),
			tooltip: "When on, the AutoSwap system will handle swapping of the Secondary AEGIS Disruptor.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.autoSwapSecondaryEnabled = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.autoSwapSecondaryEnabled;
			}
		};
		_uiControls.autoSwapShieldEnabled = {
			ui:	AddCheckbox( "autoSwapShieldEnabled", "AEGIS Shield" ),
			tooltip: "When on, the AutoSwap system will handle swapping of the AEGIS shield.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.autoSwapShieldEnabled = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.autoSwapShieldEnabled;
			}
		};
		AddIndent( -10);

		
		// dual select section
		AddHeading("Disruptor Dual-Select");
		_uiControls.dualSelectWithButton = {
			ui:	AddCheckbox( "dualSelectWithButton", "...with Right-Click" ),
			tooltip: "Enables dual-selecting AEGIS controllers when right-clicking one of the selector buttons.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.dualSelectWithButton = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.dualSelectWithButton;
			}
		};
		_uiControls.dualSelectWithModifier = {
			ui:	AddCheckbox( "dualSelectWithModifier", "...with Shift-Click" ),
			tooltip: "Enables dual-selecting AEGIS controllers when shift-left-clicking one of the selector buttons.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.dualSelectWithModifier = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.dualSelectWithModifier;
			}
		};
		_uiControls.dualSelectByDefault = {
			ui:	AddCheckbox( "dualSelectByDefault", "Dual-by-Default (inverts single/dual behaviour)" ),
			tooltip: "Enables dual-select as the default behaviour when left-clicking one of the selector buttons.  This inverts the above settings such that a right-click or shift-left-click will do a <i>single</i> select instead.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.dualSelectByDefault = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.dualSelectByDefault;
			}
		};
		AddIndent(10);
		_uiControls.dualSelectFromHotkey = {
			ui:	AddCheckbox( "dualSelectFromHotkey", "also when using default hotkeys [<variable name='hotkey:Combat_NextPrimaryAEGIS'/ > / <variable name='hotkey:Combat_NextSecondaryAEGIS'/ >]" ),
			tooltip: "If Dual-by-Default is enabled, enabling this setting will perform a dual-select when you use the default in-game hotkeys to rotate AEGIS disruptors.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.dualSelectFromHotkey = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.dualSelectFromHotkey;
			}
		};
		AddIndent( -10);

		
		// visibility options
		AddHeading("Visibility");
		_uiControls.hideDefaultDisruptorSwapUI = {
			ui:	AddCheckbox( "hideDefaultDisruptorSwapUI", "Hide default AEGIS Disruptor swap UI" ),
			tooltip: "When on, will remove the default TSW AEGIS Disruptor swap buttons from the UI.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.hideDefaultDisruptorSwapUI = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.hideDefaultDisruptorSwapUI;
			}
		};
		_uiControls.hideDefaultShieldSwapUI = {
			ui:	AddCheckbox( "hideDefaultShieldSwapUI", "Hide default AEGIS Shield swap UI" ),
			tooltip: "When on, will remove the default TSW AEGIS Shield swap button from the UI (next to the player health bar).",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.hideDefaultShieldSwapUI = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.hideDefaultShieldSwapUI;
			}
		};
		AddVerticalSpace(10);
		_uiControls.hideWhenAutoSwapEnabled = {
			ui:	AddCheckbox( "hideWhenAutoSwapEnabled", "Hide HUD when AutoSwap is enabled" ),
			tooltip: "When on, will keep the HUD invisible, but active, when AutoSwap is enabled.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.hideWhenAutoSwapEnabled = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.hideWhenAutoSwapEnabled;
			}
		};
		_uiControls.hideWhenNotInCombat = {
			ui:	AddCheckbox( "hideWhenNotInCombat", "Hide HUD when not in combat" ),
			tooltip: "When on, will keep the HUD invisible when there are no enemies engaging you.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.hideWhenNotInCombat = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.hideWhenNotInCombat;
			}
		};

		
		// position section
		AddHeading("HUD Position");
		_uiControls.MoveToDefaultPosition = {
			ui:	AddButton("MoveToDefaultPosition", "Reset to default position"),
			tooltip: "Clicking this button will position the HUD in its default position just above the passive ability bar.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.MoveToDefaultPosition();
			}
		};
		_uiControls.lockBars = {
			ui:	AddCheckbox( "lockBars", "Lock bar position and scale" ),
			tooltip: "Prevents the HUD from being moved or scaled.  Recommended to enable once you have positioned and scaled the HUD where you want, so there are no accidental moves.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.lockBars = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.lockBars;
			}
		};

		_uiControls.attachToPassiveBar = {
			ui:	AddCheckbox( "attachToPassiveBar", "Attach and lock HUD to PassiveBar" ),
			tooltip: "Attaches the HUD directly to the passive ability bar, in precisely the same position as the default swap buttons.  HUD will not be moveable, but will follow the slide in/out of the passive ability bar.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.attachToPassiveBar = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.attachToPassiveBar;
			}
		};
		AddIndent(10);
		_uiControls.animateMovementsToDefaultPosition = {
			ui:	AddCheckbox( "animateMovementsToDefaultPosition", "Animate HUD during PassiveBar open/close" ),
			tooltip: "If the HUD is attached to the passive ability bar, this will animate the HUD movement when the passive bar is opened or closed.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.animateMovementsToDefaultPosition = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.animateMovementsToDefaultPosition;
			}
		};
		AddIndent( -10);


		AddColumn();
		
		// add weapon slots section
		AddHeading("Item Slots");
		_uiControls.showWeapons = {
			ui:	AddCheckbox( "showWeapons", "Show Weapons" ),
			tooltip: "Shows the slotted weapon in each AegisHUD weapon/disruptor bar.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.showWeapons = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.showWeapons;
			}
		};
		AddIndent(10);
		_uiControls.primaryItemFirst = {
			ui:	AddCheckbox( "primaryItemFirst", "On Primary bar, weapon placed first" ),
			tooltip: "On the Primary bar, the weapon will be positioned first.  Otherwise it will be placed last.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.primaryItemFirst = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.primaryItemFirst;
			}
		};
		_uiControls.secondaryItemFirst = {
			ui:	AddCheckbox( "secondaryItemFirst", "On Secondary bar, weapon placed first" ),
			tooltip: "On the Secondary bar, the weapon will be positioned first.  Otherwise it will be placed last.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.secondaryItemFirst = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.secondaryItemFirst;
			}
		};
		AddIndent(-10);

		AddVerticalSpace(10);		
		
		_uiControls.showShield = {
			ui:	AddCheckbox( "showShield", "Show Shield symbol" ),
			tooltip: "Shows the static shield symbol on the AegisHUD shield bar.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.showShield = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.showShield;
			}
		};
		AddIndent(10);
		_uiControls.shieldItemFirst = {
			ui:	AddCheckbox( "shieldItemFirst", "On Shield bar, symbol placed first" ),
			tooltip: "On the Shield bar, the static shield symbol will be positioned first.  Otherwise it will be placed last.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.shieldItemFirst = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.shieldItemFirst;
			}
		};
		AddIndent(-10);

		AddVerticalSpace(10);		
		
		_uiControls.tintWeaponIconByActiveAegis = {
			ui:	AddCheckbox( "tintWeaponIconByActiveAegis", "Tint icon per active AEGIS type" ),
			tooltip: "Directly tints the item icons according to their corresponding active AEGIS type.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.tintWeaponIconByActiveAegis = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.tintWeaponIconByActiveAegis;
			}
		};
		_uiControls.neonGlowWeapon = {
			ui:	AddCheckbox( "neonGlowWeapon", "[NEON] Glow icon per active AEGIS type" ),
			tooltip: "If [NEON] options are enabled, emits a glow from the item slot on each bar, according to the selected AEGIS type.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.neonGlowWeapon = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.neonGlowWeapon;
			}
		};
		
		
		// add XP section
		AddHeading("AEGIS Slots");

		_uiControls.aegisTypeIcons = {
			ui:	AddCheckbox( "aegisTypeIcons", "Use AEGIS-type icons" ),
			tooltip: "Use colourful embedded AEGIS-type icons for each slotted icon, rather than the in-game item icon.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.aegisTypeIcons = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.aegisTypeIcons;
			}
		};
		_uiControls.tintAegisIconByType = {
			ui:	AddCheckbox( "tintAegisIconByType", "Tint icon per AEGIS type" ),
			tooltip: "Directly tints the controller icons according to their corresponding AEGIS type.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.tintAegisIconByType = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.tintAegisIconByType;
			}
		};

		AddVerticalSpace(10);
		
		_uiControls.showXP = {
			ui:	AddCheckbox( "showXP", "Show XP percentage" ),
			tooltip: "Enables an AEGIS XP (i.e. 'Analysis %') meter on each of the AEGIS controller selector buttons.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.showXP = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.showXP;
			}
		};
		AddIndent(10);		
		_uiControls.hideXPWhenFull = {
			ui:	AddCheckbox( "hideXPWhenFull", "Hide when at 100%" ),
			tooltip: "By default, the XP meter will change colours when it reaches 100%.  This option will hide the meter instead, on a per button basis.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.hideXPWhenFull = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.hideXPWhenFull;
			}
		};
		AddIndent(-10);

		// active aegis section
		AddHeading("Active AEGIS Slot");
		_uiControls.neonGlowAegis = {
			ui:	AddCheckbox( "neonGlowAegis", "[NEON] Glow icon per AEGIS type" ),
			tooltip: "Emits a glow from the currently active AEGIS controller.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.neonGlowAegis = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.neonGlowAegis;
			}
		};
		_uiControls.showActiveAegisBackground = {
			ui:	AddCheckbox( "showActiveAegisBackground", "Show Background" ),
			tooltip: "Displays a lit background on active AEGIS controllers.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.showActiveAegisBackground = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.showActiveAegisBackground;
			}
		};
		AddIndent(10);
		_uiControls.tintActiveAegisBackground = {
			ui:	AddCheckbox( "tintActiveAegisBackground", "Tint per AEGIS type" ),
			tooltip: "Tints the background of active AEGIS controllers their AEGIS type.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.tintActiveAegisBackground = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.tintActiveAegisBackground;
			}
		};
		AddIndent(10);
		_uiControls.neonGlowActiveAegisBackground = {
			ui:	AddCheckbox( "neonGlowActiveAegisBackground", "[NEON] Use NeonFX Glow" ),
			tooltip: "If [NEON] options are enabled, replaces the tint on active AEGIS controller backgrounds with a glow effect",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.neonGlowActiveAegisBackground = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.neonGlowActiveAegisBackground;
			}
		};
		AddIndent(-20);

		// tooltips section
		AddHeading("Tooltips");
		
		_uiControls.showTooltips = {
			ui:	AddCheckbox( "showTooltips", "Show Tooltips" ),
			tooltip: "Enables bringing up the slotted item tooltip when hovering the mouse over a button on the HUD.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.showTooltips = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.showTooltips;
			}
		};
		AddIndent(10);
		_uiControls.suppressTooltipsInCombat = {
			ui:	AddCheckbox( "suppressTooltipsInCombat", "Suppress in combat" ),
			tooltip: "Suppress the tooltips when in combat, which is handy if you typically use the mouse to select AEGIS controllers.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.suppressTooltipsInCombat = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.suppressTooltipsInCombat;
			}
		};	
		AddIndent(-10);

		
		AddColumn();

		// bar background style
		AddHeading("Bar Background");
		_uiControls.showBarBackground = {
			ui:	AddCheckbox( "showBarBackground", "Show Background" ),
			tooltip: "Enables the semi-transparent background behind each of the AegisHUD bars.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.showBarBackground = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.showBarBackground;
			}
		};
		AddIndent(10);
		_uiControls.barBackgroundThin = {
			ui:	AddCheckbox( "barBackgroundThin", "Thin background" ),
			tooltip: "Uses a thin bar for the background, placed vertically in the centre of the bar, rather than a full height box.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.barBackgroundThin = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.barBackgroundThin;
			}
		};
		_uiControls.tintBarBackgroundByActiveAegis = {
			ui:	AddCheckbox( "tintBarBackgroundByActiveAegis", "Tint per active AEGIS type" ),
			tooltip: "Tints each bar background with its corresponding selected AEGIS controller type.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.tintBarBackgroundByActiveAegis = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.tintBarBackgroundByActiveAegis;
			}
		};
		AddIndent(10);
		_uiControls.neonGlowBarBackground = {
			ui:	AddCheckbox( "neonGlowBarBackground", "[NEON] Use NeonFX Glow" ),
			tooltip: "If [NEON] options are enabled, replaces the tint on the bar background with a glow effect",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.neonGlowBarBackground = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.neonGlowBarBackground;
			}
		};
		AddIndent( -20);
		
		AddVerticalSpace(10);
		_uiControls.neonGlowEntireBar = {
			ui:	AddCheckbox( "neonGlowEntireBar", "[NEON] Glow entire bar per active AEGIS type" ),
			tooltip: "Enables a strong glow which wraps around all HUD elements on each bar.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.neonGlowEntireBar = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.neonGlowEntireBar;
			}
		};
		
		// neon highlighting section
		AddHeading("NeonFX");
		_uiControls.neonEnabled = {
			ui:	AddCheckbox( "neonEnabled", "Allow use of [NEON] options" ),
			tooltip: "Global override for all options labelled [NEON].  Does not toggle the individual options, but rather provides an overriding global setting.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.neonEnabled = e.target.selected;
			},
			init:		function(e:Object) {
				e.control.ui.selected = _hud.neonEnabled;
			}
		};

		
		// Tints section
		AddHeading("Tints", false);
		_uiControls.ApplyDefaultTints = {
			ui:	AddButton("ApplyDefaultTints", "Reset to default tints"),
			tooltip: "Clicking this button will reset all tint colours to their default values.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.ApplyDefaultTints();
				LoadValues();
			}
		};

		_uiControls.tintAegisPsychic = {
			ui:	AddTextInput( "tintAegisPsychic", "Psychic", "", 6, true, undefined, true ),
			event:		"textChange",
			context:	this,
			fn: 		function(e:Object) {
				var eventValue:Number = parseInt( '0x' + e.target.text );
				if ( AddonUtils.isRGB(eventValue) ) _hud.tintAegisPsychic = eventValue;
			},
			init:		function(e:Object) {
				var displayString:String = decColor2hex(_hud.tintAegisPsychic);
				if ( e.control.ui.text != displayString ) e.control.ui.text = displayString;
			}
		};
		_uiControls.tintAegisCybernetic = {
			ui:	AddTextInput( "tintAegisCybernetic", "Cybernetic", "", 6, true, undefined, true ),
			event:		"textChange",
			context:	this,
			fn: 		function(e:Object) {
				var eventValue:Number = parseInt( '0x' + e.target.text );
				if ( AddonUtils.isRGB(eventValue) ) _hud.tintAegisCybernetic = eventValue;
			},
			init:		function(e:Object) {
				var displayString:String = decColor2hex(_hud.tintAegisCybernetic);
				if ( e.control.ui.text != displayString ) e.control.ui.text = displayString;
			}
		};
		_uiControls.tintAegisDemonic = {
			ui:	AddTextInput( "tintAegisDemonic", "Demonic", "", 6, true, undefined, true ),
			event:		"textChange",
			context:	this,
			fn: 		function(e:Object) {
				var eventValue:Number = parseInt( '0x' + e.target.text );
				if ( AddonUtils.isRGB(eventValue) ) _hud.tintAegisDemonic = eventValue;
			},
			init:		function(e:Object) {
				var displayString:String = decColor2hex(_hud.tintAegisDemonic);
				if ( e.control.ui.text != displayString ) e.control.ui.text = displayString;
			}
		};
		_uiControls.tintAegisEmpty = {
			ui:	AddTextInput( "tintAegisEmpty", "Empty Slot", "", 6, true, undefined, true ),
			event:		"textChange",
			context:	this,
			fn: 		function(e:Object) {
				var eventValue:Number = parseInt( '0x' + e.target.text );
				if ( AddonUtils.isRGB(eventValue) ) _hud.tintAegisEmpty = eventValue;
			},
			init:		function(e:Object) {
				var displayString:String = decColor2hex(_hud.tintAegisEmpty);
				if ( e.control.ui.text != displayString ) e.control.ui.text = displayString;
			}
		};
		_uiControls.tintAegisStandard = {
			ui:	AddTextInput( "tintAegisStandard", "Default Active Highlight", "", 6, true, undefined, true ),
			event:		"textChange",
			context:	this,
			fn: 		function(e:Object) {
				var eventValue:Number = parseInt( '0x' + e.target.text );
				if ( AddonUtils.isRGB(eventValue) ) _hud.tintAegisStandard = eventValue;
			},
			init:		function(e:Object) {
				var displayString:String = decColor2hex(_hud.tintAegisStandard);
				if ( e.control.ui.text != displayString ) e.control.ui.text = displayString;
			}
		};

		_uiControls.tintXPProgress = {
			ui:	AddTextInput( "tintXPProgress", "XP 0-99%", "", 6, true, undefined, true ),
			event:		"textChange",
			context:	this,
			fn: 		function(e:Object) {
				var eventValue:Number = parseInt( '0x' + e.target.text );
				if ( AddonUtils.isRGB(eventValue) ) _hud.tintXPProgress = eventValue;
			},
			init:		function(e:Object) {
				var displayString:String = decColor2hex(_hud.tintXPProgress);
				if ( e.control.ui.text != displayString ) e.control.ui.text = displayString;
			}
		};
		_uiControls.tintXPFull = {
			ui:	AddTextInput( "tintXPFull", "XP 100%", "", 6, true, undefined, true ),
			event:		"textChange",
			context:	this,
			fn: 		function(e:Object) {
				var eventValue:Number = parseInt( '0x' + e.target.text );
				if ( AddonUtils.isRGB(eventValue) ) _hud.tintXPFull = eventValue;
			},
			init:		function(e:Object) {
				var displayString:String = decColor2hex(_hud.tintXPFull);
				if ( e.control.ui.text != displayString ) e.control.ui.text = displayString;
			}
		};


		// global reset section
		AddHeading("Global Reset");
		_uiControls.ApplyDefaultSettings = {
			ui:	AddButton("ApplyDefaultSettings", "Reset all settings to defaults"),
			tooltip: "Clicking this button will reset every setting to defaults.  The only information that will not be overwritten is the per-playfield memory for the HUD Enabled setting.",
			event:		"click",
			context:	this,
			fn: 		function(e:Object) {
				_hud.ApplyDefaultSettings();
				LoadValues();
			}
		};
		
		
		SetSize( Math.round(Math.max(m_Content._width, 200)), Math.round(Math.max(m_Content._height, 200)) );
		
		// wire up event handlers for ui controls
		for (var s:String in _uiControls) {
			_uiControls[s].ui.addEventListener( _uiControls[s].event, this, "ControlHandler" );
			
			_uiControls[s].ui.addEventListener( "rollOver", this, "OpenTooltip" );
			_uiControls[s].ui.addEventListener( "rollOut", this, "CloseTooltip" );
			
		}

		// load initial values
		LoadValues();
	}

	private function OpenTooltip(e:Object) : Void {
		
		CloseTooltip();

		var control = _uiControls[e.target.controlName];
		
		if ( control.tooltip == undefined ) return;
		
		var tooltipData:TooltipData = new TooltipData();
		tooltipData.AddAttribute("","<font face=\'_StandardFont\' size=\'12\' color=\'#3ad9ff\'>" + e.target.tooltipTitle + "</font>");
		tooltipData.AddAttribute( "", "<font face=\'_StandardFont\' size=\'11\' color=\'#f0f0f0\'>" + control.tooltip + "</font>" );
		tooltipData.m_Padding = 8;
		tooltipData.m_MaxWidth = 350;
		
		_tooltip = TooltipManager.GetInstance().ShowTooltip( undefined /*e.target*/, TooltipInterface.e_OrientationVertical, -1, tooltipData );
	}

	private function CloseTooltip(e:Object) : Void {
		_tooltip.Close();
		_tooltip = undefined;
	}
	
	// universal control interaction handler
	private function ControlHandler( e:Object ) {
		if ( !_uiInitialised ) return;

		// handle textinput hex color fields
		if ( e.target instanceof TextInput && e.target["isHexColor"] ) {
			eventValue = parseInt( '0x' + eventValue );
			if ( !AddonUtils.isRGB(eventValue) ) return;
		}
		
		var control:Object = _uiControls[e.target.controlName];
		
		// execute the control event handler
		Delegate.create(control.context, control.fn)(e);
	}
	

	// populate the states of the config ui controls based on the hud module's published data
	private function LoadValues() : Void {
		_uiInitialised = false;
		
		var data:Object = _hud.g_data;
		
		for ( var s:String in _uiControls ) {
			var control = _uiControls[s];
			Delegate.create(control.context, control.init)( { control: control } );
		}
		
		_uiInitialised = true;
	}

	private function decColor2hex(color:Number) {
		// input:   (Number) decimal color (i.e. 16711680)
		// returns: (String) hex color (i.e. 0xFF0000)
		colArr = color.toString(16).toUpperCase().split('');
		numChars = colArr.length;
		for(a=0;a<(6-numChars);a++){colArr.unshift("0");}
		return('' + colArr.join(''));
	}
	

	// add and return a new checkbox, layed out vertically
	private function AddCheckbox(name:String, text:String):CheckBox
	{	
		var y:Number = m_Content._height;
		
		var o:CheckBox = CheckBox(m_Content.attachMovie( "Checkbox", "m_" + name, m_Content.getNextHighestDepth() ));
		o["tooltipTitle"] = text;
		o["controlName"] = name;
		o["eventValue"] = "e.target.selected";
		with ( o )
		{
			disableFocus = true;
			textField.autoSize = true;
			textField.text = text;
			//_y = y;
		}

		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x;
		
		_layoutCursor.y += o._height;
		
		return o;
	}

	// add and return a new button, layed out vertically
	private function AddButton(name:String, text:String):Button
	{
		var y:Number = m_Content._height;
		
		var o:Button = Button(m_Content.attachMovie( "Button", "m_" + name, m_Content.getNextHighestDepth() ));
		o["tooltipTitle"] = text;
		o["controlName"] = name;
		o["eventValue"] = "e.target.selected";
		o.label = text;
		o.autoSize = "left";
		o.disableFocus = true;

		var marginTop:Number = ( _layoutCursor.y > 0 ? 3 : 0 );

		o._y = _layoutCursor.y + marginTop;
		o._x = _layoutCursor.x; // + 6;

		_layoutCursor.y += marginTop + o._height + 3;
		
		return o;
	}
	
	
	// add and return a dropdown
	private function AddDropdown(name:String, label:String, values:Array):DropdownMenu
	{
		var y:Number = m_Content._height;

		var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth() );
		l.textField.autoSize = "left";
		l.textField.text = label;
		l._y = _layoutCursor.y;
		l._x = _layoutCursor.x;
		
		var o:DropdownMenu = DropdownMenu(m_Content.attachMovie( "Dropdown", "m_" + name, m_Content.getNextHighestDepth() ));

		o["tooltipTitle"] = text;
		o["controlName"] = name;
		o["eventValue"] = "e.index";
		//o["labelField"].autoSize = "left";
		//o["labelField"].text = label;
		o.disableFocus = true;
		o.dropdown = "ScrollingList";
		o.itemRenderer = "ListItemRenderer";
		o.dataProvider = values;
		o.dropdown.addEventListener("focusIn", this, "RemoveFocus");
//		o._y = y;
		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x + 3 + l._width;

		_layoutCursor.y += o._height;
		
		return o;
	}
	
	// add a group heading, layed out vertically
	private function AddHeading(text:String):Void
	{
		var y:Number = m_Content._height;
		if ( y != 0) y += 10;
		
		var o:MovieClip = m_Content.attachMovie( "ConfigGroupHeading", "m_Heading", m_Content.getNextHighestDepth() );

		o["tooltipTitle"] = text;
		o.textField.autoSize = "left";
		o.textField.text = text;
//		o._y = y;

		if ( _layoutCursor.y > 0 )  _layoutCursor.y += 15;

		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x;
		
		_layoutCursor.y += o._height;
	}
	
	private function AddSlider(name:String, label:String, minValue:Number, maxValue:Number):FCSlider
	{
		var y:Number = m_Content._height;

		var o:FCSlider = FCSlider(m_Content.attachMovie( "Slider", "m_" + name, m_Content.getNextHighestDepth() ));
		o["tooltipTitle"] = text;
		o["controlName"] = name;
		o["eventValue"] = "e.value";
		o.width = 200;
		o._x = 100;
		
		o.minimum = minValue;
		o.maximum = maxValue;
		o.snapInterval = 1;
		o.snapping = true;
		o.liveDragging = true;
//		o._y = y;

		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x;

		_layoutCursor.y += o._height;
		
		return o;
	}
	
	private function AddTextInput(name:String, label:String, defaultValue:String, maxChars:Number, isHexColor:Boolean, width:Number, alignRight:Boolean):TextInput {
		
			var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth() );
			o["tooltipTitle"] = text;
			l.textField.autoSize = "left";
			l.textField.text = label;
			l._y = _layoutCursor.y;
			l._x = _layoutCursor.x;
			
			var o:TextInput = TextInput(m_Content.attachMovie( "TextInput", "m_" + name, m_Content.getNextHighestDepth() ));

			o.maxChars = maxChars == undefined ? 0 : maxChars;
			
			o["controlName"] = name;
			o["eventValue"] = "e.target.text";
			if( isHexColor ) {
				o["isHexColor"] = isHexColor;
				o.maxChars = 6;
			}
			
			if ( width != undefined ) o._width = width;
			
//			o.disableFocus = true;
			
			o._y = _layoutCursor.y;
			o._x = _layoutCursor.x + 3;	// hardcoded because textinput is currently only used for one thing -- clean up in future

			if ( alignRight ) o._x += 130;
			else o._x += l._width;
			
			_layoutCursor.y += o._height + 3;
			
			return o;
	}
	
	private function AddLabel(name:String, text:String):MovieClip {

		var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth() );
		o["tooltipTitle"] = text;
		l.textField.autoSize = "left";
		l.textField.text = text;
		l._y = _layoutCursor.y;
		l._x = _layoutCursor.x;
		
		_layoutCursor.y += l._height;
		
		return l;
	}
	
	private function AddColumn():Void
	{
		_layoutCursor.x = this._width + 30;
		_layoutCursor.y = 0;
	}
	
	private function AddIndent(indentX:Number):Void
	{
		if ( indentX != undefined ) _layoutCursor.x += indentX;
	}
	
	private function AddVerticalSpace(size:Number):Void {
		if ( size != undefined ) _layoutCursor.y += size;
	}
	
    //Remove Focus
    private function RemoveFocus():Void
    {
        Selection.setFocus(null);
    }
	
	public function Close():Void
	{
		super.Close();
	}

	
	/**
	 * this is the all-important override that makes window resizing work properly
	 * the SignalSizeChanged signal is monitored by the host window, which resizes accordingly
	 */
    public function SetSize(width:Number, height:Number)
    {	
        m_ContentSize._width = width;
        m_ContentSize._height = height;
        
		SignalSizeChanged.Emit();	// must fire this signal, else the parent WinComp container never gets resized
    }	

    public function GetSize():Point {
        return new Point( m_ContentSize._width, m_ContentSize._height );
    }	
}