import flash.geom.Point;
import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Slider;
import com.Utils.Format;

import mx.utils.Delegate;

import com.GameInterface.UtilsBase;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.Config.ConfigPanelBuilder {

	public function ConfigPanelBuilder( def:Object, container:MovieClip ) {
		
		build( def, container );
	
	}
	
	/**
	 * build a configuration panel as defined in a definition object, built within a container movieclip
	 * 
	 * @param	def
	 * @param	container
	 */
	private function build( def:Object, container:MovieClip ) : Void {
		
		this.container = container;
		
		height = 0;
		width = 0;
		
		indent = 0;
		columnCount = 1;
		
		controlCursor = new Point( 0, 0 );
		columnCursor = new Point( 0, 0 );
		
		columnWidth = def.columnWidth ? def.columnWidth : 0;
		columnPadding = def.columnPadding ? def.columnPadding : 10;

		blockSpacing = def.blockSpacing ? def.blockSpacing : 10;
		indentSpacing = def.indentSpacing ? def.indentSpacing : 10;
		groupSpacing = def.groupSpacing ? def.groupSpacing : 20;

		var control:Object;
		var clip:MovieClip;
		
		for ( var element:Number = 0; element < def.layout.length; element++ ) {
			
			control = def.layout[ element ];
			
			var id:String = control.id ? control.id : element;
		
			clip = container.createEmptyMovieClip( id, container.getNextHighestDepth() );
			clip._x = controlCursor.x;
			clip._y = controlCursor.y;
			
			switch ( control.type ) {
				
				case "heading":
					createHeading( clip, id, control.subType, control.text );
				break;
				
				case "checkbox":
					createCheckbox( clip, id, control.label, control.data, control.getFn, control.setFn );
				break;
				
				case "dropdown":
					createDropdown( clip, id, control.label, control.list );
				break;
				
				case "slider":
					createSlider( clip, id, control.label, control.min, control.max, control.valueLabelFormat );
				break;
				
				case "indent":
					if ( control.size == "reset" ) {
						controlCursor.x -= indent;
						indent = 0;
					}
					
					else {
						indent += indentSpacing;
						controlCursor.x += indentSpacing;
					}
					
				break;
				
				case "block":
					controlCursor.y += blockSpacing;
				break;
				
				case "column":
					columnCursor.x += columnWidth + columnPadding;
					columnCursor.y = 0;
					
					controlCursor.x = columnCursor.x;
					controlCursor.y = columnCursor.y;
					
					indent = 0;
					columnCount++;
				break;
				
			}
			
			height = controlCursor.y > height ? controlCursor.y : height;
			
		}
		
		container.panelHeight = height;
		container.panelWidth = (columnCount * columnWidth) + ((columnCount - 1) * columnPadding);
		
	}
	
	
	/**
	 * component creators
	 */
	
	private function createHeading( componentContainer:MovieClip, id:String, type:String, text:String ) : MovieClip {
		
		var headingType:String = type ? type + "-heading" : "heading";
		var extraSpacing:Number = 0;
		
		var el:MovieClip;
		
		switch ( headingType ) {
			
			case "heading":
				el = componentContainer.attachMovie( "heading", id, componentContainer.getNextHighestDepth() );
				extraSpacing = groupSpacing;
				
			break;
			
			case "sub-heading":
				el = componentContainer.attachMovie( "sub-heading", id, componentContainer.getNextHighestDepth() );
				extraSpacing = blockSpacing;
				
			break;
			
		}
		
		// add extra spacing
		if ( controlCursor.y != 0 ) controlCursor.y += extraSpacing;
		componentContainer._y = controlCursor.y;
		
		el.textField.text = text;
		el.textField.autoSize = "left";

		controlCursor.y += el._height;
		
		return el;
	}
	
	private function createCheckbox( componentContainer:MovieClip, id:String, label:String, data:Object, getFn:Function, setFn:Function ) : MovieClip {
		
		var el:CheckBox = CheckBox( componentContainer.attachMovie( "checkbox", "el", componentContainer.getNextHighestDepth() ) );
		
		el.label = label;
		el.disableFocus = true;
		el.textField.autoSize = "left";
		
		controlCursor.y += el._height - 1;
		
		el[ "container" ] = componentContainer;
		
		el[ "configData" ] = data;
		
		el[ "getFn" ] = getFn;
		el[ "setFn" ] = setFn;
		
		el.addEventListener( "click", el[ "setFn" ] );
		
		el[ "getFn" ]();
		
		return el;
	}
	
	private function createDropdown( componentContainer:MovieClip, id:String, label:String, list:Array ) : MovieClip {
		
		var dropdownWidth:Number = 150;
		var labelOffset:Number = 3;
		
		var elLabel:MovieClip = componentContainer.attachMovie( "label", "label", componentContainer.getNextHighestDepth() );
		elLabel.textField.autoSize = "left";
		elLabel.textField.text = label;
		elLabel._x = labelOffset;

		var el:DropdownMenu = DropdownMenu( componentContainer.attachMovie( "dropdown", "el", componentContainer.getNextHighestDepth() ) );

		el[ "container" ] = componentContainer;
		
		el.dropdown = "ScrollingList";
		el.itemRenderer = "ListItemRenderer";
		el.dataProvider = list;

		el.addEventListener("focusIn", this, "clearFocus");

		el.width = dropdownWidth;
		el._x = columnWidth - indent - dropdownWidth;
		
		controlCursor.y += el.height + 3;
		
		return el;
	}

	private function createSlider( componentContainer:MovieClip, id:String, label:String, min:Number, max:Number, valueLabelFormat:String ) : MovieClip {

		var leftOffset:Number = 3;
		
		var elLabel:MovieClip = componentContainer.attachMovie( "label", "label", componentContainer.getNextHighestDepth() );
		elLabel.textField.autoSize = "left";
		elLabel.textField.text = label;
		elLabel._x = leftOffset;
		
		var el:Slider = Slider( componentContainer.attachMovie( "slider", "el", componentContainer.getNextHighestDepth() ) );

		el[ "container" ] = componentContainer;
		
		el[ "valueLabelFormat" ] = valueLabelFormat;
		el.width = columnWidth - 50;

		el.addEventListener( "focusIn", this, "clearFocus" );
		el.addEventListener( "change", el, "updateValueLabel" );
		

		// since we're building a composite control, this is essentially a glorified setter
		// to make sure the label text can be updated
		// -- use this instead of "value = x;" in property setting
		el["setValue"] = Delegate.create( el, function(value:Number) {
			this.value = value;
			this.updateValueLabel();
		});
		
		el["updateValueLabel"] = Delegate.create( el, function() {
			this["valueLabel"].textField.text = Format.Printf( this.valueLabelFormat, this.value );
		});
		
		el.minimum = min;
		el.maximum = max;
		el.snapInterval = 1;
		el.snapping = true;
		el.liveDragging = true;
		el.value = min;

		el._x = 6;
		el._y = elLabel.textField._height + 2;
		
		// add value label
		var valueLabel = componentContainer.attachMovie( "label", "valueLabel", componentContainer.getNextHighestDepth() );
		valueLabel.textField.autoSize = "left";
		valueLabel.textField.text = el.value;

		valueLabel._y = el._y - 5;
		valueLabel._x = columnWidth - 40;
		
		el["valueLabel"] = valueLabel;

		el[ "updateValueLabel" ]();
		
		controlCursor.y += componentContainer._height;
		
		return el;
	}

	
	private function clearFocus( event:Object ) : Void {
		//event.target.focused = false;
		Selection.setFocus( null );
	}
	
	/*
	 * internal variables
	 */
	
	private var container:MovieClip;
	 
	private var controlCursor:Point;
	private var columnCursor:Point;
	
	private var columnWidth:Number;
	private var columnPadding:Number;

	private var blockSpacing:Number;
	private var indentSpacing:Number;
	private var groupSpacing:Number;
	
	private var indent:Number;
	
	private var columnCount:Number;

	
	/*
	 * properties
	 */
	
	public var width:Number;
	public var height:Number;

}