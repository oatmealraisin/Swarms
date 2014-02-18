class SHUD extends HUDKillingFloor;
// This was a little project of mine, I might comment this all out and use it in a separate mutator.  I hate the color of the HUD,
//		so I decided to change it.  It's still pretty ugly though, so I'm probably just going to leave it as it was...
var() int iBlue, iRed, iGreen;

simulated function UpdateHud()
{
	local float MaxGren, CurGren;
	local KFHumanPawn KFHPawn;
	local Syringe S;

	if( PawnOwner == none )
	{
		super.UpdateHud();
		return;
	}

	KFHPawn = KFHumanPawn(PawnOwner);

	CalculateAmmo();

	if ( KFHPawn != none )
	{
		FlashlightDigits.Value = 100 * (float(KFHPawn.TorchBatteryLife) / float(KFHPawn.default.TorchBatteryLife));
	}

	if ( KFWeapon(PawnOwner.Weapon) != none )
	{
		BulletsInClipDigits.Value = KFWeapon(PawnOwner.Weapon).MagAmmoRemaining;

		if ( BulletsInClipDigits.Value < 0 )
		{
			BulletsInClipDigits.Value = 0;
		}
	}

	ClipsDigits.Value = CurClipsPrimary;
	SecondaryClipsDigits.Value = CurClipsSecondary;

	if ( LAW(PawnOwner.Weapon) != none || Crossbow(PawnOwner.Weapon) != none
        || M79GrenadeLauncher(PawnOwner.Weapon) != none || PipeBombExplosive(PawnOwner.Weapon) != none
        || HuskGun(PawnOwner.Weapon) != none || CrossBuzzSaw(PawnOwner.Weapon) != none )
	{
		ClipsDigits.Value += KFWeapon(PawnOwner.Weapon).MagAmmoRemaining;
	}

	if ( PlayerGrenade == none )
	{
		FindPlayerGrenade();
	}

	if ( PlayerGrenade != none )
	{
		PlayerGrenade.GetAmmoCount(MaxGren, CurGren);
		GrenadeDigits.Value = CurGren;
	}
	else
	{
		GrenadeDigits.Value = 0;
	}

 	HealthDigits.Value = PawnOwner.Health;
	ArmorDigits.Value = xPawn(PawnOwner).ShieldStrength;

	// "Poison" the health meter
	if ( VomitHudTimer > Level.TimeSeconds )
	{
		HealthDigits.Tints[0].R = 196;
		HealthDigits.Tints[0].G = 206;
		HealthDigits.Tints[0].B = 0;

		HealthDigits.Tints[1].R = 196;
		HealthDigits.Tints[1].G = 206;
		HealthDigits.Tints[1].B = 0;
	}
	else if ( PawnOwner.Health < 50 )
	{
		if ( Level.TimeSeconds < SwitchDigitColorTime )
		{
			HealthDigits.Tints[0].R = 0;
			HealthDigits.Tints[0].G = 0;
			HealthDigits.Tints[0].B = 0;

			HealthDigits.Tints[1].R = 0;
			HealthDigits.Tints[1].G = 0;
			HealthDigits.Tints[1].B = 0;
		}
		else
		{
			HealthDigits.Tints[0].R = 255;
			HealthDigits.Tints[0].G = 0;
			HealthDigits.Tints[0].B = 0;

			HealthDigits.Tints[1].R = 255;
			HealthDigits.Tints[1].G = 0;
			HealthDigits.Tints[1].B = 0;

			if ( Level.TimeSeconds > SwitchDigitColorTime + 0.2 )
			{
				SwitchDigitColorTime = Level.TimeSeconds + 0.2;
			}
		}
	}
	else
	{
// SWARMSTAG
		HealthDigits.Tints[0].R = 50;
		HealthDigits.Tints[0].G = 255;
		HealthDigits.Tints[0].B = 50;

		HealthDigits.Tints[1].R = 50;
		HealthDigits.Tints[1].G = 255;
		HealthDigits.Tints[1].B = 50;
	}



	CashDigits.Value = PawnOwnerPRI.Score;

	WelderDigits.Value = 100 * (CurAmmoPrimary / MaxAmmoPrimary);
	SyringeDigits.Value = WelderDigits.Value;

	if ( SyringeDigits.Value < 50 )
	{
		SyringeDigits.Tints[0].R = 128;
		SyringeDigits.Tints[0].G = 128;
		SyringeDigits.Tints[0].B = 128;

		SyringeDigits.Tints[1] = SyringeDigits.Tints[0];
	}
	else if ( SyringeDigits.Value < 100 )
	{
		SyringeDigits.Tints[0].R = 96;
		SyringeDigits.Tints[0].G = 192;
		SyringeDigits.Tints[0].B = 96;

		SyringeDigits.Tints[1] = SyringeDigits.Tints[0];
	}
	else
	{
		SyringeDigits.Tints[0].R = 64;
		SyringeDigits.Tints[0].G = 255;
		SyringeDigits.Tints[0].B = 64;

		SyringeDigits.Tints[1] = SyringeDigits.Tints[0];
	}

	if ( bDisplayQuickSyringe  )
	{
		S = Syringe(PawnOwner.FindInventoryType(class'Syringe'));
		if ( S != none )
		{
			QuickSyringeDigits.Value = S.ChargeBar() * 100;

			if ( QuickSyringeDigits.Value < 50 )
			{
				QuickSyringeDigits.Tints[0].R = 128;
				QuickSyringeDigits.Tints[0].G = 128;
				QuickSyringeDigits.Tints[0].B = 128;

				QuickSyringeDigits.Tints[1] = QuickSyringeDigits.Tints[0];
			}
			else if ( QuickSyringeDigits.Value < 100 )
			{
				QuickSyringeDigits.Tints[0].R = 96;
				QuickSyringeDigits.Tints[0].G = 192;
				QuickSyringeDigits.Tints[0].B = 96;

				QuickSyringeDigits.Tints[1] = QuickSyringeDigits.Tints[0];
			}
			else
			{
				QuickSyringeDigits.Tints[0].R = 64;
				QuickSyringeDigits.Tints[0].G = 255;
				QuickSyringeDigits.Tints[0].B = 64;

				QuickSyringeDigits.Tints[1] = QuickSyringeDigits.Tints[0];
			}
		}
	}

	// Hints
	if ( PawnOwner.Health <= 50 )
	{
		KFPlayerController(PlayerOwner).CheckForHint(51);
	}

	Super(HudBase).UpdateHud();
}

