class SMapPage extends KFMapPage;

function InitGameType()
{
    local int i;
    local array<CacheManager.GameRecord> Games;
    local bool bReloadMaps;

	// Get a list of all gametypes.
    class'CacheManager'.static.GetGameTypeList(Games);
	for (i = 0; i < Games.Length; i++)
    {
        if (Games[i].ClassName ~= Controller.LastGameType)
        {
        	bReloadMaps = CurrentGameType.MapPrefix != Games[i].MapPrefix;
            CurrentGameType = Games[i];
            break;
        }
    }

    if ( i == Games.Length )
    	return;
		
	// Enable/Disable extra options based on GameType
	if ( CurrentGameType.ClassName == "Swarms.SGameType" )
	{
		co_GameLength.EnableMe();
		ch_Sandbox.EnableMe();
	}
	else
	{
		co_GameLength.DisableMe();
		ch_Sandbox.DisableMe();
	}

	// Update the gametype label's text
    SetGameTypeCaption();

    // Should the tutorial button be enabled?
    // CheckGameTutorial();

    // Load Maps for the new gametype, but only if it uses a different maplist
    if (bReloadMaps)
   		InitMaps();

    // Set the selected map
    i = li_Maps.FindIndexByValue(LastSelectedMap);
    if ( i == -1 )
    	i = 0;
    li_Maps.SetIndex(i);
    li_Maps.Expand(i);

	// Load the information (screenshot, desc., etc.) for the currently selected map
    // ReadMapInfo(li_Maps.GetParentCaption());
}