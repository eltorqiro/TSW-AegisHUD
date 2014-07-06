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

var m_VTIOIcon:MovieClip;

var g_HUD:AegisHUD;
var g_configWindow:WinComp;
var g_configPos:Point;
var g_ConfigVersion = "1.0";
var g_ModuleVersion = "1.0";

// internal distributed value listeners
var g_showConfigDV:DistributedValue;

// Viper's Top Bar Information Overload (VTIO) integration
var m_VTIOIsLoadedMonitor:DistributedValue;

//Init
// modules.xml DOES NOT include:
// GUIMODEFLAGS_ENABLEALLGUI  -- only needs to be present in playfield, not needed in other GUIs
function onLoad()
{
	//UtilsBase.PrintChatText("AEGIS.HUD loaded");

	// VTIO integration
	m_VTIOIsLoadedMonitor = DistributedValue.Create("VTIO_IsLoaded");
	m_VTIOIsLoadedMonitor.SignalChanged.Connect(SlotCheckVTIOIsLoaded, this);
	
	// handle race condition for DV already having been set before our listener was connected
	if ( Boolean(m_VTIOIsLoadedMonitor.GetValue()) ) SlotCheckVTIOIsLoaded();
}

function onUnload()
{
	//UtilsBase.PrintChatText("AEGIS.HUD unloaded");
}

// module activated (i.e. its distributed value set to 1)
// saved config data is passed in
function OnModuleActivated(archive:Archive)
{
	g_configPos = new Point( archive.FindEntry("ConfigX", 200), archive.FindEntry("ConfigY", 200) );

	var initObj:Object = { };
	if ( archive.FindEntry("ConfigVersion") )
	{
		initObj = {
			hideDefaultSwapButtons: archive.FindEntry("HideDefaultSwapButtons"),
			layoutStyle: archive.FindEntry("LayoutStyle"),
			linkBars: archive.FindEntry("LinkBars"),
			showWeapons: archive.FindEntry("ShowWeapons"),
			showWeaponHighlight: archive.FindEntry("ShowWeaponHighlight"),
			showBarBackground: archive.FindEntry("ShowBarBackground"),
			showXPBars: archive.FindEntry("ShowXPBars"),
			showTooltips: archive.FindEntry("ShowTooltips"),
			primaryBarWeaponFirst: archive.FindEntry("PrimaryBarWeaponFirst"),
			secondaryBarWeaponFirst: archive.FindEntry("SecondaryBarWeaponFirst"),
			enableDrag: archive.FindEntry("EnableDrag")
		};
		
		if ( archive.FindEntry("PrimaryX", false) )
		{
			initObj.primaryBarPosition = new Point( archive.FindEntry("PrimaryX", 0), archive.FindEntry("PrimaryY", 0) );
			initObj.secondaryBarPosition = new Point( archive.FindEntry("SecondaryX", 0), archive.FindEntry("SecondaryY", 0) );
		}
		
		g_ModuleVersion = archive.FindEntry( "ConfigVersion", g_ModuleVersion );
	}
	
	// instantiate HUD
	g_HUD = new AegisHUD(this, "m_AegisHUD", initObj );
	
	// wire up show/hide config based on distributed value
	g_showConfigDV = DistributedValue.Create( "ElTorqiro_AegisHUD_ShowConfig" );
	g_showConfigDV.SetValue(0);	// initial value is "closed"
	g_showConfigDV.SignalChanged.Connect( ShowConfigDVHandler, this);
}


// module deactivated (i.e. its distributed value set to 0)
// config data to be saved must be returned
function OnModuleDeactivated()
{
    var archive:Archive = new Archive();

	archive.AddEntry( "ConfigVersion", g_ConfigVersion );
	archive.AddEntry( "HideDefaultSwapButtons", g_HUD.hideDefaultSwapButtons );
	archive.AddEntry( "PrimaryX", g_HUD.primaryBarPosition.x );
	archive.AddEntry( "PrimaryY", g_HUD.primaryBarPosition.y );
	archive.AddEntry( "SecondaryX", g_HUD.secondaryBarPosition.x );
	archive.AddEntry( "SecondaryY", g_HUD.secondaryBarPosition.y );
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
	archive.AddEntry( "ConfigX", g_configPos.x );
	archive.AddEntry( "ConfigY", g_configPos.y );
	
	// clean up elements
	g_showConfigDV.SignalChanged.Disconnect( ShowConfigDVHandler, this );
	DestroyConfigWindow();
	g_HUD.Destroy();
	g_HUD = null;
	
	// return config data
    return archive;
}

function ShowConfigDVHandler():Void
{
	if ( Boolean(g_showConfigDV.GetValue()) )  CreateConfigWindow();
	else  DestroyConfigWindow();
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

	// set position -- rounding of the values is critical here, else it will not reposition reliably
	g_configWindow._x = Math.round(g_configPos.x);
	g_configWindow._y = Math.round(g_configPos.y);
	
	// wire up close button
	g_configWindow.SignalClose.Connect( function() {
		g_showConfigDV.SetValue(false);
	}, this);
}

function DestroyConfigWindow():Void
{
	if ( g_configWindow )
	{
		g_configPos.x = g_configWindow._x;
		g_configPos.y = g_configWindow._y;
		g_configWindow.removeMovieClip();
		g_configWindow = null;
	}
}

// VTIO registration handler
function SlotCheckVTIOIsLoaded()
{
	if (!m_VTIOIsLoadedMonitor.GetValue()) return;
	
	// load icon
	if ( m_VTIOIcon == undefined )
	{
		m_VTIOIcon = this.attachMovie("VTIOIcon", "m_VTIOIcon", this.getNextHighestDepth() );
		m_VTIOIcon.onMousePress = function() {
			DistributedValue.SetDValue("ElTorqiro_AegisHUD_ShowConfig",	!DistributedValue.GetDValue("ElTorqiro_AegisHUD_ShowConfig"));
		};
	}
	
	// register with VTIO
	if (m_VTIOIsLoadedMonitor.GetValue()) DistributedValue.SetDValue("VTIO_RegisterAddon", 
		"ElTorqiro_AegisHUD|ElTorqiro|" + g_ModuleVersion + "|ElTorqiro_AegisHUD_ShowConfig|_root.eltorqiro_aegishud\\aegishud.m_VTIOIcon"
	);
}