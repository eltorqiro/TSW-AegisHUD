import com.Components.FCSlider;
import com.Components.WindowComponentContent;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import com.Utils.Archive;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Button;
import gfx.controls.Slider;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;
import com.GameInterface.DistributedValue;

class ConfigWindowContent extends WindowComponentContent
{
	private var _hudData:DistributedValue;
	private var _uiControls:Object = {};
	
	
	private var m_ContentSize:MovieClip;
	private var m_Content:MovieClip;
	
	public function ConfigWindowContent()
	{
		super();
		
		// hud data listener
		_hudData = DistributedValue.Create(AddonInfo.Name + "_Data");
		_hudData.SignalChanged.Connect(HUDDataChanged, this);
	}

	
	// HUD settings have changed
	function HUDDataChanged():Void
	{
		// do nothing if config window is not present
		if ( !g_configWindow )  return;
		
		
	}	
	
	private function configUI():Void
	{
		super.configUI();

		m_Content = createEmptyMovieClip("m_Content", getNextHighestDepth() );
		
		// add options section
		AddHeading("Options");
		_uiControls.hideDefaultSwapButtons = {
			control:	AddCheckbox( "m_HideDefaultButtons", "Hide default AEGIS swap buttons" ),
			event:		"change"
		};
		_uiControls.enableDrag = {
			control:	AddCheckbox( "m_EnableDrag", "Enable dragging with CTRL+LeftMouse" ),
			event:		"click"
		};
		_uiControls.linkBars = {
			control:	AddCheckbox( "m_LinkBars", "Link primary and secondary bars when dragging" ),
			event:		"click"
		};

		// add visuals section
		AddHeading("Visuals");
		_uiControls.showWeapons = {
			control:	AddCheckbox( "m_ShowWeapons", "Show weapon slots" ),
			event:		"click"
		};
		_uiControls.primaryWeaponFirst = {
			control:	AddCheckbox( "m_PrimaryShowWeaponFirst", "On Primary bar, show weapon first" ),
			event:		"click"
		};
		_uiControls.secondaryWeaponFirst = {
			control:	AddCheckbox( "m_SecondaryShowWeaponFirst", "On Secondary bar, show weapon first" ),
			event:		"click"
		};
		_uiControls.showWeaponHighlight = {
			control:	AddCheckbox( "m_ShowWeaponHighlight", "Show slotted weapon highlight" ),
			event:		"click"
		};
		_uiControls.showBarBackground = {
			control:	AddCheckbox( "m_ShowBarBackground", "Show bar background" ),
			event:		"click"
		};
		//AddCheckbox( "m_ShowXPBars", "Show AEGIS XP progress on slots", g_HUD.showXPBars ).addEventListener("click", this, "ShowXPBarsClickHandler");
		//AddCheckbox( "m_ShowTooltips", "Show Tooltips", g_HUD.showTooltips ).addEventListener("click", this, "ShowTooltipsClickHandler");

		// add layout section
		AddHeading("Layout Style");
		_uiControls.barStyle = {
			control:	AddDropdown( "m_BarStyle", "Layout Style", ["Horizontal", "Vertical"] ),
			event:		"change"
		}
		
		// positioning section
		AddHeading("Position");
		_uiControls.SetDefaultPosition = {
			control:	AddButton("m_ResetPosition", "Reset to default position"),
			event:		"click"
		}
		
		SetSize( Math.round(Math.max(m_Content._width, 200)), Math.round(Math.max(m_Content._height, 200)) );
		
		// wire up event handlers for ui controls
		for (var s:String in _uiControls)
		{
			switch( _uiControls[s].event )
			{
				// used for checkbox, button
				case "click":
					var fName:String = s + _uiControls[s].event + "Handler";
					this[fName] = function(e:Object) {
						UtilsBase.PrintChatText( e.target.selected );
					};
					_uiControls[s].control.addEventListener( _uiControls[s].event, this, fName );
					
				break;
				
				
				// used for dropdown
				case "change":
					var fName:String = s + _uiControls[s].event + "Handler";
					this[fName] = function(e:Object) {
						UtilsBase.PrintChatText( e.index );
					};
					_uiControls[s].control.addEventListener( _uiControls[s].event, this, fName );
				
				break;
			}
		}

		// load initial values
		LoadValues();
	}


	// populate the states of the config ui controls based on the hud module's published data
	private function LoadValues():Void
	{
		var hudValues = _hudData.GetValue();
		
		for ( var s:String in _uiControls )
		{
			_uiControls[s].control.selected = hudValues.FindEntry( s, 0 );
		}
	}

	
	// add and return a new checkbox, layed out vertically
	private function AddCheckbox(name:String, text:String):CheckBox
	{
		var y:Number = m_Content._height;
		
		var o:CheckBox = CheckBox(m_Content.attachMovie( "Checkbox", name, m_Content.getNextHighestDepth() ));
		with ( o )
		{
			disableFocus = true;
			textField.autoSize = true;
			textField.text = text;
			_y = y;
		}
		
		return o;
	}

	// add and return a new button, layed out vertically
	private function AddButton(name:String, text:String):Button
	{
		var y:Number = m_Content._height;
		
		var o:Button = Button(m_Content.attachMovie( "Button", name, m_Content.getNextHighestDepth() ));
		o.label = text;
		o.autoSize = "center";
		o.disableFocus = true;
		o._y = y;
		
		return o;
	}
	
	
	// add and return a dropdown
	private function AddDropdown(name:String, label:String, values:Array):DropdownMenu
	{
		var y:Number = m_Content._height;

		var o:DropdownMenu = DropdownMenu(m_Content.attachMovie( "Dropdown", name, m_Content.getNextHighestDepth() ));
		with ( o )
		{
			disableFocus = true;
			dropdown = "ScrollingList";
			itemRenderer = "ListItemRenderer";
			dataProvider = values;
		}
		o.dropdown.addEventListener("focusIn", this, "RemoveFocus");
		o._y = y;
		
		return o;
	}
	
	// add a group heading, layed out vertically
	private function AddHeading(text:String):Void
	{
		var y:Number = m_Content._height;
		if ( y != 0) y += 10;
		
		var o:MovieClip = m_Content.attachMovie( "ConfigGroupHeading", "testing", m_Content.getNextHighestDepth() );
		o.textField.text = text;
		o._y = y;
	}
	
	private function AddSlider(name:String, label:String, minValue:Number, maxValue:Number):FCSlider
	{
		var y:Number = m_Content._height;

		var o:FCSlider = FCSlider(m_Content.attachMovie( "Slider", name, m_Content.getNextHighestDepth() ));
		o.width = 200;
		o._x = 100;
		
		o.minimum = minValue;
		o.maximum = maxValue;
		o.snapInterval = 1;
		o.snapping = true;
		o.liveDragging = true;
		o._y = y;
		
		return o;
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