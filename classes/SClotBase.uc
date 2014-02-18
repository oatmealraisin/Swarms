class SClotBase extends SMonster;

#exec OBJ LOAD FILE=KF_Freaks_Trip.ukx
#exec OBJ LOAD FILE=KF_Specimens_Trip_T.utx

var     KFPawn  	DisabledPawn;           // The pawn that has been disabled by this zombie's Grapple

var     bool    	bGrappling;

var     float   	GrappleEndTime;         // When the current grapple should be over
var()   float   	GrappleDuration;        // How long a grapple by this zombie should last
var	  	float  		ClotGrabMessageDelay;	// Amount of time between a player saying "I've been grabbed" message

replication
{
	reliable if(bNetDirty && Role == ROLE_Authority)
		bGrappling;
}

simulated function PostBeginPlay()
{
	local float RandomGroundSpeedScale;
	local vector AttachPos;
	local SGameType SGT;
	local float STime;

	if(ROLE==ROLE_Authority)
	{
			
		if ( (ControllerClass != None) && (Controller == None) )
			Controller = spawn(ControllerClass);

		if ( Controller != None )
			Controller.Possess(self);

		SplashTime = 0;
		SpawnTime = Level.TimeSeconds;
		EyeHeight = BaseEyeHeight;
		OldRotYaw = Rotation.Yaw;
		if( HealthModifer!=0 )
			Health = HealthModifer;

		if ( bUseExtendedCollision && MyExtCollision == none )
		{
			MyExtCollision = Spawn(class 'ExtendedZCollision',self);
			MyExtCollision.SetCollisionSize(ColRadius,ColHeight);

			MyExtCollision.bHardAttach = true;
			AttachPos = Location + (ColOffset >> Rotation);
			MyExtCollision.SetLocation( AttachPos );
			MyExtCollision.SetPhysics( PHYS_None );
			MyExtCollision.SetBase( self );
			SavedExtCollision = MyExtCollision.bCollideActors;
		}

	}


	AssignInitialPose();
	// Let's randomly alter the position of our zombies' spines, to give their animations
	// the appearance of being somewhat unique.
	SetTimer(1.0, false);

	// Set Karma Ragdoll skeleton for this character.
	if (KFRagdollName != "")
		RagdollOverride = KFRagdollName; // ClotKarma

	if (bActorShadows && bPlayerShadows && (Level.NetMode != NM_DedicatedServer))
	{
		// decide which type of shadow to spawn
		if (!bRealtimeShadows)
		{
			PlayerShadow = Spawn(class'ShadowProjector',Self,'',Location);
			PlayerShadow.ShadowActor = self;
			PlayerShadow.bBlobShadow = bBlobShadow;
			PlayerShadow.LightDirection = Normal(vect(1,1,3));
			PlayerShadow.LightDistance = 320;
			PlayerShadow.MaxTraceDistance = 350;
			PlayerShadow.InitShadow();
		}
		else
		{
			RealtimeShadow = Spawn(class'Effect_ShadowController',self,'',Location);
			RealtimeShadow.Instigator = self;
			RealtimeShadow.Initialize();
		}
	}

	bSTUNNED = false;
	DECAP = false;

	// Difficulty Scaling
	if (Level.Game != none && !bDiffAdjusted)
	{
		SGT = SGameType(Level.Game);
		STime = SGT.ElapsedTime;
		if( (GroundSpeed + (STime * SpeedPerSecondRatio) < MaxGroundSpeed ) ){
			GroundSpeed+= (STime * SpeedPerSecondRatio);
		} else {
			GroundSpeed = MaxGroundSpeed;
		}
		

		// Some randomization to their walk speeds.
		RandomGroundSpeedScale = 1.0 + ((1.0 - (FRand() * 2.0)) * 0.1); // +/- 10;

		// Store the difficulty adjusted ground speed to restore if we change it elsewhere
		OriginalGroundSpeed = GroundSpeed;

		// Scale health by time
		Health += (STime * HealthPerSecondRatio);

		ScoringValue += ((Health/5) - 4);
		
		if(MeleeDamage < MaxMeleeDamage){
			MeleeDamage += (STime*MeleePerSecondRatio);
		}

		SpinDamConst = Max((DifficultyDamageModifer() * SpinDamConst),1);
		SpinDamRand = Max((DifficultyDamageModifer() * SpinDamRand),1);

		bDiffAdjusted = true;
	}

	if( Level.NetMode!=NM_DedicatedServer )
	{
		AdditionalWalkAnims[AdditionalWalkAnims.length] = default.MovementAnims[0];
		MovementAnims[0] = AdditionalWalkAnims[Rand(AdditionalWalkAnims.length)];
	}
	
	log("SClot.PostBeginPlay():  Health:  "$Health$", Value:  "$ScoringValue$", Damage:  "$MeleeDamage$", Speed:  "$GroundSpeed, 'Swarms');
}

function float DifficultyDamageModifer()
{
	local float AdjustedDamageModifier;
	AdjustedDamageModifier = 0.3;

	AdjustedDamageModifier *= 0.75;
	
// Hey we should find a way to make it so that if the player is being surrounded, the clots do more damage.  Also we should
// bring back grapple.

	return AdjustedDamageModifier;
}

