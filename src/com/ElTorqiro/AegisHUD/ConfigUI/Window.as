import com.Components.WinComp;
import flash.filters.GlowFilter;
import flash.geom.Point;

import mx.transitions.easing.Strong;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.ConfigUI.Window extends WinComp {

	public function Window() {
	
		_alpha = 0;
		
		ShowStroke(false);
		ShowFooter(false);
		ShowResizeButton(false);
		
	}

	public function configUI() : Void {
		super.configUI();
		
		SignalContentLoaded.Connect( contentLoadedHandler, this );
	}
	
	/**
	 * show the window only after content is loaded
	 */
	private function contentLoadedHandler() : Void {
		
		var position:Point = openingPosition ? openingPosition : new Point( _x, _y );
		
		_x = position.x;
		_y = position.y + 10;
		
		this["tweenTo"]( 0.3, { _y: position.y, _alpha: 100 }, Strong.easeInOut );
	}
	
	public function Layout() : Void {
		super.Layout();
		
		//m_Shadow._width = m_Background._width + 58 - 1;
		//m_Shadow._height = m_Background._height + 58;
		m_Shadow._width = m_Background._width + 22 - 1;
		m_Shadow._height = m_Background._height + 22 - 0.5;
		
		m_Title._y -= 3;
		
		m_Title.filters = m_Title.filters.concat( [ new GlowFilter( 0xffffff, 1, 4, 4, 3, 3, false, false ) ] );
	}
	
	/*
	 * internal variables
	 */
	
	public var m_Shadow:MovieClip;
	
	private var openingPosition:Point;
	 
	/*
	 * properties
	 */
	
}