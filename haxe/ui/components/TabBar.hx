package haxe.ui.components;

import haxe.ui.behaviours.Behaviour;
import haxe.ui.behaviours.DataBehaviour;
import haxe.ui.components.Button.ButtonEvents;
import haxe.ui.components.Button.ButtonLayout;
import haxe.ui.containers.Box;
import haxe.ui.containers.HBox;
import haxe.ui.core.Component;
import haxe.ui.core.CompositeBuilder;
import haxe.ui.core.ICompositeInteractiveComponent;
import haxe.ui.events.Events;
import haxe.ui.events.MouseEvent;
import haxe.ui.events.UIEvent;
import haxe.ui.geom.Size;
import haxe.ui.layouts.DefaultLayout;
import haxe.ui.styles.Style;
import haxe.ui.util.Variant;

@:composite(Builder, Events, TabBarLayout)
class TabBar extends Component implements ICompositeInteractiveComponent {
    //***********************************************************************************************************
    // Public API
    //***********************************************************************************************************
    @:behaviour(SelectedIndex, -1)      public var selectedIndex:Int;
    @:behaviour(SelectedTab)            public var selectedTab:Component;
    @:behaviour(TabPosition, "top")     public var tabPosition:String;
    @:behaviour(TabCount)               public var tabCount:Int;
    @:behaviour(Closable, false)        public var closable:Bool;
    @:behaviour(ButtonWidth, null)      public var buttonWidth:Null<Float>;
    @:behaviour(ButtonHeight, null)     public var buttonHeight:Null<Float>;
    @:call(RemoveTab)                   public function removeTab(index:Int);
    @:call(GetTab)                      public function getTab(index:Int):Component;

    public var tabButtons(get, null):Array<Button>;
    private function get_tabButtons():Array<Button> {
        var container:Box = findComponent("tabbar-contents", false);
        return container.findComponents(Button, 1);
    }
}

//***********************************************************************************************************
// Composite Layout
//***********************************************************************************************************
@:dox(hide) @:noCompletion
class TabBarLayout extends DefaultLayout {
    public function new() {
        super();
        _roundFullWidths = true;
    }
    
    private override function repositionChildren() {
        super.repositionChildren();

        var filler:Box = _component.findComponent("tabbar-filler", false);
        var container:Box = _component.findComponent("tabbar-contents", false);
        if (filler != null) {
            filler.width = _component.width - container.width;
            filler.height = _component.height;
            filler.left = container.width;
        }

        var leftFiller:Component = _component.findComponent("tabbar-filler-left", false);
        if (leftFiller != null) {
            leftFiller.height = _component.height;
        }

        var rightFiller:Component = _component.findComponent("tabbar-filler-right", false);
        if (rightFiller != null) {
            rightFiller.left = _component.width - rightFiller.width;
            rightFiller.height = _component.height;
        }

        var max:Float = 0;
        for (button in container.childComponents) {
            button.validateNow();
            if (button.componentHeight > max) {
                max = button.componentHeight;
            }
        }
        if (max > 0) {
            for (button in container.childComponents) {
                button.componentHeight = max;
            }
        }

        var left:Button = _component.findComponent("tabbar-scroll-left", false);
        var right:Button = _component.findComponent("tabbar-scroll-right", false);
        if (left != null && hidden(left) == false) {
            var x = _component.width - left.width;
            if (right != null) {
                x -= right.width;
            }
            if (left.style == null) {
                left.validateNow();
            }
            left.left = x - left.style.marginLeft;
            left.top = (_component.height / 2) - (left.height / 2);
        }

        if (right != null && hidden(right) == false) {
            right.left = _component.width - right.width - right.marginLeft;
            right.top = (_component.height / 2) - (right.height / 2);
        }
    }

    public override function calcAutoSize(exclusions:Array<Component> = null) {
        var size = super.calcAutoSize();
        var max:Float = 0;
        for (b in _component.findComponents(TabBarButton)) {
            if (b.height > max) {
                max = b.height;
            }
        }
        size.height = max + paddingTop + paddingBottom;
        return size;
    }
}

