package;

import flixel.util.FlxColor;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

/**
 * A Class That Supports Cinematic Bars.
 *
 * This Addes Black Bars on Top/Bottom of the Screen.
 *
 * Also Can Adjust Bar `height` by Adjusting `bar_height`.
 *
 * @author Lego0_77
 */
class CinematicBar extends FlxSpriteGroup
{
    // why
    @:noCompletion @:noPrivateAccess
    private var _init:Bool = false;

    /**
    * The Sprite of Upper Bar.
    *
    * Height Changing Controlled by `bar_height`.
    */
    public var upperBar(default, null):FlxSprite;
    /**
    * The Sprite of Lower Bar.
    *
    * Height Changing Controlled by `bar_height`.
    */
    public var lowerBar(default, null):FlxSprite;
    /**
    * The Variable That Controlls Lower/Upper Bar's `Height`.
    */
    public var bar_height(default, set):Int = 100;
    function set_bar_height(b:Int):Int
    {
        if (_init)
        {
            upperBar.setGraphicSize(FlxG.width, b);
            lowerBar.setGraphicSize(FlxG.width, b);
            lowerBar.y = FlxG.height - b;
        }
        return b;
    }
    
    /**
    * Addes A Bar.
    */
    public function new(bar_height:Int = 100, ?X:Float, ?Y:Float)
    {
        super(X,Y);

        upperBar = new FlxSprite().makeGraphic(FlxG.width, bar_height, FlxColor.BLACK);
        lowerBar = new FlxSprite(0,FlxG.height-bar_height).makeGraphic(FlxG.width, bar_height, FlxColor.BLACK);

        add(upperBar);
        add(lowerBar);

        this.bar_height = bar_height;

        _init = true;
    }
}