simulated function DrawHealthBar(Canvas C, Actor A, int Health, int MaxHealth, float Height)
{
	local vector CameraLocation, CamDir, TargetLocation, HBScreenPos;
	local rotator CameraRotation;
	local float Dist, HealthPct;
	local color OldDrawColor;

	// rjp --  don't draw the health bar if menus are open
	// exception being, the Veterancy menu

	if ( PlayerOwner.Player.GUIController.bActive && GUIController(PlayerOwner.Player.GUIController).ActivePage.Name != 'GUIVeterancyBinder' )
	{
		return;
	}

	OldDrawColor = C.DrawColor;

	C.GetCameraLocation(CameraLocation, CameraRotation);
	TargetLocation = A.Location + vect(0, 0, 1) * (A.CollisionHeight * 2);
	Dist = VSize(TargetLocation - CameraLocation);

	CamDir  = vector(CameraRotation);

	// Check Distance Threshold / behind camera cut off
	if ( Dist > HealthBarCutoffDist || (Normal(TargetLocation - CameraLocation) dot CamDir) < 0 )
	{
		return;
	}

	// Target is located behind camera
	HBScreenPos = C.WorldToScreen(TargetLocation);

	if ( HBScreenPos.X <= 0 || HBScreenPos.X >= C.SizeX || HBScreenPos.Y <= 0 || HBScreenPos.Y >= C.SizeY)
	{
		return;
	}

	if ( FastTrace(TargetLocation, CameraLocation) )
	{
		C.SetDrawColor(192, 192, 192, 255);
		C.SetPos(HBScreenPos.X - EnemyHealthBarLength * 0.5, HBScreenPos.Y);
		C.DrawTileStretched(WhiteMaterial, EnemyHealthBarLength, EnemyHealthBarHeight);

		HealthPct = 1.0f * Health / MaxHealth;

		C.SetDrawColor(255, 0, 0, 255);
		C.SetPos(HBScreenPos.X - EnemyHealthBarLength * 0.5 + 1.0, HBScreenPos.Y + 1.0);
		C.DrawTileStretched(WhiteMaterial, (EnemyHealthBarLength - 2.0) * HealthPct, EnemyHealthBarHeight - 2.0);
	}

	C.DrawColor = OldDrawColor;
}

