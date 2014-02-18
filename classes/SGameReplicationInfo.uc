class SGameReplicationInfo extends KFGameReplicationInfo;

// I hate this part of the code, mainly because it was so damn hard to get working...

var bool bDebug;

var() array<SHighScore> HighScoreArray;

simulated function AddHighScore(SHighScore SHS){
	if(bDebug)
		log("SGameReplicationInfo.AddHighScore(SHighScore)", 'Swarms');
		
	HighScoreArray[HighScoreArray.length] = SHS;
}

defaultproperties
{
     bDebug = true
}
