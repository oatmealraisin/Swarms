class SPlayerController extends KFPlayerController config(Swarms);

// Lots of oc in here, not really.  But it's where I finally got that high score thing to work.  Don't know why it took 
//		me so long to decide to resort to this, it doesn't seem to affect anything too much besides MAKING IT WORK!!!!
//																										Go me.

var() class<SHighScore> HighScoreClass;
var SHighScore HighScore;

var bool bDebug;

function SetPawnClass(string inClass, string inCharacter)
{
	if(bDebug)
		log("SPlayerController.SetPawnClass(string, string)", 'Swarms');
	PawnClass = Class'SHumanPawn';
	inCharacter = Class'KFGameType'.Static.GetValidCharacter(inCharacter);
	PawnSetupRecord = class'xUtil'.static.FindPlayerRecord(inCharacter);
	PlayerReplicationInfo.SetCharacterName(inCharacter);
}

event PostBeginPlay(){
	if(bDebug)
		log("SPlayerController.PostBeginPlay()", 'Swarms');
	Super.PostBeginPlay();
	
// They did it with PlayerReplicationInfo, I can do it with my stuff too!  Spawns a SHighScore for the controller and then goes down a little...

	if (!bDeleteMe && bIsPlayer && (Level.NetMode != NM_Client) ){
		HighScore = New HighScoreClass;
		if(HighScore != none)
			InitHighScore();
		else
			log("SPlayerController.PostBeginPlay(): Warning, the High Score was not initialized.", 'Swarms');
	}
}

function InitHighScore(){
// To here.  This initializes the high score int in the SHighScore class so that I don't have to grab
//		it more than once.  This may be a bit of overkill, but I don't really know how servers work,
//		so I assume that I want to minimize the amount of information that is sent back to the server.
	if(bDebug)
		log("SPlayerController.InitHighScore()", 'Swarms');
	if(HighScore != none){
		HighScore.getScore(Level.Title);
		SGameReplicationInfo(Level.GRI).AddHighScore(HighScore);
	}
}

defaultproperties
{
     SelectedVeterancy=Class'KFMod.KFVetSupportSpec'
	 // Shut up I like talking to people.
     PerkChangeOncePerWaveString="But you can't just change who you are like that!"
     bWantsTraderPath=False
     PlayerReplicationInfoClass=Class'Swarms.SPlayerReplicationInfo'
	 // Just in case this gets popular enough for people to mod :'D
	 HighScoreClass = class'Swarms.SHighScore'
	 
	 bDebug = true
}
