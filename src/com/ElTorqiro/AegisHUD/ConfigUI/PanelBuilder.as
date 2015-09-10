import mx.utils.Delegate;

import flash.geom.Point;

import gfx.controls.CheckBox;
import gfx.controls.DropdownMenu;
import gfx.controls.Slider;
import gfx.controls.TextInput;
import gfx.controls.Button;

import com.Utils.Format;
import flash.geom.ColorTransform;

import com.GameInterface.UtilsBase;


/**
 * 
 * 
 */
class com.ElTorqiro.AegisHUD.ConfigUI.PanelBuilder {

	public function PanelBuilder( def:Object, container:MovieClip ) {
		
		build( def, container );
	
	}
	
	/**
	 * build a configuration panel as defined in a definition object, built within a container movieclip
	 * 
	 * @param	def
	 * @param	container
	 */
	private function build( def:Object, container:MovieClip ) : Void {
		
		container.panelHeight = 0;
		container.panelWidth = 0;
		
		container.indent = 0;
		container.columnCount = 1;
		
		container.controlCursor = new Point( 0, 0 );
		container.columnCursor = new Point( 0, 0 );
		
		container.columnWidth = def.columnWidth != undefined ? def.columnWidth : 0;
		container.columnPadding = def.columnPadding != undefined ? def.columnPadding : 10;

		container.blockSpacing = def.blockSpacing != undefined ? def.blockSpacing : 10;
		container.indentSpacing = def.indentSpacing != undefined ? def.indentSpacing : 10;
		container.groupSpacing = def.groupSpacing != undefined ? def.groupSpacing : 20;

		for ( var i:Number = 0; i < def.layout.length; i++ ) {
			
			var element:Object = def.layout[ i ];
			
			var id:String = "component_" + (element.id ? element.id : + i);
		
			var component:MovieClip = container.createEmptyMovieClip( id, container.getNextHighestDepth() );
			component.panel = container;
			component.data = element.data;
			component.loader = element.loader;
			component.saver = element.saver;
			component.onChange = element.onChange;
			component.onClick = element.onClick;

			component._x = container.controlCursor.x;
			component._y = container.controlCursor.y;
			
			switch ( element.type ) {
				
				case "heading":
					createHeading( component, id, element.subType, element.text );
				break;
				
				case "button":
					createButton( component, id, element.text );
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
				
				case "colourRGB":
					createColourRGB( component, id, element.label );
				break;
				
				case "indent":
					if ( element.size == "reset" ) {
						container.controlCursor.x -= container.indent;
						container.indent = 0;
					}
					
					else {
						container.indent += container.indentSpacing;
						container.controlCursor.x += container.indentSpacing;
					}
					
				break;
				
				case "block":
					container.controlCursor.y += container.blockSpacing;
				break;
				
				case "column":
					container.columnCursor.x += container.columnWidth + container.columnPadding;
					container.columnCursor.y = 0;
					
					container.controlCursor.x = container.columnCursor.x;
					container.controlCursor.y = container.columnCursor.y;
					
					container.indent = 0;
					container.columnCount++;
				break;
				
			}
			
			container.panelHeight = container.controlCursor.y > container.panelHeight ? container.controlCursor.y : container.panelHeight;
			
		}
		
		container.panelWidth = (container.columnCount * container.columnWidth) + ((container.columnCount - 1) * container.columnPadding);
		
	}
	
	
	/**
	 * component creators
	 */
	
	private function createHeading( component:MovieClip, id:String, type:String, text:String ) : MovieClip {
		
		var headingType:String = type ? type + "-heading" : "heading";
		var extraSpacing:Number = 0;
		
		var el:MovieClip;
		
		switch ( headingType ) {
			
			case "heading":
				el = component.attachMovie( "heading", id, component.getNextHighestDepth() );
				extraSpacing = component.panel.groupSpacing;
				
			break;
			
			case "sub-heading":
				el = component.attachMovie( "sub-heading", id, component.getNextHighestDepth() );
				extraSpacing = component.panel.blockSpacing;
				
			break;
			
		}
		
		// add extra spacing
		if ( component.panel.controlCursor.y != 0 ) component.panel.controlCursor.y += extraSpacing;
		component._y = component.panel.controlCursor.y;
		
		el.textField.text = text;
		el.textField.autoSize = "left";

		component.panel.controlCursor.y += el._height;
		
		return el;
	}

