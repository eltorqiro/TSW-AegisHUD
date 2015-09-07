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

		for ( var i:Number = 0; i < def.layout.length; i++ ) {
			
			var element:Object = def.layout[ i ];
			
			var id:String = "component_" + (element.id ? element.id : + i);
		
			var component:MovieClip = container.createEmptyMovieClip( id, container.getNextHighestDepth() );
			component._x = controlCursor.x;
			component._y = controlCursor.y;
			
			switch ( element.type ) {
				
				case "heading":
					createHeading( component, id, element.subType, element.text );
				break;
				
				case "checkbox":
					createCheckbox( component, id, element.label, element.data, element.loader, element.saver, element.onClick );
				break;
				
				case "dropdown":
					createDropdown( component, id, element.label, element.list, element.data, element.loader, element.saver, element.onChange );
				break;
				
				case "slider":
					createSlider( component, id, element.label, element.min, element.max, element.valueLabelFormat );
				break;
				
				case "indent":
					if ( element.size == "reset" ) {
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
	
	private function createCheckbox( component:MovieClip, id:String, label:String, data:Object, loader:Function, saver:Function, onClick:Function ) : MovieClip {

		component.data = data;
		component.loader = loader;
		component.saver = saver;
		component.onClick = onClick;
		
		component.checkboxClickHandler = function( event:Object ) {
			this.component.onClick( { component: this.component, value: this.component.getValue() } );
			
			this.component.saver();
		};

		component.getValue = function () {
			return this.checkbox.selected;
		}
		
		component.setValue = function ( value:Boolean ) {
			if ( Boolean( value ) != this.checkbox.selected ) {
				this.checkbox.selected = Boolean( value );
			}
		}
		
		// create checkbox subcomponent
		var checkbox:CheckBox = CheckBox( component.attachMovie( "checkbox", "checkbox", component.getNextHighestDepth() ) );
		component.checkbox = checkbox;
		
		checkbox.label = label;
		checkbox.disableFocus = true;
		checkbox.textField.autoSize = "left";
		
		controlCursor.y += checkbox._height - 1;

		checkbox[ "component" ] = component;
		checkbox.addEventListener( "click", component.checkboxClickHandler );

		// initial load of value
		component.loader();
		
		return component;
	}
	
	private function createDropdown( component:MovieClip, id:String, label:String, list:Array, data:Object, loader:Function, saver:Function, onChange:Function ) : MovieClip {

		component.data = data;
		component.loader = loader;
		component.saver = saver;
		component.onChange = onChange;

		component.list = list;
		
		component.dropdownChangeHandler = function( event:Object ) {
			this.component.onChange( { component: this.component, value: this.component.getValue() } );
			
			this.component.saver();
		};

		component.getValue = function () {
			return this.dropdown.selectedItem.value;
		}
		
		component.setValue = function ( value ) {
			
			if ( this.dropdown.selectedItem.value == value ) return;
			
			for ( var s:String in this.list ) {
				if ( this.list[s].value == value ) {
					this.dropdown.selectedIndex = s;
				}
			}
			
		}
		
		var dropdownLabel:MovieClip = component.attachMovie( "label", "label", component.getNextHighestDepth() );
		dropdownLabel.textField.autoSize = "left";
		dropdownLabel.textField.text = label;
		dropdownLabel._x = 3;

		var dropdown:DropdownMenu = DropdownMenu( component.attachMovie( "dropdown", "dropdown", component.getNextHighestDepth(), { offsetY: 2, margin: 0 } ) );

		dropdown[ "component" ] = component;

		// it is essential that this is set prior to the dropdown being created below, else there is no way to have a "focus-less" dropdown working
		dropdown.disableFocus = true;
		
		dropdown.dropdown = "ScrollingList";
		dropdown.itemRenderer = "ListItemRenderer";
		dropdown.dataProvider = list;

		var dropdownWidth:Number = 150;
		dropdown.width = dropdownWidth;
		dropdown._x = columnWidth - indent - dropdownWidth;
		
		controlCursor.y += dropdown.height + 3;
		
		dropdown.dropdown.addEventListener( "focusIn", this, "clearFocus" );
		dropdown.addEventListener( "change", component.dropdownChangeHandler );

		// initial load of value
		component.loader();
		
		return component;
	}

	private function createSlider( componentContainer:MovieClip, id:String, label:String, min:Number, max:Number, valueLabelFormat:String ) : MovieClip {

		/**
		 * to avoid an infinite loop of slider change => pref change => slider change
		 * 
		 * on the setValue for the component, check if the new value is different to the old value before updating
		 * 
		 */
		
		
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
		valueLabel._x = columnWidth - 37;
		
		el["valueLabel"] = valueLabel;

		el[ "updateValueLabel" ]();
		
		controlCursor.y += componentContainer._height;
		
		return el;
	}

	
	private function clearFocus( event:Object ) : Void {
		
		event.target.focused = false;
		//Selection.setFocus( null );
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