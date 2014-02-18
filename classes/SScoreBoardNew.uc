class SScoreBoardNew extends KFScoreBoardNew;
// Not even going to comment this up.  I just change up the scoreboard a little and add the high score.  
var() localized string HighscoreText;

function DrawTitle(Canvas Canvas, float HeaderOffsetY, float PlayerAreaY, float PlayerBoxSizeY)
{
	local string TitleString, ScoreInfoString, RestartString;
	local float TitleXL, ScoreInfoXL, YL, TitleY, TitleYL;

	TitleString =  "Swarms |" @ Level.Title;

	Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);

	Canvas.StrLen(TitleString, TitleXL, TitleYL);

	if ( GRI.TimeLimit != 0 )
	{
		ScoreInfoString = TimeLimit $ FormatTime(GRI.RemainingTime);
	}
	else
	{
		ScoreInfoString = FooterText @ FormatTime(GRI.ElapsedTime);
	}
	
	Canvas.DrawColor.R = 13;
	Canvas.DrawColor.G = 216;
	Canvas.DrawColor.B = 7;
	Canvas.DrawColor.A = 255;

	if ( UnrealPlayer(Owner).bDisplayLoser )
	{
		ScoreInfoString = class'HUDBase'.default.YouveLostTheMatch;
	}
	else if ( UnrealPlayer(Owner).bDisplayWinner )
	{
		ScoreInfoString = class'HUDBase'.default.YouveWonTheMatch;
	}
	else if ( PlayerController(Owner).IsDead() )
	{
		RestartString = Restart;

		if ( PlayerController(Owner).PlayerReplicationInfo.bOutOfLives )
		{
			RestartString = OutFireText;
		}

		ScoreInfoString = RestartString;
	}

	TitleY = Canvas.ClipY * 0.13;
	Canvas.SetPos(0.5 * (Canvas.ClipX - TitleXL), TitleY);
	Canvas.DrawText(TitleString);

	Canvas.StrLen(ScoreInfoString, ScoreInfoXL, YL);
	Canvas.SetPos(0.5 * (Canvas.ClipX - ScoreInfoXL), TitleY + TitleYL);
	Canvas.DrawText(ScoreInfoString);
}