//***********************************************************************************************************
// Behaviours
//***********************************************************************************************************
@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class Closable extends DataBehaviour {
    public override function validateData() {
        var builder:Builder = cast(_component._compositeBuilder, Builder);
        if (builder._container == null) {
            return;
        }

        var buttons = builder._container.findComponents(TabBarButton, 1);
        for (b in buttons) {
            b.closable = _value;
        }
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class SelectedIndex extends DataBehaviour {
    private override function validateData() {
        var builder:Builder = cast(_component._compositeBuilder, Builder);
        if (builder._container == null) {
            return;
        }
        if (_value < 0) {
            return;
        }
        if (_value > builder._container.childComponents.length - 1) {
            _value = builder._container.childComponents.length - 1;
            return;
        }

        var beforeChangeEvent = new UIEvent(UIEvent.BEFORE_CHANGE);
        beforeChangeEvent.value = _value;
        _component.dispatch(beforeChangeEvent);
        if (beforeChangeEvent.canceled) {
            _value = _previousValue;
            return;
        }

        var tab:Component = cast(builder._container.getComponentAt(_value), Button);
        if (tab != null) {
            var selectedTab:Component = cast(_component, TabBar).selectedTab;
            if (selectedTab != null) {
                //cast(selectedTab, InteractiveComponent).allowFocus = true;
                selectedTab.removeClass("tabbar-button-selected");
                selectedTab.invalidateComponentStyle(false, true);
                var label = selectedTab.findComponent(Label);
                if (label != null) {
                    label.invalidateComponent();
                }
                var icon = selectedTab.findComponent(Image);
                if (icon != null) {
                    icon.invalidateComponent();
                }
            }
            tab.addClass("tabbar-button-selected");
            tab.invalidateComponentStyle(false, true);
            //cast(tab, InteractiveComponent).allowFocus = false;
            var label = tab.findComponent(Label);
            if (label != null) {
                label.invalidateComponent();
            }
            var icon = tab.findComponent(Image);
            if (icon != null) {
                icon.invalidateComponent();
            }

            var rangeMin = Math.abs(builder._container.left);
            var rangeMax = rangeMin + _component.width;

            var left:Button = _component.findComponent("tabbar-scroll-left", Button);
            var right:Button = _component.findComponent("tabbar-scroll-right", Button);
            if (left != null && left.hidden == false) {
                rangeMax -= left.width;
                rangeMax -= _component.layout.horizontalSpacing;
            }
            if (right != null && right.hidden == false) {
                rangeMax -= right.width;
            }

            if (tab.left < rangeMin || (tab.left + tab.width) > rangeMax) {
                var max = -(builder._container.width - _component.width);
                var x = -tab.left + _component.layout.paddingLeft;
                if (left != null && left.hidden == false) {
                    max -= left.width;
                    max -= _component.layout.horizontalSpacing;
                }
                if (right != null && right.hidden == false) {
                    max -= right.width;
                }

                if (x < max) {
                    x = max;
                }

                builder._containerPosition = x;
                builder._container.left = x;
                builder.checkLeftRightFillers();
            }

            _component.invalidateComponentLayout();
            _component.dispatch(new UIEvent(UIEvent.CHANGE));
        }
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class SelectedTab extends DataBehaviour {
    public override function get():Variant {
        var builder:Builder = cast(_component._compositeBuilder, Builder);
        return Variant.fromComponent(builder._container.findComponent("tabbar-button-selected", false, "css")); // TODO: didnt happen automatically
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class TabPosition extends DataBehaviour {
    public override function validateData() {
        var builder:Builder = cast(_component._compositeBuilder, Builder);
        if (_value == "bottom") {
            _component.addClass(":bottom");
            for (child in builder._container.childComponents) {
                child.addClass(":bottom");
            }
        } else {
            _component.removeClass(":bottom");
            for (child in builder._container.childComponents) {
                child.removeClass(":bottom");
            }
        }
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class TabCount extends Behaviour {
    public override function get():Variant {
        var builder:Builder = cast(_component._compositeBuilder, Builder);
        return builder._container.childComponents.length;
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class RemoveTab extends Behaviour {
    public override function call(param:Any = null):Variant {
        var builder:Builder = cast(_component._compositeBuilder, Builder);
        var index:Int = param;
        if (index < builder._container.childComponents.length) {
            var selectedIndex = cast(_component, TabBar).selectedIndex;
            var newSelectedIndex = selectedIndex;
            if (index < selectedIndex) {
                newSelectedIndex--;
            } else if (index == selectedIndex) {
                cast(_component, TabBar).selectedIndex = -1;
                newSelectedIndex = selectedIndex;
                if (newSelectedIndex > builder._container.childComponents.length - 2) {
                    newSelectedIndex = builder._container.childComponents.length - 2;
                }
            }

            var removedButton = builder._container.removeComponentAt(index);
            for (child in builder._childToButtonMap.keys()) {
                if (builder._childToButtonMap.get(child) == removedButton) {
                    builder._childToButtonMap.remove(child);
                    break;
                }
            }
            var event = new UIEvent(UIEvent.CLOSE, index);
            event.target = removedButton;
            _component.dispatch(event);

            cast(_component, TabBar).selectedIndex = newSelectedIndex;
        }
        return null;
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class GetTab extends Behaviour {
    public override function call(param:Any = null):Variant {
        var builder:Builder = cast(_component._compositeBuilder, Builder);
        var index:Int = param;
        var tab:Component = null;
        if (index < builder._container.childComponents.length) {
            tab = builder._container.childComponents[index];
        }
        return tab;
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class ButtonWidth extends DataBehaviour {
    public override function validateData() {
        if (_value == null || _value.isNull) {
            return;
        }
        for (b in _component.findComponents(Button)) {
            b.width = _value;
        }
    }
}

@:dox(hide) @:noCompletion
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class ButtonHeight extends DataBehaviour {
    public override function validateData() {
        if (_value == null || _value.isNull) {
            return;
        }
        for (b in _component.findComponents(Button)) {
            b.height = _value;
        }
    }
}

//***********************************************************************************************************
// Events
//***********************************************************************************************************
@:access(haxe.ui.core.Component)
@:access(haxe.ui.components.Builder)
private class Events extends haxe.ui.events.Events {
    private var _tabbar:TabBar;

    public function new(tabbar:TabBar) {
        super(tabbar);
        _tabbar = tabbar;
    }

    public override function register() {
        var builder:Builder = cast(_tabbar._compositeBuilder, Builder);
        for (t in builder._container.childComponents) {
            if (t.hasEvent(MouseEvent.MOUSE_DOWN, onTabMouseDown) == false) {
                t.registerEvent(MouseEvent.MOUSE_DOWN, onTabMouseDown);
            }
        }
        registerEvent(MouseEvent.MOUSE_WHEEL, onMouseWheel);
    }

    public override function unregister() {
        unregisterEvent(MouseEvent.MOUSE_WHEEL, onMouseWheel);
    }

    private function onMouseWheel(event:MouseEvent) {
        var builder:Builder = cast(_tabbar._compositeBuilder, Builder);
        if (builder._scrollLeft == null || builder._scrollLeft.hidden == true) {
            return;
        }
        if (event.delta < 0) {
            builder.scrollRight();
        } else {
            builder.scrollLeft();
        }

        event.cancel();
    }

    private function onTabMouseDown(event:MouseEvent) {
        var builder:Builder = cast(_tabbar._compositeBuilder, Builder);
        var button = event.target;
        var close = button.findComponent("tab-close-button", Image, false);
        var select:Bool = true;
        if (close != null) {
            select = !close.hitTest(event.screenX, event.screenY);
        }
        if (select == true) {
            _tabbar.selectedIndex = builder._container.getComponentIndex(button);
        }
    }
}

//***********************************************************************************************************
// Composite Builder
//***********************************************************************************************************
@:dox(hide) @:noCompletion
@:allow(haxe.ui.components.TabBar)
@:access(haxe.ui.core.Component)
private class Builder extends CompositeBuilder {
    private var _tabbar:TabBar;
    private var _container:HBox;
    private var _filler:Box;

    public function new(tabbar:TabBar) {
        super(tabbar);
        _tabbar = tabbar;
        createContainer();
    }

    public override function create() {
        createContainer();
    }

    private function createContainer() {
        if (_filler == null) {
            _filler = new Box();
            _filler.id = "tabbar-filler";
            _filler.addClass("tabbar-filler");
            _filler.includeInLayout = false;
            _tabbar.addComponent(_filler);
        }
        if (_container == null) {
            _container = new HBox();
            _container.id = "tabbar-contents";
            _container.addClass("tabbar-contents");
            _tabbar.addComponent(_container);
        }
    }

    private function addTab(child:Component):Component {
        var button = createTabBarButton(child);
        var v = _container.addComponent(button);
        _tabbar.registerInternalEvents(Events, true);
        if (_tabbar.selectedIndex < 0) {
            _tabbar.selectedIndex = 0;
        }
        return v;
    }

    private function addTabAt(child:Component, index:Int):Component {
        var button = createTabBarButton(child);
        var v = _container.addComponentAt(button, index);
        _tabbar.registerInternalEvents(Events, true);
        if (_tabbar.selectedIndex < 0) {
            _tabbar.selectedIndex = 0;
        } else if (index <= _tabbar.selectedIndex) {
            _tabbar.selectedIndex++;
        }
        return v;

    }

    private var _childToButtonMap:Map<Component, TabBarButton> = new Map<Component, TabBarButton>();
    private function createTabBarButton(child:Component):TabBarButton {
        var button = new TabBarButton();

        button.addClass("tabbar-button");
        if (_tabbar.tabPosition == "bottom") {
            button.addClass(":bottom");
        }
        if (child.disabled == true) {
            button.disabled = child.disabled;
        }

        button.id = child.id;
        button.text = child.text;
        button.tooltip = child.tooltip;
        button.userData = child.userData;
        if ((child is Button)) {
            button.icon = cast(child, Button).icon;
        }
        button.closable = _tabbar.closable;
        if (_tabbar.buttonWidth != null) {
            button.componentWidth = _tabbar.buttonWidth;
        }
        if (_tabbar.buttonHeight != null) {
            button.componentHeight = _tabbar.buttonHeight;
        }
        if (child.styleNames != null) {
            button.styleNames = child.styleNames;
        }

        _childToButtonMap.set(child, button);
        child.registerEvent(UIEvent.PROPERTY_CHANGE, onButtonPropertyChange);

        return button;
    }

    private function onButtonPropertyChange(event:UIEvent) {
        if (event.data == "text") {
            var button = _childToButtonMap.get(event.target);
            if (button != null) {
                button.text = event.target.text;
            }
        }
    }

    private override function get_numComponents():Null<Int> {
        return _container.numComponents;
    }

    public override function addComponent(child:Component):Component {
        if (child != _container && child != _scrollLeft && child != _scrollRight && child != _filler && child.id != "tabbar-filler-left" && child.id != "tabbar-filler-right") {
            return addTab(child);
        }
        return null;
    }

    public override function addComponentAt(child:Component, index:Int):Component {
        if (child != _container && child != _scrollLeft && child != _scrollRight && child != _filler && child.id != "tabbar-filler-left" && child.id != "tabbar-filler-right") {
            return addTabAt(child, index);
        }
        return null;
    }

    public override function removeComponent(child:Component, dispose:Bool = true, invalidate:Bool = true):Component {
        if (child != _container && child != _scrollLeft && child != _scrollRight && child != _filler && child.id != "tabbar-filler-left" && child.id != "tabbar-filler-right") {
            var index = _container.getComponentIndex(child);
            if (index != -1) {
                _tabbar.removeTab(index);
                return child;
            }
        }
        return null;
    }

    public override function removeComponentAt(index:Int, dispose:Bool = true, invalidate:Bool = true):Component {
        var child = _container.getComponentAt(index);
        if (child != null) {
            _tabbar.removeTab(index);
        }
        return child;
    }

    public override function getComponentIndex(child:Component):Int {
        if (child != _container && child != _scrollLeft && child != _scrollRight && child != _filler && child.id != "tabbar-filler-left" && child.id != "tabbar-filler-right") {
            return _container.getComponentIndex(child);
        }
        return -1;
    }

    public override function setComponentIndex(child:Component, index:Int):Component {
        if (child != _container && child != _scrollLeft && child != _scrollRight && child != _filler && child.id != "tabbar-filler-left" && child.id != "tabbar-filler-right") {
            return _container.setComponentIndex(child, index);
        }
        return null;
    }

    public override function getComponentAt(index:Int):Component {
        return _container.getComponentAt(index);
    }

    public override function validateComponentLayout():Bool {
        if (_tabbar.native == true || _container == null) {
            return false;
        }

        if (_containerPosition == null) {
            _containerPosition = _tabbar.layout.paddingLeft;
        }

        if (_container.width > _tabbar.layout.usableWidth && _tabbar.layout.usableWidth > 0) {
            showScrollButtons();
            _container.left = _containerPosition;
        } else {
            hideScrollButtons();
            _containerPosition = null;
        }

        checkLeftRightFillers();

        return true;
    }

    private var _scrollLeft:Button;
    private var _scrollRight:Button;
    private function showScrollButtons() {
        if (_scrollLeft == null) {
            _scrollLeft = new Button();
            _scrollLeft.id = "tabbar-scroll-left";
            _scrollLeft.addClass("tabbar-scroll-left");
            _scrollLeft.includeInLayout = false;
            _scrollLeft.repeater = true;
            _tabbar.addComponent(_scrollLeft);
            _scrollLeft.onClick = function(e) {
                scrollLeft();
            }
        } else {
            _scrollLeft.show();
        }

        if (_scrollRight == null) {
            _scrollRight = new Button();
            _scrollRight.id = "tabbar-scroll-right";
            _scrollRight.addClass("tabbar-scroll-right");
            _scrollRight.includeInLayout = false;
            _scrollRight.repeater = true;
            _tabbar.addComponent(_scrollRight);
            _scrollRight.onClick = function(e) {
                scrollRight();
            }
        } else {
            _scrollRight.show();
        }
    }

    private var _containerPosition:Null<Float>;
    private static inline var SCROLL_INCREMENT:Int = 20; // todo: calc based on button width?
    private function scrollLeft() {
        if (_scrollLeft == null || _scrollLeft.hidden == true) {
            return;
        }

        var x = _container.left + SCROLL_INCREMENT;
        if (x > _tabbar.layout.paddingLeft) {
            x = _tabbar.layout.paddingLeft;
        }
        _containerPosition = x;
        _container.left = x;
        checkLeftRightFillers();
    }

    private function checkLeftRightFillers() {
        var leftFiller = _tabbar.findComponent("tabbar-filler-left", false);
        if (_containerPosition < 0) {
            if (leftFiller == null) {
                leftFiller = new Box();
                leftFiller.id = "tabbar-filler-left";
                leftFiller.addClass("tabbar-filler-left");
                leftFiller.includeInLayout = false;
                _tabbar.addComponent(leftFiller);
            }
            leftFiller.show();
        } else if (leftFiller != null) {
            leftFiller.hide();
        }

        var rightFiller = _tabbar.findComponent("tabbar-filler-right", false);
        var max = -(_container.width - _tabbar.width);
        if (_containerPosition > max) {
            if (rightFiller == null) {
                rightFiller = new Box();
                rightFiller.id = "tabbar-filler-right";
                rightFiller.addClass("tabbar-filler-right");
                rightFiller.includeInLayout = false;
                _tabbar.addComponent(rightFiller);
            }
            rightFiller.show();
        } else if (rightFiller != null) {
            rightFiller.hide();
        }
    }

    private function scrollRight() {
        if (_scrollLeft == null || _scrollLeft.hidden == true) {
            return;
        }

        var x = _container.left - SCROLL_INCREMENT;
        var max = -(_container.width - _tabbar.width);

        var left:Button = _tabbar.findComponent("tabbar-scroll-left", Button);
        var right:Button = _tabbar.findComponent("tabbar-scroll-right", Button);
        if (left != null && left.hidden == false) {
            max -= left.width;
            max -= _tabbar.layout.horizontalSpacing;
        }
        if (right != null && right.hidden == false) {
            max -= right.width;
        }

        if (x < max) {
            x = max;
        }
        _containerPosition = x;
        _container.left = x;
        checkLeftRightFillers();
    }

    private function hideScrollButtons() {
        if (_scrollLeft != null) {
            _scrollLeft.hide();
        }
        if (_scrollRight != null) {
            _scrollRight.hide();
        }
    }
    
    public override function applyStyle(style:Style) {
        super.applyStyle(style);
        
        haxe.ui.macros.ComponentMacros.cascadeStylesToList(Button, [
            color, fontName, fontSize, textAlign, fontBold, fontUnderline, fontItalic
        ]);
    }
}

@:composite(TabBarButtonLayout)
@:access(haxe.ui.components.Builder)
private class TabBarButton extends Button {
    private var _closable:Bool = false;
    public var closable(get, set):Bool;
    private function get_closable():Bool {
        return _closable;
        return _closable;
    }
    private function set_closable(value:Bool):Bool {
        if (_closable == value) {
            return value;
        }

        _closable = value;
        var existing = findComponent("tab-close-button", Image, false);

        var events:ButtonEvents = cast(this._internalEvents, ButtonEvents);
        events.recursiveStyling = false;
        if (_closable == true && existing == null) {
            iconPosition = "far-left";
            textAlign = "left";
            var image = new Image();
            image.id = "tab-close-button";
            image.addClass("tab-close-button");
            image.includeInLayout = false;
            image.onClick = onCloseClicked;
            addComponent(image);
        } else if (existing != null) {
            removeComponent(existing);
        }

        return value;
    }

    private function onCloseClicked(e:MouseEvent) {
        var tabbar = findAncestor(TabBar);

        var builder:Builder = cast(tabbar._compositeBuilder, Builder);
        var index = builder._container.getComponentIndex(this);
        var event = new UIEvent(UIEvent.BEFORE_CLOSE, index);
        tabbar.dispatch(event);
        if (event.canceled == false) {
            if (index != -1) {
                tabbar.removeTab(index);
            }
        }
    }
}

private class TabBarButtonLayout extends ButtonLayout {
    private override function repositionChildren() {
        super.repositionChildren();

        var image = _component.findComponent("tab-close-button", Image, false);
        if (image != null && image.hidden == false && component.componentWidth > 0) {
            image.top = Std.int((component.componentHeight / 2) - (image.componentHeight / 2)) + marginTop(image) - marginBottom(image);
            image.left = component.componentWidth - image.componentWidth - paddingRight + marginLeft(image) - marginRight(image);
        }
    }

    public override function calcAutoSize(exclusions:Array<Component> = null):Size {
        var size = super.calcAutoSize(exclusions);

        var image = _component.findComponent("tab-close-button", Image, false);
        if (image != null && image.hidden == false) {
            size.width += image.width + horizontalSpacing;
        }

        return size;
    }
}