import com.Components.WindowComponentContent;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;

class com.ElTorqiro.AegisHUD.ConfigWindowContent extends WindowComponentContent
{
	private var m_ContentSize:MovieClip;
	private var m_Content:MovieClip;
	
	private var __barLayoutStylesArray:Array;
	
	public function ConfigWindowContent()
	{
		super();
		
		for ( var i:String in AegisBarLayoutStyles.list)
		{
			
		}
	}

	
	private function configUI():Void
	{
		super.configUI();

		m_Content = createEmptyMovieClip("m_Content", getNextHighestDepth() );
		
		// add options section
		AddHeading("Options");
		AddCheckbox( "m_HideDefaultButtons", "Hide default AEGIS swap buttons", g_hideDefaultSwapButtons ).addEventListener("click", this, "HideDefaultButtonsClickHandler");
		AddCheckbox( "m_LinkBars", "Link primary and secondary bars when dragging", g_linkBars ).addEventListener("click", this, "LinkBarsClickHandler");

		// add visuals section
		AddHeading("Visuals");
		AddCheckbox( "m_ShowWeapons", "Show weapon slots", g_showWeapons ).addEventListener("click", this, "ShowWeaponsClickHandler");
		AddCheckbox( "m_ShowWeaponGlow", "Show weapon slot glow", g_showWeaponGlow ).addEventListener("click", this, "ShowWeaponGlowClickHandler");
		AddCheckbox( "m_ShowBarBackground", "Show bar background", g_showBarBackground ).addEventListener("click", this, "ShowBarBackgroundClickHandler");
		AddCheckbox( "m_ShowXPBars", "Show AEGIS XP bars on slots", g_showXPBars ).addEventListener("click", this, "ShowXPBars");
		AddCheckbox( "m_ShowTooltips", "Show Tooltips", g_showTooltips ).addEventListener("click", this, "ShowTooltips");
		
		// add layout section
		AddHeading("Layout Style");
		AddDropdown( "m_BarStyle", "Layout Style", ["Horizontal", "Vertical"], 0 );// .addEventListener("click", this, "LinkBarsClickHandler");
		
		//  add position shortcut section
		AddHeading("Position at...");
		AddDropdown( "m_Position", "Position", ["", "Default Location"], 0 );// .addEventListener("click", this, "LinkBarsClickHandler");
		
		
		SetSize( Math.max(m_Content._width, 200), Math.max(m_Content._height, 200) );
	}

	private function HideDefaultButtonsClickHandler(e:Object) {
		HideDefaultSwapButtons(e.target.selected);
	}
	
	private function LinkBarsClickHandler(e:Object) {
		LinkBars(e.target.selected);
	}
	
	// add and return a new checkbox, layed out vertically
	private function AddCheckbox(name:String, text:String, initialState:Boolean):CheckBox
	{
		var y:Number = m_Content._height;
		
		var o:CheckBox = CheckBox(m_Content.attachMovie( "Checkbox", name, m_Content.getNextHighestDepth() ));
		with ( o )
		{
			disableFocus = true;
			textField.autoSize = true;
			textField.text = text;
			selected = initialState;
			_y = y;
		}
		
		return o;
	}
	
	// add and return a dropdown
	private function AddDropdown(name:String, label:String, values:Array, initialValue):DropdownMenu
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
		//textField.autoSize = true;
		//textField.text = text;
		//selected = initialState;
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
	

    //Remove Focus
    private function RemoveFocus():Void
    {
        Selection.setFocus(null);
    }
	
	
	/* this is the all-important override that lets window resizing work properly
	 * the underlying WindowComponentContent.SetSize() is just a stub, since it doesn't know what Instance Name you've given your content wrapper in Flash
	 */
    public function SetSize(width:Number, height:Number)
    {	
        m_ContentSize._width = width;
        m_ContentSize._height = height;
        
		SignalSizeChanged.Emit();	// must fire this signal, else the parent WinComp container never gets resized, only the inner content does
    }	
	
}