simulated event UpdateScoreBoard(Canvas Canvas)
{
	local PlayerReplicationInfo PRI, OwnerPRI;
	local int i,j, FontReduction, NetXPos, PlayerCount, HeaderOffsetY, HeadFoot, MessageFoot, PlayerBoxSizeY, BoxSpaceY, NameXPos, BoxTextOffsetY, OwnerOffset, HealthXPos, BoxXPos,KillsXPos, TitleYPos, BoxWidth, VetXPos, TempVetXPos, VetYPos;
	local float XL,YL, MaxScaling;
	local float deathsXL, KillsXL, netXL,HealthXL, MaxNamePos, KillWidthX, HealthWidthX, TimeXL, TimeWidthX, TimeXPos, ScoreXPos, ScoreXL;
	local bool bNameFontReduction;
	local Material VeterancyBox, StarMaterial;
	local int TempLevel, TempY;
	local string PlayerTime;
	local KFPlayerReplicationInfo KFPRI;
	local float AssistsXPos,AssistsWidthX;
	local float CashX;
	local string CashString,HealthString;
	local float OutX;
	
	local int HSXPos;

	OwnerPRI = KFPlayerController(Owner).PlayerReplicationInfo;
	OwnerOffset = -1;

	for (i = 0; i < GRI.PRIArray.Length; i++)
	{
		PRI = GRI.PRIArray[i];

		if ( !PRI.bOnlySpectator )
		{
			if ( PRI == OwnerPRI )
				OwnerOffset = i;

			PlayerCount++;
		}
	}

	PlayerCount = Min(PlayerCount, MAXPLAYERS);

	Canvas.Font = class'ROHud'.static.GetSmallMenuFont(Canvas);
	Canvas.StrLen("Test", XL, YL);
	BoxSpaceY = 0.25 * YL;
	PlayerBoxSizeY = 1.2 * YL;
	HeadFoot = 7 * YL;
	MessageFoot = 1.5 * HeadFoot;

	if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
	{
		BoxSpaceY = 0.125 * YL;
		PlayerBoxSizeY = 1.25 * YL;

		if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
		{
			if ( PlayerCount > (Canvas.ClipY - 1.5 * HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) )
			{
				PlayerBoxSizeY = 1.125 * YL;
			}
		}
	}

	if ( Canvas.ClipX < 512 )
	{
		PlayerCount = Min(PlayerCount, 1+(Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) );
	}
	else
	{
		PlayerCount = Min(PlayerCount, (Canvas.ClipY - HeadFoot) / (PlayerBoxSizeY + BoxSpaceY) );
	}

	if ( FontReduction > 2 )
	{
		MaxScaling = 3;
	}
	else
	{
		MaxScaling = 2.125;
	}

	PlayerBoxSizeY = FClamp((1.25 + (Canvas.ClipY - 0.67 * MessageFoot)) / PlayerCount - BoxSpaceY, PlayerBoxSizeY, MaxScaling * YL);

	bDisplayMessages = (PlayerCount <= (Canvas.ClipY - MessageFoot) / (PlayerBoxSizeY + BoxSpaceY));

	HeaderOffsetY = 10 * YL;
	BoxWidth = 0.7 * Canvas.ClipX;
	BoxXPos = 0.5 * (Canvas.ClipX - BoxWidth);
	BoxWidth = Canvas.ClipX - 2 * BoxXPos;
	VetXPos = BoxXPos + 0.00005 * BoxWidth;
	NameXPos = BoxXPos + 0.075 * BoxWidth;
	KillsXPos = BoxXPos + 0.50 * BoxWidth;
	AssistsXPos = BoxXPos + 0.60 * BoxWidth;
	HealthXpos = BoxXPos + 0.70 * BoxWidth;
	ScoreXPos = BoxXPos + 0.80 * BoxWidth;
	NetXPos = BoxXPos + 0.95 * BoxWidth;
	
	HSXPos = BoxXPos + 0.35 * BoxWidth;

	// draw background boxes
	Canvas.Style = ERenderStyle.STY_Alpha;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.DrawColor.A = 128;

	for ( i = 0; i < PlayerCount; i++ )
	{
		Canvas.SetPos(BoxXPos, HeaderOffsetY + (PlayerBoxSizeY + BoxSpaceY) * i);
		Canvas.DrawTileStretched( BoxMaterial, BoxWidth, PlayerBoxSizeY);
	}

	// draw title
	Canvas.Style = ERenderStyle.STY_Normal;
	DrawTitle(Canvas, HeaderOffsetY, (PlayerCount + 1) * (PlayerBoxSizeY + BoxSpaceY), PlayerBoxSizeY);

	// Draw headers
	TitleYPos = HeaderOffsetY - 1.1 * YL;
	Canvas.StrLen(HealthText, HealthXL, YL);
	Canvas.StrLen(DeathsText, DeathsXL, YL);
	Canvas.StrLen(KillsText, KillsXL, YL);
	Canvas.StrLen(PointsText, ScoreXL, YL);
	Canvas.StrLen(AssistsHeaderText, TimeXL, YL);

	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(NameXPos, TitleYPos);
	Canvas.DrawText(PlayerText,true);

	Canvas.SetPos(KillsXPos - 0.5 * KillsXL, TitleYPos);
	Canvas.DrawText(KillsText,true);

	Canvas.SetPos(ScoreXPos - 0.5 * ScoreXL, TitleYPos);
	Canvas.DrawText(PointsText,true);

	Canvas.SetPos(AssistsXPos - 0.5 * TimeXL, TitleYPos);
	Canvas.DrawText(AssistsHeaderText,true);

	Canvas.SetPos(HealthXPos - 0.5 * HealthXL, TitleYPos);
	Canvas.DrawText(HealthText,true);
	
	Canvas.SetPos(HSXPos - 0.8 *KillsXL, TitleYPos);
	Canvas.DrawText(HighscoreText, true);

	// draw player names
	MaxNamePos = 0.9 * (KillsXPos - NameXPos);

	for ( i = 0; i < PlayerCount; i++ )
	{
		Canvas.StrLen(GRI.PRIArray[i].PlayerName, XL, YL);

		if ( XL > MaxNamePos )
		{
			bNameFontReduction = true;
			break;
		}
	}

	if ( bNameFontReduction )
	{
		Canvas.Font = GetSmallerFontFor(Canvas, FontReduction + 1);
	}

	Canvas.Style = ERenderStyle.STY_Normal;
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(0.5 * Canvas.ClipX, HeaderOffsetY + 4);
	BoxTextOffsetY = HeaderOffsetY + 0.5 * (PlayerBoxSizeY - YL);

	Canvas.DrawColor = HUDClass.default.WhiteColor;
	MaxNamePos = Canvas.ClipX;
	Canvas.ClipX = KillsXPos - 4.f;

	for ( i = 0; i < PlayerCount; i++ )
	{
		Canvas.SetPos(NameXPos, (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);

		if( i == OwnerOffset )
		{
			Canvas.DrawColor.R = 13;
			Canvas.DrawColor.G = 216;
			Canvas.DrawColor.B = 7;
			Canvas.DrawColor.A = 255;
		}
		else
		{
			Canvas.DrawColor.G = 255;
			Canvas.DrawColor.B = 255;
		}

		Canvas.DrawTextClipped(GRI.PRIArray[i].PlayerName);
	}

	Canvas.ClipX = MaxNamePos;
	Canvas.DrawColor = HUDClass.default.WhiteColor;

	if ( bNameFontReduction )
	{
		Canvas.Font = GetSmallerFontFor(Canvas, FontReduction);
	}

	Canvas.Style = ERenderStyle.STY_Normal;
	MaxScaling = FMax(PlayerBoxSizeY,30.f);

	// Draw the player informations.
	for (i = 0; i < PlayerCount; i++)
	{
        KFPRI = KFPlayerReplicationInfo(GRI.PRIArray[i]) ;
		Canvas.DrawColor = HUDClass.default.WhiteColor;

		// Display perks.
		if ( KFPRI!=None && KFPRI.ClientVeteranSkill != none )
		{
			if(KFPRI.ClientVeteranSkillLevel == 6)
			{
				VeterancyBox = KFPRI.ClientVeteranSkill.default.OnHUDGoldIcon;
                StarMaterial = class'HUDKillingFloor'.default.VetStarGoldMaterial;
				TempLevel = KFPRI.ClientVeteranSkillLevel - 5;
			}
			else
			{
				VeterancyBox = KFPRI.ClientVeteranSkill.default.OnHUDIcon;
				StarMaterial = class'HUDKillingFloor'.default.VetStarMaterial;
				TempLevel = KFPRI.ClientVeteranSkillLevel;
			}

			if ( VeterancyBox != None )
			{
				TempVetXPos = VetXPos;
				VetYPos = (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY - PlayerBoxSizeY * 0.22;
				Canvas.SetPos(TempVetXPos, VetYPos);
				Canvas.DrawTile(VeterancyBox, PlayerBoxSizeY, PlayerBoxSizeY, 0, 0, VeterancyBox.MaterialUSize(), VeterancyBox.MaterialVSize());

				if(StarMaterial != none)
				{
					TempVetXPos += PlayerBoxSizeY - ((PlayerBoxSizeY/5) * 0.75);
					VetYPos += PlayerBoxSizeY - ((PlayerBoxSizeY/5) * 1.5);

					for ( j = 0; j < TempLevel; j++ )
					{
						Canvas.SetPos(TempVetXPos, VetYPos);
						Canvas.DrawTile(StarMaterial, (PlayerBoxSizeY/5) * 0.7, (PlayerBoxSizeY/5) * 0.7, 0, 0, StarMaterial.MaterialUSize(), StarMaterial.MaterialVSize());

						VetYPos -= (PlayerBoxSizeY/5) * 0.7;
					}
				}
			}
		}


		// draw kills
		if( bDisplayWithKills )
		{
			Canvas.StrLen(KFPRI.Kills, KillWidthX, YL);
			Canvas.SetPos(KillsXPos - 0.5 * KillWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
			Canvas.DrawText(KFPRI.Kills, true);

          // Draw Kill Assists

            Canvas.StrLen(KFPRI.KillAssists, AssistsWidthX, YL);
            Canvas.SetPos(AssistsXPos - 0.5 * AssistsWidthX, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
            Canvas.DrawText(KFPRI.KillAssists, true);
    	}
		
		// draw the high score
		// tag
		Canvas.SetPos(HSXPos, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
		if(SGameReplicationInfo(GRI).HighScoreArray[i].HighScore > GRI.ElapsedTime)
			Canvas.DrawText(FormatTime(SGameReplicationInfo(GRI).HighScoreArray[i].HighScore), true);
		else
			Canvas.DrawText(FormatTime(GRI.ElapsedTime), true);
		// draw cash
		
		CashString = "£"@string(int(GRI.PRIArray[i].Score)) ;

		if(GRI.PRIArray[i].Score >= 1000)
		{
            CashString = "£"@string(GRI.PRIArray[i].Score/1000.f)$"K" ;
		}

		Canvas.StrLen(CashString,CashX,YL);
		Canvas.SetPos(ScoreXPos - CashX/2 , (PlayerBoxSizeY + BoxSpaceY)*i + BoxTextOffsetY);
		Canvas.DrawColor = Canvas.MakeColor(255,255,125,255);
        Canvas.DrawText(CashString);
		Canvas.DrawColor = HUDClass.default.WhiteColor;

		// Draw health status

		HealthString = KFPRI.PlayerHealth$" HP" ;
		Canvas.StrLen(HealthString,HealthWidthX,YL);
		Canvas.SetPos(HealthXpos - HealthWidthX/2, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);

		if ( GRI.PRIArray[i].bOutOfLives )
		{
            Canvas.StrLen(OutText,OutX,YL);
			Canvas.DrawColor = HUDClass.default.RedColor;
            Canvas.SetPos(HealthXpos - OutX/2, (PlayerBoxSizeY + BoxSpaceY) * i + BoxTextOffsetY);
			Canvas.DrawText(OutText);
		}
		else
		{
			if( KFPRI.PlayerHealth>=80 )
			{
				Canvas.DrawColor = HUDClass.default.GreenColor;
			}
			else if( KFPRI.PlayerHealth>=50 )
			{
				Canvas.DrawColor = HUDClass.default.GoldColor;
			}
			else
			{
				Canvas.DrawColor = HUDClass.default.RedColor;
			}

  			Canvas.DrawText(HealthString);
		}
	}

	if (Level.NetMode == NM_Standalone)
		return;

	Canvas.StrLen(NetText, NetXL, YL);
	Canvas.DrawColor = HUDClass.default.WhiteColor;
	Canvas.SetPos(NetXPos - 0.5 * NetXL, TitleYPos);
	Canvas.DrawText(NetText,true);

	for (i=0; i<GRI.PRIArray.Length; i++)
		PRIArray[i] = GRI.PRIArray[i];

	DrawNetInfo(Canvas, FontReduction, HeaderOffsetY, PlayerBoxSizeY, BoxSpaceY, BoxTextOffsetY, OwnerOffset, PlayerCount, NetXPos);
	DrawMatchID(Canvas, FontReduction);
}

defaultproperties
{
     HighscoreText="High Score"
}