	private function createButton( component:MovieClip, id:String, text:String ) : MovieClip {
		
		var button:Button = Button( component.attachMovie( "button", "button", component.getNextHighestDepth() ) );
		button.label = text;
		button.autoSize = "left";
		button.disableFocus = true;

		button.addEventListener( "click", component, "onClick" );

		// offset by a small amount if not at top of column
		if ( component.panel.controlCursor.y != 0 ) {
			component.panel.controlCursor.y += 3;
			component._y += 3;
		}
		
		component.panel.controlCursor.y += component._height;
		
		return component;
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
		
		component.panel.controlCursor.y += checkbox._height - 1;
		
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
		dropdown._x = component.panel.columnWidth - component.panel.indent - dropdownWidth;
		
		dropdown.dropdown.addEventListener( "focusIn", this, "clearFocus" );
		dropdown.addEventListener( "change", component, "dropdownChangeHandler" );

		// initial load of value
		component.loader();

		component.panel.controlCursor.y += dropdown.height + 3;
		
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

		slider.width = component.panel.columnWidth - 50;
		slider._x = 6;
		slider._y = sliderLabel.textField._height + 2;

		slider.addEventListener( "focusIn", this, "clearFocus" );
		slider.addEventListener( "change", component, "sliderChangeHandler" );
		
		// add value label
		var valueLabel = component.attachMovie( "label", "valueLabel", component.getNextHighestDepth() );
		valueLabel.format = valueLabelFormat;
		valueLabel.textField.autoSize = "left";
		valueLabel._y = slider._y - 5;
		valueLabel._x = component.panel.columnWidth - 37;
		
		component[ "updateValueLabel" ]();
		
		// initial load of value
		component.loader();
		
		component.panel.controlCursor.y += component._height;
		
		return component;
	}

