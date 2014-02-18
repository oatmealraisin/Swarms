class SGameType extends KFGameType config(Swarms);

var bool bIsShopAlwaysEnabled;
var bool bSGameInProgress;
var bool bSFirst;

var bool bDebug;
var config bool ResetHS, bGameType;

var int traderOpenTime;
var int iMaxMonsters;
var int iPlayerAdjustment;

var string HighscoreGroup;

// Lol just copy the KF code and put an S in front of it, don't know what the localized is for or why they use
//		an array for the PropText, but oh well.
const SPROPNUM = 3;
var localized string SSurvivalPropText[SPROPNUM];
var localized string SSurvivalDescText[SPROPNUM];

event InitGame( string Options, out string Error ){
	local KFLevelRules KFLRit;
	local ShopVolume SH;
	local ZombieVolume ZZ;
	local string InOpt;
	local int i;
	
	Super(Invasion).InitGame(Options, Error);
	
	if(bDebug)
		log("SGameType.InitGame(string, out string)", 'Swarms');
	
// 	This is to disable game difficulties, because the last chosen difficulty 
//  	is the difficulty used.  This shouldn't matter anymore, but just in case I missed 
//		something that uses it..
	GameDifficulty = 1.0;

//  Setting up the game for Swarms.
	bSFirst=true;
	bIsShopAlwaysEnabled=true;
	bSGameInProgress = false;
	traderOpenTime = 1;

	MaxPlayers = Clamp(GetIntOption( Options, "MaxPlayers", MaxPlayers ),0,6);
	default.MaxPlayers = Clamp( default.MaxPlayers, 0, 6 );

	foreach DynamicActors(class'KFLevelRules',KFLRit)
	{
		if(KFLRules==none)
			KFLRules = KFLRit;
		else Warn("MULTIPLE KFLEVELRULES FOUND!!!!!");
	}
	
	foreach AllActors(class'ShopVolume',SH)
		ShopList[ShopList.Length] = SH;
	foreach AllActors(class'ZombieVolume',ZZ)
		ZedSpawnList[ZedSpawnList.Length] = ZZ;

// provide default rules if mapper did not need custom one
	if(KFLRules==none)
		KFLRules = spawn(class'KFLevelRules');

	log("KFLRules = "$KFLRules);

	InOpt = ParseOption(Options, "UseBots");
	if ( InOpt != "" )
	{
		bNoBots = bool(InOpt);
	}

    log("Game length = "$KFGameLength);

	LoadUpMonsterList();
	
	
}

