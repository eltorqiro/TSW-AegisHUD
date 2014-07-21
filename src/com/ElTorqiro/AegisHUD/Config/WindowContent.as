import com.Components.FCSlider;
import com.Components.WindowComponentContent;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import com.Utils.Archive;
import flash.geom.Point;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Button;
import gfx.controls.Slider;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;
import com.GameInterface.DistributedValue;
import com.ElTorqiro.AegisHUD.AddonInfo;

class com.ElTorqiro.AegisHUD.Config.WindowContent extends com.Components.WindowComponentContent
{
	private var _hudData:DistributedValue;
	private var _uiControls:Object = {};
	private var _uiInitialised:Boolean = false;
	
	private var m_ContentSize:MovieClip;
	private var m_Content:MovieClip;
	
	private var _layoutCursor:Point;
	
	public function ConfigWindowContent()
	{
		super();
		
		// hud data listener
		_hudData = DistributedValue.Create(AddonInfo.Name + "_Data");
		_hudData.SignalChanged.Connect(HUDDataChanged, this);
	}

	// cleanup operations
	public function Destroy():Void
	{
		// disconnnect from signals
		_hudData.SignalChanged.Disconnect(HUDDataChanged, this);
	}
	
	// HUD settings have changed
	function HUDDataChanged():Void
	{
		LoadValues();
	}	
	