simulated function DrawKFHUDTextElements(Canvas C)
{
	local float    XL, YL;
	local int      NumZombies, Min;
	local string   S;
//	local vector   Pos, FixedZPos;
//	local rotator  ShopDirPointerRotation;

	if ( PlayerOwner == none || KFGRI == none || !KFGRI.bMatchHasBegun || KFPlayerController(PlayerOwner).bShopping )
	{
		return;
	}

	// Countdown Text
	
	// if( !KFGRI.bWaveInProgress)
	if( true )
	{	
		C.SetDrawColor(255, 255, 255, 255);
		C.SetPos(C.ClipX - 130, 2);
//		C.DrawTile(Material'KillingFloorHUD.HUD.Hud_Bio_Clock_Circle', 128, 128, 0, 0, 256, 256);

		if ( KFGRI.TimeToNextWave <= 5 )
		{
			// Hints
		   	if ( bIsSecondDowntime )
		   	{
				KFPlayerController(PlayerOwner).CheckForHint(40);
			}
		}
		
		Min = KFGRI.TimeToNextWave / 60;
		NumZombies = KFGRI.TimeToNextWave - (Min * 60);

		S = Eval((Min >= 10), string(Min), "0" $ Min) $ ":" $ Eval((NumZombies >= 10), string(NumZombies), "0" $ NumZombies);
		C.Font = LoadFont(2);
		C.Strlen(S, XL, YL);
		C.SetDrawColor(13, 216, 7, KFHUDAlpha);
		C.SetPos(C.ClipX - 66 - (XL / 2), 66 - YL / 2);
		C.DrawText(S, False);
	}
	else
	{
		//Hints
		if ( KFPlayerController(PlayerOwner) != none )
		{
			KFPlayerController(PlayerOwner).CheckForHint(30);

			if ( !bHint_45_TimeSet && KFGRI.WaveNumber == 1)
			{
				Hint_45_Time = Level.TimeSeconds + 5;
				bHint_45_TimeSet = true;
			}
		}

		C.SetDrawColor(255, 255, 255, 255);
		C.SetPos(C.ClipX - 128, 2);
		C.DrawTile(Material'KillingFloorHUD.HUD.Hud_Bio_Circle', 128, 128, 0, 0, 256, 256);

		S = string(KFGRI.MaxMonsters);
		C.Font = LoadFont(1);
		C.Strlen(S, XL, YL);
		C.SetDrawColor(255, 50, 50, KFHUDAlpha);
		C.SetPos(C.ClipX - 64 - (XL / 2), 66 - (YL / 1.5));
		C.DrawText(S);

		// Show the number of waves
		S = WaveString @ string(KFGRI.WaveNumber + 1) $ "/" $ string(KFGRI.FinalWave);
		C.Font = LoadFont(5);
		C.Strlen(S, XL, YL);
		C.SetPos(C.ClipX - 64 - (XL / 2), 66 + (YL / 2.5));
		C.DrawText(S);

   		//Needed for the hints showing up in the second downtime
		bIsSecondDowntime = true;
	}

	if ( KFPRI == none || KFPRI.Team == none || KFPRI.bOnlySpectator || PawnOwner == none )
	{
		return;
	}
/*
	// Draw the shop pointer
	if ( ShopDirPointer == None )
	{
		ShopDirPointer = Spawn(Class'KFShopDirectionPointer');
		ShopDirPointer.bHidden = bHideHud;
	}

	Pos.X = C.SizeX / 18.0;
	Pos.Y = C.SizeX / 18.0;
	Pos = PlayerOwner.Player.Console.ScreenToWorld(Pos) * 10.f * (PlayerOwner.default.DefaultFOV / PlayerOwner.FovAngle) + PlayerOwner.CalcViewLocation;
	ShopDirPointer.SetLocation(Pos);

	if ( KFGRI.CurrentShop != none )
	{
		// Let's check for a real Z difference (i.e. different floor) doesn't make sense to rotate the arrow
		// only because the trader is a midget or placed slightly wrong
		if ( KFGRI.CurrentShop.Location.Z > PawnOwner.Location.Z + 50.f || KFGRI.CurrentShop.Location.Z < PawnOwner.Location.Z - 50.f )
		{
		    ShopDirPointerRotation = rotator(KFGRI.CurrentShop.Location - PawnOwner.Location);
		}
		else
		{
		    FixedZPos = KFGRI.CurrentShop.Location;
		    FixedZPos.Z = PawnOwner.Location.Z;
		    ShopDirPointerRotation = rotator(FixedZPos - PawnOwner.Location);
		}
	}
	else
	{
		ShopDirPointer.bHidden = true;
		return;
	}

   	ShopDirPointer.SetRotation(ShopDirPointerRotation);

	if ( Level.TimeSeconds > Hint_45_Time && Level.TimeSeconds < Hint_45_Time + 2 )
	{
		if ( KFPlayerController(PlayerOwner) != none )
		{
			KFPlayerController(PlayerOwner).CheckForHint(45);
		}
	}

	C.DrawActor(None, False, True); // Clear Z.
	ShopDirPointer.bHidden = false;
	C.DrawActor(ShopDirPointer, False, false);
	ShopDirPointer.bHidden = true;
	DrawTraderDistance(C);		*/
}