state MatchInProgress {	
	function CloseShops()
	{
		local int i;
		local Controller C;

		bTradingDoorsOpen = False;
		for( i=0; i<ShopList.Length; i++ )
		{
			if( ShopList[i].bCurrentlyOpen )
				ShopList[i].CloseShop();
		}
		traderOpenTime= ElapsedTime+60;
		
		// Tell all players to stop showing the path to the trader
		For( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			if( C.Pawn!=None && C.Pawn.Health>0 )
			{
				if( KFPlayerController(C) !=None )
				{
					KFPlayerController(C).SetShowPathToTrader(false);
					KFPlayerController(C).ClientLocationalVoiceMessage(C.PlayerReplicationInfo, none, 'TRADER', 6);
				}
			}
		}
	}
	
	function Timer()
	{
		local float SineMod;
		
		local Controller C;
		local bool bOneMessage;
		local Bot B;
		
		local int count;
		

		Global.Timer();

		if ( !bFinalStartup )
		{
			bFinalStartup = true;
			PlayStartupMessage();
		}
		if ( NeedPlayers() && AddBot() && (RemainingBots > 0) )
			RemainingBots--;
			
		ElapsedTime++;
		GameReplicationInfo.ElapsedTime = ElapsedTime;
		
		if( !UpdateMonsterCount() )
		{
			EndGame(None,"TimeLimit");
			Return;
		}

		if( bUpdateViewTargs )
			UpdateViews();

		if (!bNoBots && !bBotsAdded)
		{
			if(KFGameReplicationInfo(GameReplicationInfo) != none)

			if((NumPlayers + NumBots) < MaxPlayers && KFGameReplicationInfo(GameReplicationInfo).PendingBots > 0 )
			{
				AddBots(1);
				KFGameReplicationInfo(GameReplicationInfo).PendingBots --;
			}

			if (KFGameReplicationInfo(GameReplicationInfo).PendingBots == 0)
			{
				bBotsAdded = true;
				return;
			}
		}
		
//      Begin my stuff.  Bumbumbumbabum! -- Apples

// --------------------------------------------------------------
//	I'm going to have to redo this.  It's a flawed, crude system 
//	that rewards people for camping and doesn't allow ample time 
//  for a single player to shop for more than 10 seconds.  The result
//	is just plain annoying and must be changed if this is going to
// 	be a truly fluid gametype.  -- Apples
// --------------------------------------------------------------
		else if(bSGameInProgress) 
		{
			if(bSFirst) 
			{		
				bSFirst=false;
				ElapsedTime=1;
				count=0;
				iMaxMonsters = 60;
				iPlayerAdjustment = 0;
				
				if(bDebug)
					log("NumPlayers:  " $ NumPlayers,'Swarms');
					
				switch(NumPlayers){
				
//				This makes it so that there are more clots maximum and more minimum,
//					so that on single player there are gaps of no clots, and with 6
//					people there are always some.

					case 1:
						iPlayerAdjustment=20;
						iMaxMonsters = 60;
						break;
					case 2:
						iPlayerAdjustment=10;
						iMaxMonsters = 70;
						break;
					case 3:
						iPlayerAdjustment=0;
						iMaxMonsters=80;
						break;
					case 4:
						iPlayerAdjustment=-20;
						iMaxMonsters = 70;
						break;
					case 5:
						iPlayerAdjustment=-30;
						iMaxMonsters=80;
						break;
					case 6:
						iPlayerAdjustment=-40;
						iMaxMonsters=90;
						break;
					default:
						iMaxMonsters=NumPlayers*15; // in case someone makes a mutator with > 6 players
						iPlayerAdjustment=(NumPlayers*-10)+20;
						log("Set to the default player adjustments.  If <7 players, this is bad.", 'Swarms');
				}
			}
			
			SineMod = Abs(sin((WaveTimeElapsed) * SineWaveFreq));

			WaveTimeElapsed += 1.0;
			KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveTimeElapsed;

			log(NumMonsters $ "/" $ ((SineMod*iMaxMonsters) - iPlayerAdjustment) $ "/" $ WaveTimeElapsed, 'Swarms');
						
			if(NumMonsters <= ((SineMod*iMaxMonsters) - iPlayerAdjustment)){
				AddMonster();
				
				if(NumMonsters<=5){
				AddMonster();
				}
				
				if(WaveTimeElapsed >= 180){
				AddMonster();
				}
				
				if(WaveTimeElapsed >= 300){
				AddMonster();
				}
				
				if(WaveTimeElapsed >= 540){
				AddMonster();
				}
				
				if(WaveTimeElapsed >= 720){
				AddMonster();
				}
				
				if(WaveTimeElapsed >= 900){
				AddMonster();
				AddMonster();
				}
			}
		
			if(!MusicPlaying)
				StartGameMusic(True);

			if ( NumMonsters <= 5)
			{
				for ( C = Level.ControllerList; C != None; C = C.NextController )
					if ( KFMonsterController(C)!=None && KFMonsterController(C).CanKillMeYet() )
					{
						C.Pawn.KilledBy( C.Pawn );
						Break;
					}
			}
		}
		
		if(WaveCountDown>0){
			WaveCountDown--;
		}
		
		else if(WaveCountDown<=0 && bSGameInProgress==false)
			bSGameInProgress=true;
		if(traderOpenTime<=ElapsedTime){
			if(KFGameReplicationInfo(GameReplicationInfo).CurrentShop == none){
                SelectShop();
            }
			
			OpenShops();
		}
	}
	
	function DoWaveEnd()
	{
		local Controller C;
		local KFDoorMover KFDM;
		local PlayerController Survivor;
		local int SurvivorCount;

        // Only reset this at the end of wave 0. That way the sine wave that scales
        // the intensity up/down will be somewhat random per wave
        if( WaveNum < 1 )
        {
            WaveTimeElapsed = 0;
        }

		if ( !rewardFlag )
			RewardSurvivingPlayers();

		if( bDebugMoney )
		{
			log("$$$$$$$$$$$$$$$$ Wave "$WaveNum$" TotalPossibleWaveMoney = "$TotalPossibleWaveMoney,'Debug');
			log("$$$$$$$$$$$$$$$$ TotalPossibleMatchMoney = "$TotalPossibleMatchMoney,'Debug');
			TotalPossibleWaveMoney=0;
		}

		// Clear Trader Message status
//		bDidTraderMovingMessage = false;
//		bDidMoveTowardTraderMessage = false;

		bWaveInProgress = false;
		bSGameInProgress = true;
		bWaveBossInProgress = false;
		bNotifiedLastManStanding = false;
		KFGameReplicationInfo(GameReplicationInfo).bWaveInProgress = false;

		WaveCountDown = Max(TimeBetweenWaves,2);
		KFGameReplicationInfo(GameReplicationInfo).TimeToNextWave = WaveCountDown;

		for ( C = Level.ControllerList; C != none; C = C.NextController )
		{
			if ( C.PlayerReplicationInfo != none )
			{
				C.PlayerReplicationInfo.bOutOfLives = false;
				C.PlayerReplicationInfo.NumLives = 0;

				if ( KFPlayerController(C) != none )
				{
					if ( KFPlayerReplicationInfo(C.PlayerReplicationInfo) != none )
					{
						KFPlayerController(C).bChangedVeterancyThisWave = false;

						if ( KFPlayerReplicationInfo(C.PlayerReplicationInfo).ClientVeteranSkill != KFPlayerController(C).SelectedVeterancy )
						{
							KFPlayerController(C).SendSelectedVeterancyToServer();
						}
					}
				}

				if ( C.Pawn != none )
				{
					if ( PlayerController(C) != none )
					{
						Survivor = PlayerController(C);
						SurvivorCount++;
					}
				}
				else if ( !C.PlayerReplicationInfo.bOnlySpectator )
				{
					C.PlayerReplicationInfo.Score = Max(MinRespawnCash,int(C.PlayerReplicationInfo.Score));

					if( PlayerController(C) != none )
					{
						PlayerController(C).GotoState('PlayerWaiting');
						PlayerController(C).SetViewTarget(C);
						PlayerController(C).ClientSetBehindView(false);
						PlayerController(C).bBehindView = False;
						PlayerController(C).ClientSetViewTarget(C.Pawn);
					}

					C.ServerReStartPlayer();
				}

				if ( KFPlayerController(C) != none )
				{
					if ( KFSteamStatsAndAchievements(PlayerController(C).SteamStatsAndAchievements) != none )
					{
						KFSteamStatsAndAchievements(PlayerController(C).SteamStatsAndAchievements).WaveEnded();
					}

                    // Don't broadcast this message AFTER the final wave!
                    if( WaveNum < FinalWave )
                    {
						KFPlayerController(C).bSpawnedThisWave = false;
						BroadcastLocalizedMessage(class'KFMod.WaitingMessage', 2);
					}
					else if ( WaveNum == FinalWave )
					{
						KFPlayerController(C).bSpawnedThisWave = false;
					}
					else
					{
						KFPlayerController(C).bSpawnedThisWave = true;
					}
				}
			}
		}

		if ( Level.NetMode != NM_StandAlone && Level.Game.NumPlayers > 1 &&
			 SurvivorCount == 1 && Survivor != none && KFSteamStatsAndAchievements(Survivor.SteamStatsAndAchievements) != none )
		{
			KFSteamStatsAndAchievements(Survivor.SteamStatsAndAchievements).AddOnlySurvivorOfWave();
		}

		bUpdateViewTargs = True;

		//respawn doors
		foreach DynamicActors(class'KFDoorMover', KFDM)
			KFDM.RespawnDoor();
	}

	
	function BeginState()
	{
		Super.BeginState();
		WaveCountDown = 10;
	}
}