	private function createColourRGB( component:MovieClip, id:String, label:String ) : MovieClip {
		
		component.value = 0;
		
		component.fields = [ "r", "g", "b" ];
		
		component.textChangeHandler = function( event:Object ) {

			if ( event.target.textField.text.length > 2 ) {
				event.target.textField.text = event.target.textField.text.substr( 0, 2 );
			}

			var fullString:String = "";
			var pad:Array = [ "00", "0" ];
			
			for ( var i:Number = 0; i < this.fields.length; i++ ) {
				var fieldText:String = this[ this.fields[i] + "TextInput" ].text;
				if ( pad[ fieldText.length ] ) fullString += pad[ fieldText.length ];
				fullString += fieldText;
			}
			
			var oldValue:Number = this.value;
			this.value = parseInt( "0x" + fullString );
			
			if ( this.value == Number.NaN ) this.value = 0;
			
			if ( oldValue != this.value ) {
				this.updatePreview( parseInt( "0x" + fullString ) );
				this.onChange( { component: this, value: this.getValue() } );
				this.saver();
			}
		};

		component.fieldFocusInHandler = function( event:Object ) {
			Selection.setSelection( 0, event.target.text.length );
		}
		
		component.fieldFocusOutHandler = function( event:Object ) {
			event.target.text = event.target.text.toUpperCase();
		}
		
		component.getValue = function () {
			return this.value;
		};
		
		component.setValue = function ( value ) {
			
			// only set if there is a different value
			if ( value == this.value ) {
				this.updatePreview( value );
				return;
			}

			this.value = value;
			
			// convert number into hex string
			var colArr:Array = value.toString(16).toUpperCase().split('');
			var numChars:Number = colArr.length;
			for ( var i:Number = 0; i < ( 6 - numChars ); i++ ) {
				colArr.unshift("0");
			}
			
			var texts:Array = [ colArr[0] + colArr[1], colArr[2] + colArr[3], colArr[4] + colArr[5] ];
			
			for ( var i:Number = 0; i < this.fields.length; i++ ) {
				if ( !this[ this.fields[i] + "TextInput" ].focused ) {
					this[ this.fields[i] + "TextInput" ].text = texts[ i ];
				}
			}
			
			this.updatePreview( value );
		};

		// add label
		var pickerLabel:MovieClip = component.attachMovie( "label", "label", component.getNextHighestDepth(), { actAsButton: true } );
		pickerLabel.textField.autoSize = "left";
		pickerLabel.textField.text = label;
		pickerLabel._x = 3;

		// add colour fields
		var fieldWidth:Number = 30;
		var fieldTop:Number = 1;
		var fieldLabelWidth:Number = 13;
		
		var onKillFocus = function( newFocus:Object ) {
			if ( newFocus != this && newFocus != this._parent ) {
				this._parent.focused = false;
			}			
		};
		
		var onSetFocus = function( oldFocus:Object ) {
			if ( oldFocus != this && oldFocus != this._parent ) {
				this._parent.focused = true;
			}
		};
		
		for ( var i:Number = 0; i < component.fields.length; i++ ) {

			// add "blue" field
			var field:TextInput = TextInput( component.attachMovie( "textInput", component.fields[i] + "TextInput", component.getNextHighestDepth() ) );
			field[ "component" ] = component;
			field.maxChars = 2;
			field.width = fieldWidth;
			field._x = component.panel.columnWidth - component.panel.indent - (3 * (fieldWidth + fieldLabelWidth) + 10) + ( i * (fieldWidth + fieldLabelWidth + 10) );
			field._y = fieldTop;
			
			field.text = "00";
			
			field.textField.onKillFocus = onKillFocus;
			field.textField.onSetFocus = onSetFocus;
			
			field.addEventListener( "textChange", component, "textChangeHandler" );
			field.addEventListener( "focusIn", component, "fieldFocusInHandler" );
			field.addEventListener( "focusOut", component, "fieldFocusOutHandler" );

			var fieldLabel:MovieClip = component.attachMovie( "colourRGBFieldLabel", component.fields[i] + "Label", component.getNextHighestDepth() );
			fieldLabel.textField.autoSize = "left";
			fieldLabel.textField.text = component.fields[i];
			fieldLabel._x = field._x - fieldLabel.textField.textWidth - 5;
			fieldLabel._y = field._y + (field._height - fieldLabel._height) / 2; // _height;

		}
		
		// add colour preview
		var preview:MovieClip = component.attachMovie( "colourPreview", "preview", component.getNextHighestDepth() );
		preview._width = 10;
		preview._height = field._height - 4;
		preview._x = component[ component.fields[0] + "Label" ]._x - preview._width - 10;
		preview._y = fieldTop + 2;
		
		/**
		 * Colorize movieclip using color multiply method rather than flat color
		 * 
		 * Courtesy of user "bummzack" at http://gamedev.stackexchange.com/a/51087
		 * 
		 * @param	color Color to apply
		 */	
		component.updatePreview = function ( color:Number ) {
			// get individual color components 0-1 range
			var r:Number = ((color >> 16) & 0xff) / 255;
			var g:Number = ((color >> 8) & 0xff) / 255;
			var b:Number = ((color) & 0xff) / 255;

			// get the color transform and update its color multipliers
			var ct:ColorTransform = this.preview.box.transform.colorTransform;
			ct.redMultiplier = r;
			ct.greenMultiplier = g;
			ct.blueMultiplier = b;

			// assign transform back to sprite/movieclip
			this.preview.box.transform.colorTransform = ct;
		}	

		// initial load of value
		component.loader();

		component.panel.controlCursor.y += component._height + 2;
		
		return component;
	}

	private function clearFocus( event:Object ) : Void {
		
		event.target.focused = false;
		//Selection.setFocus( null );
	}
	
	/*
	 * internal variables
	 */
	
	/*
	 * properties
	 */
	
}