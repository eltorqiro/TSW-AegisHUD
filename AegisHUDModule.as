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

var g_AegisHUD:AegisHUD;

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
	g_AegisHUD = new AegisHUD(this);
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
	g_AegisHUD.Destroy();
	g_AegisHUD = undefined;
	
	// return config data
    return archive;
}


// create config window
function CreateConfigWindow():Void
{
	m_ConfigWindow = WinComp(__parentMC.attachMovie( "WindowComponent", "m_ConfigWindow", __parentMC.getNextHighestDepth() ));
	m_ConfigWindow.SetTitle("AEGIS HUD");
	m_ConfigWindow.ShowStroke(false);
	m_ConfigWindow.ShowFooter(false);
	m_ConfigWindow.ShowResizeButton(false);

	
	// load the content panel
	m_ConfigWindow.SetContent( "ConfigWindowContent" );

	// set position
	// -- whatever has been previously saved, or middle of screen if not saved before
	m_ConfigWindow._x = __ConfigPos.x;
	m_ConfigWindow._y = __ConfigPos.y;
	
	//__archive.FindEntry( "ConfigWindowX", (Stage.visibleRect._width / 2) - (m_ConfigWindow._width / 2) );
}