function ShowPathTo(PlayerController P, int TeamNum){}

function SetupWave(){
	local int i,j;
	local float NewMaxMonsters;
	//local int m;
	local float DifficultyMod, NumPlayersMod;
	local int UsedNumPlayers;

	if ( WaveNum > 15 )
	{
		SetupRandomWave();
		return;
	}

	TraderProblemLevel = 0;
	rewardFlag=false;
	ZombiesKilled = 0;
	WaveMonsters = 0;
	WaveNumClasses = 0;
	NewMaxMonsters = Waves[WaveNum].WaveMaxMonsters;

	// scale number of zombies by difficulty
	if ( GameDifficulty >= 7.0 ) // Suicidal
	{
		DifficultyMod=1.7;
	}
	else if ( GameDifficulty >= 4.0 ) // Hard
	{
		DifficultyMod=1.7;
	}
	else if ( GameDifficulty >= 2.0 ) // Normal
	{
		DifficultyMod=1.7;
	}
	else //if ( GameDifficulty == 1.0 ) // Beginner
	{
		DifficultyMod=1.7;
	}

	UsedNumPlayers = NumPlayers + NumBots;

	// Scale the number of zombies by the number of players. Don't want to
	// do this exactly linear, or it just gets to be too many zombies and too
	// long of waves at higher levels - Ramm
	NumPlayersMod=4.5;

	KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonsters=TotalMaxMonsters;
	KFGameReplicationInfo(Level.Game.GameReplicationInfo).MaxMonstersOn=true;
	WaveEndTime = Level.TimeSeconds + Waves[WaveNum].WaveDuration;
	AdjustedDifficulty = GameDifficulty + Waves[WaveNum].WaveDifficulty;

	j = ZedSpawnList.Length;
	for( i=0; i<j; i++ )
		ZedSpawnList[i].Reset();
	j = 1;
	SquadsToUse.Length = 0;

	for ( i=0; i<InitSquads.Length; i++ )
	{
		if ( (j & Waves[WaveNum].WaveMask) != 0 )
		{
			SquadsToUse.Insert(0,1);
			SquadsToUse[0] = i;

			// Ramm ZombieSpawn debugging
			/*for ( m=0; m<InitSquads[i].MSquad.Length; m++ )
			{
			   log("Wave "$WaveNum$" Squad "$SquadsToUse.Length$" Monster "$m$" "$InitSquads[i].MSquad[m]);
			}
			log("TotalMaxMonsters "$TotalMaxMonsters,'Swarms');*/
		}
		j *= 2;
	}

	// Save this for use elsewhere
	InitialSquadsToUseSize = SquadsToUse.Length;
	bUsedSpecialSquad=false;
	SpecialListCounter=1;
}

