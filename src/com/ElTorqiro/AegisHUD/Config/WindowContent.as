import com.Components.FCSlider;
import com.Components.WindowComponentContent;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import com.Utils.Archive;
import flash.geom.Point;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Button;
import gfx.controls.Slider;
import gfx.controls.TextInput;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;
import com.GameInterface.DistributedValue;
import com.ElTorqiro.AegisHUD.AddonInfo;
import com.ElTorqiro.AddonUtils.AddonUtils;

class com.ElTorqiro.AegisHUD.Config.WindowContent extends com.Components.WindowComponentContent
{
	private var _uiControls:Object = {};
	private var _uiInitialised:Boolean = false;
	
	private var m_ContentSize:MovieClip;
	private var m_Content:MovieClip;
	
	private var _layoutCursor:Point;
	
	private var _hud:MovieClip;
	
	public function WindowContent()
	{
		super();
		
		// get a handle on the hud module
		_hud = _root["eltorqiro_aegishud\\hud"];
	}

	// cleanup operations
	public function Destroy():Void
	{
	}
	
	private function configUI():Void
	{
		_layoutCursor = new Point(0, 0);
		
		super.configUI();

		m_Content = createEmptyMovieClip("m_Content", getNextHighestDepth() );

		// positioning section
		// add options section
		AddHeading("Options");
		_uiControls.hideDefaultSwapButtons = {
			control:	AddCheckbox( "hideDefaultSwapButtons", "Hide default AEGIS swap buttons" ),
			event:		"click",
			type:		"option"
		};
		_uiControls.playfieldMemoryEnabled = {
			control:	AddCheckbox( "playfieldMemoryEnabled", "HUD visibility memory enabled" ),
			event:		"click",
			type:		"option"
		};

		
		// dual select section
		AddHeading("Dual-Select");
		_uiControls.dualSelectWithButton = {
			control:	AddCheckbox( "dualSelectWithButton", "...with Right-Click" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.dualSelectWithModifier = {
			control:	AddCheckbox( "dualSelectWithModifier", "...with Shift-Click" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.dualSelectByDefault = {
			control:	AddCheckbox( "dualSelectByDefault", "Dual-by-Default (inverts single/dual behaviour)" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent();
		_uiControls.dualSelectFromHotkey = {
			control:	AddCheckbox( "dualSelectFromHotkey", "also when using default hotkeys [<variable name='hotkey:Combat_NextPrimaryAEGIS'/ > / <variable name='hotkey:Combat_NextSecondaryAEGIS'/ >]" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent( -10);


		// add position section
		AddHeading("Position");
		_uiControls.MoveToDefaultPosition = {
			control:	AddButton("MoveToDefaultPosition", "Reset to default position"),
			event:		"click",
			type:		"command"
		};
		_uiControls.lockBars = {
			control:	AddCheckbox( "lockBars", "Lock bar position and scale" ),
			event:		"click",
			type:		"setting"
		};

		_uiControls.attachToPassiveBar = {
			control:	AddCheckbox( "attachToPassiveBar", "Attach and lock HUD to PassiveBar" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent();
		_uiControls.animateMovementsToDefaultPosition = {
			control:	AddCheckbox( "animateMovementsToDefaultPosition", "Animate HUD during PassiveBar open/close" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent( -10);

		
		// add layout section
		AddHeading("Bar Layout");
		_uiControls.barStyle = {
			control:	AddDropdown( "barStyle", "Bar Layout", ["Horizontal", "Vertical"] ),
			event:		"change",
			type:		"setting"
		};

		
		// bar background style
		AddHeading("Bar Backgrounds");
		_uiControls.showBarBackground = {
			control:	AddCheckbox( "showBarBackground", "Show" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.tintBarBackgroundByActiveAegis = {
			control:	AddCheckbox( "tintBarBackgroundByActiveAegis", "Tint per active AEGIS type" ),
			event:		"click",
			type:		"setting"
		};
		
		AddColumn();
		
		// add weapon slots section
		AddHeading("Weapon Slots");
		_uiControls.showWeapons = {
			control:	AddCheckbox( "showWeapons", "Show" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.primaryWeaponFirst = {
			control:	AddCheckbox( "primaryWeaponFirst", "On Primary bar, weapon placed first" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.secondaryWeaponFirst = {
			control:	AddCheckbox( "secondaryWeaponFirst", "On Secondary bar, weapon placed first" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.showWeaponBackgroundBehaviour = {
			control:	AddDropdown( "showWeaponBackgroundBehaviour", "Show Background", ["Never", "Always", "Only when slotted"] ),
			event:		"change",
			type:		"setting"
		};
		_uiControls.tintWeaponBackgroundByActiveAegis = {
			control:	AddCheckbox( "tintWeaponBackgroundByActiveAegis", "Tint background per active AEGIS type" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.tintWeaponIconByActiveAegis = {
			control:	AddCheckbox( "tintWeaponIconByActiveAegis", "Tint icon per active AEGIS type" ),
			event:		"click",
			type:		"setting"
		};
		
		
		// add XP section
		AddHeading("AEGIS Slots");
		_uiControls.showAegisBackgroundBehaviour = {
			control:	AddDropdown( "showAegisBackgroundBehaviour", "Show Background", ["Never", "Always", "Only when slotted"] ),
			event:		"change",
			type:		"setting"
		};		
		_uiControls.tintAegisBackgroundByType = {
			control:	AddCheckbox( "tintAegisBackgroundByType", "Tint background per AEGIS type" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.tintAegisIconByType = {
			control:	AddCheckbox( "tintAegisIconByType", "Tint icon per AEGIS type" ),
			event:		"click",
			type:		"setting"
		};
		
		_uiControls.showXP = {
			control:	AddCheckbox( "showXP", "Show XP indicator" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent();
		
		_uiControls.xpIndicatorStyle = {
			control:	AddDropdown( "xpIndicatorStyle", "Style", ["Progress Bar", "Numbers"] ),
			event:		"change",
			type:		"setting"
		};	
		_uiControls.showXPProgressBackground = {
			control:	AddCheckbox( "showXPProgressBackground", "Show background in Progress Bar" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent(-10);

		_uiControls.showTooltips = {
			control:	AddCheckbox( "showTooltips", "Show Tooltips" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent();
		_uiControls.suppressTooltipsInCombat = {
			control:	AddCheckbox( "suppressTooltipsInCombat", "Suppress in combat" ),
			event:		"click",
			type:		"setting"
		};	
		AddIndent(-10);


		// active aegis section
		AddHeading("Active AEGIS Slot");
		_uiControls.showActiveAegisBackground = {
			control:	AddCheckbox( "showActiveAegisBackground", "Show background" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.tintActiveAegisBackgroundBehaviour = {
			control:	AddDropdown( "tintActiveAegisBackgroundBehaviour", "Tint Background", ["Never", "Standard", "Per Active AEGIS"] ),
			event:		"change",
			type:		"setting"
		};	
		
		AddColumn();
		// neon highlighting section
		AddHeading("NeonFX");
		_uiControls.neonEnabled = {
			control:	AddCheckbox( "neonEnabled", "Enable NeonFX per active AEGIS type" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent();
		_uiControls.neonGlowEntireBar = {
			control:	AddCheckbox( "neonGlowEntireBar", "Overall HUD" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.neonGlowBarBackground = {
			control:	AddCheckbox( "neonGlowBarBackground", "Bar background" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.neonGlowWeapon = {
			control:	AddCheckbox( "neonGlowWeapon", "Weapon slot" ),
			event:		"click",
			type:		"setting"
		};
		_uiControls.neonGlowAegis = {
			control:	AddCheckbox( "neonGlowAegis", "Active AEGIS" ),
			event:		"click",
			type:		"setting"
		};
		AddIndent(-10);
		
		// Tints section
		AddHeading("Tints", false);
		AddIndent( -10);
		_uiControls.SetDefaultTints = {
			control:	AddButton("SetDefaultTints", "Reset to default tints"),
			event:		"click",
			type:		"command"
		};
		AddIndent();

		_uiControls.tintAegisPsychic = {
			control:	AddTextInput( "tintAegisPsychic", "Psychic", "", 6, true ),
			event:		"textChange",
			type:		"setting"
		};
		_uiControls.tintAegisCybernetic = {
			control:	AddTextInput( "tintAegisCybernetic", "Cybernetic", "", 6, true ),
			event:		"textChange",
			type:		"setting"
		};
		_uiControls.tintAegisDemonic = {
			control:	AddTextInput( "tintAegisDemonic", "Demonic", "", 6, true ),
			event:		"textChange",
			type:		"setting"
		};
		_uiControls.tintAegisEmpty = {
			control:	AddTextInput( "tintAegisEmpty", "Empty Slot", "", 6, true ),
			event:		"textChange",
			type:		"setting"
		};
		_uiControls.tintAegisStandard = {
			control:	AddTextInput( "tintAegisStandard", "Default Active Highlight", "", 6, true ),
			event:		"textChange",
			type:		"setting"
		};

		_uiControls.tintXPBackground = {
			control:	AddTextInput( "tintXPBackground", "XP Bar Background", "", 6, true ),
			event:		"textChange",
			type:		"setting"
		};
		_uiControls.tintXPProgress = {
			control:	AddTextInput( "tintXPProgress", "XP Bar Progress", "", 6, true ),
			event:		"textChange",
			type:		"setting"
		};
		_uiControls.tintXPFull = {
			control:	AddTextInput( "tintXPFull", "XP Full", "", 6, true ),
			event:		"textChange",
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
		
		var eventValue = eval(e.target.eventValue + "");

		// handle textinput hex color fields
		if ( e.target instanceof TextInput && e.target["isHexColor"] ) {
			eventValue = parseInt( '0x' + eventValue );
			if ( !AddonUtils.isRGB(eventValue) ) return;
		}
		
		// execute against HUD module
		_hud.Do( _uiControls[e.target.controlName].type + '.' + e.target.controlName, ( eventValue == undefined ? true : eventValue ) );
	}
	

	// populate the states of the config ui controls based on the hud module's published data
	private function LoadValues():Void
	{
		_uiInitialised = false;
		
		var data:Object = _hud.g_data;
		
		for ( var s:String in _uiControls )
		{
			var control = _uiControls[s].control;
			var value = data[ _uiControls[s].type + 's' ][s];
			
			if ( control instanceof DropdownMenu ) {
				if( control.selectedIndex != value )  control.selectedIndex = value;
			}
			
			else if ( control instanceof CheckBox ) {
				if( control.selected != value )  control.selected = value;				
			}
			
			else if ( control instanceof TextInput ) {
				var displayString:String = control["isHexColor"] ? decColor2hex(value) : value;
				if ( control.text != displayString ) control.text = displayString;
			}
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

		var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth() );
		l.textField.autoSize = "left";
		l.textField.text = label;
		l._y = _layoutCursor.y;
		l._x = _layoutCursor.x;
		
		var o:DropdownMenu = DropdownMenu(m_Content.attachMovie( "Dropdown", "m_" + name, m_Content.getNextHighestDepth() ));

		o["controlName"] = name;
		o["eventValue"] = "e.index";
		//o["labelField"].autoSize = "left";
		//o["labelField"].text = label;
		o.disableFocus = true;
		o.dropdown = "ScrollingList";
		o.itemRenderer = "ListItemRenderer";
		o.dataProvider = values;
		o.dropdown.addEventListener("focusIn", this, "RemoveFocus");
//		o._y = y;
		o._y = _layoutCursor.y;
		o._x = _layoutCursor.x + 3 + l._width;

		_layoutCursor.y += o._height;
		
		return o;
	}
	
	// add a group heading, layed out vertically
	private function AddHeading(text:String):Void
	{
		var y:Number = m_Content._height;
		if ( y != 0) y += 10;
		
		var o:MovieClip = m_Content.attachMovie( "ConfigGroupHeading", "m_Heading", m_Content.getNextHighestDepth() );
		o.textField.autoSize = "left";
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
	
	private function AddTextInput(name:String, label:String, defaultValue:String, maxChars:Number, isHexColor:Boolean):TextInput {
		
			var l = m_Content.attachMovie( "ConfigLabel", "m_" + name + "_Label", m_Content.getNextHighestDepth() );
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
			
//			o.disableFocus = true;
			
			o._y = _layoutCursor.y;
			o._x = _layoutCursor.x + 3 + 130;	// hardcoded because textinput is currently only used for one thing -- clean up in future

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