class SHumanPawn extends KFHumanPawn;

// At one point when I didn't know what I was doing I grabbed this class because I could, turned off 
//		the flashlight running out, because that's pointless really, what if I wanted to make a map
//		that you needed the flashlight!?  I'm really thinking of making a mutator that uses that
//		drugs thing down there...  

function Timer()
{
	local Actor WallActor;
	local KFBloodSplatter Streak;
	local vector WallHit, WallNormal;

	if (BurnDown > 0)
	{
		LastBurnDamage *= 0.5;
        TakeFireDamage(LastBurnDamage, BurnInstigator);
	}
	else
	{
		RemoveFlamingEffects();
		StopBurnFX();
	}

	if (Controller != none)
	{
		if(KFPC != none )
		{
			bOnDrugs = false;
			// Update for the scoreboards.
			if (Health <= 0)
			{
				PlaySound(MiscSound,SLOT_Talk);
				return;
			}
			if ( Health < HealthMax * 0.25 )
			{
				PlaySound(BreathingSound, SLOT_Talk, ((50-Health)/5)*TransientSoundVolume,,TransientSoundRadius,, false);
				WallActor = Trace(WallHit, WallNormal, Location - 50 * Velocity, Location, false);
				Streak= spawn(class 'KFMod.KFBloodSplatter',,,vect(0,0,0), Rotation);
				if (Streak != none)
					Streak.SetRotation(Rotator(Velocity));
			}

			// Accuracy vs. Movement tweakage!  - Alex
			if (KFWeapon(Weapon) != none)
				KFWeapon(Weapon).AccuracyUpdate(vsize(Velocity));
		}
	}

	// TODO: WTF? central here
	// Instantly set the animation to arms at sides Idle if we've got no weapon (rather than Pointing an invisible gun!)
	if (Weapon != none)
	{
		if (WeaponAttachment(Weapon.ThirdPersonActor) == none && VSize(Velocity) <= 0)
			IdleWeaponAnim = IdleRestAnim;
	}
	else if (Weapon == none)
		IdleWeaponAnim = IdleRestAnim;


}

defaultproperties
{
     HealthSpeedModifier=0.000000
     WeightSpeedModifier=0.000000
}
