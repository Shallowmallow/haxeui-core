package haxe.ui.components;
import haxe.ds.StringMap;
import haxe.ui.core.Component;
import haxe.ui.core.DataBehaviour;
import haxe.ui.core.UIEvent;
import haxe.ui.util.Variant;

class OptionBox2 extends CheckBox2 {
    //***********************************************************************************************************
    // Public API
    //***********************************************************************************************************
    @:behaviour(GroupBehaviour, "defaultGroup")     public var group:String;
    @:behaviour(SelectedBehaviour)                  public var selected:Bool;
    @:behaviour(SelectedOptionBehaviour)            public var selectedOption:Component;
}

//***********************************************************************************************************
// Behaviours
//***********************************************************************************************************
@:dox(hide) @:noCompletion
private class GroupBehaviour extends DataBehaviour {
    public override function validateData() {
        OptionBoxGroups.instance.add(_value, cast _component);
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
private class SelectedBehaviour extends DataBehaviour {
    public override function validateData() {
        var optionbox:OptionBox2 = cast(_component, OptionBox2);
        if (optionbox.group != null && _value == false) { // dont allow false if no other group selection
            var arr:Array<OptionBox2> = OptionBoxGroups.instance.get(optionbox.group);
            var hasSelection:Bool = false;
            if (arr != null) {
                for (option in arr) {
                    if (option != _component && option.selected == true) {
                        hasSelection = true;
                        break;
                    }
                }
            }
            if (hasSelection == false) {
                _value = true;
                return;
            }
        }
        
        if (optionbox.group != null && _value == true) { // set all the others in group
            var arr:Array<OptionBox2> = OptionBoxGroups.instance.get(optionbox.group);
            if (arr != null) {
                for (option in arr) {
                    if (option != _component) {
                        option.selected = false;
                    }
                }
            }
        }

        
        var valueComponent:Component = _component.findComponent("optionbox2-value");
        if (_value == true) {
            valueComponent.addClass(":selected");
            _component.dispatch(new UIEvent(UIEvent.CHANGE));
        } else {
            valueComponent.removeClass(":selected");
        }
        
    }
}

@:dox(hide) @:noCompletion
private class SelectedOptionBehaviour extends DataBehaviour {
    public override function get():Variant {
        var optionbox:OptionBox2 = cast(_component, OptionBox2);
        var arr:Array<OptionBox2> = OptionBoxGroups.instance.get(optionbox.group);
        var selectionOption:OptionBox2 = null;
        if (arr != null) {
            for (test in arr) {
                if (test.selected == true) {
                    selectionOption = test;
                    break;
                }
            }
        }
        return selectionOption;
    }
}

//***********************************************************************************************************
// Util classes
//***********************************************************************************************************
@:dox(hide) @:noCompletion
class OptionBoxGroups { // singleton
    private static var _instance:OptionBoxGroups;
    public static var instance(get, null):OptionBoxGroups;
    private static function get_instance() {
        if (_instance == null) {
            _instance = new OptionBoxGroups();
        }
        return _instance;
    }
    
    private var _groups:StringMap<Array<OptionBox2>> = new StringMap<Array<OptionBox2>>();
    private function new () {
        
    }
    
    public function get(name:String):Array<OptionBox2> {
        return _groups.get(name);
    }
    
    public function set(name:String, options:Array<OptionBox2>) {
        _groups.set(name, options);
    }
    
    public function add(name:String, optionbox:OptionBox2) {
        if (name != null) {
            var arr:Array<OptionBox2> = get(name);
            if (arr != null) {
                arr.remove(optionbox);
            }
        }
        
        var arr:Array<OptionBox2> = get(name);
        if (arr == null) {
            arr = [];
        }
        
        if (arr.indexOf(optionbox) == -1) {
            arr.push(optionbox);
        }
        set(name, arr);
    }
}