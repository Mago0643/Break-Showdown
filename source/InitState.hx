package;

import flixel.FlxG;
import flixel.util.FlxTimer;
import flixel.tweens.FlxTween;
import flixel.FlxSprite;

class InitState extends MusicBeatState
{
    var canSkip:Bool = false;

    override function create()
    {
        var spr = new FlxSprite().loadGraphic(Paths.image("newgrounds_logo.png"));
        spr.screenCenter();
        spr.alpha = 0;
        add(spr);

        new FlxTimer().start(2, function(a:FlxTimer)
        {
            FlxTween.tween(spr, {alpha: 1}, 2, {onComplete: function(b:FlxTween)
                {
                    FlxTween.tween(spr, {alpha: 0}, 2, {startDelay: 1, onComplete: function(self:FlxTween)
                        {
                            FlxG.switchState(new TitleState());
                        }
                    });
                }
            });
        });

        super.create();
    }

    override function update(elapsed:Float)
    {
        if (canSkip)
        {
            var key = FlxG.keys.justPressed;
            if (key.ENTER || key.SPACE || key.ESCAPE)
                FlxG.switchState(new TitleState());
        }
        super.update(elapsed);
    }
}