static function FillPlayInfo(PlayInfo PlayInfo)
{
	Super(Info).FillPlayInfo(PlayInfo);  // Always begin with calling parent

	PlayInfo.AddSetting(default.GameGroup,"GameDifficulty", GetDisplayText("GameDifficulty"),	0, 0, "Select", default.GIPropsExtras[0], "Xb");
	PlayInfo.AddSetting(default.GameGroup,"bGameType", GetDisplayText("bGameType"),	0, 0, "Check",, "Xb");
	PlayInfo.AddSetting(default.SandboxGroup,"StartingCash", GetDisplayText("StartingCash"),0,0,"Text","200;0:500");

	PlayInfo.AddSetting(default.HighScoreGroup,"ResetHS", GetDisplayText("ResetHS"),0,0,"Custom",";;Swarms.SResetAllConfig",,,);


    if( class'ROEngine.ROLevelInfo'.static.RODebugMode() ){
	   PlayInfo.AddSetting(default.SandboxGroup, "MaxZombiesOnce", GetDisplayText("MaxZombiesOnce"),70,2,"Text","4;1:600");
    } else {
	   PlayInfo.AddSetting(default.SandboxGroup, "MaxZombiesOnce", GetDisplayText("MaxZombiesOnce"),70,2,"Text","4;6:600");
    }

	PlayInfo.AddSetting(default.ServerGroup, "LobbyTimeOut",	GetDisplayText("LobbyTimeOut"),		0, 1, "Text",	"3;0:120",	,True,True);
	PlayInfo.AddSetting(default.ServerGroup, "bAdminCanPause",	GetDisplayText("bAdminCanPause"),	1, 1, "Check",			 ,	,True,True);
	PlayInfo.AddSetting(default.ServerGroup, "MaxSpectators",	GetDisplayText("MaxSpectators"),	1, 1, "Text",	 "6;0:32",	,True,True);
	PlayInfo.AddSetting(default.ServerGroup, "MaxPlayers",		GetDisplayText("MaxPlayers"),		0, 1, "Text",	  "6;1:6",	,True);
	PlayInfo.AddSetting(default.ServerGroup, "MaxIdleTime",		GetDisplayText("MaxIdleTime"),		0, 1, "Text",	"3;0:300",	,True,True);

	// Add GRI's PIData
	if (default.GameReplicationInfoClass != None)
	{
		default.GameReplicationInfoClass.static.FillPlayInfo(PlayInfo);
		PlayInfo.PopClass();
	}

	if (default.VoiceReplicationInfoClass != None)
	{
		default.VoiceReplicationInfoClass.static.FillPlayInfo(PlayInfo);
		PlayInfo.PopClass();
	}

	if (default.BroadcastClass != None)
		default.BroadcastClass.static.FillPlayInfo(PlayInfo);
	else class'BroadcastHandler'.static.FillPlayInfo(PlayInfo);

	PlayInfo.PopClass();

	if (class'Engine.GameInfo'.default.VotingHandlerClass != None)
	{
		class'Engine.GameInfo'.default.VotingHandlerClass.static.FillPlayInfo(PlayInfo);
		PlayInfo.PopClass();
	}
	else
		log("GameInfo::FillPlayInfo class'Engine.GameInfo'.default.VotingHandlerClass = None");
}

