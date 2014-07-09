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

var g_VTIOIcon:MovieClip;

var g_HUD:AegisHUD;
var g_configWindow:WinComp;
var g_configPos:Point;
var g_ConfigVersion = "1.0";
var g_ModuleVersion = "1.5.1";
var g_Debug = false;

// internal distributed value listeners



//Init
function onLoad()
{
	Debug("onLoad");


}

function onUnload()
{
	Debug("onUnload");
	
}

// module activated (i.e. its distributed value set to 1)
// saved config data is passed in
function OnModuleActivated(archive:Archive)
{
	Debug("OnModuleActivated");
	
	var initObj:Object = { };
	
	// instantiate HUD
	g_HUD = new AegisHUD(this, "m_AegisHUD", initObj );
	
}


// module deactivated (i.e. its distributed value set to 0)
// config data to be saved must be returned
function OnModuleDeactivated()
{
	Debug("OnModuleDeactivated");
	
    var archive:Archive = new Archive();

	archive.AddEntry( "ConfigVersion", g_ConfigVersion );
	archive.AddEntry( "HideDefaultSwapButtons", g_HUD.hideDefaultSwapButtons );
	archive.AddEntry( "PrimaryPosition", g_HUD.primaryBarPosition );
	archive.AddEntry( "SecondaryPosition", g_HUD.secondaryBarPosition );
	archive.AddEntry( "ConfigPosition", g_configPos );
/*
	archive.AddEntry( "PrimaryX", g_HUD.primaryBarPosition.x );
	archive.AddEntry( "PrimaryY", g_HUD.primaryBarPosition.y );
	archive.AddEntry( "SecondaryX", g_HUD.secondaryBarPosition.x );
	archive.AddEntry( "SecondaryY", g_HUD.secondaryBarPosition.y );
*/
	archive.AddEntry( "LinkBars", g_HUD.linkBars );
	archive.AddEntry( "LayoutStyle", g_HUD.layoutStyle );
	archive.AddEntry( "ShowWeapons", g_HUD.showWeapons );
	archive.AddEntry( "ShowWeaponHighlight", g_HUD.showWeaponHighlight );
	archive.AddEntry( "ShowBarBackground", g_HUD.showBarBackground );
	archive.AddEntry( "ShowXPBars", g_HUD.showXPBars );
	archive.AddEntry( "ShowTooltips", g_HUD.showTooltips );
	archive.AddEntry( "PrimaryBarWeaponFirst", g_HUD.primaryBarWeaponFirst );
	archive.AddEntry( "SecondaryBarWeaponFirst", g_HUD.secondaryBarWeaponFirst );
	archive.AddEntry( "EnableDrag", g_HUD.enableDrag );
/*
	archive.AddEntry( "ConfigX", g_configPos.x );
	archive.AddEntry( "ConfigY", g_configPos.y );
*/	
	// clean up elements
	g_HUD.Destroy();
	g_HUD = null;
	
	// return config data
    return archive;
}

function Debug(s:String)
{
	if ( g_Debug )  UtilsBase.PrintChatText("AegisHUD: " + s);
	
}