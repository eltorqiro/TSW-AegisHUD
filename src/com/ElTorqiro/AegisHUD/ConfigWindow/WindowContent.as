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

import com.ElTorqiro.AegisHUD.Config.ConfigPanelBuilder;
import com.ElTorqiro.AegisHUD.Const;
import com.ElTorqiro.AegisHUD.App;

/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.ConfigWindow.WindowContent extends com.Components.WindowComponentContent {

	public function WindowContent() {
		
	}

	private function configUI() : Void {
		
		super.configUI();

		createEmptyMovieClip( "m_Panel", getNextHighestDepth() );
		
		// define the config panel to be built
		var def:Object = {
			
			columnWidth: 280,
			columnPadding: 40,
			
			blockSpacing: 10,
			indentSpacing: 15,
			groupSpacing: 20,
			
			layout: [
				
				{	id: "visitForumsButton",
					type: "button",
					label: "Visit forum thread",
					tooltip: "Click to open the in-game browser and visit the forum thread for the addon."
				},
				
				{	type: "heading",
					text: "General"
				},

				{	id: "hud.enabled",
					type: "checkbox",
					label: "HUD enabled (per playfield)",
					tooltip: "Enables the AegisHUD.  It may not be visible on the screen, depending on other settings, but it will still be active.<br><br>This setting is remembered on a per-playfield basis.",
					data: { pref: "hud.enabled" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},

				{ type: "block"
				},
				
				{	id: "hud.hide.whenNotInCombat",
					type: "checkbox",
					label: "Hide HUD when out of combat",
					tooltip: "Hides the HUD when you are not engaged in combat.  This is not the same as disabling the HUD, it is merely hidden from view.",
					data: { pref: "hud.hide.whenNotInCombat" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{ type: "block"
				},
				
				{	id: "defaultUI.disruptorSelectors.hide",
					type: "checkbox",
					label: "Hide default UI disruptor buttons",
					tooltip: "Hides the default UI disruptor selection buttons.",
					data: { pref: "defaultUI.disruptorSelectors.hide" },
					loader: function() {
						this.setValue( !DistributedValue.GetDValue( "ShowAegisSwapUI" ) );
					},
					saver: function() {
						DistributedValue.SetDValue( "ShowAegisSwapUI", !this.getValue() );
					}
				},
				
				{	id: "defaultUI.shieldSelector.hide",
					type: "checkbox",
					label: "Hide default UI shield button",
					tooltip: "Hides the default UI shield selection button.",
					data: { pref: "defaultUI.shieldSelector.hide" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{	type: "heading",
					text: "AutoSwap"
				},

				{	id: "autoSwap.enabled",
					type: "checkbox",
					label: "AutoSwap system enabled",
					tooltip: "Enables the AutoSwap system.  Your Aegis controllers will be swapped to match the target controllers specified below.",
					data: { pref: "autoSwap.enabled" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{	type: "indent"
				},

				{	id: "hud.hide.whenAutoswapEnabled",
					type: "checkbox",
					label: "Hide HUD when AutoSwap enabled",
					tooltip: "Hides the HUD when the AutoSwap system is enabled.  This is not the same as disabling the HUD, it is merely hidden from view.",
					data: { pref: "hud.hide.whenAutoswapEnabled" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{	type: "heading",
					subType: "sub",
					text: "Controller Focus"
				},
				
				{	id: "autoSwap.type.primary",
					type: "dropdown",
					label: "Primary",
					tooltip: "AutoSwap behaviour for the Primary Disruptor.",
					data: { pref: "autoSwap.type.primary" },
					list: [
						{ label: "No AutoSwap", value: Const.e_AutoSwapNone },
						{ label: "Enemy Shield", value: Const.e_AutoSwapOffensiveShield },
						{ label: "Friendly Shield", value: Const.e_AutoSwapDefensiveShield }
					],
					loader: dropdownLoadHandler,
					saver: dropdownSaveHandler
				},
				
				{	id: "autoSwap.type.secondary",
					type: "dropdown",
					label: "Secondary",
					tooltip: "AutoSwap behaviour for the Secondary Disruptor.",
					data: { pref: "autoSwap.type.secondary" },
					list: [
						{ label: "No AutoSwap", value: Const.e_AutoSwapNone },
						{ label: "Enemy Shield", value: Const.e_AutoSwapOffensiveShield },
						{ label: "Friendly Shield", value: Const.e_AutoSwapDefensiveShield }
					],
					loader: dropdownLoadHandler,
					saver: dropdownSaveHandler
				},
				
				{	id: "autoSwap.type.shield",
					type: "dropdown",
					label: "Shield",
					tooltip: "AutoSwap behaviour for the Shield.",
					data: { pref: "autoSwap.type.shield" },
					list: [
						{ label: "No AutoSwap", value: Const.e_AutoSwapNone },
						{ label: "Enemy Disruptor", value: Const.e_AutoSwapOffensiveDisruptor }
					],
					loader: dropdownLoadHandler,
					saver: dropdownSaveHandler
				},
				
				{	type: "indent", size: "reset"
				},
				
				{	type: "heading",
					text: "Click Selection"
				},
				
				{	id: "hud.click.multiSelectType.leftButton",
					type: "dropdown",
					label: "Left Button",
					tooltip: "Selection behaviour when clicking an Aegis slot with the Left mouse button.",
					pref: "hud.click.multiSelectType.leftButton",
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{	id: "hud.click.multiSelectType.rightButton",
					type: "dropdown",
					label: "Right Button",
					tooltip: "Selection behaviour when clicking an Aegis slot with the Right mouse button.",
					pref: "hud.click.multiSelectType.rightButton",
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{	id: "hud.click.multiSelectType.shiftLeftButton",
					type: "dropdown",
					label: "Shift+Left Button",
					tooltip: "Selection behaviour when clicking an Aegis slot with Shift+Left Button.",
					pref: "hud.click.multiSelectType.shiftLeftButton",
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},
				
				{	type: "heading",
					text: "Hotkey Selection"
				},
				
				{	id: "hotkeys.multiSelectType.primary",
					type: "dropdown",
					label: "Primary",
					tooltip: "Selection behaviour when using the Primary Disruptor hotkeys [<variable name='hotkey:Combat_NextPrimaryAEGIS'/ > / <variable name='hotkey:Combat_PreviousPrimaryAEGIS'/ >].",
					pref: "hotkeys.multiSelectType.primary",
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{	id: "hotkeys.multiSelectType.secondary",
					type: "dropdown",
					label: "Secondary",
					tooltip: "Selection behaviour when using the Secondary Disruptor hotkeys [<variable name='hotkey:Combat_NextSecondaryAEGIS'/ > / <variable name='hotkey:Combat_PreviousSecondaryAEGIS'/ >].",
					pref: "hotkeys.multiSelectType.secondary",
					list: [
						{ label: "Single Select", value: Const.e_SelectSingle },
						{ label: "Multi Select", value: Const.e_SelectMulti }
					]
				},

				{ type: "block"
				},
				
				{	id: "hotkeys.lockoutWhenHudDisabled",
					type: "checkbox",
					label: "Prevent hotkey swaps when HUD is disabled",
					tooltip: "Disables the Aegis selection hotkeys when the AegisHUD is disabled.  This helps prevent accidental swaps (and the accompanying ability lockout) in areas without Aegis content.",
					data: { pref: "hotkeys.lockoutWhenHudDisabled" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{ type: "column"
				},
				
				{	type: "heading",
					text: "Tooltips"
				},
				
				{	id: "hud.tooltips.enabled",
					type: "checkbox",
					label: "Show tooltips",
					tooltip: "Enables tooltips when hovering the mouse over items in the HUD.",
					data: { pref: "hud.tooltips.enabled" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},

				{ type: "indent"
				},
				
				{	id: "hud.tooltips.suppressInCombat",
					type: "checkbox",
					label: "Suppress in combat",
					tooltip: "Prevents tooltips from being shown when you are engaged in combat.",
					data: { pref: "hud.tooltips.suppressInCombat" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{ type: "indent", size: "reset"
				},
				
				{	type: "heading",
					text: "Item Slots"
				},

				{	id: "hud.bars.primary.itemSlotPlacement",
					type: "dropdown",
					label: "Primary Weapon",
					tooltip: "Placement of the Primary Weapon item slot on the Primary bar in the HUD.",
					pref: "hud.bars.primary.itemSlotPlacement",
					list: [
						{ label: "Do not show", value: Const.e_BarItemPlaceNone },
						{ label: "First on bar", value: Const.e_BarItemPlaceFirst },
						{ label: "Last on  bar", value: Const.e_BarItemPlaceLast }
					]
				},
				
				{	id: "hud.bars.secondary.itemSlotPlacement",
					type: "dropdown",
					label: "Secondary Weapon",
					tooltip: "Placement of the Secondary Weapon item slot on the Secondary bar in the HUD.",
					pref: "hud.bars.secondary.itemSlotPlacement",
					list: [
						{ label: "Do not show", value: Const.e_BarItemPlaceNone },
						{ label: "First on bar", value: Const.e_BarItemPlaceFirst },
						{ label: "Last on  bar", value: Const.e_BarItemPlaceLast }
					]
				},
				
				{	id: "hud.bars.shield.itemSlotPlacement",
					type: "dropdown",
					label: "Shield symbol",
					tooltip: "Placement of the Shield symbol on the Shield bar in the HUD.",
					pref: "hud.bars.shield.itemSlotPlacement",
					list: [
						{ label: "Do not show", value: Const.e_BarItemPlaceNone },
						{ label: "First on bar", value: Const.e_BarItemPlaceFirst },
						{ label: "Last on  bar", value: Const.e_BarItemPlaceLast }
					]
				},
				
				{ type: "block"
				},
				
				{	id: "hud.slots.item.neon",
					type: "checkbox",
					label: "Glow icon per active Aegis type",
					tooltip: "Adds a glow to item slot icons per their currently selected Aegis type.",
					data: { pref: "hud.slots.item.neon" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{	id: "hud.slots.item.tint",
					type: "checkbox",
					label: "Tint icon per active Aegis type",
					tooltip: "Tint item slot icons per their currently selected Aegis type.",
					pref: "hud.slots.item.tint"
				},
				
				{	type: "heading",
					text: "Aegis Slots"
				},


				{	id: "hud.icons.type",
					type: "dropdown",
					label: "Icon style",
					tooltip: "The style of icons to use for Aegis controllers.",
					pref: "hud.icons.type",
					list: [
						{ label: "AegisHUD themed icons", value: Const.e_IconTypeAegisHUD },
						{ label: "Default game icons", value: Const.e_IconTypeRDB }
					]
				},
				
				{	id: "hud.slots.aegis.tint",
					type: "checkbox",
					label: "Tint icon per Aegis type",
					tooltip: "Tint Aegis slot icons per their Aegis type.",
					data: { pref: "hud.slots.aegis.tint" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},

				{	type: "block"
				},
				
				{	id: "hud.slots.aegis.xp.enabled",
					type: "checkbox",
					label: "Show Analysis %",
					tooltip: "Shows the analysis percentage (i.e. \"Aegis XP\") on Aegis controllers.",
					data: { pref: "hud.slots.aegis.xp.enabled" } ,
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{	type: "indent"
				},
				
				{	id: "hud.slots.aegis.xp.hideWhenFull",
					type: "checkbox",
					label: "Hide at 100%",
					tooltip: "Hides the analysis percentage when a controller reaches 100%.",
					data: { pref: "hud.slots.aegis.xp.hideWhenFull" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},
				
				{	type: "indent", size: "reset"
				},
				
				{	type: "heading",
					text: "Selected Aegis Slots"
				},

				{	id: "hud.slots.selectedAegis.neon",
					type: "checkbox",
					label: "Glow icon per Aegis type",
					tooltip: "Adds a glow to selected Aegis slots per their Aegis type.",
					data: { pref: "hud.slots.selectedAegis.neon" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},

				{	type: "block"
				},
				
				{	id: "hud.slots.selectedAegis.background.transparency",
					type: "slider",
					min: 0,
					max: 100,
					valueLabelFormat: "%i%%",
					label: "Selection box transparency",
					tooltip: "The transparency level of the background box that appears behind selected Aegis slots.  A value of zero disables the background box.",
					pref: "hud.slots.selectedAegis.background.transparency"
				},
				
				{	id: "hud.slots.selectedAegis.background.neon",
					type: "checkbox",
					label: "Glow box per Aegis type",
					tooltip: "Adds a glow to the background box of selected Aegis slots per their Aegis type.",
					data: { pref: "hud.slots.selectedAegis.background.neon" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},

				{	id: "hud.slots.selectedAegis.background.tint",
					type: "checkbox",
					label: "Tint box per Aegis type",
					tooltip: "Tint the background box of selected Aegis slots per their Aegis type.",
					data: { pref: "hud.slots.selectedAegis.background.tint" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},

				{	type: "column"
				},
				
				{	type: "heading",
					text: "Bar Backgrounds"
				},
				
				{	id: "hud.bar.background.type",
					type: "dropdown",
					label: "Bar Style",
					tooltip: "The style of the bar background boxes.",
					pref: "hud.bar.background.type",
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
					valueLabelFormat: "%i%%",
					label: "Transparency",
					tooltip: "The transparency level of the bar backgrounds.  A value of zero effectively disables the background box.",
					pref: "hud.bar.background.transparency"
				},
				
				{	id: "hud.bar.background.neon",
					type: "checkbox",
					label: "Glow background per Aegis type",
					tooltip: "Adds a glow to the background bars per their group selected Aegis type.",
					data: { pref: "hud.bar.background.neon" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				},

				{	id: "hud.bar.background.tint",
					type: "checkbox",
					label: "Tint background per Aegis type",
					tooltip: "Tint bar backgrounds per their group selected Aegis type.",
					data: { pref: "hud.bar.background.tint" },
					loader: checkboxLoadHandler,
					saver: checkboxSaveHandler
				}

				
			]

		};
		
		// build the panel based on definition
		var panel:ConfigPanelBuilder = new ConfigPanelBuilder( def, m_Panel );
		
		//loadValues();
		
		// set up listener for pref changes
		App.prefs.SignalValueChanged.Connect( prefListener, this );
		
		//SetSize( Math.round(Math.max(m_Content._width, 200)), Math.round(Math.max(m_Content._height, 200)) );
		SignalSizeChanged.Emit();
	}

	private function checkboxLoadHandler() : Void {
		this.setValue( App.prefs.getVal( this.data.pref ) );
	}

	private function checkboxSaveHandler() : Void {
		App.prefs.setVal( this.data.pref, this.getValue() );
	}

	private function dropdownLoadHandler() : Void {
		this.setValue( App.prefs.getVal( this.data.pref ) );
	}
	
	private function dropdownSaveHandler() : Void {
		App.prefs.setVal( this.data.pref, this.getValue() );
	}
	
	private function loadValues() : Void {

		for ( var s:String in m_Panel ) {
			
			// handle controls that use the pref shortcut
			if ( m_Panel[s].data.pref ) {
				//loadValue( s, App.prefs.getVal( m_Panel[s].data.pref ) );
				m_Panel[s].loader();
			}
			
			// handle controls that use a custom value loader
			else if ( m_Panel[s].data.loader ) {
				//m_Panel[[s].data.loader( 
			}
			
		}
		
	}
	
	private function loadValue( controlName:String, value ) : Void {
		m_Panel[ controlName ].setValue( value );
	}
	
	/**
	 * listener for pref value changes, to update the config ui
	 * 
	 * @param	name
	 * @param	newValue
	 * @param	oldValue
	 */
	private function prefListener( name:String, newValue, oldValue ) : Void {
		
		var componentName:String = "component_" + name;
		
		// only update controls that are using the pref shortcuts
		if ( m_Panel[ componentName ].data.pref ) {
			
			UtilsBase.PrintChatText( "pref changed handler: " + name + " = " + newValue );
			
			m_Panel[ componentName ].loader();
		}
		
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
		
		return new Point( m_Panel.panelWidth, m_Panel.panelHeight );
    }
	
	/*
	 * internal variables
	 */
	
	public var m_Panel:MovieClip;
	
	/*
	 * properties
	 */
	
}