package;

import flixel.util.FlxTimer;
import flixel.graphics.FlxGraphic;
import flixel.effects.FlxFlicker;
import Shaders.BlurShader;
import flixel.tweens.FlxEase;
import openfl.filters.ShaderFilter;
import Shaders.BlurEffect;
import flixel.FlxCamera;
import flixel.input.keyboard.FlxKey;
#if desktop
import Discord.DiscordClient;
#end
import editors.ChartingState;
import flash.text.TextField;
import flixel.FlxG;
import flixel.FlxSprite;
import flixel.addons.display.FlxGridOverlay;
import flixel.addons.transition.FlxTransitionableState;
import flixel.group.FlxGroup.FlxTypedGroup;
import flixel.math.FlxMath;
import flixel.text.FlxText;
import flixel.util.FlxColor;
import flixel.tweens.FlxTween;
import lime.utils.Assets;
import flixel.system.FlxSound;
import openfl.utils.Assets as OpenFlAssets;
import WeekData;
#if MODS_ALLOWED
import sys.FileSystem;
#end

using StringTools;

class FreeplayState extends MusicBeatState
{
	var songs:Array<SongMetadata> = [];

	var selector:FlxText;
	private static var curSelected:Int = 0;
	var curDifficulty:Int = -1;
	private static var lastDifficultyName:String = '';

	var camSel:FlxCamera;
	var camDisk:FlxCamera;
	var camOther:FlxCamera; // why this cam not workin
	var trans:FlxCamera;

	var isDisked:Bool = false;

	/*var downBar:FlxSprite = new FlxSprite(-5,FlxG.height-85).makeGraphic(FlxG.width+10, 90, FlxColor.BLACK);
	var upBar:FlxSprite = new FlxSprite(-5,-5).makeGraphic(FlxG.width + 10, 90, FlxColor.BLACK);*/
	var bars:CinematicBar;
	var disk:FlxSprite;
	var disket:FlxSprite;
	var escSpr:FlxSprite;
	var infoTxt:FlxText;
	var fcSpr:FlxSprite;

	var scoreBG:FlxSprite;
	var scoreText:FlxText;
	var diffText:FlxText;
	var lerpScore:Int = 0;
	var lerpRating:Float = 0;
	var intendedScore:Int = 0;
	var intendedRating:Float = 0;
	var canUseDiff:Bool = false;

	private var grpSongs:FlxTypedGroup<Alphabet>;
	private var curPlaying:Bool = false;

	private var iconArray:Array<HealthIcon> = [];

	var bg:FlxSprite;
	var intendedColor:Int;
	var colorTween:FlxTween;
	var blurShad:BlurEffect;
	var diffSpr:FlxSprite;
	var leftSpr:FlxSprite;
	var rightSpr:FlxSprite;

	var bgBlk:FlxSprite;

