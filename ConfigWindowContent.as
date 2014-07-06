import com.Components.WindowComponentContent;
import com.ElTorqiro.AegisHUD.Enums.AegisBarLayoutStyles;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Button;
import mx.utils.Delegate;
import com.GameInterface.UtilsBase;

class ConfigWindowContent extends WindowComponentContent
{
	private var m_ContentSize:MovieClip;
	private var m_Content:MovieClip;
	
	public function ConfigWindowContent()
	{
		super();
	}
	
	private function configUI():Void
	{
		super.configUI();

		m_Content = createEmptyMovieClip("m_Content", getNextHighestDepth() );
		
		// add options section
		AddHeading("Options");
		AddCheckbox( "m_HideDefaultButtons", "Hide default AEGIS swap buttons", g_HUD.hideDefaultSwapButtons ).addEventListener("click", this, "HideDefaultButtonsClickHandler");
		AddCheckbox( "m_EnableDrag", "Enable dragging with CTRL+LeftMouse", g_HUD.enableDrag ).addEventListener("click", this, "EnableDragClickHandler");
		AddCheckbox( "m_LinkBars", "Link primary and secondary bars when dragging", g_HUD.linkBars ).addEventListener("click", this, "LinkBarsClickHandler");

		// add visuals section
		AddHeading("Visuals");
		AddCheckbox( "m_ShowWeapons", "Show weapon slots", g_HUD.showWeapons ).addEventListener("click", this, "ShowWeaponsClickHandler");
		AddCheckbox( "m_PrimaryShowWeaponFirst", "On Primary bar, show weapon first", g_HUD.primaryBarWeaponFirst ).addEventListener("click", this, "PrimaryShowWeaponFirstClickHandler");
		AddCheckbox( "m_SecondaryShowWeaponFirst", "On Secondary bar, show weapon first", g_HUD.secondaryBarWeaponFirst ).addEventListener("click", this, "SecondaryShowWeaponFirstClickHandler");
		AddCheckbox( "m_ShowWeaponHighlight", "Show slotted weapon highlight", g_HUD.showWeaponHighlight ).addEventListener("click", this, "ShowWeaponHighlightClickHandler");
		AddCheckbox( "m_ShowBarBackground", "Show bar background", g_HUD.showBarBackground ).addEventListener("click", this, "ShowBarBackgroundClickHandler");
		//AddCheckbox( "m_ShowXPBars", "Show AEGIS XP progress on slots", g_HUD.showXPBars ).addEventListener("click", this, "ShowXPBarsClickHandler");
		//AddCheckbox( "m_ShowTooltips", "Show Tooltips", g_HUD.showTooltips ).addEventListener("click", this, "ShowTooltipsClickHandler");

		// add layout section
		AddHeading("Layout Style");
		AddDropdown( "m_BarStyle", "Layout Style", ["Horizontal", "Vertical"], g_HUD.layoutStyle ).addEventListener("change", this, "LayoutStyleChangeHandler");
		
		// positioning section
		AddHeading("Position");
		AddButton("m_ResetPosition", "Reset to default position").addEventListener("click", this, "ResetPositionClickHandler");
		
		SetSize( Math.round(Math.max(m_Content._width, 200)), Math.round(Math.max(m_Content._height, 200)) );
	}

	private function HideDefaultButtonsClickHandler(e:Object) {
		g_HUD.hideDefaultSwapButtons = e.target.selected;
	}
	
	private function LinkBarsClickHandler(e:Object) {
		g_HUD.linkBars = e.target.selected;
	}

	private function ShowWeaponsClickHandler(e:Object) {
		g_HUD.showWeapons = e.target.selected;
	}
	
	private function ShowWeaponHighlightClickHandler(e:Object) {
		g_HUD.showWeaponHighlight = e.target.selected;
	}
	
	private function ShowBarBackgroundClickHandler(e:Object) {
		g_HUD.showBarBackground = e.target.selected;
	}

	private function ShowXPBarsClickHandler(e:Object) {
		g_HUD.showXPBars = e.target.selected;
	}
	
	private function ShowTooltipsClickHandler(e:Object) {
		g_HUD.showTooltips = e.target.selected;
	}
	
	private function PrimaryShowWeaponFirstClickHandler(e:Object) {
		g_HUD.primaryBarWeaponFirst = e.target.selected;
	}
	
	private function SecondaryShowWeaponFirstClickHandler(e:Object) {
		g_HUD.secondaryBarWeaponFirst = e.target.selected;
	}

	private function ResetPositionClickHandler(e:Object) {
		g_HUD.SetDefaultPosition();
	}
	
	private function EnableDragClickHandler(e:Object) {
		g_HUD.enableDrag = e.target.selected;
	}

	private function LayoutStyleChangeHandler(e:Object) {
		g_HUD.layoutStyle = e.index;
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
		o.selectedIndex = initialValue;
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
	
	private function Close():Void
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