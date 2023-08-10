package;

import flixel.system.FlxAssets.FlxGraphicAsset;
import flixel.util.FlxSpriteUtil;
#if desktop
import Discord.DiscordClient;
#end
import flixel.FlxG;
import flixel.FlxObject;
import flixel.FlxSprite;
import flixel.FlxCamera;
import flixel.addons.transition.FlxTransitionableState;
import flixel.effects.FlxFlicker;
import flixel.graphics.frames.FlxAtlasFrames;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.text.FlxText;
import flixel.math.FlxMath;
import flixel.tweens.FlxEase;
import flixel.tweens.FlxTween;
import flixel.util.FlxColor;
import lime.app.Application;
import Achievements;
import editors.MasterEditorMenu;
import flixel.input.keyboard.FlxKey;

using StringTools;

class MainMenuState extends MusicBeatState
{
	public static var psychEngineVersion:String = '0.6.3'; //This is also used for Discord RPC
	public static var curSelected:Int = 0;

	var menuItems:FlxTypedGroup<FlxSprite>;
	var camWalls:FlxCamera;
	private var camGame:FlxCamera;
	private var camAchievement:FlxCamera;

	var cool_thing:FlxSprite;
	
	var optionShit:Array<String> = [
		'play',
		#if MODS_ALLOWED 'mods', #end
		#if ACHIEVEMENTS_ALLOWED 'awards', #end
		'credits',
		'options'
	];
	var optionColor:Array<FlxGraphicAsset> = [
		Paths.image("menuBG"),
		Paths.image("menuBGMagenta"),
		Paths.image("menuBGBlue")
	];

	var menui:FlxSprite;
	var cacheUI = [
		Paths.getSparrowAtlas("ui/menu/play-ui", "hellojeff"),
		Paths.getSparrowAtlas("ui/menu/credits-ui", "hellojeff"),
		Paths.getSparrowAtlas("ui/menu/options-ui", "hellojeff")
	];

	var magenta:FlxSprite;
	var camFollow:FlxObject;
	var camFollowPos:FlxObject;
	var debugKeys:Array<FlxKey>;

	var bg:FlxSprite;
	var bg_mag:FlxSprite;
	var bg_blue:FlxSprite;

