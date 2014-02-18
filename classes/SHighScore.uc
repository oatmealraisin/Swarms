class SHighScore extends Object config(Swarms);
// Woo OC!
var bool bDebug;

var() private config array<string> Maps;
var() private config array<int> Scores;

var int HighScore;

simulated function getScore(string MapName){
	local int i, MapID;
	local bool bMapFound;
	
	if(bDebug)
		log("SHighScore.getScore(string)", 'Swarms');
	bMapFound = false;
	
	for(i = 0; i < Maps.length; i++){
		if(Maps[i] ~= MapName){
			MapID = i;
			bMapFound = true;
			if(bDebug)
				log("I've found the map in getScore and the Map ID is " $ i,'Swarms');
		}
	}
	
	if(!bMapFound){
		setScore(MapName, 0);
		HighScore = 0;
		return;
	}
	HighScore = Scores[MapID];
}

simulated function string getMapFromArray(int ID){
	return Maps[ID];
}

simulated function int getScoreFromArray(int ID){
	return Scores[ID];
}

simulated function int getArrayLength(){
	return Maps.length;
}

simulated function setScore(string MapName,int FinalTime){
	local int i, MapID;
	local bool bMapFound;
	
	if(bDebug)
		log("SHighScore.setScore(string, int)", 'Swarms');
	bMapFound = false;

	for(i = 0; i < Maps.length; i++){
		if(Maps[i] ~= MapName){
			MapID = i;
			bMapFound = true;
			if(bDebug)
				log("I've found the map in setScore and the Map ID is " $ i, 'Swarms');
		}
	}
	
	if(!bMapFound){
		if(bDebug)
			log("Adding map:  " $MapName$ " to Maps.  It's ID Number is:  " $ Maps.length,'Swarms');
		Maps[Maps.length] = MapName;
		Scores[Scores.length] = FinalTime;
	} else if(FinalTime > Scores[MapID]) {
		Scores[MapID] = FinalTime;
		if(bDebug)
			log("The HighScore is now" $ Scores[MapID],'Swarms');
	}
	
	SaveConfig();
}

simulated function resetScore(int MapID){
	if(bDebug)
		log("SHighScore.resetScore(int)", 'Swarms');
	if(MapID >= Scores.length){
		log("SHighScore.resetScore(int): Warning, I was passed an invalid parameter", 'Swarms');
		return;
	}
	Scores[MapID] = 0;
	SaveConfig();
}

defaultproperties
{	
	bDebug = false
}
