class NFPawn extends UDKPawn implements(SaveGameStateInterface)
	ClassGroup(NF)
    AutoExpandCategories(NF)
	config(Game);

var transient NFInventoryManager NFInventoryManager;	//Reference InventoryManager

/** Lantern To Show then were pressing "F" **/
var(NF) const archetype Lantern LanternArchetype;

/** Physical Weapon that simulates our Draggen/Carrying etc **/
var(NF) const archetype PhysGrabber PhysicsArchetype;

/** SoundCues to Show how high our Pulse is **/
var(NF) const SoundCue BreathSoundSlow, BreathSound;

/** SoundCues if we get feared **/
var(NF) const SoundCue BreathSoundPant, BreathSoundScared;

/** SoundCues to Show how feared we are **/
var(NF) const SoundCue SanityLow, SanityMedium, SanityHigh;

/** SoundCues to Show how low lifed we are **/
var(NF) const SoundCue Heartbeat1, HeartBeat2, HeartBeat3;

/** SoundCues for a Terrormeter **/
var(NF) const SoundCue TerrorMeterCue;

/** Jumping Sounds **/
var(NF) const SoundCue JumpSound, FallDamageSound;

var(NF) const float RunSpeed, WalkSpeed, SneakSpeed;
var(NF) const float InjuredSpeedModifier;
/** How Far You Can Hear the Footsteps **/
var(NF) const float MaxFootstepDistSq;

/** The Multiplier of the chance to enable Horror effects**/
var(NF) float HorrorMultiplier;
/** How fast our heart is beating and how far we can run **/
var(NF) float Pulse;
var(NF) const float MaxPulse;
/** How distorted the screen is and how scared we are **/
var(NF) float Illnes;

var(NF) float TerrorMeter;

// the following is used by tfpAnimBlendByTurnInPlace to play select the correct child animation when turning in place
var int LegsTurning;

/**Camera Sockets :O**/
var NFCameraProperties Cam;
var name CameraSocket;
var(NF) const name EyeSocket, ThirdPersonSocket, LanternAttachment, WeaponAttachment, BreathParticlesAttachment, WeatherParticleAttachment;

/** Slot node used for playing animations only on the top half. */
var AnimNodeSlot TopHalfAnimSlot;

var SkelControlLimb SkeletalArmMover;
var UDKSkelControl_LookAt LookAtControl;
var AnimBlendByLantern LanternBlender;

/** AudioComponent that Plays Our Breathing Sounds **/
var(NF)  AudioComponent BreathSounds;

/** AudioComponent that Plays Our Fear Sounds **/
var(NF)  AudioComponent SanitySounds, HeartBeatSounds;

/** AudioComponent that Plays Our Terrormeter Sounds **/
var(NF)  AudioComponent TerrormeterSounds;

/** The pawn's light environment */
var(NF) DynamicLightEnvironmentComponent LightEnvironment;

var  bool OutOfBreath;
var  bool bIsSprinting;
var NFPlayerController NFController;


// (see UpdateLegsYaw() below)
var  rotator LegsOffset;
var  int MaxLegsYawIdle;
var  int MaxYawLegsRun;
var  int MaxLegsYawChangePerSecond;

// used to remember our raw rotation's yaw from last tick
var  int OldYaw;

// Used for manipulating sound and pulse rate :D
var float tempPulse,tempRate;
var  bool bInjuried;

// Used For A Timer as Well, Resets after 5 Seconds not bein Fighting an ReEnables regenarating and lowered horrormeter :D
var bool bInFight;

//Multiplies our Healing value by how much our Character stands near light
var  float CharacterBrightness;

//The Physical Material we touched last for calculating friction of our pawn
var PhysicalMaterial lastTouchedPhysicalMaterial;

// DO we alread got a Lantern?
var  bool hasLantern;

var array<Light> lightArray;

replication
{
	// replicated properties
	if ( bNetDirty )
		hasLantern;
}

exec function SwitchCamera()
{
	if(CameraSocket==EyeSocket)
		CameraSocket=ThirdPersonSocket;
	else
		CameraSocket=EyeSocket;
}

