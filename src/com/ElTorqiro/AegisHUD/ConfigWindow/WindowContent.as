import flash.geom.Point;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;
import com.GameInterface.DistributedValue;

import com.ElTorqiro.AegisHUD.AddonUtils.UI.PanelBuilder;
import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.App;

import com.ElTorqiro.AegisHUD.AddonUtils.MovieClipHelper;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.ConfigWindow.WindowContent extends com.Components.WindowComponentContent {

	public function WindowContent() {
		
	}

	private function configUI() : Void {
		
		super.configUI();

		// define the config panel to be built
		var def:Object = {
			
			// panel default load/save handlers
			load: componentLoadHandler,
			save: componentSaveHandler,
			
			layout: [
			
				{	id: "hud.enabled",
					type: "checkbox",
					label: "HUD enabled (per playfield)",
					tooltip: "Enables the AegisHUD.  It may not be visible on the screen, depending on other settings, but it will still be active.<br><br>This setting is remembered on a per-playfield basis.",
					data: { pref: "hud.enabled" }
				},
				
				{ type: "group"
				},
				
				{	id: "hud.hide.whenNotInCombat",
					type: "checkbox",
					label: "Hide HUD when out of combat",
					tooltip: "Hides the HUD when you are not engaged in combat.  This is not the same as disabling the HUD, it is merely hidden from view.",
					data: { pref: "hud.hide.whenNotInCombat" }
				},
				
				{ type: "group"
				},
				
				{	id: "defaultUI.disruptorSelectors.hide",
					type: "checkbox",
					label: "Hide default UI disruptor buttons",
					tooltip: "Hides the default UI disruptor selection buttons.",
					load: function() {
						this.setValue( !DistributedValue.GetDValue( "ShowAegisSwapUI" ) );
					},
					save: function() {
						DistributedValue.SetDValue( "ShowAegisSwapUI", !this.getValue() );
					}
				},
				
				{	id: "defaultUI.shieldSelector.hide",
					type: "checkbox",
					label: "Hide default UI shield button",
					tooltip: "Hides the default UI shield selection button.",
					data: { pref: "defaultUI.shieldSelector.hide" }
				},

				{	type: "section",
					label: "AutoSwap"
				},

				{	id: "autoSwap.enabled",
					type: "checkbox",
					label: "AutoSwap system enabled",
					tooltip: "Enables the AutoSwap system.  Your Aegis controllers will be swapped to match the target controllers specified below.",
					data: { pref: "autoSwap.enabled" }
				},
				
				{	type: "indent-in"
				},

				{	id: "hud.hide.whenAutoswapEnabled",
					type: "checkbox",
					label: "Hide HUD when AutoSwap enabled",
					tooltip: "Hides the HUD when the AutoSwap system is enabled.  This is not the same as disabling the HUD, it is merely hidden from view.",
					data: { pref: "hud.hide.whenAutoswapEnabled" }
				},
				
				{	type: "indent-reset"
				},
				
				{	type: "group"
				},
				
				{	type: "h2",
					text: "Match ..."
				},
				
				{	id: "autoSwap.type.primary",
					type: "dropdown",
					label: "Primary Disruptor with",
					tooltip: "AutoSwap behaviour for the Primary Disruptor.",
					data: { pref: "autoSwap.type.primary" },
					list: [
						{ label: "nothing (no AutoSwap)", value: Const.e_AutoSwapNone },
						{ label: "Enemy Shield", value: Const.e_AutoSwapOffensiveShield },
						{ label: "Enemy Shield / Disruptor", value: Const.e_AutoSwapOffensiveShieldXorDisruptor },
						{ label: "Friendly Shield", value: Const.e_AutoSwapDefensiveShield }
					]
				},
				
				{	id: "autoSwap.type.secondary",
					type: "dropdown",
					label: "Secondary Disruptor with",
					tooltip: "AutoSwap behaviour for the Secondary Disruptor.",
					data: { pref: "autoSwap.type.secondary" },
					list: [
						{ label: "nothing (no AutoSwap)", value: Const.e_AutoSwapNone },
						{ label: "Enemy Shield", value: Const.e_AutoSwapOffensiveShield },
						{ label: "Enemy Shield / Disruptor", value: Const.e_AutoSwapOffensiveShieldXorDisruptor },
						{ label: "Friendly Shield", value: Const.e_AutoSwapDefensiveShield }
					]
				},
				
				{	id: "autoSwap.type.shield",
					type: "dropdown",
					label: "Shield with",
					tooltip: "AutoSwap behaviour for the Shield.",
					data: { pref: "autoSwap.type.shield" },
					list: [
						{ label: "nothing (no AutoSwap)", value: Const.e_AutoSwapNone },
						{ label: "Enemy Disruptor", value: Const.e_AutoSwapOffensiveDisruptor }
					]
				},
				
				{	type: "group"
				},
				
				{	id: "autoSwap.match.friendly.self",
					type: "checkbox",
					label: "\"Friendly\" targets include self",
					tooltip: "Includes your character in the category of \"Friend\" targets for AutoSwap focusing.",
					data: { pref: "autoSwap.match.friendly.self" }
				},
				
				{	id: "autoSwap.match.enemy.players",
					type: "checkbox",
					label: "\"Enemy\" targets include PvP opponents",
					tooltip: "Includes PvP opponents in the category of \"Enemy\" targets for AutoSwap focusing.",
					data: { pref: "autoSwap.match.enemy.players" }
				},
				
				{	type: "section",
					label: "Selection"
				},
				
				{	type: "h2",
					text: "Mouse Clicks"
				},
				
				{	id: "hud.click.multiSelectType.leftButton",
					type: "dropdown",
					label: "Left Button",
					tooltip: "Selection behaviour when clicking an Aegis slot with the Left mouse button.",
					data: { pref: "hud.click.multiSelectType.leftButton" },
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{	id: "hud.click.multiSelectType.rightButton",
					type: "dropdown",
					label: "Right Button",
					tooltip: "Selection behaviour when clicking an Aegis slot with the Right mouse button.",
					data: { pref: "hud.click.multiSelectType.rightButton" },
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{	id: "hud.click.multiSelectType.shiftLeftButton",
					type: "dropdown",
					label: "Shift+Left Button",
					tooltip: "Selection behaviour when clicking an Aegis slot with Shift+Left Button.",
					data: { pref: "hud.click.multiSelectType.shiftLeftButton" },
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},
				
				{	type: "group"
				},
				
				{	type: "h2",
					text: "Hotkeys"
				},
				
				{	id: "hotkeys.multiSelectType.primary",
					type: "dropdown",
					label: "Primary Disruptor",
					tooltip: "Selection behaviour when using the Primary Disruptor hotkeys [<variable name='hotkey:Combat_NextPrimaryAEGIS'/ > / <variable name='hotkey:Combat_PreviousPrimaryAEGIS'/ >].",
					data: { pref: "hotkeys.multiSelectType.primary" },
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{	id: "hotkeys.multiSelectType.secondary",
					type: "dropdown",
					label: "Secondary Disruptor",
					tooltip: "Selection behaviour when using the Secondary Disruptor hotkeys [<variable name='hotkey:Combat_NextSecondaryAEGIS'/ > / <variable name='hotkey:Combat_PreviousSecondaryAEGIS'/ >].",
					data: { pref: "hotkeys.multiSelectType.secondary" },
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{ type: "group"
				},
				
				{	id: "hotkeys.lockoutWhenHudDisabled",
					type: "checkbox",
					label: "Prevent hotkey swaps when HUD is disabled",
					tooltip: "Disables the Aegis selection hotkeys when the AegisHUD is disabled.  This helps prevent accidental swaps (and the accompanying ability lockout) in areas without Aegis content.",
					data: { pref: "hotkeys.lockoutWhenHudDisabled" }
				},
				
				{ type: "column"
				},
				
				{	type: "section",
					label: "Background Bars"
				},
				
				{	id: "hud.bar.background.type",
					type: "dropdown",
					label: "Style",
					tooltip: "The style of the bar background bars for each controller group.",
					data: { pref: "hud.bar.background.type" },
					list: [
						{ label: "None", value: Const.e_BarTypeNone },
						{ label: "Thin Strip", value: Const.e_BarTypeThin },
						{ label: "Full Box", value: Const.e_BarTypeFull }
					]
				},
				
				{	id: "hud.bar.background.transparency",
					type: "slider",
					min: 0,
					max: 100,
					valueFormat: "%i%%",
					label: "Transparency",
					tooltip: "The transparency level of the background bars.  A value of zero disables the background.",
					data: { pref: "hud.bar.background.transparency" }
				},
				
				{	id: "hud.bar.background.neon",
					type: "checkbox",
					label: "Glow (selected Aegis type)",
					tooltip: "Adds a glow to the background bars per their group selected Aegis type.",
					data: { pref: "hud.bar.background.neon" }
				},

				{	id: "hud.bar.background.tint",
					type: "checkbox",
					label: "Tint (selected Aegis type)",
					tooltip: "Tint bar backgrounds per their group selected Aegis type.",
					data: { pref: "hud.bar.background.tint" }
				},
				
				{	type: "section",
					label: "Item Slots"
				},

				{	id: "hud.bars.primary.itemSlotPlacement",
					type: "dropdown",
					label: "Primary Weapon",
					tooltip: "Placement of the Primary Weapon item slot on the Primary bar in the HUD.",
					data: { pref: "hud.bars.primary.itemSlotPlacement" },
					list: [
						{ label: "Do not show", value: Const.e_BarItemPlaceNone },
						{ label: "Place first on bar", value: Const.e_BarItemPlaceFirst },
						{ label: "Place last on bar", value: Const.e_BarItemPlaceLast }
					]
				},
				
				{	id: "hud.bars.secondary.itemSlotPlacement",
					type: "dropdown",
					label: "Secondary Weapon",
					tooltip: "Placement of the Secondary Weapon item slot on the Secondary bar in the HUD.",
					data: { pref: "hud.bars.secondary.itemSlotPlacement" },
					list: [
						{ label: "Do not show", value: Const.e_BarItemPlaceNone },
						{ label: "Place first on bar", value: Const.e_BarItemPlaceFirst },
						{ label: "Place last on bar", value: Const.e_BarItemPlaceLast }
					]
				},
				
				{	id: "hud.bars.shield.itemSlotPlacement",
					type: "dropdown",
					label: "Shield symbol",
					tooltip: "Placement of the Shield symbol on the Shield bar in the HUD.",
					data: { pref: "hud.bars.shield.itemSlotPlacement" },
					list: [
						{ label: "Do not show", value: Const.e_BarItemPlaceNone },
						{ label: "Place first on bar", value: Const.e_BarItemPlaceFirst },
						{ label: "Place last on  bar", value: Const.e_BarItemPlaceLast }
					]
				},
				
				{ type: "group"
				},
				
				{	id: "hud.slots.item.neon",
					type: "checkbox",
					label: "Glow (selected Aegis type)",
					tooltip: "Adds a glow to item slot icons per their currently selected Aegis type.",
					data: { pref: "hud.slots.item.neon" }
				},
				
				{	id: "hud.slots.item.tint",
					type: "checkbox",
					label: "Tint (selected Aegis type)",
					tooltip: "Tint item slot icons per their currently selected Aegis type.",
					data: { pref: "hud.slots.item.tint" }
				},
				
				{	type: "section",
					label: "Aegis Slots"
				},


				{	id: "hud.icons.type",
					type: "dropdown",
					label: "Icon Style",
					tooltip: "The style of icons to use for Aegis controllers.",
					data: { pref: "hud.icons.type" },
					list: [
						{ label: "AegisHUD Icons", value: Const.e_IconTypeAegisHUD },
						{ label: "Default Game Icons", value: Const.e_IconTypeRDB }
					]
				},
				
				{	id: "hud.slots.aegis.tint",
					type: "checkbox",
					label: "Tint icon (controller Aegis type)",
					tooltip: "Tint Aegis slot icons per their Aegis type.",
					data: { pref: "hud.slots.aegis.tint" }
				},

				{	type: "group"
				},
				
				{	id: "hud.slots.aegis.xp.enabled",
					type: "checkbox",
					label: "Show Analysis % (Aegis XP)",
					tooltip: "Shows the analysis percentage (i.e. \"Aegis XP\") on Aegis controllers.",
					data: { pref: "hud.slots.aegis.xp.enabled" } 
				},
				
				{	type: "indent-in"
				},
				
				{	id: "hud.slots.aegis.xp.hideWhenFull",
					type: "checkbox",
					label: "Hide at 100%",
					tooltip: "Hides the analysis percentage when a controller reaches 100%.",
					data: { pref: "hud.slots.aegis.xp.hideWhenFull" }
				},
				
				{	type: "indent-reset"
				},
				
				{	type: "group"
				},
				
				{	type: "h2",
					text: "Selection Highlights"
				},
				
				{	id: "hud.slots.selectedAegis.neon",
					type: "checkbox",
					label: "Glow icon (selected Aegis type)",
					tooltip: "Adds a glow to selected Aegis slots per their Aegis type.",
					data: { pref: "hud.slots.selectedAegis.neon" }
				},

				{	type: "group"
				},

				{	id: "hud.slots.selectedAegis.background.transparency",
					type: "slider",
					min: 0,
					max: 100,
					valueFormat: "%i%%",
					label: "Selection Box Transparency",
					tooltip: "The transparency level of the background box that appears behind selected Aegis slots.  A value of zero disables the background box.",
					data: { pref: "hud.slots.selectedAegis.background.transparency" }
				},
				
				{	id: "hud.slots.selectedAegis.background.neon",
					type: "checkbox",
					label: "Glow selection box (selected Aegis type)",
					tooltip: "Adds a glow to the background box of selected Aegis slots per their Aegis type.",
					data: { pref: "hud.slots.selectedAegis.background.neon" }
				},

				{	id: "hud.slots.selectedAegis.background.tint",
					type: "checkbox",
					label: "Tint selection box (selected Aegis type)",
					tooltip: "Tint the background box of selected Aegis slots per their Aegis type.",
					data: { pref: "hud.slots.selectedAegis.background.tint" }
				},

				{	type: "column"
				},
				
				{	type: "section",
					label: "Tooltips"
				},
				
				{	id: "hud.tooltips.enabled",
					type: "checkbox",
					label: "Show tooltips",
					tooltip: "Enables tooltips when hovering the mouse over items in the HUD.",
					data: { pref: "hud.tooltips.enabled" }
				},

				{ type: "indent-in"
				},
				
				{	id: "hud.tooltips.suppressInCombat",
					type: "checkbox",
					label: "Suppress in combat",
					tooltip: "Prevents tooltips from being shown when you are engaged in combat.",
					data: { pref: "hud.tooltips.suppressInCombat" }
				},
				
				{ type: "indent-reset"
				},
				
				{	type: "section",
					label: "Tints"
				},
				
				{	id: "hud.tints.aegis.psychic",
					type: "colorInput",
					label: "Psychic",
					data: { pref: "hud.tints.aegis.psychic" }
				},
				
				{	id: "hud.tints.aegis.cybernetic",
					type: "colorInput",
					label: "Cybernetic",
					data: { pref: "hud.tints.aegis.cybernetic" }
				},

				{	id: "hud.tints.aegis.demonic",
					type: "colorInput",
					label: "Demonic",
					data: { pref: "hud.tints.aegis.demonic" }
				},

				{	type: "group"
				},
				
				{	id: "hud.tints.aegis.empty",
					type: "colorInput",
					label: "Empty Slot",
					data: { pref: "hud.tints.aegis.empty" }
				},
				
				{	type: "group"
				},
				
				{	id: "hud.tints.selectedAegis.background",
					type: "colorInput",
					label: "Selection Box (untinted)",
					data: { pref: "hud.tints.selectedAegis.background" }
				},
				
				{	id: "hud.tints.bar.background",
					type: "colorInput",
					label: "Background Bar (untinted)",
					data: { pref: "hud.tints.bar.background" }
				},
				
				{	type: "group"
				},
				
				{	id: "hud.tints.xp.notFull",
					type: "colorInput",
					label: "Analysis 0-99%",
					data: { pref: "hud.tints.xp.notFull" }
				},
				
				{	id: "hud.tints.xp.full",
					type: "colorInput",
					label: "Analysis 100%",
					data: { pref: "hud.tints.xp.full" }
				},
				
				{	type: "group"
				},
				
				{	type: "button",
					text: "Reset Tints",
					onClick: Delegate.create( this, resetTintDefaults )
				},
				
				{	type: "section",
					label: "Size & Position"
				},
				
				{	type: "text",
					text: "Use GUI edit mode to manipulate the HUD.  Left-button drags a single bar, right-button drags all bars together, and mouse wheel adjusts scale."
				},
				
				{	type: "group"
				},
				
				{	id: "hud.scale",
					type: "slider",
					min: Const.MinBarScale,
					max: Const.MaxBarScale,
					step: 5,
					valueFormat: "%i%%",
					label: "Bar Scale",
					tooltip: "The scale of the HUD bars.  You can also change this in GUI Edit Mode by scrolling the mouse wheel while hovering over any of the bars.",
					data: { pref: "hud.scale" }
				},

				{	type: "button",
					text: "Reset Position",
					tooltip: "Reset bar positions to default, which will also integrate them with the ability bar.",
					onClick: function() {
						App.prefs.setVal( "hud.position.default", true );
					}
				}
				
			]
		};
		
		// only add icon related settings if not using VTIO
		if ( !App.isRegisteredWithVtio ) {
			
			def.layout = def.layout.concat( [
				
				{	type: "group"
				},

				{	id: "icon.scale",
					type: "slider",
					min: Const.MinIconScale,
					max: Const.MaxIconScale,
					step: 5,
					valueFormat: "%i%%",
					label: "Icon Scale",
					tooltip: "The scale of the app icon.  You can also change this in GUI Edit Mode by scrolling the mouse wheel while hovering over the icon.",
					data: { pref: "icon.scale" }
				},

				{	type: "button",
					text: "Reset Position",
					tooltip: "Reset icon to its default position.",
					onClick: function() {
						App.prefs.setVal( "icon.position", undefined );
					}
				}
			] );
			
		}
		
		def.layout = def.layout.concat( [
			{	type: "section",
				label: "Global Reset"
			},

			{	type: "button",
				text: "Reset All",
				onClick: Delegate.create( this, resetAllDefaults )
			}
		] );
		
		// build the panel based on definition
		var panel:PanelBuilder = PanelBuilder( MovieClipHelper.createMovieWithClass( PanelBuilder, "m_Panel", this, this.getNextHighestDepth() ) );
		panel.build( def );
		
		// set up listener for pref changes
		App.prefs.SignalValueChanged.Connect( prefListener, this );
		
		def = {
			layout: [
				{	type: "button",
					text: "Visit forum thread",
					tooltip: "Click to open the in-game browser and visit the forum thread for the addon.",
					onClick: function() {
						DistributedValue.SetDValue("web_browser", false);
						DistributedValue.SetDValue("WebBrowserStartURL", "https://forums.thesecretworld.com/showthread.php?80429-MOD-ElTorqiro_AegisHUD");
						DistributedValue.SetDValue("web_browser", true);
					}
				}
			]
		};
		
		var panel:PanelBuilder = PanelBuilder( MovieClipHelper.createMovieWithClass( PanelBuilder, "m_TitleBarPanel", this, this.getNextHighestDepth() ) );
		panel.build( def );
		
		panel._x = Math.round( _parent.m_Title.textWidth + 10 );
		panel._y -= Math.round( _y - _parent.m_Title._y + 1);
		
		// listen for default ui swap changes
		defaultDisruptorSwapUiMonitor = DistributedValue.Create("ShowAegisSwapUI");
		defaultDisruptorSwapUiMonitor.SignalChanged.Connect( defaultDisruptorSwapUiPrefHandler, this );
		
		SignalSizeChanged.Emit();
	}

	private function componentLoadHandler() : Void {
		this.setValue( App.prefs.getVal( this.data.pref ) );
	}

	private function componentSaveHandler() : Void {
		App.prefs.setVal( this.data.pref, this.getValue() );
	}

	/**
	 * listener for pref value changes, to update the config ui
	 * 
	 * @param	name
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefListener( name:String, newValue, oldValue ) : Void {
		
		// only update controls that are using the pref shortcuts
		if ( m_Panel.components[ name ].api.data.pref ) {
			m_Panel.components[ name ].api.load();
		}
		
	}

	/**
	 * resets most settings to defaults, with a few exceptions
	 */
	private function resetAllDefaults() : Void {

		var prefs:Array = [
		
			"icon.position",
			"icon.scale",
			
			"hud.enabled",

			"autoSwap.enabled",
			
			"autoSwap.type.primary",
			"autoSwap.type.secondary",
			"autoSwap.type.shield",

			"autoSwap.match.friendly.self",
			"autoSwap.match.enemy.players",
			
			"defaultUI.disruptorSelectors.hide",
			"defaultUI.shieldSelector.hide",

			"hud.hide.whenAutoswapEnabled",
			"hud.hide.whenNotInCombat",
			
			"hud.position.default",
			"hud.scale",
			
			"hud.icons.type",
			
			"hud.abilityBarIntegration.enable",
			
			"hud.bars.primary.position",
			"hud.bars.primary.itemSlotPlacement",
			
			"hud.bars.secondary.position",
			"hud.bars.secondary.itemSlotPlacement",

			"hud.bars.shield.position",
			"hud.bars.shield.itemSlotPlacement",

			"hud.bar.background.type",
			"hud.bar.background.tint",
			"hud.bar.background.neon",
			"hud.bar.background.transparency",

			"hud.slots.item.tint",
			"hud.slots.item.neon",

			"hud.slots.aegis.xp.enabled",
			"hud.slots.aegis.xp.hideWhenFull",
			
			"hud.tooltips.enabled",
			"hud.tooltips.suppressInCombat",
			
			"hud.slots.aegis.tint",
			"hud.slots.selectedAegis.neon",
			"hud.slots.selectedAegis.background.transparency",
			"hud.slots.selectedAegis.background.tint",
			"hud.slots.selectedAegis.background.neon",

			"hud.click.multiSelectType.leftButton",
			"hud.click.multiSelectType.rightButton",
			"hud.click.multiSelectType.shiftLeftButton",
			
			"hotkeys.enabled",
			"hotkeys.lockoutWhenHudDisabled",
			"hotkeys.multiSelectType.primary",
			"hotkeys.multiSelectType.secondary"
		];
		
		for ( var s:String in prefs ) {
			App.prefs.reset( prefs[s] );
		}
		
		resetTintDefaults();
	}
	
	/**
	 * resets all tings to default values
	 */
	private function resetTintDefaults() : Void {
		
		for ( var s:String in App.prefs.list ) {
			
			if ( s.substr( 0, 10 ) == "hud.tints." ) {
				App.prefs.reset( s );
			}
			
		}
		
	}
	
	/**
	 * handler for the DistributedValue that toggles the default disruptor swap buttons on/off
	 */
	private function defaultDisruptorSwapUiPrefHandler() : Void {
		m_Panel.components[ "defaultUI.disruptorSelectors.hide" ].api.load();
	}
	
	/**
	 * set the size of the content
	 * 
	 * @param	width
	 * @param	height
	 */
    public function SetSize(width:Number, height:Number) : Void {
		
		SignalSizeChanged.Emit();
    }

	/**
	 * return the dimensions of the content
	 * 
	 * @return dimensions of content size
	 */
    public function GetSize() : Point {
        //return new Point( m_Panel._width + 10, m_Panel._height );
		
		return new Point( m_Panel.width, m_Panel.height );
    }
	
	/*
	 * internal variables
	 */
	
	public var m_Panel:MovieClip;
	public var m_TitleBarPanel:MovieClip;
	
	private var defaultDisruptorSwapUiMonitor:DistributedValue;
	
	/*
	 * properties
	 */
	
}