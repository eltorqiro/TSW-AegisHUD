import mx.utils.Delegate;

import flash.geom.Point;

import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Slider;
import gfx.controls.TextInput;
import com.Utils.Format;

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
			component.data = element.data;
			component.loader = element.loader;
			component.saver = element.saver;
			component.onChange = element.onChange;

			component._x = controlCursor.x;
			component._y = controlCursor.y;
			
			switch ( element.type ) {
				
				case "heading":
					createHeading( component, id, element.subType, element.text );
				break;
				
				case "checkbox":
					createCheckbox( component, id, element.label );
				break;
				
				case "dropdown":
					createDropdown( component, id, element.label, element.list );
				break;
				
				case "slider":
					createSlider( component, id, element.label, element.min, element.max, element.valueLabelFormat );
				break;
				
				case "textInput":
					createTextInput( component, id, element.label, element.maxChars );
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
	
	private function createCheckbox( component:MovieClip, id:String, label:String ) : MovieClip {

		component.checkboxClickHandler = function( event:Object ) {
			this.onChange( { component: this, value: this.getValue() } );
			
			this.saver();
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
		checkbox[ "component" ] = component;
		
		checkbox.label = label;
		checkbox.disableFocus = true;
		checkbox.textField.autoSize = "left";
		
		checkbox.addEventListener( "click", component, "checkboxClickHandler" );

		// initial load of value
		component.loader();
		
		controlCursor.y += checkbox._height - 1;
		
		return component;
	}
	
	private function createDropdown( component:MovieClip, id:String, label:String, list:Array ) : MovieClip {

		component.list = list;
		
		component.dropdownChangeHandler = function( event:Object ) {
			this.onChange( { component: this, value: this.getValue() } );
			
			this.saver();
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
		
		dropdown.dropdown.addEventListener( "focusIn", this, "clearFocus" );
		dropdown.addEventListener( "change", component, "dropdownChangeHandler" );

		// initial load of value
		component.loader();

		controlCursor.y += dropdown.height + 3;
		
		return component;
	}

	private function createSlider( component:MovieClip, id:String, label:String, min:Number, max:Number, valueLabelFormat:String ) : MovieClip {

		component.sliderChangeHandler = function( event:Object ) {
			this.onChange( { component: this, value: this.getValue() } );
			
			this.updateValueLabel();
			
			this.saver();
		};

		component.getValue = function () {
			return this.slider.value;
		};
		
		component.setValue = function ( value ) {
			
			if ( this.slider.value == value || Number(value) == Number.NaN ) return;

			this.slider.value = Number( value );
			this.updateValueLabel();
		};

		component.updateValueLabel = function ( event:Object ) {
			this.valueLabel.textField.text = Format.Printf( this.valueLabel.format, this.getValue() );
		};
		
		// add label
		var sliderLabel:MovieClip = component.attachMovie( "label", "label", component.getNextHighestDepth() );
		sliderLabel.textField.autoSize = "left";
		sliderLabel.textField.text = label;
		sliderLabel._x = 3;
		
		// add slider control
		var slider:Slider = Slider( component.attachMovie( "slider", "slider", component.getNextHighestDepth() ) );
		slider[ "component" ] = component;
		
		slider.minimum = min;
		slider.maximum = max;
		slider.snapInterval = 1;
		slider.snapping = true;
		slider.liveDragging = true;
		slider.value = min;

		slider.width = columnWidth - 50;
		slider._x = 6;
		slider._y = sliderLabel.textField._height + 2;

		slider.addEventListener( "focusIn", this, "clearFocus" );
		slider.addEventListener( "change", component, "sliderChangeHandler" );
		
		// add value label
		var valueLabel = component.attachMovie( "label", "valueLabel", component.getNextHighestDepth() );
		valueLabel.format = valueLabelFormat;
		valueLabel.textField.autoSize = "left";
		valueLabel._y = slider._y - 5;
		valueLabel._x = columnWidth - 37;
		
		component[ "updateValueLabel" ]();
		
		// initial load of value
		component.loader();
		
		controlCursor.y += component._height;
		
		return component;
	}

	private function createTextInput( component:MovieClip, id:String, label:String, maxChars:Number ) : MovieClip {
		
		component.textChangeHandler = function( event:Object ) {
			this.onChange( { component: this, value: this.getValue() } );
			
			this.saver();
		};

		component.getValue = function () {
			return this.textInput.text;
		};
		
		component.setValue = function ( value ) {
			
			if ( this.textInput.text == value || value.length > this.textInput.maxChars ) return;

			this.textInput.text = value;
		};

		// add label
		var textInputLabel:MovieClip = component.attachMovie( "label", "label", component.getNextHighestDepth(), { actAsButton: true } );
		textInputLabel.textField.autoSize = "left";
		textInputLabel.textField.text = label;
		textInputLabel._x = 3;
		
		// add textinput
		var textInput:TextInput = TextInput( component.attachMovie( "textInput", "textInput", component.getNextHighestDepth() ) );
		textInput[ "component" ] = component;
		
		textInput.maxChars = maxChars == undefined ? 0 : maxChars;
		
		var fieldWidth:Number = 70;
		
		textInput.width = fieldWidth;
		//textInput._x = columnWidth - indent - fieldWidth;
		textInput._x = columnWidth - indent - fieldWidth - 80;
		textInput._y = 1;
		
		// the TextInput class isn't issuing "focusOut" events when clicking outside the box, as it thinks the focus hasn't changed, so this trickery is necessary
		textInput.textField.onKillFocus = function( newFocus:Object ) {
			if ( newFocus != this && newFocus != this._parent ) {
				this._parent.focused = false;
			}
		};
		
		textInput.textField.onSetFocus = function( oldFocus:Object ) {
			if ( oldFocus != this && oldFocus != this._parent ) {
				this._parent.focused = true;
			}
		}
		
		textInput.addEventListener( "textChange", component.textChangeHandler );
		
		// initial load of value
		component.loader();
		
		controlCursor.y += component._height + 2;
		
		return component;
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