simulated event PostBeginPlay()
{
	local Light tempLight;
	super.PostBeginPlay();
	SetTimer(1, True, 'Regeneration');
	if(TerrormeterSounds != none && TerrorMeterCue != none)
		TerrorMeterSounds.SoundCue = TerrorMeterCue;
	if (Mesh != None)
		{
			BaseTranslationOffset = Mesh.Translation.Z;
			CrouchTranslationOffset = Mesh.Translation.Z + CylinderComponent.CollisionHeight - CrouchHeight;
		}
	UpdateTerrorSound();
	UpdateBreathSound();
	UpdateSanitySound();
	UpdateHealthSound();
	
	foreach AllActors(class'Light',tempLight)
	{
		`log("Added light");
		lightArray.AddItem(tempLight);
	}
	CameraSocket=EyeSocket;
	Mesh.SetTraceBlocking(false,false);
	CollisionComponent.SetTraceBlocking(false,false);
}

simulated event PostInitAnimTree(SkeletalMeshComponent SkelComp)
{
	super.PostInitAnimTree(SkelComp);
	if (SkelComp == None) return;
	AimNode = AnimNodeAimOffset(SkelComp.FindAnimNode('AimNode'));
	LookAtControl = UDKSkelControl_LookAt(SkelComp.FindSkelControl('HeadLookAt'));
	LanternBlender = AnimBlendByLantern(SkelComp.FindAnimNode('LanternBlender'));
	SkeletalArmMover = SkelControlLimb(SkelComp.FindSkelControl('LeftHand'));
	LeftLegControl = SkelControlFootPlacement(SkelComp.FindSkelControl(LeftFootControlName));
	RightLegControl = SkelControlFootPlacement(SkelComp.FindSkelControl(RightFootControlName));
}

simulated event Destroyed()
{
  Super.Destroyed();
  
  AimNode = None;
  TopHalfAnimSlot = none;
  LookAtControl = none;
  SkeletalArmMover = none;
}
 
simulated event PossessedBy(Controller C, bool bVehicleTransition)
{
	local Vector spawnloc;
	local Rotator spawnrot;
	NFController = NFPlayerController(C);
	NFController.bePawn = self;
	if(PhysicsArchetype != none)
		NFController.PhysGrabber = Spawn(class'PhysGrabber',NFController,,,,PhysicsArchetype,true);
	else
		NFController.PhysGrabber = Spawn(class'PhysGrabber',NFController,,,,,true);
	NFController.PhysGrabber.Init(NFController);

	if (NFInventoryManager == None)
		NFInventoryManager = new class'NFInventoryManager';
	if(NFInventoryManager != None)
		NFInventoryManager.InitInventory(NFHUD(NFController.myHUD),NFController,self);

	if(LanternArchetype != none && Mesh.GetSocketWorldLocationAndRotation(LanternAttachment,spawnloc,spawnrot))
	{
		NFController.Lantern = Spawn(class'Lantern',NFController,,spawnloc,spawnrot,LanternArchetype,true);
		NFController.Lantern.SetBase(self, spawnloc, Mesh, LanternAttachment);
		NFController.Lantern.SetHardAttach(true);
		Mesh.AttachComponentToSocket(NFController.Lantern.SkeletalMeshComponent,LanternAttachment);
		NFController.Lantern.SkeletalMeshComponent.SetShadowParent(Mesh);
		NFController.Lantern.SetTotallyHidden(false,0.01);
	}
	super.PossessedBy(C,bVehicleTransition);
}

function Regeneration()
{
	if(bInFight) return;
	Health = Min(HealthMax, Health + (1*CharacterBrightness));
	AddHorrorMultiplier(0.0004*(6-CharacterBrightness));
	UpdateHealthSound();
}

simulated function Tick(float DeltaTime)
{
	local Light tempLight;
	local Vector EyePos;
	local float TempDistance, TempRadius;
	super.Tick(DeltaTime);
	if(OutOfBreath)
	{
		Pulse = FMax(0, Pulse - (Pulse*0.14*DeltaTime*CharacterBrightness));
		if(Pulse < 50)
			OutOfBreath = false;
	}
	else
		Pulse = FMax(0, Pulse - (3.5*DeltaTime*CharacterBrightness));
	UpdateBreathSound();
	tempRate=Pulse/MaxPulse;
	tempPulse=(Pulse*FMax(0.95,tempRate))+(Sin(WorldInfo.RealTimeSeconds*FClamp(1,10,tempRate*10))*(Pulse*FMin(0.05,(1-tempRate))));
	UpdateLegsYaw(DeltaTime);
	if(bInFight)
		AddHorror(HorrorMultiplier*DeltaTime);
	else
	{
		TerrorMeter = FMax(0, TerrorMeter - 20*DeltaTime*CharacterBrightness);
		UpdateTerrorSound();
		Illnes = FMax(0, Illnes - ((5-HorrorMultiplier)*DeltaTime*CharacterBrightness*0.8));
	}
	CharacterBrightness=1;
	if(NFController.bLanternOut)
		CharacterBrightness+=7;
	UpdateSanitySound();
	if(Mesh.GetSocketWorldLocationAndRotation(EyeSocket,EyePos))
	{
		foreach lightArray(tempLight)
		{
			if(DirectionalLight(tempLight) != none)
			{
				if(FastTrace(tempLight.Location,EyePos,,true))
				{
					CharacterBrightness += tempLight.LightComponent.Brightness;
				}
			}
			else if(PointLight(tempLight) != none)
			{
				TempDistance = Vsize(EyePos - tempLight.Location );
				TempRadius=PointLightComponent(PointLight(tempLight).LightComponent).Radius;
				if(TempDistance < TempRadius && FastTrace(tempLight.Location,EyePos,,true))
				{
					CharacterBrightness += tempLight.LightComponent.Brightness * (1-(TempDistance/TempRadius));
				}
			}
		}
	}
	CharacterBrightness*=0.5f;
	if(CharacterBrightness > 5) CharacterBrightness=5;
}

event PlayFootStepSound(int FootDown)
{
	local NF_PhysicalMaterialProperty NFPhys;
	local Vector Hitlocation, HitNormal;
	local PlayerController PC;
	if(bIsSprinting)
		AddPulse(4);
	else if(bIsCrouched)
		AddPulse(2);
	else
		AddPulse(1);

    ForEach LocalPlayerControllers(class'PlayerController', PC)
	{
		if ( (PC.ViewTarget != None) && (VSizeSq(PC.ViewTarget.Location - Location) < MaxFootstepDistSq) )
		{
			NFPhys = GetMaterialBelowFeet(,Hitlocation,HitNormal);
			if (NFPhys != None)
			{   
				if(NFPhys.FootstepParticles != none)
				{
					WorldInfo.MyEmitterPool.SpawnEmitter(NFPhys.FootstepParticles,HitLocation,Rotator(HitNormal));
				}
				if (bIsSprinting && NFPhys.FootstepSoundRunning != none)
				{
					MakeNoise(0.1*NFPhys.MakeNoiseMultiplier);
					PlaySound(NFPhys.FootstepSoundRunning, false, true,,Hitlocation, true);
				}
				else if(bIsCrouched && NFPhys.FootstepSoundSneak != none)
				{
					PlaySound(NFPhys.FootstepSoundSneak, false, true,,Hitlocation, true);
				}
				else if(NFPhys.FootstepSoundWalk != none)
				{
					MakeNoise(0.05*NFPhys.MakeNoiseMultiplier);
					PlaySound(NFPhys.FootstepSoundWalk, false, true,,Hitlocation, true);
				}
			}
			return;
		}
	}
}

function TakeFallingDamage()
{
	local float EffectiveSpeed;

	if (Velocity.Z < -0.5 * MaxFallSpeed)
	{
		if ( Role == ROLE_Authority )
		{
			if (Velocity.Z < -1 * MaxFallSpeed)
			{
				EffectiveSpeed = Velocity.Z;
				if (TouchingWaterVolume())
				{
					EffectiveSpeed += 100;
				}
				if (EffectiveSpeed < -1 * MaxFallSpeed)
				{
					TakeDamage(-100 * (EffectiveSpeed + MaxFallSpeed)/MaxFallSpeed, None, Location, vect(0,0,0), class'DmgType_Fell');
					if(FallDamageSound != none)
						PlaySound(FallDamageSound, false, true,,Location, true);
				}
			}
		}
	}
}

event Landed(vector HitNormal, actor FloorActor)
{
	local NF_PhysicalMaterialProperty NFPhys;
	local Vector HitLocation;
	super.Landed(HitNormal,FloorActor);

	NFPhys = GetMaterialBelowFeet(3,HitLocation);
	if(NFPhys != none)
	{
		if(NFPhys.FootstepParticles != none)
			WorldInfo.MyEmitterPool.SpawnEmitter(NFPhys.FootstepParticles,HitLocation,Rotator(HitNormal));
		if (Velocity.Z < -0.5 * MaxFallSpeed && NFPhys.FootstepSoundRunning != none)
		{
			MakeNoise(1.0*NFPhys.MakeNoiseMultiplier);
			PlaySound(NFPhys.FootstepSoundRunning, false, true,,HitLocation, true);
		}
		else if (Velocity.Z < -0.7 * JumpZ && NFPhys.FootstepSoundWalk != none)
		{
			PlaySound(NFPhys.FootstepSoundWalk, false, true,,HitLocation, true);
			MakeNoise(0.8*NFPhys.MakeNoiseMultiplier);
		}
		else if(NFPhys.FootstepSoundSneak != none)
		{
			MakeNoise(0.6*NFPhys.MakeNoiseMultiplier);
			PlaySound(NFPhys.FootstepSoundSneak, false, true,,HitLocation, true);
		}
	}
}

simulated function NF_PhysicalMaterialProperty GetMaterialBelowFeet(optional float TraceLength = 1.5, optional out Vector Hitlocation, optional out Vector HitNormal)
{
	local TraceHitInfo HitInfo;
	local NF_PhysicalMaterialProperty PhysicalProperty;
	local actor HitActor;
	local float TraceDist;

	TraceDist = TraceLength * GetCollisionHeight();

	HitActor = Trace(Hitlocation, HitNormal, Location - TraceDist*vect(0,0,1), Location, false,, HitInfo, TRACEFLAG_PhysicsVolumes);
	if ( WaterVolume(HitActor) != None )
	{
		//return (Location.Z - HitLocation.Z < 0.33*TraceDist) ? 'Water' : 'ShallowWater';
	}
	if (HitInfo.PhysMaterial != None)
	{
		lastTouchedPhysicalMaterial=HitInfo.PhysMaterial;
		PhysicalProperty = NF_PhysicalMaterialProperty(HitInfo.PhysMaterial.GetPhysicalMaterialProperty(class'NF_PhysicalMaterialProperty'));
		if (PhysicalProperty != None)
		{
			return PhysicalProperty;
		}
	}
	return none;
}

exec function AddPulse(float value = 35)
{
	Pulse+=value;
	if(Pulse > MaxPulse)
	{
		Pulse = MaxPulse;
		OutOfBreath = true;
		SetWalking(false);
	}
	UpdateBreathSound();
}

exec simulated function AddHorrorMultiplier(float value = 1)
{
	HorrorMultiplier = FClamp(HorrorMultiplier+value,1,5);
}

exec simulated function AddCharacterBrightness(float value = 1)
{
	CharacterBrightness = FClamp(CharacterBrightness+value,0.5,5);
}

exec simulated function AddHorror(float value = 50)
{
	if(value < 50 && BreathSoundPant != none)
	{
		PlaySound(BreathSoundPant, false, true,,, true);
	}
	else if(BreathSoundScared != none)
	{
		PlaySound(BreathSoundScared, false, true,,, true);
	}
	AddHorrorMultiplier(-(value*0.00013));
	Illnes=FMin(100,Illnes+value);
	UpdateSanitySound();
}

exec simulated function AddTerror(float value = 50)
{
	TerrorMeter=FMin(100,TerrorMeter+value);
	AddHorrorMultiplier(-(value*0.0003));
	UpdateTerrorSound();
}

exec simulated function TakeDamageExec(float value = 50)
{
	TakeDamage(value, None, Location, vect(0,0,0), class'DmgType_Fell');
}

function simulated UpdateBreathSound()
{
	if(tempRate>0.5 && BreathSound != none)
		BreathSounds.SoundCue=BreathSound;
	else if(BreathSoundSlow != none)
		BreathSounds.SoundCue=BreathSoundSlow;

	BreathSounds.VolumeMultiplier=tempRate;
	BreathSounds.PitchMultiplier= 0.9 + (tempRate*0.25f);
}

function simulated UpdateSanitySound()
{
	if(Illnes > 70 && SanityHigh != none)
			SanitySounds.SoundCue = SanityHigh;
	else if(Illnes > 50 && SanityMedium != none)
			SanitySounds.SoundCue = SanityMedium;
	else if(Illnes > 15 && SanityLow != none)
			SanitySounds.SoundCue = SanityLow;
	SanitySounds.VolumeMultiplier=Illnes*0.01;
}

function simulated UpdateTerrorSound()
{
	local float TerrorInPercent;
	TerrorInPercent = TerrorMeter*0.012f;
	if(TerrormeterSounds != none)
	{
		TerrormeterSounds.VolumeMultiplier=TerrorInPercent;
		TerrormeterSounds.PitchMultiplier=0.92+(TerrorInPercent*0.1);
	}
}

function simulated UpdateHealthSound()
{
	local float PercentOfHealth;
	PercentOfHealth = (float(Health)/float(HealthMax));
	
	if(PercentOfHealth < 0.2 && Heartbeat3 != none)
		HeartBeatSounds.SoundCue = Heartbeat3;
	else if(PercentOfHealth < 0.4 && Heartbeat2 != none)
		HeartBeatSounds.SoundCue = Heartbeat2;
	else if(PercentOfHealth < 0.6 && Heartbeat1 != none)
		HeartBeatSounds.SoundCue = Heartbeat1;
	HeartBeatSounds.VolumeMultiplier=1-PercentOfHealth;
}

function simulated OutOfFightTimer()
{
	SetInFight(false);
}

function simulated SetInFight(bool Infight)
{
	bInFight=Infight;
	if(IsTimerActive('OutOfFightTimer'))
		ClearTimer('OutOfFightTimer');
	if(bInFight)
		SetTimer(7,false,'OutOfFightTimer');
}

simulated event TakeDamage(int Damage, Controller InstigatedBy, vector HitLocation, vector Momentum, class<DamageType> DamageType, optional TraceHitInfo HitInfo, optional Actor DamageCauser)
{
	super.TakeDamage(Damage, InstigatedBy, HitLocation, Momentum, DamageType, HitInfo, DamageCauser);
	if(ClassIsChildOf(DamageType, class'NFDamageType'))
	{
		if(class<NFDamageType>(DamageType).default.AddHorror) SetInFight(true);
		if(class<NFDamageType>(DamageType).default.AddTerror) AddTerror(Damage);
	}
	UpdateHealthSound();
}

/**GetPawnViewLocation
Someone wants the position of our eyes - lets give it to them.
Its probably CalcCamera() anyway (see above).**/
simulated event Vector GetPawnViewLocation()
{
    local vector viewLoc;

    if(Mesh.GetSocketWorldLocationAndRotation(CameraSocket, viewLoc))
		return viewLoc;
	return Location + BaseEyeHeight * vect(0,0,1);
}

/**Dying
Instead of switching to a third person view, 
match the camera to the location and rotation of the eye socket.**/
simulated State Dying
{
    simulated event rotator GetViewRotation()
    {
        local vector out_Loc;
        local rotator out_Rot;

		if(Mesh.GetSocketWorldLocationAndRotation(CameraSocket, out_Loc,out_Rot))
			return out_Rot;
		return Global.GetViewRotation();
    }

	event BeginState(Name PreviousStateName)
	{
		local Actor A;
		local array<SequenceEvent> TouchEvents;
		local int i;

		SetDyingPhysics();

		SetCollision(true, false);

		foreach TouchingActors(class'Actor', A)
		{
			if (A.FindEventsOfClass(class'SeqEvent_Touch', TouchEvents))
			{
				for (i = 0; i < TouchEvents.length; i++)
				{
					SeqEvent_Touch(TouchEvents[i]).NotifyTouchingPawnDied(self);
				}
				// clear array for next iteration
				TouchEvents.length = 0;
			}
		}
		foreach BasedActors(class'Actor', A)
		{
			A.PawnBaseDied();
		}
	}
}

event SetWalking( bool bNewIsWalking )
{
	if(OutOfBreath || bIsCrouched)
		bIsSprinting=false;
	else if (bNewIsWalking != bIsSprinting)
		bIsSprinting = bNewIsWalking;
	
	if (bIsSprinting)
	{
		//NFController.PlayerCamera.SetFOV(120);
		GroundSpeed = RunSpeed;
	}
	else
	{
		//NFController.PlayerCamera.SetFOV(90);
		if(bIsCrouched)
			GroundSpeed = SneakSpeed;
		else
			GroundSpeed = WalkSpeed;
	}
//	NFController.PlayerCamera.SetFOV(90 + ((VSize(Velocity)/RunSpeed)*30));
	//`log(VSize(Velocity));
}

function bool DoJump( bool bUpdating )
{
	if(super.DoJump(bUpdating))
	{
		AddPulse(10);
		if(JumpSound != none)
			PlaySound(JumpSound, false, true,,, true);
		return true;
	}
	return false;
}

simulated function UpdateLegsYaw(float DeltaTime)
{
	local int yawChange, newLegYaw, desiredLegYaw;
	local rotator rawRot;

	// base our raw rotation on GetBaseAimRotation(), because it takes our controller into account
	rawRot.Yaw = GetBaseAimRotation().Yaw;

	// how much did our yaw change since last time?
	yawChange = oldYaw - rawRot.Yaw;

	// setup our new legs offset yaw and normalise it
	newLegYaw = NormalizeRotAxis(LegsOffset.Yaw + yawChange);
	
	// by default, we want to center our legs
	desiredLegYaw = 0;

	// if we are falling, re-center the legs to the torso
	if (Physics == PHYS_Falling)
	{
		// no turning in place while falling
		LegsTurning = 0;
	}
	// legs are handled differently while moving
	else if (VSize2D(Velocity) != 0)
	{
		// no turning in place while moving
		LegsTurning = 0;
	}
	else
	{
		// if we want to center our legs and torso (or they nearly are anyway), no point playing the turning in place animaitons
		if (((abs(yawChange) < 10) && (abs(newLegYaw) < 1024)))
			LegsTurning = 0;
		// if we have turned too far, play the turning animation
		else if (Abs(newLegYaw) > MaxLegsYawIdle)
			LegsTurning = (newLegYaw > 0) ? -1 : 1;

		if (LegsTurning == 0)
			desiredLegYaw = newLegYaw;
	}

	// FIXME - since we're not limited players view rotation speed, limit the maximum difference to the leg yaw
	newLegYaw = ClampRotAxisFromBase(newLegYaw, 0, MaxYawLegsRun);

	// turn our legs back towards our desired leg yaw
	if (newLegYaw < desiredLegYaw)
		newLegYaw = Clamp(newLegYaw + (DeltaTime * MaxLegsYawChangePerSecond), newLegYaw, desiredLegYaw);
	else if (newLegYaw > desiredLegYaw)
		newLegYaw = Clamp(newLegYaw - (DeltaTime * MaxLegsYawChangePerSecond), desiredLegYaw, newLegYaw);
	
	LegsOffset.Yaw = newLegYaw;
	oldYaw = rawRot.Yaw;	
}


function String Serialize()
{
    local JSonObject PJSonObject;

    PJSonObject = new class'JSonObject';

    if (PJSonObject == None)
    {
		`Warn(Self$" could not be serialized for saving the game state.");
		return "";
    }

    PJSonObject.SetFloatValue("Location_X", Location.X);
    PJSonObject.SetFloatValue("Location_Y", Location.Y);
    PJSonObject.SetFloatValue("Location_Z", Location.Z);

    PJSonObject.SetIntValue("Rotation_Pitch", Rotation.Pitch);
    PJSonObject.SetIntValue("Rotation_Yaw", Rotation.Yaw);
    PJSonObject.SetIntValue("Rotation_Roll", Rotation.Roll);

	PJSonObject.SetBoolValue("Has_Lantern",hasLantern);


	PJSonObject.SetIntValue("Health",Health);
	PJSonObject.SetFloatValue("CharacterBrightness",CharacterBrightness);
	PJSonObject.SetFloatValue("HorrorMultiplier",HorrorMultiplier);
	PJSonObject.SetFloatValue("Illnes",Illnes);
	PJSonObject.SetFloatValue("Pulse",Pulse);
	PJSonObject.SetFloatValue("TerrorMeter",TerrorMeter);

	if(NFInventoryManager!=none)
		PJSonObject.SetObject("Inventory",NFInventoryManager.Serialize());

    return class'JSonObject'.static.EncodeJson(PJSonObject);
}

function Deserialize(JSonObject Data)
{
    local Vector SavedLocation;
    local Rotator SavedRotation;
	local NFGameInfo BeGameInfo;

    SavedLocation.X = Data.GetFloatValue("Location_X");
    SavedLocation.Y = Data.GetFloatValue("Location_Y");
    SavedLocation.Z = Data.GetFloatValue("Location_Z");
    SetLocation(SavedLocation);

    SavedRotation.Pitch = Data.GetIntValue("Rotation_Pitch");
    SavedRotation.Yaw = Data.GetIntValue("Rotation_Yaw");
    SavedRotation.Roll = Data.GetIntValue("Rotation_Roll");
    SetRotation(SavedRotation);

	hasLantern = Data.GetBoolValue("Has_Lantern");

	Health = Data.GetIntValue("Health");
	CharacterBrightness = Data.GetFloatValue("CharacterBrightness");
	HorrorMultiplier = Data.GetFloatValue("HorrorMultiplier");
	Illnes = Data.GetFloatValue("Illnes");
	Pulse = Data.GetFloatValue("Pulse");
	TerrorMeter = Data.GetFloatValue("TerrorMeter");

	if (NFInventoryManager == None)
		NFInventoryManager = new class'NFInventoryManager';
	if(NFInventoryManager != None)
	{
		NFInventoryManager.InitInventory(none,none,self);
		NFInventoryManager.Deserialize(Data.GetObject("Inventory"));
	}

	BeGameInfo = NFGameInfo(self.WorldInfo.Game);

	if (BeGameInfo != none)
		BeGameInfo.PendingPlayerPawn = self;
}

exec function GiveLantern()
{
	hasLantern=true;
}

exec function LookBackLeft()
{
	Cam.Direction = -1;
}

exec function LookBackRight()
{
	Cam.Direction = 1;	
}

exec function LookForward()
{
	Cam.Direction = 0;	
}

defaultproperties
{

	Cam=NFCameraProperties'Main.Character.NFCameraProperties'
	LeftFootBone="LeftFoot"
	RightFootBone="RightFoot"
	LeftFootControlName="LeftFootControl"
	RightFootControlName="RightFootControl"
	BaseTranslationOffset=6.0
	CrouchTranslationOffset=5
	bEnableFootPlacement=false
	MaxFootPlacementDistSquared=9000000.0

	CharacterBrightness=0.5

	MaxFootstepDistSq=1000
	HorrorMultiplier=1f
	Pulse=0f
	Illnes=0f
	MaxPulse=100f

	WalkSpeed=300
	RunSpeed=640
	SneakSpeed=200
	InjuredSpeedModifier=0.7

	EyeSocket=Camera_First_Person
	ThirdPersonSocket=Camera_Third_Person

	OutOfBreath = false;

	bPhysRigidBodyOutOfWorldCheck=TRUE
	bRunPhysicsWithNoController=true

	bCanCrouch=true
	bCanClimbLadders=True
	bCanStrafe=True
	bCanSwim=true

	Buoyancy=+000.99000000
	UnderWaterTime=+00020.000000
	RotationRate=(Pitch=20000,Yaw=20000,Roll=20000)
	AirControl=+0.35

	WalkingPct=+0.4
	CrouchedPct=+0.4
	BaseEyeHeight=38.0
	EyeHeight=38.0
	GroundSpeed=630.0
	AirSpeed=640.0
	WaterSpeed=220.0
	AccelRate=2048.0
	JumpZ=482.0
	CrouchHeight=29.0
	CrouchRadius=21.0
	WalkableFloorZ=0.78

	ViewPitchMin=-18000
	ViewPitchMax=18000

	Components.Remove(Sprite)

	Begin Object Class=DynamicLightEnvironmentComponent Name=MyLightEnvironment
		bSynthesizeSHLight=TRUE
		bIsCharacterLightEnvironment=TRUE
		bUseBooleanEnvironmentShadowing=FALSE
	End Object
	Components.Add(MyLightEnvironment)
	LightEnvironment=MyLightEnvironment

	Begin Object Class=SkeletalMeshComponent Name=WPawnSkeletalMeshComponent
		bCacheAnimSequenceNodes=FALSE
		AlwaysLoadOnClient=true
		AlwaysLoadOnServer=true
		bOwnerNoSee=false
		CastShadow=true
		BlockRigidBody=TRUE
		bUpdateSkelWhenNotRendered=true
		bIgnoreControllersWhenNotRendered=TRUE
		bUpdateKinematicBonesFromAnimation=true
		bCastDynamicShadow=true
		Translation=(Z=8.0)
		RBChannel=RBCC_Untitled3
		RBCollideWithChannels=(Untitled3=true)
		LightEnvironment=MyLightEnvironment
		bOverrideAttachmentOwnerVisibility=true
		bAcceptsDynamicDecals=FALSE
		//AnimTreeTemplate=AnimTree'CH_AnimHuman_Tree.AT_CH_Human'
		bHasPhysicsAssetInstance=true
		TickGroup=TG_PreAsyncWork
		MinDistFactorForKinematicUpdate=0.2
		bChartDistanceFactor=true
		//bSkipAllUpdateWhenPhysicsAsleep=TRUE
		RBDominanceGroup=20
		Scale=1.7
		MotionBlurInstanceScale=0
		// Nice lighting for hair
		bUseOnePassLightingOnTranslucency=TRUE
		bPerBoneMotionBlur=true
	End Object
	Mesh=WPawnSkeletalMeshComponent
	Components.Add(WPawnSkeletalMeshComponent)

	bPushesRigidBodies=true
	bIgnoreForces=false
	bAllowLedgeOverhang=true
	bCanPickupInventory=false

	begin object Class=AudioComponent Name=BreathAudioComponent
		bAutoPlay=true
		bAlwaysPlay=true
		bShouldRemainActiveIfDropped=true
	end object
	BreathSounds=BreathAudioComponent
	Components.Add(BreathAudioComponent)

	begin object Class=AudioComponent Name=HeartBeatAudioComponent
		bAutoPlay=true
		bAlwaysPlay=true
		bShouldRemainActiveIfDropped=true
	end object
	HeartBeatSounds=HeartBeatAudioComponent
	Components.Add(HeartBeatAudioComponent)

	begin object Class=AudioComponent Name=SanityAudioComponent
		bAutoPlay=true
		bAlwaysPlay=true
		bShouldRemainActiveIfDropped=true
	end object
	SanitySounds=SanityAudioComponent
	Components.Add(SanityAudioComponent)

	begin object Class=AudioComponent Name=TerrormeterAudioComponent
		bAutoPlay=true
		bAlwaysPlay=true
		bShouldRemainActiveIfDropped=true
	end object
	TerrormeterSounds=TerrormeterAudioComponent
	Components.Add(TerrormeterAudioComponent)
}