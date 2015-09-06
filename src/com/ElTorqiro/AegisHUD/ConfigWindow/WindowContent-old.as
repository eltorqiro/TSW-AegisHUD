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
import com.ElTorqiro.AegisHUD.Enums;
import com.ElTorqiro.AegisHUD.Preferences;


class com.ElTorqiro.AegisHUD.ConfigWindow.WindowContent extends com.Components.WindowComponentContent
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

		
		// forum page button
		AddControl( {
			id: "visitForumsButton",
			type: "button",
			label: "Visit forum thread",
			tooltip: "Clicking this button will open the in-game browser and visit the AegisHUD forum thread.",
			
			onClick: function() {
				DistributedValue.SetDValue("web_browser", false);
				DistributedValue.SetDValue("WebBrowserStartURL", "https://forums.thesecretworld.com/showthread.php?80429-MOD-ElTorqiro_AegisHUD");
				DistributedValue.SetDValue("web_browser", true);
			}
		});		

		
		// options section
		AddControl( {
			id: "optionsHeading",
			type: "heading",
			label: "General"
		});
		
		AddControl( {
			id: "hudEnabled",
			type: "checkbox",
			label: "HUD enabled (per playfield)",
			tooltip: "Enables the AegisHUD.  It may not be visible on the screen, depending on other settings, but it will still be active.<br><br>This setting is remembered on a per-playfield basis.",
			pref: "app.enabled"
		});

		
		// autoswap section
		AddControl( {
			id: "autoSwapHeading",
			type: "heading",
			label: "AutoSwap"
		});

		AddControl( {
			id: "autoSwapEnabled",
			type: "checkbox",
			label: "AutoSwap system enabled",
			tooltip: "When on, the AutoSwap system will swap AEGIS controllers based on your offensive target.",
			pref: "autoSwap.enabled"
		});

		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "add"
		});
		
		AddControl( {
			id: "autoSwapBehaviour",
			type: "dropdown",
			label: "Behaviour",
			tooltip: "The AutoSwap behaviour to use for managing swap decisions.",
			pref: "autoSwap.behaviour",
			data: [
				{ label: "Offensive Target", value: Enums.e_AutoSwapBehaviourOffensive },
				{ label: "Defensive Target", value: Enums.e_AutoSwapBehaviourDefensive }
			]
		});

		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});
		
		AddControl( {
			id: "autoSwapPrimaryEnabled",
			type: "checkbox",
			label: "Primary Disruptor",
			tooltip: "When on, the AutoSwap system will handle swapping of the Primary AEGIS Disruptor.",
			pref: "autoSwap.primary.enabled"
		});
		
		AddControl( {
			id: "autoSwapSecondaryEnabled",
			type: "checkbox",
			label: "Secondary Disruptor",
			tooltip: "When on, the AutoSwap system will handle swapping of the Secondary AEGIS Disruptor.",
			pref: "autoSwap.secondary.enabled"
		});

		AddControl( {
			id: "autoSwapShieldEnabled",
			type: "checkbox",
			label: "Shield",
			tooltip: "When on, the AutoSwap system will handle swapping of the AEGIS Shield.",
			pref: "autoSwap.shield.enabled"
		});
		
		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "sub"
		});

		
		// element visibility section
		AddControl( {
			id: "visibilityHeading",
			type: "heading",
			label: "Visibility"
		});
		
		AddControl( {
			id: "hideDefaultDisruptorSwapUI",
			type: "checkbox",
			label: "Hide default Disruptor swap UI",
			tooltip: "When on, will remove the default AEGIS Disruptor swap buttons from the UI.",
			pref: "defaultUI.disruptorSelect.hide"
		});
		
		AddControl( {
			id: "hideDefaultShieldSwapUI",
			type: "checkbox",
			label: "Hide default AEGIS Shield swap UI",
			tooltip: "When on, will remove the default AEGIS Shield swap button from the UI (next to the player health bar).",
			pref: "defaultUI.shieldSelect.hide"
		});

		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});
		
		AddControl( {
			id: "hideWhenAutoSwapEnabled",
			type: "checkbox",
			label: "Hide HUD when AutoSwap is enabled",
			tooltip: "When on, will keep the HUD invisible (but still active) when AutoSwap is enabled.",
			pref: "ui.hide.whenAutoswapEnabled"
		});
		
		AddControl( {
			id: "hideWhenNotInCombat",
			type: "checkbox",
			label: "Hide HUD when not in combat",
			tooltip: "When on, will keep the HUD invisible (but still active) when there are no enemies engaging you.",
			pref: "ui.hide.whenNotInCombat"
		});
		
		
		// hotkeys section
		AddControl( {
			id: "hotkeysHeading",
			type: "heading",
			label: "Hotkey Selection"
		});
		
		AddControl( {
			id: "overrideHotkeys",
			type: "checkbox",
			label: "Override hotkeys",
			tooltip: "When on, will override default hotkeys with selected behaviour.",
			pref: "hotkeys.enabled"
		});
		
		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "add"
		});		
		
		AddControl( {
			id: "primaryHotkeyBehaviour",
			type: "dropdown",
			label: "Primary Disruptor [<variable name='hotkey:Combat_NextPrimaryAEGIS'/ >]",
			tooltip: "The hotkey behaviour for the Primary Disruptor swap hotkey.",
			pref: "hotkeys.primary.select",
			data: [
				{ label: "Single Select", value: Enums.e_SelectionSingle },
				{ label: "Dual Select", value: Enums.e_SelectionDual }
			]
		});
		
		AddControl( {
			id: "secondaryHotkeyBehaviour",
			type: "dropdown",
			label: "Secondary Disruptor [<variable name='hotkey:Combat_NextSecondaryAEGIS'/ >]",
			tooltip: "The hotkey behaviour for the Secondary Disruptor swap hotkey.",
			pref: "hotkeys.secondary.select",
			data: [
				{ label: "Single Select", value: Enums.e_SelectionSingle },
				{ label: "Dual Select", value: Enums.e_SelectionDual }
			]
		});
		
		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "sub"
		});		
		
		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});
		
		AddControl( {
			id: "lockoutHotkeysWhenHUDDisabled",
			type: "checkbox",
			label: "Lockout hotkeys when HUD disabled",
			tooltip: "When on, hotkeys will be locked out when the HUD is disabled.  This helps prevent accidental swaps in non-AEGIS playfields, such as early dungeons etc.",
			pref: "hotkeys.lockedOutWhenHudDisabled"
		});
		
		
		// mouse selection section
		AddControl( {
			id: "mouseSelectionHeading",
			type: "heading",
			label: "Mouse Selection"
		});		
		
		AddControl( {
			id: "leftButtonBehaviour",
			type: "dropdown",
			label: "Left Button",
			tooltip: "The selection behaviour to use when clicking an AEGIS controller with the left mouse button.",
			pref: "ui.select.leftButton",
			data: [
				{ label: "Single Select", value: Enums.e_SelectionSingle },
				{ label: "Dual Select", value: Enums.e_SelectionDual }
			]
		});
		
		AddControl( {
			id: "rightButtonBehaviour",
			type: "dropdown",
			label: "Right Button",
			tooltip: "The selection behaviour to use when clicking an AEGIS controller with the right mouse button.",
			pref: "ui.select.rightButton",
			data: [
				{ label: "Single Select", value: Enums.e_SelectionSingle },
				{ label: "Dual Select", value: Enums.e_SelectionDual }
			]
		});
		
		AddControl( {
			id: "shiftLeftButtonBehaviour",
			type: "dropdown",
			label: "Shift+Left Button",
			tooltip: "The selection behaviour to use when clicking an AEGIS controller with SHIFT+left mouse button.",
			pref: "ui.select.shiftLeftButton",
			data: [
				{ label: "Single Select", value: Enums.e_SelectionSingle },
				{ label: "Dual Select", value: Enums.e_SelectionDual }
			]
		});

		
		AddControl( {
			type: "column"
		});		
		
		
		// hud position & scale section
		AddControl( {
			id: "hudPositionHeading",
			type: "heading",
			label: "HUD Position & Scale"
		});		
		
		AddControl( {
			id: "integrateWithAbilityBar",
			type: "checkbox",
			label: "Integrate HUD with Ability Bar",
			tooltip: "Attaches the HUD directly to the Passive Ability bar, in precisely the same position as the default swap buttons.  The HUD will follow the slide in/out of the passive ability bar.",
			pref: "ui.integrateWithAbilityBar"
		});
		
		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "add"
		});

		AddControl( {
			id: "animateWithAbilityBar",
			type: "checkbox",
			label: "Animate with Passive Bar open/close",
			tooltip: "If the HUD is integrated with the Ability Bar, this will animate the HUD movement when the passive bar is opened or closed.",
			pref: "ui.animateWithAbilityBar"
		});
			
		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "sub"
		});	
			
		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});	

		AddControl( {
			id: "hudScale",
			type: "slider",
			label: "HUD Scale",
			tooltip: "Sets the scale of the HUD bars.",
			suffix: "%",
			min: 50,
			max: 150,
			snap: 1,
			pref: "ui.hud.scale"
		});
		
		
		// bar layout section
		AddControl( {
			id: "barLayoutHeading",
			type: "heading",
			label: "Bar Layout"
		});
		
		AddControl( {
			id: "barBackgroundType",
			type: "dropdown",
			label: "Background Type",
			tooltip: "Selects the type of background for the bars.",
			pref: "ui.bar.background.type",
			data: [
				{ label: "None", value: Enums.e_BarTypeNone },
				{ label: "Thin Bar", value: Enums.e_BarTypeThin },
				{ label: "Box", value: Enums.e_BarTypeFull }
			]
		});
		
		
		// item slot section
		AddControl( {
			id: "itemSlotHeading",
			type: "heading",
			label: "Item Slots"
		});		
		
		AddControl( {
			id: "primaryItemSlot",
			type: "dropdown",
			label: "Primary Weapon",
			tooltip: "Selects how to display the weapon slot on the Primary bar.",
			pref: "ui.bars.primary.item.showType",
			data: [
				{ label: "None", value: Enums.e_BarItemShowNone },
				{ label: "Show First", value: Enums.e_BarItemShowFirst },
				{ label: "Show Last", value: Enums.e_BarItemShowLast }
			]
		});
		
		AddControl( {
			id: "secondaryItemSlot",
			type: "dropdown",
			label: "Secondary Weapon",
			tooltip: "Selects how to display the weapon slot on the Secondary bar.",
			pref: "ui.bars.secondary.item.showType",
			data: [
				{ label: "None", value: Enums.e_BarItemShowNone },
				{ label: "Show First", value: Enums.e_BarItemShowFirst },
				{ label: "Show Last", value: Enums.e_BarItemShowLast }
			]
		});

		AddControl( {
			id: "shieldItemSlot",
			type: "dropdown",
			label: "Shield Symbol",
			tooltip: "Selects how to display the shield symbol on the Shield bar.",
			pref: "ui.bars.shield.item.showType",
			data: [
				{ label: "None", value: Enums.e_BarItemShowNone },
				{ label: "Show First", value: Enums.e_BarItemShowFirst },
				{ label: "Show Last", value: Enums.e_BarItemShowLast }
			]
		});

		
		// aegis slot section
		AddControl( {
			id: "aegisSlotHeading",
			type: "heading",
			label: "AEGIS Slots"
		});		
		
		AddControl( {
			id: "iconType",
			type: "dropdown",
			label: "Icon Type",
			tooltip: "Selects which icons to display in AEGIS slots.",
			pref: "ui.icons.type",
			data: [
				{ label: "In-game item icons", value: Enums.e_IconTypeItem },
				{ label: "Fancy type icons", value: Enums.e_IconTypeInbuilt }
			]
		});
		
		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});		

		AddControl( {
			id: "showSelectedSlotBackground",
			type: "checkbox",
			label: "Show selected slot background",
			tooltip: "Show background box highlighting selected AEGIS slots.",
			pref: "ui.aegis.selected.background.enabled"
		});
		
		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});		

		AddControl( {
			id: "showXP",
			type: "checkbox",
			label: "Show XP percentage",
			tooltip: "Enables an AEGIS XP (i.e. 'Analysis %') meter on each of the AEGIS controller selector buttons.",
			pref: "ui.xp.enabled"
		});
		
		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "add"
		});		

		AddControl( {
			id: "hideXPWhenFull",
			type: "checkbox",
			label: "Hide when at 100%",
			tooltip: "By default, the XP meter will change colours when it reaches 100%.  This option will hide the meter instead, on a per button basis.",
			pref: "ui.xp.hideWhenFull"
		});		
		
		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "sub"
		});			


		// tooltips section
		AddControl( {
			id: "tooltipsHeading",
			type: "heading",
			label: "Tooltips"
		});		
		
		AddControl( {
			id: "showTooltips",
			type: "checkbox",
			label: "Show Tooltips",
			tooltip: "Enables item tooltips when hovering the mouse over the HUD.",
			pref: "ui.tooltips.enabled"
		});			

		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "add"
		});	
		
		AddControl( {
			id: "suppressTooltipsInCombat",
			type: "checkbox",
			label: "Suppress in combat",
			tooltip: "Suppress tooltips when in combat, which is handy if you typically use the mouse to select AEGIS controllers.",
			pref: "ui.tooltips.suppressInCombat"
		});

		AddControl( {
			type: "indent",
			direction: "horizontal",
			style: "sub"
		});	
		
		AddControl( {
			type: "column"
		});	
		
		
		AddColumn();
		

		// style section
		AddControl( {
			id: "styleHeading",
			type: "heading",
			label: "Style"
		});

		AddControl( {
			id: "tintBarPerActiveAegis",
			type: "checkbox",
			label: "Tint bar per active AEGIS type",
			tooltip: "Tint bar backgrounds per their active AEGIS type.",
			pref: "ui.bar.tint"
		});
		
		AddControl( {
			id: "neonBarPerActiveAegis",
			type: "checkbox",
			label: "Glow bar per active AEGIS type",
			tooltip: "Glow bar backgrounds per their active AEGIS type.",
			pref: "ui.bar.neon"
		});
		
		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});
		
		AddControl( {
			id: "tintItemPerActiveAegis",
			type: "checkbox",
			label: "Tint item slot per active AEGIS type",
			tooltip: "Tint item slots per their active AEGIS type.",
			pref: "ui.item.tint"
		});
		
		AddControl( {
			id: "neonItemPerActiveAegis",
			type: "checkbox",
			label: "Glow item slot per active AEGIS type",
			tooltip: "Glow item slots per their active AEGIS type.",
			pref: "ui.item.neon"
		});
		
		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});

		AddControl( {
			id: "tintAegisIconsPerType",
			type: "checkbox",
			label: "Tint AEGIS icons per their type",
			tooltip: "Tint AEGIS icons per their type.",
			pref: "ui.aegis.tint"
		});
		
		AddControl( {
			type: "indent",
			direction: "vertical",
			style: "add"
		});

		AddControl( {
			id: "glowActiveAegisIcons",
			type: "checkbox",
			label: "Glow active AEGIS icons",
			tooltip: "Glow active AEGIS icons.",
			pref: "ui.aegis.selected.neon"
		});

		AddControl( {
			id: "tintActiveAegisBackgrounds",
			type: "checkbox",
			label: "Tint active AEGIS backgrounds",
			tooltip: "Tint the background of active AEGIS slots per their AEGIS type.",
			pref: "ui.aegis.selected.background.tint"
		});
		
		AddControl( {
			id: "glowActiveAegisBackgrounds",
			type: "checkbox",
			label: "Glow active AEGIS backgrounds",
			tooltip: "Glow the background of active AEGIS slots per their AEGIS type.",
			pref: "ui.aegis.selected.background.neon"
		});
		

		// style section
		AddControl( {
			id: "tintsHeading",
			type: "heading",
			label: "Tints"
		});

		AddControl( {
			id: "tintPsychic",
			type: "textinput",
			label: "Psychic",
			tooltip: "Psychic tint colour.",
			hexColor: true,
			pref: "tints.aegis.psychic"
		});
		
		AddControl( {
			id: "tintCybernetic",
			type: "textinput",
			label: "Cybernetic",
			tooltip: "Cybernetic tint colour.",
			hexColor: true,
			pref: "tints.aegis.cybernetic"
		});

		AddControl( {
			id: "tintDemonic",
			type: "textinput",
			label: "Demonic",
			tooltip: "Demonic tint colour.",
			hexColor: true,
			pref: "tints.aegis.demonic"
		});

		AddControl( {
			id: "tintEmpty",
			type: "textinput",
			label: "Empty Slot",
			tooltip: "Empty slot colour.",
			hexColor: true,
			pref: "tints.aegis.empty"
		});

		AddControl( {
			id: "tintDefaultHighlight",
			type: "textinput",
			label: "Default Background",
			tooltip: "Default active slot background colour.",
			hexColor: true,
			pref: "tints.aegis.standardBackground"
		});

		AddControl( {
			id: "tintXPProgress",
			type: "textinput",
			label: "XP 0-99%",
			tooltip: "XP text colour between 0% and 99%",
			hexColor: true,
			pref: "tints.xp.progress"
		});

		AddControl( {
			id: "tintXPFull",
			type: "textinput",
			label: "XP 100%",
			tooltip: "XP text colour at 100%",
			hexColor: true,
			pref: "tints.xp.full"
		});


		// style section
		AddControl( {
			id: "globalResetHeading",
			type: "heading",
			label: "Global Reset"
		});
		
		AddControl( {
			id: "globalResetButton",
			type: "button",
			label: "Reset all settings to defaults",
			tooltip: "Clicking this button will reset every setting to defaults.  Only the per-playfield memory for the <i>HUD Enabled</i> setting will be preserved.",
			
			onClick: Delegate.create( this, function() {
				LoadValues();
			})
		});
		
		
		SetSize( Math.round(Math.max(m_Content._width, 200)), Math.round(Math.max(m_Content._height, 200)) );
		
		// listen for other interactive events changing settings
		//Preferences.addEventListener( "app.enabled", _uiControls["hudEnabled"], "prefLoad" );
		//Preferences.addEventListener( "autoSwap.enabled", _uiControls["autoSwapEnabled"], "prefLoad" );
		
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
		
			control.prefLoad();
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
	

	private function AddControl( def:Object ) : Object {

		var control:Object = {};
		
		control.id = def.id;
		control.tooltip = def.tooltip;
		control.pref = def.pref;
		
		switch( def.type ) {
			
			case "heading":
				AddHeading( def.label );
			break;
			
			case "space":
				if ( def.x ) _layoutCursor.x += def.x;
				if ( def.y ) _layoutCursor.y += def.y;
			break;
			
			case "indent":
				if ( def.direction == "horizontal" ) {
					AddControl( { type: "space", x: def.style == "add" ? 10 : -10 } );
				}
				
				else if ( def.direction == "vertical" ) {
					AddControl( { type: "space", y: def.style == "add" ? 10 : -10 } );
				}
			break;
			
			case "column":
				_layoutCursor.x = this._width + 30;
				_layoutCursor.y = 0;			
			break;
			
			case "checkbox":
				var ui:CheckBox = AddCheckbox( def.id, def.label );
				ui["id"] = def.id;
				
				control.ui = ui;
				
				if ( def.pref ) {
					control.prefLoad = Delegate.create( control, function() {
						this.ui.selected = Preferences.getValue( this.pref );
					});
					
					control.prefSet = Delegate.create( control, function(e:Object) {
						Preferences.setValue( this.pref, this.ui.selected );
					});
					
					ui.addEventListener( "click", control, "prefSet" );
				}
				
			break;

			case "dropdown":
				var ui:DropdownMenu = AddDropdown( def.id, def.label, def.data );
				ui["id"] = def.id;
				
				control.ui = ui;
				
				if ( def.pref ) {
					control.prefLoad = Delegate.create( control, function() {
						var value = Preferences.getValue( this.pref );
						for ( var i:String in this.ui.dataProvider ) {
							if ( this.ui.dataProvider[i].value == value ) {
								this.ui.selectedIndex = i;
								break;
							}
						}
					});
					
					control.prefSet = Delegate.create( control, function(e:Object) {
						Preferences.setValue( this.pref, this.ui.dataProvider[this.ui.selectedIndex].value );
					});
					
					ui.addEventListener( "change", control, "prefSet" );
				}
				
			break;
			
			case "slider":
				var ui:Slider = AddSlider( def.id, def.label, def.min, def.max, def.snap, def.suffix );
				ui["id"] = def.id;
				
				control.ui = ui;
				
				if ( def.pref ) {
					control.prefLoad = Delegate.create( control, function() {
						this.ui.setValue( Preferences.getValue( this.pref ) );
					});
					
					control.prefSet = Delegate.create( control, function(e:Object) {
						Preferences.setValue( this.pref, this.ui.value );
					});
					
					ui.addEventListener( "change", control, "prefSet" );
				}
			
			break;
		
			case "textinput":
				var ui:TextInput = AddTextInput( def.id, def.label, "", 6, def.hexColor, 100, true );
				ui["id"] = def.id;
				
				control.hexColor = def.hexColor;
				
				control.ui = ui;
				
				if ( def.pref ) {
					control.prefLoad = Delegate.create( control, function() {
						
						var value = Preferences.getValue( this.pref );
						
						if ( this.hexColor ) {
							var colArr = value.toString(16).toUpperCase().split('');
							var numChars = colArr.length;
							for (var a = 0; a < (6 - numChars); a++) { colArr.unshift("0"); }
							value = '' + colArr.join('');
						}
						
						this.ui.text = value;
					});
					
					control.prefSet = Delegate.create( control, function(e:Object) {
						var value:String = this.hexColor ? parseInt("0x" + this.ui.text) : this.ui.text;
						Preferences.setValue( this.pref, value );
					});
					
					ui.addEventListener( "textChange", control, "prefSet" );
				}
			
			break;
			
			case "button":
				var ui:Button = AddButton( def.id, def.label );
				ui["id"] = def.id;
				
				control.ui = ui;
				
			break;
			
		}

		if ( def.onInit ) {
			control.onInit = Delegate.create( control, def.onInit );
		}
		
		if ( def.load ) {
			control.load = Delegate.create( control, def.load );
		}
		
		if ( def.onClick ) {
			control.onClick = Delegate.create( control, def.onClick );
			ui.addEventListener( "click", control, "onClick" );
		}

		if ( def.onChange ) {
			control.onChange = Delegate.create( control, def.onChange );
			ui.addEventListener( "click", control, "onChange" );
		}
		
		if ( def.tooltip ) {
			ui.addEventListener( "rollOver", this, "OpenTooltip" );
			ui.addEventListener( "rollOut", this, "CloseTooltip" );
		}

		if ( def.id ) _uiControls[ def.id ] = control;
		
		return control;
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
	private function AddDropdown( name:String, label:String, values:Array ) : DropdownMenu {
		var leftOffset:Number = 3;
		
		var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth() );
		l.textField.autoSize = "left";
		l.textField.text = label;
		l._x = _layoutCursor.x + leftOffset;
		l._y = _layoutCursor.y;
		
		var o:DropdownMenu = DropdownMenu(m_Content.attachMovie( "Dropdown", "m_" + name, m_Content.getNextHighestDepth() ));

		o["tooltipTitle"] = label;
		o["controlName"] = name;
		o["eventValue"] = "e.index";
		//o["labelField"].autoSize = "left";
		//o["labelField"].text = label;

		o.disableFocus = true;
		o.dropdown = "ScrollingList";
		o.itemRenderer = "ListItemRenderer";
		o.dataProvider = values;
		o.dropdown.addEventListener("focusIn", this, "RemoveFocus");

		o._y = _layoutCursor.y + 1;
		o._x = l._x + 10 + 3 + l._width;

		_layoutCursor.y += o._height + 2;
		
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

		if ( _layoutCursor.y > 0 )  _layoutCursor.y += 15;

		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x;
		
		_layoutCursor.y += o._height;
	}
	
	private function clearFocus(e:Object) : Void {
		e.target.focused = false;
	}
	
	private function AddSlider(name:String, label:String, minValue:Number, maxValue:Number, snap:Number, suffix:String):Slider {

		var leftOffset:Number = 3;
		
		// add label for the name of the control
		var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth() );
		l.textField.autoSize = "left";
		l.textField.text = label;
		l._y = _layoutCursor.y;
		l._x = _layoutCursor.x + leftOffset;

		_layoutCursor.y += l.textField._height;// textHeight;
		
		var o:Slider = Slider(m_Content.attachMovie( "Slider", "m_" + name, m_Content.getNextHighestDepth() ));
		o["tooltipTitle"] = text;
		o["controlName"] = name;
		o["eventValue"] = "e.value";
		o["valueLabelSuffix"] = suffix;
		o.width = 200;

		o.addEventListener( "focusIn", this, "clearFocus" );
		o.addEventListener( "change", o, "updateValueLabel" );

		// since we're building a composite control, this is essentially a glorified setter
		// to make sure the label text can be updated
		// -- use this instead of "value = x;" in property setting
		o["setValue"] = Delegate.create( o, function(value:Number) {
			this.value = value;
			this.updateValueLabel();
		});
		
		o["updateValueLabel"] = Delegate.create( o, function() {
			this["valueLabel"].textField.text = this.value + (this["valueLabelSuffix"] != undefined ? this["valueLabelSuffix"] : "");
		});
		
		o.minimum = minValue;
		o.maximum = maxValue;
		o.snapInterval = snap == undefined ? 1 : snap;
		o.snapping = true;
		o.liveDragging = true;
		o.value = minValue;

		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x + leftOffset;

		// add label for the value
		var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Value", m_Content.getNextHighestDepth() );
		l.textField.autoSize = "left";
		l.textField.text = o.value;
		l._y = o._y - 5;
		l._x = o._x + o._width + 6;
		
		o["valueLabel"] = l;

		_layoutCursor.y += o._height;
		
		return o;
	}
	
	private function AddTextInput(name:String, label:String, defaultValue:String, maxChars:Number, isHexColor:Boolean, width:Number, alignRight:Boolean):TextInput {
		
			var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth(), { actAsButton: true } );
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