static event string GetDisplayText(string PropName)
{
	switch (PropName)
	{
		case "ResetHS":		return default.SSurvivalPropText[0];
		case "ResetAll":	return default.SSurvivalPropText[1];
		case "bGameType":	return default.SSurvivalPropText[2];
	}
	return Super.GetDisplayText( PropName );
}

static event string GetDescriptionText(string PropName)
{
	switch (PropName)
	{
		case "ResetHS":		return default.SSurvivalDescText[0];
		case "ResetAll":	return default.SSurvivalDescText[1];
		case "bGameType":	return default.SSurvivalDescText[2];
	}
	return Super.GetDescriptionText(PropName);
}

function AddMonster()
{
	local NavigationPoint StartSpot;
	local Pawn NewMonster;
	local class<Monster> NewMonsterClass;
	local int MonstersAdded;

	StartSpot = FindPlayerStart(None,1);
	if ( StartSpot == None )
		return;

	NewMonsterClass = class<Monster>(DynamicLoadObject("Swarms.SClot", class'Class'));
	MonstersAdded ++;
	NewMonster = Spawn(NewMonsterClass,,,StartSpot.Location+(NewMonsterClass.Default.CollisionHeight - StartSpot.CollisionHeight) * vect(0,0,1),StartSpot.Rotation);
	if ( NewMonster ==  None )
		NewMonster = Spawn(class<Monster>(DynamicLoadObject("Swarms.SClot", class'Class')),,,StartSpot.Location+(class<Monster>(DynamicLoadObject("Swarms.SClot", class'Class')).Default.CollisionHeight - StartSpot.CollisionHeight) * vect(0,0,1),StartSpot.Rotation);
	MonstersAdded ++;
	if ( NewMonster != None )
	{
		WaveMonsters++;
		NumMonsters++;
	}

	if (NewMonster != none && MonstersAdded < 3){}
//		Super.AddMonster();

	if (MonstersAdded >= 3)
		MonstersAdded = 0;
}

function bool CheckMaxLives(PlayerReplicationInfo Scorer)
{
	local Controller C;
	local PlayerController Living;
	local byte AliveCount;
	
	if(bDebug)
		log("SGameType.CheckMaxLives(PlayerReplicationInfo)", 'Swarms');

	if ( MaxLives > 0 )
	{
		for ( C=Level.ControllerList; C!=None; C=C.NextController )
		{
			if ( (C.PlayerReplicationInfo != None) && C.bIsPlayer && !C.PlayerReplicationInfo.bOutOfLives && !C.PlayerReplicationInfo.bOnlySpectator )
			{
				AliveCount++;
				if( Living==None )
					Living = PlayerController(C);
			}
		}
		if ( AliveCount==0 ){			
			EndGame(Scorer,"LastMan");
			setHighScores();
			return true;
		}
		else if( !bNotifiedLastManStanding && AliveCount==1 && Living!=None )
		{
			bNotifiedLastManStanding = true;
			Living.ReceiveLocalizedMessage(Class'KFLastManStandingMsg');
		}
	}
	return false;
}

event PostLogin( PlayerController NewPlayer ){
	Super.PostLogin(NewPlayer);
	if(bDebug)
		log("I am in PostLogin( PlayerController NewPlayer )", 'Swarms');
}

function setHighScores(){
	local int i;
	
	if(bDebug)
		log("SGameType.setHighScores()", 'Swarms');
		
	for(i = 0; i < SGameReplicationInfo(GameReplicationInfo).HighScoreArray.length; i++)
		SGameReplicationInfo(GameReplicationInfo).HighScoreArray[i].setScore(Level.Title, ElapsedTime);
}

