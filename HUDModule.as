import com.Components.WinComp;
import com.GameInterface.Tooltip.TooltipData;

//import com.Utils.Point;
import flash.geom.Point;

import gfx.core.UIComponent;
import mx.utils.Delegate;
import com.GameInterface.Chat;
import com.GameInterface.DistributedValue;
import com.Utils.Archive;
import com.GameInterface.UtilsBase;
import com.GameInterface.Game.Shortcut;

import com.GameInterface.Inventory;
import com.Utils.ID32;
import com.GameInterface.Game.Character;
import com.GameInterface.Tooltip.TooltipDataProvider;
import com.GameInterface.Lore

import com.ElTorqiro.AegisHUD.*;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import AddonInfo;

// main object of the module
var g_HUD:AegisHUD;

// settings persistence objects
var g_settings:Object;

//Init
function onLoad()
{
	// default values for non-user configurable settings
	g_configSettings = {
		hideDefaultSwapButtons: true,
		linkBars:				true,
		layoutStyle:			AegisBarLayoutStyles.HORIZONTAL,
		showWeapons:			true,
		showWeaponHighlight:	true,
		showBarBackground:		true,
		showXPBars:				false,
		showTooltips:			false,
		primaryWeaponFirst:		true,
		secondaryWeaponFirst:	true,
		enableDrag:				true
	};
	
	// default values for inherent settings
	g_settings = {
		primaryPosition:		new Point( -1, -1 ),
		secondaryPosition:		new Point( -1, -1 ),
		scale:					100
	};
}

function onUnload()
{
}

// module activated (i.e. its distributed value set to 1)
function OnModuleActivated()
{
	// load settings values
	var hudData = DistributedValue.GetDValue(AddonInfo.Name + "_Data");
	for (var s:String in g_settings)
	{
		g_settings[s] = hudData.FindEntry( s, g_settings[s] );
	}
	
	// instantiate HUD
	g_HUD = new AegisHUD(this, "m_AegisHUD", g_settings );
}


// module deactivated (i.e. its distributed value set to 0)
function OnModuleDeactivated()
{
	// save module settings
	var saveData:Archive = new Archive();

	saveData.AddEntry( "hideDefaultSwapButtons", g_HUD.hideDefaultSwapButtons );
	saveData.AddEntry( "primaryPosition", g_HUD.primaryPosition );
	saveData.AddEntry( "secondaryPosition", g_HUD.secondaryPosition );
	saveData.AddEntry( "linkBars", g_HUD.linkBars );
	saveData.AddEntry( "layoutStyle", g_HUD.layoutStyle );
	saveData.AddEntry( "showWeapons", g_HUD.showWeapons );
	saveData.AddEntry( "showWeaponHighlight", g_HUD.showWeaponHighlight );
	saveData.AddEntry( "showBarBackground", g_HUD.showBarBackground );
	saveData.AddEntry( "showXPBars", g_HUD.showXPBars );
	saveData.AddEntry( "showTooltips", g_HUD.showTooltips );
	saveData.AddEntry( "primaryWeaponFirst", g_HUD.primaryWeaponFirst );
	saveData.AddEntry( "secondaryWeaponFirst", g_HUD.secondaryWeaponFirst );
	saveData.AddEntry( "enableDrag", g_HUD.enableDrag );
	
	// because LoginPrefs.xml has a reference to this DValue, the contents will be saved whenever the game thinks it is necessary (e.g. closing the game, reloadui etc)
	DistributedValue.SetDValue(AddonInfo.Name + "_Data", saveData);
	
	// clean up elements
	g_HUD.Destroy();
	g_HUD = null;
}