function DrawDoorBar(Canvas C, float XCentre, float YCentre, float BarPercentage, byte BarAlpha)
{
	local float TextWidth, TextHeight;
	local string IntegrityText;

	IntegrityText = int(BarPercentage * 100) $ "%";

	if ( !bLightHud )
	{
		C.SetDrawColor(255, 255, 255, 112);
		C.Style = ERenderStyle.STY_Alpha;
		C.SetPos(XCentre - ((DoorWelderBG.USize * 1.18) / 2) , YCentre - ((DoorWelderBG.VSize * 0.9) / 2));
		C.DrawTileScaled(DoorWelderBG, 1.18, 0.9);
	}

	C.SetDrawColor(50, 255, 50, 255);

	C.Font = LoadSmallFontStatic(4);
	C.StrLen(IntegrityText, TextWidth, TextHeight);
	C.SetDrawColor(50, 255, 50, 255);
	C.SetPos(XCentre + 5 , YCentre - (TextHeight / 2.4));
	C.DrawTextClipped(IntegrityText);

	C.SetPos((XCentre - 5) - 64, YCentre - 24);
	C.Style = ERenderStyle.STY_Alpha;
	C.DrawTile(DoorWelderIcon, 64, 48, 0, 0, 256, 192);
}

simulated function DrawWeaponName(Canvas C)
{
	local string CurWeaponName;
	local float XL,YL;

	if (  PawnOwner == None || PawnOwner.Weapon == None )
	{
		return;
	}

	CurWeaponName = PawnOwner.Weapon.GetHumanReadableName();
	C.Font  = GetFontSizeIndex(C, -1);
	C.SetDrawColor(50, 255, 50, KFHUDAlpha);
	C.Strlen(CurWeaponName, XL, YL);

	// Diet Hud needs to move the weapon name a little bit or it looks weird
	if ( !bLightHud )
	{
		C.SetPos((C.ClipX * 0.983) - XL, C.ClipY * 0.90);
	}
	else
	{
		C.SetPos((C.ClipX * 0.97) - XL, C.ClipY * 0.915);
	}

	C.DrawText(CurWeaponName);
}

defaultproperties
{
     iGreen=255
     HealthBG=(Tints[0]=(B=7,G=216,R=13,A=255),Tints[1]=(B=7,G=216,R=13,A=255))
     HealthIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     HealthDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     ArmorBG=(Tints[0]=(B=7,G=216,R=13,A=255),Tints[1]=(B=7,G=216,R=13,A=255))
     ArmorIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     ArmorDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     WeightBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     WeightIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     WeightDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     GrenadeBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     GrenadeIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     GrenadeDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     ClipsBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     ClipsIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     ClipsDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SecondaryClipsBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SecondaryClipsIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SecondaryClipsDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     BulletsInClipBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     BulletsInClipIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     BulletsInClipDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     M79Icon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     PipeBombIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     LawRocketIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     ArrowheadIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SingleBulletIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     FlameIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     FlameTankIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     HuskAmmoIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SawAmmoIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     FlashlightBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     FlashlightIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     FlashlightOffIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     FlashlightDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     WelderBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     WelderIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     WelderDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SyringeBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SyringeIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     SyringeDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     MedicGunBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     MedicGunIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     MedicGunDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     QuickSyringeBG=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     QuickSyringeIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     QuickSyringeDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     CashIcon=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     CashDigits=(Tints[0]=(B=7,G=216,R=13),Tints[1]=(B=7,G=216,R=13))
     LevelActionFontColor=(B=7,G=216,R=13)
     HintBackground=(Tints[0]=(B=7,G=216,R=13))
     HintTitleWidget=(Tints[0]=(B=7,G=216,R=13,A=192),Tints[1]=(B=7,G=216,R=13,A=192))
     HintTextWidget=(Tints[0]=(B=7,G=216,R=13,A=192),Tints[1]=(B=7,G=216,R=13,A=192))
     ConsoleColor=(G=255,R=220)
}