defaultproperties
{	 
     KFHints(0)="Try to get kills early in the game!  The longer you wait, the harder it can get to earn some dosh!"
     KFHints(2)="Don't forget to comment!  I read all of them!"
     KFHints(3)="Got an idea for me?  Comment on the mod's steam page!"
     KFHints(4)="If you find a bug, don't hesitate to tell me!"
     KFHints(5)="Dosh!"
     KFHints(6)="Your flashlight now has infinite batteries!  Hoorah!"
     KFHints(7)="More to come!"
     KFHints(9)="Better than Nazi Zombies!"
     KFHints(10)="Better than Dead Space!"
     KFHints(11)="Better than Left 4 Dead!"
     KFHints(12)="Better than Sliced Bread!"
     KFHints(13)="The clots may not be able to grab you, but they can do quite a bit of damage in late game!  Keep your distance!"
     KFHints(14)="LODS OF EMONE!"
     
	 MonsterSquad(0)="4A"
     TimeBetweenWaves=0
     MaxZombiesOnce=32
     SineWaveFreq=0.030000
	 
     MonsterClasses(0)=(MClassName="Swarms.SClot")
     MonsterClasses(1)=(MClassName="KFChar.ZombieClot")
     MonsterClasses(2)=(MClassName="KFChar.ZombieCrawler")
	 MonsterClasses(3)=(MClassName="KFChar.ZombieGoreFast")
     MonsterClasses(4)=(MClassName="KFChar.ZombieStalker")
     MonsterClasses(5)=(MClassName="KFChar.ZombieScrake")
     MonsterClasses(6)=(MClassName="KFChar.ZombieFleshpound")
     MonsterClasses(7)=(MClassName="KFChar.ZombieBloat")
     MonsterClasses(8)=(MClassName="KFChar.ZombieSiren")	 
     MonsterClasses(9)=(MClassName="KFChar.ZombieHusk")	
	 
     ShortSpecialSquads(2)=(ZedClass=(),NumZeds=())
     ShortSpecialSquads(3)=(ZedClass=(),NumZeds=())
     NormalSpecialSquads(3)=(ZedClass=(),NumZeds=())
     NormalSpecialSquads(4)=(ZedClass=(),NumZeds=())
     NormalSpecialSquads(5)=(ZedClass=(),NumZeds=())
     NormalSpecialSquads(6)=(ZedClass=(),NumZeds=())
     LongSpecialSquads(4)=(ZedClass=(),NumZeds=())
     LongSpecialSquads(6)=(ZedClass=(),NumZeds=())
     LongSpecialSquads(7)=(ZedClass=(),NumZeds=())
     LongSpecialSquads(8)=(ZedClass=(),NumZeds=())
     LongSpecialSquads(9)=(ZedClass=("Swarms.SClot","Swarms.SClot","Swarms.SClot","Swarms.SClot"),NumZeds=(1,2,1,2))
     StandardMonsterClasses(0)=(MClassName="Swarms.SClot",Mid="A")
     StandardMonsterClasses(1)=(MClassName="KFChar.ZombieClot",Mid="B")
     StandardMonsterClasses(2)=(MClassName="KFChar.ZombieCrawler",Mid="C")
     StandardMonsterClasses(3)=(MClassName="KFChar.ZombieGoreFast",Mid="D")
     StandardMonsterClasses(4)=(MClassName="KFChar.ZombieStalker",Mid="E")
     StandardMonsterClasses(5)=(MClassName="KFChar.ZombieScrake",Mid="F")
     StandardMonsterClasses(6)=(MClassName="KFChar.ZombieFleshpound",Mid="G")
     StandardMonsterClasses(7)=(MClassName="KFChar.ZombieBloat",Mid="H")
     StandardMonsterClasses(8)=(MClassName="KFChar.ZombieSiren",Mid="I")	 
     StandardMonsterClasses(9)=(MClassName="KFChar.ZombieHusk",Mid="J")	 
     FallbackMonsterClass="Swarms.SClot"
	 
     bWaitForNetPlayers=False
     GameDifficulty=1.000000
     DefaultPlayerClassName="Swarms.SHumanPawn"
     ScoreBoardType="Swarms.SScoreBoardNew"
//     HUDType="Swarms.SHUD"
     PlayerControllerClass=class'Swarms.SPlayerController'
     PlayerControllerClassName="Swarms.SPlayerController"
     GameReplicationInfoClass = class'Swarms.SGameReplicationInfo'
     
	 GameName	 = "Swarms"
     Description = "Fear the Horde"
	 Acronym = "S"
	 
     MaxIdleTime = 30.000000
	 
	 HighscoreGroup 		= "High Score"	 
	 SSurvivalPropText[0]	= "Reset" 
	 SSurvivalDescText[0] 	= "Reset your high scores"
	 
	 bDebug = true
	 ResetHS = false
	 bGameType = false
}