function float DifficultyHealthModifer()
{
	if(bDebug)
		log("SClotBase.DifficultyHealthModifer()", 'Swarms');
	return 1.0;
}

// Scales the health this Zed has by number of players
function float NumPlayersHealthModifer()
{
	local float AdjustedModifier;
	local int NumEnemies;
	local Controller C;

	AdjustedModifier = 1.0;

	For( C=Level.ControllerList; C!=None; C=C.NextController )
	{
		if( C.bIsPlayer && C.Pawn!=None && C.Pawn.Health > 0 )
		{
			NumEnemies++;
		}
	}

	if( NumEnemies > 1 )
	{
		AdjustedModifier += (NumEnemies - 1) * PlayerCountHealthScale;
	}

	return AdjustedModifier;
}

simulated function Tick(float DeltaTime)
{
	if ( bResetAnimAct && ResetAnimActTime<Level.TimeSeconds )
	{
		AnimAction = '';
		bResetAnimAct = False;
	}

	if ( Controller != None )
	{
		LookTarget = Controller.Enemy;
	}

	// If the Zed has been bleeding long enough, make it die
	if ( Role == ROLE_Authority && bDecapitated )
	{
		if ( BleedOutTime > 0 && Level.TimeSeconds - BleedOutTime >= 0 )
		{
			Died(LastDamagedBy.Controller,class'DamTypeBleedOut',Location);
			BleedOutTime=0;
		}

	}

	// SPLATTER!!!!!!!!!
	// TODO - can we work this into Epics gib code?
	// Will we see enough improvement in efficiency to be worth the effort?
	if ( Level.NetMode!=NM_DedicatedServer )
	{
		TickFX(DeltaTime);

		if ( bBurnified && !bBurnApplied )
		{
			if ( !bGibbed )
			{
				StartBurnFX();
			}
		}
		else if ( !bBurnified && bBurnApplied )
		{
			StopBurnFX();
		}

		if ( bAshen && Level.NetMode == NM_Client && !class'GameInfo'.static.UseLowGore() )
		{
			ZombieCrispUp();
			bAshen = False;
		}
	}

	if ( DECAP )
	{
		if ( Level.TimeSeconds > (DecapTime + 2.0) && Controller != none )
		{
			DECAP = false;
			MonsterController(Controller).ExecuteWhatToDoNext();
		}
	}

	if ( BileCount > 0 && NextBileTime<level.TimeSeconds )
	{
		--BileCount;
		NextBileTime+=BileFrequency;
		TakeBileDamage();
	}
}

defaultproperties
{
     ClotGrabMessageDelay=12.000000
     MaxGroundSpeed=180.000000
     SpeedPerSecondRatio=0.250000
     MaxMeleeDamage=50 // 100
     MeleePerSecondRatio=0.030000
     HealthPerSecondRatio=0.200000
     MeleeAnims(0)="ClotGrapple"
     MeleeAnims(1)="ClotGrappleTwo"
     MeleeAnims(2)="ClotGrappleThree"
     MoanVoice=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Talk'
     bCannibal=True
     MeleeDamage=5
     damageForce=5000
     KFRagdollName="Clot_Trip"
     MeleeAttackHitSound=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_HitPlayer'
     JumpSound=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Jump'
     CrispUpThreshhold=9
     PuntAnim="ClotPunt"
     AdditionalWalkAnims(0)="ClotWalk2"
     Intelligence=BRAINS_Mammal
     bUseExtendedCollision=True
     ColOffset=(Z=48.000000)
     ColRadius=25.000000
     ColHeight=5.000000
     ExtCollAttachBoneName="Collision_Attach"
     SeveredArmAttachScale=0.800000
     SeveredLegAttachScale=0.800000
     SeveredHeadAttachScale=0.800000
     OnlineHeadshotOffset=(X=20.000000,Z=37.000000)
     OnlineHeadshotScale=1.300000
     MotionDetectorThreat=0.340000
     HitSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Pain'
     DeathSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Death'
     ChallengeSound(0)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
     ChallengeSound(1)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
     ChallengeSound(2)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
     ChallengeSound(3)=SoundGroup'KF_EnemiesFinalSnd.clot.Clot_Challenge'
     
	 ScoringValue=3
	 
     MeleeRange=20.000000
     GroundSpeed=105.000000
     WaterSpeed=105.000000
	 
     JumpZ=340.000000
	 
     HealthMax=100000.000000
     Health=20
	 
     MenuName="Swarming Clot"
     MovementAnims(0)="ClotWalk"
     WalkAnims(0)="ClotWalk"
     WalkAnims(1)="ClotWalk"
     WalkAnims(2)="ClotWalk"
     WalkAnims(3)="ClotWalk"
     AmbientSound=Sound'KF_BaseClot.Clot_Idle1Loop'
     Mesh=SkeletalMesh'KF_Freaks_Trip.CLOT_Freak'
     DrawScale=1.100000
     PrePivot=(Z=5.000000)
     Skins(0)=Combiner'KF_Specimens_Trip_T.clot_cmb'
     RotationRate=(Yaw=45000,Roll=0)
	 
	 bDebug = false
}
