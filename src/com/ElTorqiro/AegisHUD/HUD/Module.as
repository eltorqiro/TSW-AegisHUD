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

import com.ElTorqiro.Utils;
import com.ElTorqiro.AegisHUD.HUD.HUD;
import com.ElTorqiro.AegisHUD.Enums.*;

// the AegisHUD instance
var g_HUD:HUD;

// settings persistence objects
var g_settings:Object;

// RPC DValue for receiving settings changes from other modules  (e.g. the Config module)
var g_RPC:DistributedValue;
var g_RPCFilter:Object;


//Init
function onLoad()
{
	// default values for settings
	g_settings = {
		primaryPosition:		new Point( -1, -1 ),
		secondaryPosition:		new Point( -1, -1 ),
		scale:					100,
		
		hideDefaultSwapButtons: true,
		barStyle:				AegisBarLayoutStyles.HORIZONTAL,
		showWeapons:			true,
		showWeaponHighlight:	true,
		showBarBackground:		true,
		showXPBars:				false,
		showTooltips:			false,
		primaryWeaponFirst:		true,
		secondaryWeaponFirst:	true,
		hudScale:				100,
		lockBars:				false
	};
	
	// RPC permissable settings/commands
	g_RPCFilter = {
		/* settings */
		hideDefaultSwapButtons: "setting",
		barStyle:				"setting",
		showWeapons:			"setting",
		showWeaponHighlight:	"setting",
		showBarBackground:		"setting",
		showXPBars:				"setting",
		showTooltips:			"setting",
		primaryWeaponFirst:		"setting",
		secondaryWeaponFirst:	"setting",
		lockBars:				"setting",
		
		/* commands */
		SetDefaultPosition:		"command"
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
	g_HUD = new HUD(this, "m_AegisHUD", g_settings );

	// wire up RPC listener
	g_RPC = DistributedValue.Create(AddonInfo.Name + "_RPC");
	g_RPC.SignalChanged.Connect(RPCListener, this);
}


// module deactivated (i.e. its distributed value set to 0)
function OnModuleDeactivated()
{
	// disconnect from DValues
	g_RPC.SignalChanged.Disconnect(RPCListener, this);

	// persist settings
	SaveData();
	
	// clean up elements
	g_HUD.Destroy();
	g_HUD = null;
}

function SaveData():Void
{
	// save module settings
	var saveData:Archive = new Archive();

	saveData.AddEntry( "hideDefaultSwapButtons", g_HUD.hideDefaultSwapButtons );
	saveData.AddEntry( "primaryPosition", g_HUD.primaryPosition );
	saveData.AddEntry( "secondaryPosition", g_HUD.secondaryPosition );
	saveData.AddEntry( "barStyle", g_HUD.barStyle );
	saveData.AddEntry( "showWeapons", g_HUD.showWeapons );
	saveData.AddEntry( "showWeaponHighlight", g_HUD.showWeaponHighlight );
	saveData.AddEntry( "showBarBackground", g_HUD.showBarBackground );
	saveData.AddEntry( "showXPBars", g_HUD.showXPBars );
	saveData.AddEntry( "showTooltips", g_HUD.showTooltips );
	saveData.AddEntry( "primaryWeaponFirst", g_HUD.primaryWeaponFirst );
	saveData.AddEntry( "secondaryWeaponFirst", g_HUD.secondaryWeaponFirst );
	saveData.AddEntry( "hudScale", g_HUD.hudScale );
	saveData.AddEntry( "lockBars", g_HUD.lockBars );

	// because LoginPrefs.xml has a reference to this DValue, the contents will be saved whenever the game thinks it is necessary (e.g. closing the game, reloadui etc)
	DistributedValue.SetDValue(AddonInfo.Name + "_Data", saveData);
}

// RPC listener
function RPCListener():Void
{	
	var rpcData = g_RPC.GetValue();

	for ( var s:String in g_RPCFilter )
	{
		var value = rpcData.FindEntry( s, undefined );
		if ( value != undefined )
		{
			switch( g_RPCFilter[s] )
			{
				case "setting":
					g_HUD[s] = value;
				break;
				
				case "command":
					g_HUD[s](value);
				break;
			}
		}
	}
	
	// a setting may have changed, update the persistence object
	SaveData();
}
