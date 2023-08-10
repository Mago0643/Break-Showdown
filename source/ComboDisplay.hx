package;

import sys.io.File;
import haxe.Json;
import flixel.FlxSprite;
import flixel.group.FlxSpriteGroup;

/**
* A Class That Controlls Number Offsets.
*/
typedef ComboOffset = {
    pos_0:Array<Float>,
    pos_1:Array<Float>,
    pos_2:Array<Float>,
    pos_3:Array<Float>,
    pos_4:Array<Float>,
    pos_5:Array<Float>,
    pos_6:Array<Float>,
    pos_7:Array<Float>,
    pos_8:Array<Float>,
    pos_9:Array<Float>
}
/**
 * A FNF Combo System. `(idk who made sprites first or idea)`
 * 
 * anyways this code is by me `(Lego0_77)` and you can use this if you credit me.
 *
 * Heres is an example.
 * ```haxe
 * var plrCom:Int = 2;
 * var spr = new ComboDisplay();
 * spr.setPosition(100, 100);
 * add(spr);
 *
 * spr.showCombo(plrCom);
 * ```
 */
class ComboDisplay extends FlxSpriteGroup
{
    @:noCompletion
        private var _num0(default, null):FlxSprite;
    @:noCompletion
        private var _num1(default, null):FlxSprite;
    @:noCompletion
        private var _text(default, null):FlxSprite;
    @:noCompletion
        private var _offsets:ComboOffset;

    /**
    * Creates A New ComboDisplay Object.
    */
    public function new()
    {
        super();

        reloadOffset();

        _num0 = new FlxSprite();
        _num0.frames = Paths.getSparrowAtlas("ui/game/Note_Combo_Assets", "hellojeff");
        for (I in 0...10) _num0.animation.addByPrefix(I+"", I+"", 24, false);
        _num0.animation.finishCallback = function (name:String) _num0.visible = false;
        _num0.antialiasing = ClientPrefs.globalAntialiasing;
        _num0.visible = false;
        _num0.setGraphicSize(Std.int(_num0.width*0.75));
        _num0.updateHitbox();
        add(_num0);

        _num1 = new FlxSprite();
        _num1.frames = Paths.getSparrowAtlas("ui/game/Note_Combo_Assets", "hellojeff");
        for (I in 0...10) _num1.animation.addByPrefix(I+"", I+"", 24, false);
        _num1.animation.finishCallback = function (name:String) _num1.visible = false;
        _num1.antialiasing = ClientPrefs.globalAntialiasing;
        _num1.visible = false;
        _num1.setGraphicSize(Std.int(_num1.width*0.75));
        _num1.updateHitbox();
        add(_num1);

        _text = new FlxSprite(-150, -100);
        _text.frames = Paths.getSparrowAtlas("ui/game/Note_Combo_Assets", "hellojeff");
        _text.animation.addByPrefix("text", "A-NoteCombo", 24, false);
        _text.animation.finishCallback = function (name:String) _text.visible = false;
        _text.antialiasing = ClientPrefs.globalAntialiasing;
        _text.visible = false;
        _text.setGraphicSize(Std.int(_text.width*0.75));
        _text.updateHitbox();
        add(_text);
    }

    /**
    * Reloads Offset by Reading JSON File.
    * @param path The path where JSON is.
    */
    public function reloadOffset(?path:String = "assets/hellojeff/images/ui/game/Combo_offsets.json")
    {
        _offsets = Json.parse(File.getContent(path));
    }

    /**
    * Shows Combo Sprites.
    */
    public function showCombo(combo:Int)
    {
        if (combo > 0)
        {
            // stolen from combo showing shit
            var seperatedScore:Array<Int> = [];
            seperatedScore.push(Math.floor(combo / 10) % 10);
            seperatedScore.push(combo % 10);

            _text.animation.play("text", true);
            _num0.animation.play(seperatedScore[0]+"", true);
            _num1.animation.play(seperatedScore[1]+"", true);

            // idk why FlxSpriteGroup dosen't update each sprite's position
            _num0.setPosition(this.x, this.y);
            _num1.setPosition(_num0.x+_num0.width-35, this.y-58);
            _num0.x += Reflect.getProperty(_offsets, "pos_"+seperatedScore[0])[0];
            _num0.y += Reflect.getProperty(_offsets, "pos_"+seperatedScore[0])[1];
            _num0.visible = true;

            _text.visible = true;
            _num1.visible = true;
        } else {
            trace("combo is nil");
        }
    }
}