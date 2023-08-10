package editors;

import flixel.text.FlxText;
import flixel.FlxG;

class ComboDisplayTestState extends MusicBeatState
{
    var combo:Int = 50;
    var sprite:ComboDisplay;
    override function create()
    {
        sprite = new ComboDisplay();
        sprite.screenCenter();
        add(sprite);

        var text = new FlxText(10, 100, 0, "Press 'R' To Reload Script.\nPress 'Esc' to Retrun To Menu.\nPress 'Space' to Play Animation.\nPress Left or Right to add/remove combo.", 16);
        add(text);

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (FlxG.keys.justPressed.R)
            sprite.reloadOffset();
        if (FlxG.keys.justPressed.ESCAPE)
            MusicBeatState.switchState(new editors.MasterEditorMenu());
        if (FlxG.keys.justPressed.SPACE)
            sprite.showCombo(combo);
        if (FlxG.keys.justPressed.LEFT)
        {
            combo--;
            if (combo <= 0) combo = 1;
        }
        if (FlxG.keys.justPressed.RIGHT)
        {
            combo++;
            if (combo >= 100) combo = 99;
        }

        super.update(elapsed);
    }
}