	private function configUI():Void
	{
		_layoutCursor = new Point(0, 0);
		
		super.configUI();

		m_Content = createEmptyMovieClip("m_Content", getNextHighestDepth() );

		// positioning section
		AddHeading("Position");
		_uiControls.lockBars = {
			control:	AddCheckbox( "lockBars", "Lock bar position and scale" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.SetDefaultPosition = {
			control:	AddButton("SetDefaultPosition", "Reset to default position"),
			event:		"click",
			type:		"command"
		};

		
		// add options section
		AddHeading("Options");
		_uiControls.hideDefaultSwapButtons = {
			control:	AddCheckbox( "hideDefaultSwapButtons", "Hide default AEGIS swap buttons" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.autoHidePerZone = {
			control:	AddCheckbox( "autoHidePerZone", "Auto-hide HUD based on zone" ),
			event:		"click",
			type:		"setting"
		};

		
		// add layout section
		AddHeading("Bar Style");
		_uiControls.barStyle = {
			control:	AddDropdown( "barStyle", "Bar Style", ["Horizontal", "Vertical"] ),
			event:		"change",
			type:		"setting"
		};

		
		// add visuals section
		AddHeading("HUD Elements");
		_uiControls.showWeapons = {
			control:	AddCheckbox( "showWeapons", "Show weapon slots" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.primaryWeaponFirst = {
			control:	AddCheckbox( "primaryWeaponFirst", "On Primary bar, show weapon first" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.secondaryWeaponFirst = {
			control:	AddCheckbox( "secondaryWeaponFirst", "On Secondary bar, show weapon first" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.showWeaponHighlight = {
			control:	AddCheckbox( "showWeaponHighlight", "Show slotted weapon highlight" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.showBarBackground = {
			control:	AddCheckbox( "showBarBackground", "Show bar background" ),
			event:		"click",
			type:		"setting"
		};
		//AddCheckbox( "m_ShowXPBars", "Show AEGIS XP progress on slots", g_HUD.showXPBars ).addEventListener("click", this, "ShowXPBarsClickHandler");
		//AddCheckbox( "m_ShowTooltips", "Show Tooltips", g_HUD.showTooltips ).addEventListener("click", this, "ShowTooltipsClickHandler");


		// neon highlighting section
		AddColumn();
		AddHeading("Neon Highlighting");
		_uiControls.neonEnabled = {
			control:	AddCheckbox( "neonEnabled", "Enable neon highlighting" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent();
		_uiControls.neonDisableDefaultActiveHighlight = {
			control:	AddCheckbox( "neonDisableDefaultActiveHighlight", "Highlight active AEGIS with glow only" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.neonColouriseBarBackground = {
			control:	AddCheckbox( "neonColouriseBarBackground", "Colourise bar background" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.neonGlowBarBackground = {
			control:	AddCheckbox( "neonGlowBarBackground", "Glow bar background" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.neonColouriseWeaponIcon = {
			control:	AddCheckbox( "neonColouriseWeapon", "Colourise weapon icon" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.neonWeaponGlow = {
			control:	AddCheckbox( "neonWeaponGlow", "Weapon glow" ),
			event:		"click",
			type:		"setting"
		};
		
		
		SetSize( Math.round(Math.max(m_Content._width, 200)), Math.round(Math.max(m_Content._height, 200)) );
		
		// wire up event handlers for ui controls
		for (var s:String in _uiControls)
		{
			_uiControls[s].control.addEventListener( _uiControls[s].event, this, "ControlHandler" );

			/* this will be useful when/if different types of interactions are needed */
			/*
			var fName:String = s + _uiControls[s].event + "Handler";

			this[fName] = function(e:Object) {
				var rpcArchive:Archive = new Archive();
				var eventValue = eval(e.target.eventValue + "");

				// always invalidate previous value
				rpcArchive.AddEntry( "_setTime", new Date().valueOf() );
				rpcArchive.AddEntry( e.target.controlName, ( eventValue == undefined ? true : eventValue ) );

				DistributedValue.SetDValue(AddonInfo.Name + "_RPC", rpcArchive);
			};
			_uiControls[s].control.addEventListener( _uiControls[s].event, this, fName );
			*/
		}

		// load initial values
		LoadValues();
	}

	
	// universal control interaction handler
	private function ControlHandler(e:Object)
	{
		if ( !_uiInitialised ) return;
		
		var rpcArchive:Archive = new Archive();
		var eventValue = eval(e.target.eventValue + "");

		// invalidate previous value to make sure the change signal is triggered
		rpcArchive.AddEntry( "_setTime", new Date().valueOf() );
		rpcArchive.AddEntry( e.target.controlName, ( eventValue == undefined ? true : eventValue ) );

		DistributedValue.SetDValue(AddonInfo.Name + "_RPC", rpcArchive);
	}
	

	// populate the states of the config ui controls based on the hud module's published data
	private function LoadValues():Void
	{
		_uiInitialised = false;
		var hudValues = _hudData.GetValue();
		
		for ( var s:String in _uiControls )
		{
			var control = _uiControls[s].control;
			var value = hudValues.FindEntry( s, 0 );
			
			if ( control instanceof DropdownMenu )
			{
				if( control.selectedIndex != value )  control.selectedIndex = value;
			}
			
			else if ( control instanceof CheckBox )
			{
				if( control.selected != value )  control.selected = value;				
			}
		}
		
		_uiInitialised = true;
	}

	
	// add and return a new checkbox, layed out vertically
	private function AddCheckbox(name:String, text:String):CheckBox
	{	
		var y:Number = m_Content._height;
		
		var o:CheckBox = CheckBox(m_Content.attachMovie( "Checkbox", "m_" + name, m_Content.getNextHighestDepth() ));
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
		o["controlName"] = name;
		o["eventValue"] = "e.target.selected";
		o.label = text;
		o.autoSize = "center";
		o.disableFocus = true;
//o._y = y;
		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x + 6;

		_layoutCursor.y += o._height;
		
		return o;
	}
	
	
	// add and return a dropdown
	private function AddDropdown(name:String, label:String, values:Array):DropdownMenu
	{
		var y:Number = m_Content._height;

		var o:DropdownMenu = DropdownMenu(m_Content.attachMovie( "Dropdown", "m_" + name, m_Content.getNextHighestDepth() ));
		o["controlName"] = name;
		o["eventValue"] = "e.index";
		with ( o )
		{
			disableFocus = true;
			dropdown = "ScrollingList";
			itemRenderer = "ListItemRenderer";
			dataProvider = values;
		}
		o.dropdown.addEventListener("focusIn", this, "RemoveFocus");
//		o._y = y;
		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x + 3;

		_layoutCursor.y += o._height;
		
		return o;
	}
	
	// add a group heading, layed out vertically
	private function AddHeading(text:String):Void
	{
		var y:Number = m_Content._height;
		if ( y != 0) y += 10;
		
		var o:MovieClip = m_Content.attachMovie( "ConfigGroupHeading", "m_Heading", m_Content.getNextHighestDepth() );
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
	
	private function AddColumn():Void
	{
		_layoutCursor.x = this._width + 30;
		_layoutCursor.y = 0;
	}
	
	private function AddIndent(indent:Number):Void
	{
		if ( indent == undefined) indent = 10;
		
		_layoutCursor.x += indent;
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
	 * 
	 * this is the all-important override that makes window resizing work properly
	 * the SignalSizeChanged signal is monitored by the host window, which resizes accordingly
	 * the underlying WindowComponentContent.SetSize() is just a stub, since it doesn't know what Instance Name you've given your content wrapper in Flash
	 */
    public function SetSize(width:Number, height:Number)
    {	
        m_ContentSize._width = width;
        m_ContentSize._height = height;
        
		SignalSizeChanged.Emit();	// must fire this signal, else the parent WinComp container never gets resized, only the inner content does
    }	
	
}