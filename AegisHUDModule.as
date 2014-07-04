import com.Components.WinComp;
import com.GameInterface.Tooltip.TooltipData;
import com.Utils.Point;
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

var g_HUD:AegisHUD;
var g_configWindow:WinComp;
var g_configWindowInitPos:Point;

//Init
// modules.xml is not set to include:
// GMF_DONT_UNLOAD	-- this is to make it simpler to hide the passivebar default swap buttons, and so we can key default bar position off those buttons
// GUIMODEFLAGS_ENABLEALLGUI  -- only needs to be present in playfield, not needed in other GUIs
function onLoad()
{
	//UtilsBase.PrintChatText("AEGIS.HUD loaded");
}


function onUnload()
{
	//UtilsBase.PrintChatText("AEGIS.HUD unloaded");
}

// module activated (i.e. its distributed value set to 1)
// saved config data is passed in
function OnModuleActivated(archive:Archive)
{
	g_configWindowInitPos = new Point(
		archive.FindEntry("ConfigX", Number.NEGATIVE_INFINITY),
		archive.FindEntry("ConfigY", Number.NEGATIVE_INFINITY)
	);
	
	g_HUD = new AegisHUD(this);
	
	CreateConfigWindow();
}


// module deactivated (i.e. its distributed value set to 0)
// config data to be saved must be returned
function OnModuleDeactivated()
{
    var archive:Archive = new Archive();

	archive.AddEntry( "HideDefaultSwapButtons", g_hideDefaultSwapButtons );
	archive.AddEntry( "PrimaryX", g_AegisHUD.primaryBar._x );
	archive.AddEntry( "PrimaryY", g_AegisHUD.primaryBar._y );
	archive.AddEntry( "SecondaryX", g_AegisHUD.secondaryBar._x );
	archive.AddEntry( "SecondaryY", g_AegisHUD.secondaryBar._y );
	archive.AddEntry( "LinkBars", g_linkBars );
	archive.AddEntry( "LayoutStyle", g_LayoutStyle );
	archive.AddEntry( "ShowWeapons", g_showWeapons );
	archive.AddEntry( "ShowWeaponGlow", g_showWeaponGlow );
	archive.AddEntry( "ShowBarBackground", g_showBarBackground );
	archive.AddEntry( "ShowXPBars", g_showXPBars );
	archive.AddEntry( "ShowTooltips", g_showTooltips );
	archive.AddEntry( "ConfigX", g_ConfigPos.x );
	archive.AddEntry( "ConfigY", g_ConfigPos.y );
	
	// clean up elements
	g_HUD.Destroy();
	g_HUD = undefined;
	
	// return config data
    return archive;
}


// create config window
function CreateConfigWindow():Void
{
	g_configWindow = WinComp(attachMovie( "WindowComponent", "m_ConfigWindow", getNextHighestDepth() ));
	g_configWindow.SetTitle("AEGIS HUD");
	g_configWindow.ShowStroke(false);
	g_configWindow.ShowFooter(false);
	g_configWindow.ShowResizeButton(false);

	// load the content panel
	g_configWindow.SetContent( "ConfigWindowContent" );

	// set position
	// -- whatever has been previously saved, or middle of screen if not saved before
	g_configWindow._x = __ConfigPos.x;
	g_configWindow._y = __ConfigPos.y;
	
	// wire up close button
	g_configWindow.SignalClose.Connect(DestroyConfigWindow, this);
	
	//__archive.FindEntry( "ConfigWindowX", (Stage.visibleRect._width / 2) - (m_ConfigWindow._width / 2) );
}

function DestroyConfigWindow():Void
{
	g_configWindow.removeMovieClip();
}