	override function create()
	{
		//Paths.clearStoredMemory();
		//Paths.clearUnusedMemory();
		
		persistentUpdate = true;

		camSel=new FlxCamera();
		camDisk=new FlxCamera();
		camOther=new FlxCamera();
		trans = new FlxCamera();
		camDisk.bgColor.alpha = 0;
		camOther.bgColor.alpha = 0;
		trans.bgColor.alpha = 0;
		FlxG.cameras.reset(camSel);
		FlxG.cameras.add(camDisk, false);
		FlxG.cameras.add(camOther, false);
		FlxG.cameras.add(trans, false);
		FlxG.cameras.setDefaultDrawTarget(camSel, true);

		if (FlxG.save.data.fcList == null) FlxG.save.data.fcList = [];
		if (FlxG.save.data.fcDiff == null) FlxG.save.data.fcDiff = [];

		PlayState.isStoryMode = false;
		WeekData.reloadWeekFiles(false);

		#if desktop
		// Updating Discord Rich Presence
		DiscordClient.changePresence("In the Menus", null);
		#end

		for (i in 0...WeekData.weeksList.length) {
			if(weekIsLocked(WeekData.weeksList[i])) continue;

			var leWeek:WeekData = WeekData.weeksLoaded.get(WeekData.weeksList[i]);
			var leSongs:Array<String> = [];
			var leChars:Array<String> = [];

			for (j in 0...leWeek.songs.length)
			{
				leSongs.push(leWeek.songs[j][0]);
				leChars.push(leWeek.songs[j][1]);
			}

			WeekData.setDirectoryFromWeek(leWeek);
			for (song in leWeek.songs)
			{
				var colors:Array<Int> = song[2];
				if(colors == null || colors.length < 3)
				{
					colors = [146, 113, 253];
				}
				addSong(song[0], i, song[1], FlxColor.fromRGB(colors[0], colors[1], colors[2]));
			}
		}
		WeekData.loadTheFirstEnabledMod();

		/*		//KIND OF BROKEN NOW AND ALSO PRETTY USELESS//

		var initSonglist = CoolUtil.coolTextFile(Paths.txt('freeplaySonglist'));
		for (i in 0...initSonglist.length)
		{
			if(initSonglist[i] != null && initSonglist[i].length > 0) {
				var songArray:Array<String> = initSonglist[i].split(":");
				addSong(songArray[0], 0, songArray[1], Std.parseInt(songArray[2]));
			}
		}*/

		bg = new FlxSprite().loadGraphic(Paths.image('menuDesat'));
		bg.antialiasing = ClientPrefs.globalAntialiasing;
		add(bg);
		bg.screenCenter();

		grpSongs = new FlxTypedGroup<Alphabet>();
		add(grpSongs);

		for (i in 0...songs.length)
		{
			var songText:Alphabet = new Alphabet(90, 320, songs[i].songName, true);
			songText.isMenuItem = true;
			songText.targetY = i - curSelected;
			grpSongs.add(songText);

			var maxWidth = 980;
			if (songText.width > maxWidth)
			{
				songText.scaleX = maxWidth / songText.width;
			}
			songText.snapToPosition();

			Paths.currentModDirectory = songs[i].folder;
			var icon:HealthIcon = new HealthIcon(songs[i].songCharacter);
			icon.sprTracker = songText;

			// using a FlxGroup is too much fuss!
			iconArray.push(icon);
			add(icon);

			// songText.x += 40;
			// DONT PUT X IN THE FIRST PARAMETER OF new ALPHABET() !!
			// songText.screenCenter(X);
		}
		WeekData.setDirectoryFromWeek();
		bars = new CinematicBar(90);
		for (i in 0...bars.length)
		{
			bars.members[i].x -= 5;
			bars.members[i].setGraphicSize(Std.int(bars.members[i].width) + 10, Std.int(bars.members[i].height) + 10);
		}
		add(bars);

		scoreText = new FlxText(FlxG.width * 0.7, 5, 0, "", 32);
		scoreText.setFormat(CoolUtil.defaultFont, 32, FlxColor.WHITE, RIGHT);

		scoreBG = new FlxSprite(scoreText.x - 6, 0).makeGraphic(1, 66, 0xFF000000);
		scoreBG.alpha = 0.6;
		//add(scoreBG);

		diffText = new FlxText(scoreText.x, scoreText.y + 36, 0, "", 24);
		diffText.font = scoreText.font;
		// add(diffText);

		add(scoreText);

		if(curSelected >= songs.length) curSelected = 0;
		bg.color = songs[curSelected].color;
		intendedColor = bg.color;

		// if(lastDifficultyName == '')
		// {
			lastDifficultyName = CoolUtil.defaultDifficulty;
		// }
		curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(lastDifficultyName)));
		

		fcSpr = new FlxSprite(25, bars.lowerBar.y - 100);
		changeSelection();
		changeDiff();

		// var swag:Alphabet = new Alphabet(1, 0, "swag");

		// JUST DOIN THIS SHIT FOR TESTING!!!
		/* 
			var md:String = Markdown.markdownToHtml(Assets.getText('CHANGELOG.md'));

			var texFel:TextField = new TextField();
			texFel.width = FlxG.width;
			texFel.height = FlxG.height;
			// texFel.
			texFel.htmlText = md;

			FlxG.stage.addChild(texFel);

			// scoreText.textField.htmlText = md;

			trace(md);
		 */

		var textBG:FlxSprite = new FlxSprite(0, FlxG.height - 26).makeGraphic(FlxG.width, 26, 0xFF000000);
		textBG.alpha = 0.6;
		//add(textBG);

		#if PRELOAD_ALL
		var leText:String = "Press SPACE to listen to the Song / Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 16;
		#else
		var leText:String = "Press CTRL to open the Gameplay Changers Menu / Press RESET to Reset your Score and Accuracy.";
		var size:Int = 18;
		#end
		var text:FlxText = new FlxText(textBG.x, textBG.y + 4, FlxG.width, leText, size);
		text.setFormat(CoolUtil.defaultFont, size, FlxColor.WHITE, RIGHT);
		text.scrollFactor.set();
		add(text);

		bgBlk = new FlxSprite(-10, 10).makeGraphic(FlxG.width + 20, FlxG.height + 20, FlxColor.BLACK);
		bgBlk.cameras = [camDisk];
		bgBlk.alpha = 0;
		add(bgBlk);

		diffSpr = new FlxSprite(FlxG.width * 0.7, 41).loadGraphic(Paths.image("menudifficulties/hard"));
		diffSpr.antialiasing = ClientPrefs.globalAntialiasing;
		diffSpr.cameras = [camDisk];
		diffSpr.alpha = 0;
		add(diffSpr);

		leftSpr = new FlxSprite(diffSpr.x - 50, diffSpr.y);
		leftSpr.frames = Paths.getSparrowAtlas("campaign_menu_UI_assets");
		leftSpr.animation.addByPrefix("idle", "arrow left", 24);
		leftSpr.animation.addByPrefix("press", "arrow push left", 24);
		leftSpr.animation.play("idle", true);
		leftSpr.antialiasing = ClientPrefs.globalAntialiasing;
		leftSpr.setGraphicSize(Std.int(leftSpr.width * 0.75));
		leftSpr.updateHitbox();
		leftSpr.alpha = 0;
		leftSpr.cameras = [camDisk];
		add(leftSpr);

		// what the f
		rightSpr = new FlxSprite(diffSpr.x + diffSpr.width + 10, diffSpr.y);
		rightSpr.frames = Paths.getSparrowAtlas("campaign_menu_UI_assets");
		rightSpr.animation.addByPrefix("idle", "arrow right", 24);
		rightSpr.animation.addByPrefix("press", "arrow push right", 24);
		rightSpr.animation.play("idle", true);
		rightSpr.antialiasing = ClientPrefs.globalAntialiasing;
		rightSpr.setGraphicSize(Std.int(rightSpr.width * 0.75));
		rightSpr.updateHitbox();
		rightSpr.alpha = 0;
		rightSpr.cameras = [camDisk];
		add(rightSpr);

		escSpr = new FlxSprite(10,10).loadGraphic(Paths.image("ui/free/esc", "hellojeff"));
		escSpr.antialiasing = ClientPrefs.globalAntialiasing;
		escSpr.alpha = 0;
		escSpr.cameras = [camDisk];
		add(escSpr);

		disk = new FlxSprite().loadGraphic(Paths.image("ui/free/disk", "hellojeff"));
		disk.antialiasing = ClientPrefs.globalAntialiasing;
		disk.setGraphicSize(Std.int(disk.width * 0.5));
		disk.updateHitbox();
		disk.setPosition(-disk.width-5, 100);
		disk.cameras = [camDisk];
		add(disk);

		disket = new FlxSprite().loadGraphic(Paths.image("ui/free/disket", "hellojeff"));
		disket.antialiasing = ClientPrefs.globalAntialiasing;
		disket.setGraphicSize(Std.int(disk.width * 0.5));
		disket.updateHitbox();
		disket.setPosition(FlxG.width, 100);
		disket.cameras = [camDisk];
		add(disket);

		var firstKey = FlxKey.toStringMap.get(ClientPrefs.keyBinds.get("accept")[0]);
		var secondKey = FlxKey.toStringMap.get(ClientPrefs.keyBinds.get("accept")[1]);
		infoTxt = new FlxText(0,0,0,'Press "${firstKey}" or "${secondKey}" Again To Start!',32);
		infoTxt.font = CoolUtil.defaultFont;
		infoTxt.alpha = 0;
		infoTxt.screenCenter();
		infoTxt.y += 100;
		infoTxt.cameras = [camDisk];
		add(infoTxt);
		fcSpr.cameras = [camDisk];
		fcSpr.alpha = 0;
		add(fcSpr);

		blurShad = new BlurEffect();
		camSel.setFilters([new ShaderFilter(blurShad.shad)]);

		super.create();
	}

	override function closeSubState() {
		changeSelection(0, false);
		persistentUpdate = true;
		super.closeSubState();
	}

	function checkFC()
	{
		var song:Array<String> = FlxG.save.data.fcList;
		var diff:Array<Int> = FlxG.save.data.fcDiff;
		fcSpr.loadGraphic(Paths.image("ui/free/fcn", "hellojeff"));
		for (i in 0...song.length)
		{
			fcSpr.loadGraphic((song[i].toLowerCase() == songs[curSelected].songName.toLowerCase() && diff[i] == curDifficulty ? Paths.image("ui/free/fc", "hellojeff") : Paths.image("ui/free/fcn", "hellojeff")));
		}
	}

	public function addSong(songName:String, weekNum:Int, songCharacter:String, color:Int)
	{
		songs.push(new SongMetadata(songName, weekNum, songCharacter, color));
	}

	function weekIsLocked(name:String):Bool {
		var leWeek:WeekData = WeekData.weeksLoaded.get(name);
		return (!leWeek.startUnlocked && leWeek.weekBefore.length > 0 && (!StoryMenuState.weekCompleted.exists(leWeek.weekBefore) || !StoryMenuState.weekCompleted.get(leWeek.weekBefore)));
	}

	/*public function addWeek(songs:Array<String>, weekNum:Int, weekColor:Int, ?songCharacters:Array<String>)
	{
		if (songCharacters == null)
			songCharacters = ['bf'];

		var num:Int = 0;
		for (song in songs)
		{
			addSong(song, weekNum, songCharacters[num]);
			this.songs[this.songs.length-1].color = weekColor;

			if (songCharacters.length != 1)
				num++;
		}
	}*/

	var instPlaying:Int = -1;
	public static var vocals:FlxSound = null;
	var holdTime:Float = 0;
	var stopSpamming:Bool = false;
	var blurVal:Float = 0.0;
	var diskSpd:Float = 2.5;
	override function update(elapsed:Float)
	{
		if (FlxG.sound.music.volume < 0.7)
		{
			FlxG.sound.music.volume += 0.5 * FlxG.elapsed;
		}

		if (trans != null) CustomFadeTransition.nextCamera = trans; // putting this as create() won't work

		if (blurShad != null)
		{
			var burp = cast (blurShad.shad, BlurShader);
			burp.iTime.value[0] += elapsed;
			burp.blurAmount.value = [blurVal];
		}

		if (disk != null)
		{
			disk.angle += diskSpd;
			if (disk.angle >= 360) disk.angle = disk.angle - 360;
		}

		lerpScore = Math.floor(FlxMath.lerp(lerpScore, intendedScore, CoolUtil.boundTo(elapsed * 24, 0, 1)));
		lerpRating = FlxMath.lerp(lerpRating, intendedRating, CoolUtil.boundTo(elapsed * 12, 0, 1));

		if (Math.abs(lerpScore - intendedScore) <= 10)
			lerpScore = intendedScore;
		if (Math.abs(lerpRating - intendedRating) <= 0.01)
			lerpRating = intendedRating;

		var ratingSplit:Array<String> = Std.string(Highscore.floorDecimal(lerpRating * 100, 2)).split('.');
		if(ratingSplit.length < 2) { //No decimals, add an empty space
			ratingSplit.push('');
		}
		
		while(ratingSplit[1].length < 2) { //Less than 2 decimals in it, add decimals then
			ratingSplit[1] += '0';
		}

		scoreText.text = 'PERSONAL BEST: ' + lerpScore + ' (' + ratingSplit.join('.') + '%)';
		positionHighscore();

		var upP = controls.UI_UP_P;
		var downP = controls.UI_DOWN_P;
		var accepted = controls.ACCEPT;
		var space = FlxG.keys.justPressed.SPACE;
		var ctrl = FlxG.keys.justPressed.CONTROL;

		var shiftMult:Int = 1;
		if(FlxG.keys.pressed.SHIFT) shiftMult = 3;

		if(songs.length > 1 && !stopSpamming && !isDisked)
		{
			if (upP)
			{
				changeSelection(-shiftMult);
				holdTime = 0;
			}
			if (downP)
			{
				changeSelection(shiftMult);
				holdTime = 0;
			}

			if(controls.UI_DOWN || controls.UI_UP)
			{
				var checkLastHold:Int = Math.floor((holdTime - 0.5) * 10);
				holdTime += elapsed;
				var checkNewHold:Int = Math.floor((holdTime - 0.5) * 10);

				if(holdTime > 0.5 && checkNewHold - checkLastHold > 0)
				{
					changeSelection((checkNewHold - checkLastHold) * (controls.UI_UP ? -shiftMult : shiftMult));
					changeDiff();
				}
			}

			if(FlxG.mouse.wheel != 0)
			{
				FlxG.sound.play(Paths.sound('scrollMenu'), 0.2);
				changeSelection(-shiftMult * FlxG.mouse.wheel, false);
				changeDiff();
			}
		}

		if (canUseDiff)
		{
			if (controls.UI_LEFT_P)
				changeDiff(-1);
			else if (controls.UI_RIGHT_P)
				changeDiff(1);
			else if (upP || downP) changeDiff();

			if (controls.UI_LEFT)
				leftSpr.animation.play("press", true);
			else
				leftSpr.animation.play("idle", true);

			if (controls.UI_RIGHT)
				rightSpr.animation.play("press", true);
			else
				rightSpr.animation.play("idle", true);
		}

		if (controls.BACK && !stopSpamming && !isDisked)
		{
			persistentUpdate = false;
			if(colorTween != null) {
				colorTween.cancel();
			}
			FlxG.sound.play(Paths.sound('cancelMenu'));
			MusicBeatState.switchState(new MainMenuState());
		}

		if(ctrl && !stopSpamming && !isDisked)
		{
			persistentUpdate = false;
			openSubState(new GameplayChangersSubstate());
		}
		else if(space)
		{
			if(instPlaying != curSelected && !stopSpamming && !isDisked)
			{
				#if PRELOAD_ALL
				destroyFreeplayVocals();
				FlxG.sound.music.volume = 0;
				Paths.currentModDirectory = songs[curSelected].folder;
				var poop:String = Highscore.formatSong(songs[curSelected].songName.toLowerCase(), curDifficulty);
				PlayState.SONG = Song.loadFromJson(poop, songs[curSelected].songName.toLowerCase());
				if (PlayState.SONG.needsVoices)
					vocals = new FlxSound().loadEmbedded(Paths.voices(PlayState.SONG.song));
				else
					vocals = new FlxSound();

				FlxG.sound.list.add(vocals);
				FlxG.sound.playMusic(Paths.inst(PlayState.SONG.song), 0.7);
				vocals.play();
				vocals.persist = true;
				vocals.looped = true;
				vocals.volume = 0.7;
				instPlaying = curSelected;
				#end
			}
		}

		else if (accepted)
		{
			if (isDisked)
			{
				if (!stopSpamming)
				{
					stopSpamming = true;
					canUseDiff = false;
					FlxTween.cancelTweensOf(diffSpr);
					var songLowercase:String = Paths.formatToSongPath(songs[curSelected].songName);
					var poop:String = Highscore.formatSong(songLowercase, curDifficulty);
					/*#if MODS_ALLOWED
					if(!sys.FileSystem.exists(Paths.modsJson(songLowercase + '/' + poop)) && !sys.FileSystem.exists(Paths.json(songLowercase + '/' + poop))) {
					#else
					if(!OpenFlAssets.exists(Paths.json(songLowercase + '/' + poop))) {
					#end
						poop = songLowercase;
						curDifficulty = 1;
						trace('Couldnt find file');
					}*/
					trace(poop);

					PlayState.SONG = Song.loadFromJson(poop, songLowercase);
					PlayState.isStoryMode = false;
					PlayState.storyDifficulty = curDifficulty;

					trace('CURRENT WEEK: ' + WeekData.getWeekFileName());
					if(colorTween != null) {
						colorTween.cancel();
					}

					var time = 1;
					var ease = FlxEase.expoOut;

					camOther.flash();
					FlxG.sound.play(Paths.sound("confirmMenu"));

					for (i in [escSpr, leftSpr, rightSpr, diffSpr, fcSpr])
						FlxTween.tween(i, {alpha: 0}, 2, {ease: FlxEase.expoOut});

					if (FlxG.keys.pressed.SHIFT)
					{
						persistentUpdate = false;
						FlxG.sound.music.volume = 0;
						destroyFreeplayVocals();
						trace("my ass");
						PlayState.chartingMode = true;
						LoadingState.loadAndSwitchState(new ChartingState());
					} else {
						// what in the actually
						FlxTween.tween(this, {diskSpd: 7.5}, 1, {ease: FlxEase.linear, onComplete: function(fuck:FlxTween)
							{
								FlxTween.tween(infoTxt, {y: FlxG.height}, time, {ease: ease});
								FlxTween.tween(disk, {x: disket.x}, time, {ease: FlxEase.backIn, onComplete: function(t:FlxTween)
									{
										diskSpd = 0;
										FlxTween.tween(disket, {x: disket.x + 10}, 0.125, {ease: ease});
										FlxTween.tween(disk, {x: disk.x + 10}, 0.125, {ease: ease, onComplete: function(a:FlxTween)
											{
												FlxTween.tween(disket, {x: disket.x - 10}, 0.25, {ease: FlxEase.quadOut});
												FlxTween.tween(disk, {x: disk.x - 10}, 0.25, {ease: FlxEase.quadOut, onComplete: function(s:FlxTween)
													{
														persistentUpdate = false;
														FlxG.sound.music.volume = 0;
														destroyFreeplayVocals();
														LoadingState.loadAndSwitchState(new PlayState());
													}
												});
											}
										});
									}
								});
							}
						});
						// fuck
					}
				}
			} else {
				if (!stopSpamming)
				{
					// it goes funny if i don't put this
					stopSpamming = true;
					FlxG.sound.play(Paths.sound("confirmMenu"));
					FlxFlicker.flicker(grpSongs.members[curSelected], 0.5, 0.05, true,false,function(f:FlxFlicker)
					{
						var aeuio = FlxEase.expoOut;
						var sex = 2; // i forgot to add y :skull:
						new FlxTimer().start(sex / 2, function(f:FlxTimer)
						{
							stopSpamming = false;
							isDisked = true;
							canUseDiff = true;
						});
						FlxTween.tween(camSel, {zoom: 0.75}, sex, {ease: aeuio});
						FlxTween.tween(this, {blurVal: 0.0625}, sex, {ease: aeuio});
						FlxTween.tween(disk, {x: 10}, sex, {ease: aeuio});
						FlxTween.tween(disket, {x: (FlxG.width - disket.width) + 25}, sex, {ease: aeuio});
						FlxTween.tween(bgBlk, {alpha: 0.5}, sex, {ease: aeuio});
						for (i in [diffSpr, leftSpr, rightSpr, escSpr, infoTxt, fcSpr])
						{
							FlxTween.tween(i, {alpha: 1}, sex, {ease: aeuio});
						}
					});
					FlxFlicker.flicker(iconArray[curSelected], 0.5, 0.05, true,false);
				}
			}
		}
		else if(controls.RESET)
		{
			if (!stopSpamming && !isDisked)
			{
				persistentUpdate = false;
				openSubState(new ResetScoreSubState(songs[curSelected].songName, curDifficulty, songs[curSelected].songCharacter));
				FlxG.sound.play(Paths.sound('scrollMenu'));
			}
		}

		if (isDisked && !stopSpamming)
		{
			if (controls.BACK)
			{
				FlxG.sound.play(Paths.sound('cancelMenu'));
				stopSpamming = true;
				var aeuio = FlxEase.expoOut;
				var sex = 2;
				new FlxTimer().start(sex / 2, function(f:FlxTimer)
				{
					stopSpamming = false;
					isDisked = false;
					canUseDiff = false;
				});
				FlxTween.tween(camSel, {zoom: 1}, sex, {ease: aeuio});
				FlxTween.tween(this, {blurVal: 0}, sex, {ease: aeuio});
				FlxTween.tween(disk, {x: -disk.width - 5}, sex, {ease: aeuio});
				FlxTween.tween(disket, {x: FlxG.width}, sex, {ease: aeuio});
				for (i in [diffSpr, leftSpr, rightSpr, escSpr, infoTxt, bgBlk])
				{
					FlxTween.tween(i, {alpha: 0}, sex, {ease: aeuio});
				}
			}
		}

		super.update(elapsed);
	}

	public static function destroyFreeplayVocals() {
		if(vocals != null) {
			vocals.stop();
			vocals.destroy();
		}
		vocals = null;
	}

	var diffTween:FlxTween;
	var curSprPath:FlxGraphic;
	function changeDiff(change:Int = 0)
	{
		curDifficulty += change;

		if (curDifficulty < 0)
			curDifficulty = CoolUtil.difficulties.length-1;
		if (curDifficulty >= CoolUtil.difficulties.length)
			curDifficulty = 0;

		lastDifficultyName = CoolUtil.difficulties[curDifficulty];

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		checkFC();

		PlayState.storyDifficulty = curDifficulty;
		if (Paths.image("menudifficulties/"+CoolUtil.difficultyString().toLowerCase()) != curSprPath && diffSpr != null && canUseDiff)
		{
			curSprPath = Paths.image("menudifficulties/"+CoolUtil.difficultyString().toLowerCase());
			if (diffTween != null) diffTween.cancel();
			//diffSpr.alpha = 0;
			var base = diffText.y + 10;
			//diffSpr.y = base + 50;
			diffSpr.loadGraphic(Paths.image("menudifficulties/"+CoolUtil.difficultyString().toLowerCase()));
			//diffTween = FlxTween.tween(diffSpr, {y: base, alpha: 1}, 1, {ease: FlxEase.expoOut, onComplete: function(s:FlxTween)diffTween=null});
		}
		diffText.text = '< ' + CoolUtil.difficultyString() + ' >';
		positionHighscore();
	}

	function changeSelection(change:Int = 0, playSound:Bool = true)
	{
		if(playSound) FlxG.sound.play(Paths.sound('scrollMenu'), 0.4);

		curSelected += change;

		if (curSelected < 0)
			curSelected = songs.length - 1;
		if (curSelected >= songs.length)
			curSelected = 0;

		checkFC();
			
		var newColor:Int = songs[curSelected].color;
		if(newColor != intendedColor) {
			if(colorTween != null) {
				colorTween.cancel();
			}
			intendedColor = newColor;
			colorTween = FlxTween.color(bg, 1, bg.color, intendedColor, {
				onComplete: function(twn:FlxTween) {
					colorTween = null;
				}
			});
		}

		// selector.y = (70 * curSelected) + 30;

		#if !switch
		intendedScore = Highscore.getScore(songs[curSelected].songName, curDifficulty);
		intendedRating = Highscore.getRating(songs[curSelected].songName, curDifficulty);
		#end

		var bullShit:Int = 0;

		for (i in 0...iconArray.length)
		{
			iconArray[i].alpha = 0.6;
		}

		iconArray[curSelected].alpha = 1;

		for (item in grpSongs.members)
		{
			item.targetY = bullShit - curSelected;
			bullShit++;

			item.alpha = 0.6;
			// item.setGraphicSize(Std.int(item.width * 0.8));

			if (item.targetY == 0)
			{
				item.alpha = 1;
				// item.setGraphicSize(Std.int(item.width));
			}
		}
		
		Paths.currentModDirectory = songs[curSelected].folder;
		PlayState.storyWeek = songs[curSelected].week;

		CoolUtil.difficulties = CoolUtil.defaultDifficulties.copy();
		var diffStr:String = WeekData.getCurrentWeek().difficulties;
		if(diffStr != null) diffStr = diffStr.trim(); //Fuck you HTML5

		if(diffStr != null && diffStr.length > 0)
		{
			var diffs:Array<String> = diffStr.split(',');
			var i:Int = diffs.length - 1;
			while (i > 0)
			{
				if(diffs[i] != null)
				{
					diffs[i] = diffs[i].trim();
					if(diffs[i].length < 1) diffs.remove(diffs[i]);
				}
				--i;
			}

			if(diffs.length > 0 && diffs[0].length > 0)
			{
				CoolUtil.difficulties = diffs;
			}
		}
		
		if(CoolUtil.difficulties.contains(CoolUtil.defaultDifficulty))
		{
			curDifficulty = Math.round(Math.max(0, CoolUtil.defaultDifficulties.indexOf(CoolUtil.defaultDifficulty)));
		}
		else
		{
			curDifficulty = 0;
		}

		var newPos:Int = CoolUtil.difficulties.indexOf(lastDifficultyName);
		//trace('Pos of ' + lastDifficultyName + ' is ' + newPos);
		if(newPos > -1)
		{
			curDifficulty = newPos;
		}
	}

	private function positionHighscore() {
		scoreText.x = FlxG.width - scoreText.width - 6;

		scoreBG.scale.x = FlxG.width - scoreText.x + 6;
		scoreBG.x = FlxG.width - (scoreBG.scale.x / 2);
		diffText.x = Std.int(scoreBG.x + (scoreBG.width / 2));
		diffText.x -= diffText.width / 2;
	}
}

class SongMetadata
{
	public var songName:String = "";
	public var week:Int = 0;
	public var songCharacter:String = "";
	public var color:Int = -7179779;
	public var folder:String = "";

	public function new(song:String, week:Int, songCharacter:String, color:Int)
	{
		this.songName = song;
		this.week = week;
		this.songCharacter = songCharacter;
		this.color = color;
		this.folder = Paths.currentModDirectory;
		if(this.folder == null) this.folder = '';
	}
}