	override function create()
	{
		#if MODS_ALLOWED
		Paths.pushGlobalMods();
		#end
		WeekData.loadTheFirstEnabledMod();

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end
		debugKeys = ClientPrefs.copyKey(ClientPrefs.keyBinds.get('debug_1'));
		camGame = new FlxCamera();
		camAchievement = new FlxCamera();
		camAchievement.bgColor.alpha = 0;

		FlxG.cameras.reset(camGame);
		FlxG.cameras.add(camAchievement, false);
		FlxG.cameras.setDefaultDrawTarget(camGame, true);

		transIn = FlxTransitionableState.defaultTransIn;
		transOut = FlxTransitionableState.defaultTransOut;

		persistentUpdate = persistentDraw = true;

		var yScroll:Float = Math.max(0.25 - (0.05 * (optionShit.length - 4)), 0.1);

		var func:(spr:FlxSprite) -> Void = function(spr:FlxSprite)
		{
			spr.scrollFactor.set(0, yScroll);
			spr.setGraphicSize(Std.int(spr.width * 1.175));
			spr.updateHitbox();
			spr.screenCenter();
			spr.antialiasing = ClientPrefs.globalAntialiasing;
		};

		bg = new FlxSprite(-80).loadGraphic(Paths.image('menuBG'));
		func(bg);
		add(bg);

		bg_blue = new FlxSprite(-80).loadGraphic(Paths.image('menuBGBlue'));
		func(bg_blue);
		bg_blue.alpha = 0;
		add(bg_blue);

		bg_mag = new FlxSprite(-80).loadGraphic(Paths.image('menuBGMagenta'));
		func(bg_mag);
		bg_mag.alpha = 0;
		add(bg_mag);

		camFollow = new FlxObject(0, 0, 1, 1);
		camFollowPos = new FlxObject(0, 0, 1, 1);
		add(camFollow);
		add(camFollowPos);

		/*magenta = new FlxSprite(-80).loadGraphic(Paths.image('menuDesat'));
		magenta.scrollFactor.set(0, yScroll);
		magenta.setGraphicSize(Std.int(magenta.width * 1.175));
		magenta.updateHitbox();
		magenta.screenCenter();
		magenta.visible = false;
		magenta.antialiasing = ClientPrefs.globalAntialiasing;
		magenta.color = 0xFFfd719b;
		add(magenta);*/

		cool_thing = new FlxSprite().loadGraphic(Paths.image("ui/menu/cool", "hellojeff"));
		cool_thing.antialiasing = true;
		cool_thing.scrollFactor.set();
		add(cool_thing);

		menui = new FlxSprite(FlxG.width / 2 + 100);
		menui.frames = cacheUI[curSelected];
		menui.animation.addByPrefix("idle-"+optionShit[curSelected], optionShit[curSelected], 24, true);
		menui.animation.play("idle-"+optionShit[curSelected], true);
		menui.animation.callback = function(name:String, fn:Int, fi:Int)
		{
			switch (name)
			{
				case "idle-play":
					menui.x = FlxG.width / 2 + 50;
				default:
					menui.x = FlxG.width / 2 + 100;
			}
		};
		menui.antialiasing = true;
		menui.setGraphicSize(Std.int(menui.width*0.9));
		menui.updateHitbox();
		menui.screenCenter(Y);
		menui.scrollFactor.set();
		add(menui);
		
		// magenta.scrollFactor.set();

		menuItems = new FlxTypedGroup<FlxSprite>();
		add(menuItems);

		var scale:Float = 1;
		/*if(optionShit.length > 6) {
			scale = 6 / optionShit.length;
		}*/

		for (i in 0...optionShit.length)
		{
			var offset:Float = 108 - (Math.max(optionShit.length, 4) - 4) * 80;
			var menuItem:FlxSprite = new FlxSprite(50, (i * 200)  + offset);
			menuItem.scale.x = scale;
			menuItem.scale.y = scale;
			switch (optionShit[i])
			{
				case "play":
					menuItem.frames = Paths.getSparrowAtlas('ui/menu/play', 'hellojeff');
				default:
					menuItem.frames = Paths.getSparrowAtlas('mainmenu/menu_' + optionShit[i]);
					menuItem.y += 25;
			}
			menuItem.animation.addByPrefix('idle', optionShit[i] + " basic", 24);
			menuItem.animation.addByPrefix('selected', optionShit[i] + " white", 24);
			menuItem.animation.play('idle');
			menuItem.ID = i;
			menuItems.add(menuItem);
			var scr:Float = (optionShit.length - 4) * 0.135;
			if(optionShit.length < 6) scr = 0;
			menuItem.scrollFactor.set(0, scr);
			menuItem.antialiasing = ClientPrefs.globalAntialiasing;
			//menuItem.setGraphicSize(Std.int(menuItem.width * 0.58));
			menuItem.updateHitbox();
		}

		FlxG.camera.follow(camFollowPos, null, 1);

		var versionShit:FlxText = new FlxText(12, FlxG.height - 44, 0, "Psych Engine v" + psychEngineVersion, 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(CoolUtil.defaultFont, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);
		var versionShit:FlxText = new FlxText(12, FlxG.height - 24, 0, "Friday Night Funkin' v" + Application.current.meta.get('version'), 12);
		versionShit.scrollFactor.set();
		versionShit.setFormat(CoolUtil.defaultFont, 16, FlxColor.WHITE, LEFT, FlxTextBorderStyle.OUTLINE, FlxColor.BLACK);
		add(versionShit);

		// NG.core.calls.event.logEvent('swag').send();

		changeItem();

		#if ACHIEVEMENTS_ALLOWED
		Achievements.loadAchievements();
		var leDate = Date.now();
		if (leDate.getDay() == 5 && leDate.getHours() >= 18) {
			var achieveID:Int = Achievements.getAchievementIndex('friday_night_play');
			if(!Achievements.isAchievementUnlocked(Achievements.achievementsStuff[achieveID][2])) { //It's a friday night. WEEEEEEEEEEEEEEEEEE
				Achievements.achievementsMap.set(Achievements.achievementsStuff[achieveID][2], true);
				giveAchievement();
				ClientPrefs.saveSettings();
			}
		}
		#end

		super.create();
	}

	#if ACHIEVEMENTS_ALLOWED
	// Unlocks "Freaky on a Friday Night" achievement
	function giveAchievement() {
		add(new AchievementObject('friday_night_play', camAchievement));
		FlxG.sound.play(Paths.sound('confirmMenu'), 0.7);
		trace('Giving achievement "friday_night_play"');
	}
	#end

	var selectedSomethin:Bool = false;

	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.8)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
			if(FreeplayState.vocals != null) FreeplayState.vocals.volume += 0.5 * elapsed;
		}

		var lerpVal:Float = CoolUtil.boundTo(elapsed * 7.5, 0, 1);
		camFollowPos.setPosition(FlxMath.lerp(camFollowPos.x, camFollow.x, lerpVal), FlxMath.lerp(camFollowPos.y, camFollow.y, lerpVal));

		if (!selectedSomethin)
		{
			if (controls.UI_UP_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(-1);
			}

			if (controls.UI_DOWN_P)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'));
				changeItem(1);
			}

			if (controls.BACK)
			{
				selectedSomethin = true;
				FlxG.sound.play(Paths.sound('cancelMenu'));
				MusicBeatState.switchState(new TitleState());
			}

			if (controls.ACCEPT)
			{
				if (optionShit[curSelected] == 'donate')
				{
					CoolUtil.browserLoad('https://ninja-muffin24.itch.io/funkin');
				}
				else
				{
					selectedSomethin = true;
					FlxG.sound.play(Paths.sound('confirmMenu'));

					// if(ClientPrefs.flashing) FlxFlicker.flicker(magenta, 1.1, 0.15, false);
					FlxTween.tween(cool_thing, {x: -cool_thing.width}, 1.1, {ease: FlxEase.quadIn});

					menui.angle = 360;
					FlxTween.tween(menui, {angle: 0}, 1, {ease: FlxEase.expoOut});
					FlxTween.tween(menui.scale, {x: 0, y: 0}, 1, {ease: FlxEase.expoIn});

					menuItems.forEach(function(spr:FlxSprite)
					{
						if (curSelected != spr.ID)
						{
							FlxTween.tween(spr, {x: -spr.width - 50}, 1, {
								ease: FlxEase.quadIn,
								onComplete: function(twn:FlxTween)
								{
									spr.kill();
								}
							});
						}
						else
						{
							FlxTween.tween(spr, {x: (FlxG.width - spr.width) / 2}, 1.5, {ease: FlxEase.expoOut});
							FlxFlicker.flicker(spr, 1.5, 0.06, false, false, function(f:FlxFlicker)
							{
								var daChoice:String = optionShit[curSelected];

								switch (daChoice)
								{
									case 'play':
										MusicBeatState.switchState(new FreeplayState());
									#if MODS_ALLOWED
									case 'mods':
										MusicBeatState.switchState(new ModsMenuState());
									#end
									case 'awards':
										MusicBeatState.switchState(new AchievementsMenuState());
									case 'credits':
										MusicBeatState.switchState(new CreditsState());
									case 'options':
										LoadingState.loadAndSwitchState(new options.OptionsState());
								}
							});
						}
					});
				}
			}
			#if desktop
			else if (FlxG.keys.anyJustPressed(debugKeys))
			{
				selectedSomethin = true;
				MusicBeatState.switchState(new MasterEditorMenu());
			}
			#end
		}

		super.update(elapsed);
	}

	function changeItem(huh:Int = 0)
	{
		curSelected += huh;

		if (curSelected >= menuItems.length)
			curSelected = 0;
		if (curSelected < 0)
			curSelected = menuItems.length - 1;

		FlxTween.cancelTweensOf(bg);
		FlxTween.cancelTweensOf(bg_mag);
		FlxTween.cancelTweensOf(bg_blue);

		switch (curSelected % 3)
		{
			case 0:
				FlxTween.tween(bg, {alpha: 1}, 1, {ease: FlxEase.expoOut});
				FlxTween.tween(bg_mag, {alpha: 0}, 1, {ease: FlxEase.expoOut});
				FlxTween.tween(bg_blue, {alpha: 0}, 1, {ease: FlxEase.expoOut});
			case 1:
				FlxTween.tween(bg, {alpha: 0}, 1, {ease: FlxEase.expoOut});
				FlxTween.tween(bg_mag, {alpha: 1}, 1, {ease: FlxEase.expoOut});
				FlxTween.tween(bg_blue, {alpha: 0}, 1, {ease: FlxEase.expoOut});
			case 2:
				FlxTween.tween(bg, {alpha: 0}, 1, {ease: FlxEase.expoOut});
				FlxTween.tween(bg_mag, {alpha: 0}, 1, {ease: FlxEase.expoOut});
				FlxTween.tween(bg_blue, {alpha: 1}, 1, {ease: FlxEase.expoOut});
		}

		menui.frames = cacheUI[curSelected];
		menui.animation.addByPrefix("idle-"+optionShit[curSelected], optionShit[curSelected], 24, true);
		menui.animation.play("idle-"+optionShit[curSelected], true);

		menuItems.forEach(function(spr:FlxSprite)
		{
			spr.animation.play('idle');
			spr.updateHitbox();

			if (spr.ID == curSelected)
			{
				spr.animation.play('selected');
				var add:Float = 0;
				if(menuItems.length > 4) {
					add = menuItems.length * 8;
				}
				camFollow.setPosition(spr.getGraphicMidpoint().x, spr.getGraphicMidpoint().y - add);
				spr.centerOffsets();
				spr.offset.x = 0;
			}
		});
	}
}
