class PhysicalDoor extends NFKActor  implements(SaveGameStateInterface)
	ClassGroup(NF)
	placeable;

var(NF) SoundCue OpenSound;
var(NF) SoundCue CloseSound;
var(NF) SoundCue LockedSound;

var(NF) SoundCue SlideSound;

var(NF) float SlideSoundReplay, SlideSoundThreshold;

/** Limits Door Moving and gives us open/close Sounds **/
var(NF) RB_HingeActor DoorConstraint;

/** Uses a PreSetDefault Physics Behavior overriding the DoorConstraint Settings **/
var(NF) bool UseDefaultDoorBehavior;

var(NF) bool bLocked;

var Rotator oldRotation;

var float DefaultAngle, lastSoundPlayed;

var bool WasOpen;

simulated event PostBeginPlay()
{
	 super.PostBeginPlay();

	 if(UseDefaultDoorBehavior && DoorConstraint != none)
	 {
		  DoorConstraint.ConstraintActor1=self;
		  DoorConstraint.ConstraintSetup.Swing1LimitAngle=90;
		  DoorConstraint.ConstraintSetup.bSwingLimited=true;
		  DoorConstraint.ConstraintSetup.TwistLimitAngle=0;
		  DoorConstraint.ConstraintSetup.bTwistLimited=true;

		  DoorConstraint.ConstraintSetup.LinearLimitStiffness=100;
		  DoorConstraint.ConstraintSetup.LinearXSetup.bLimited=1;
		  DoorConstraint.ConstraintSetup.LinearYSetup.bLimited=1;
		  DoorConstraint.ConstraintSetup.LinearZSetup.bLimited=1;
	 }

	 DefaultAngle = DoorConstraint.ConstraintSetup.Swing1LimitAngle;
	 SetLockedNew(bLocked);
}

function SetLockedNew(bool Lock)
{
	if(Lock && DoorConstraint != none)
	{
		if(DoorConstraint.ConstraintSetup.Swing1LimitAngle != 7)
			DefaultAngle = DoorConstraint.ConstraintSetup.Swing1LimitAngle;
		DoorConstraint.ConstraintSetup.Swing1LimitAngle=7;
		StaticMeshComponent.SetRBAngularVelocity( Vect(0,0,0) );
		StaticMeshComponent.PutRigidBodyToSleep();
		StaticMeshComponent.SetRBRotation(InitialRotation);
	}
	else
		 DoorConstraint.ConstraintSetup.Swing1LimitAngle = DefaultAngle;
	DoorConstraint.InitConstraint(self,none);
}

simulated function OnToggle(SeqAct_Toggle action)
{
	bLocked = !bLocked;
	SetLockedNew(bLocked);
	//super.OnToggle(action);
}

function Tick(float DeltaTime)
{
	if(StaticMeshComponent.RigidBodyIsAwake())
	{
		if(VSize(RBState.AngVel) > 0 && Rotation != oldRotation)
		{
			if(Rotation.Yaw+1000 > InitialRotation.Yaw && Rotation.Yaw-1000 < InitialRotation.Yaw)
			{
				if(WasOpen)
				{
					StaticMeshComponent.SetRBAngularVelocity( Vect(0,0,0) );
					StaticMeshComponent.SetRBLinearVelocity(vect(0,0,0));
					StaticMeshComponent.PutRigidBodyToSleep();
					WasOpen = false;
					`log("Closed");
					if(CloseSound != none) PlaySound(CloseSound);
					TriggerEventClass(class'SeqEvent_Door',self,1);
				}
			}
			else if(!WasOpen)
			{
				WasOpen=true;
				`log("Opened");
				if(OpenSound != none) PlaySound(OpenSound);
				TriggerEventClass(class'SeqEvent_Door',self,0);
			}

			if(WorldInfo.RealTimeSeconds > lastSoundPlayed+SlideSoundReplay && VSize(RBState.AngVel) > SlideSoundThreshold)
			{
				if(SlideSound != none) PlaySound(SlideSound);
				lastSoundPlayed = WorldInfo.RealTimeSeconds;
			}
		}
		oldRotation=Rotation;
	}
	super.Tick(DeltaTime);
}



function String Serialize()
{
	local JSonObject KJSonObject;

	// Instance the JSonObject, abort if one could not be created
	KJSonObject = new class'JSonObject';

	if (KJSonObject == None)
	{
		`Warn(Self$" could not be serialized for saving the game state.");
		return "";
	}

	// Save the location
	KJSonObject.SetFloatValue("Location_X", Location.X);
	KJSonObject.SetFloatValue("Location_Y", Location.Y);
	KJSonObject.SetFloatValue("Location_Z", Location.Z);

	// Save the rotation
	KJSonObject.SetIntValue("Rotation_Pitch", Rotation.Pitch);
	KJSonObject.SetIntValue("Rotation_Yaw", Rotation.Yaw);
	KJSonObject.SetIntValue("Rotation_Roll", Rotation.Roll);

	KJSonObject.SetBoolValue("bLocked",bLocked);

	// Send the encoded JSonObject
	return class'JSonObject'.static.EncodeJson(KJSonObject);
}

function Deserialize(JSonObject Data)
{
	local Vector SavedLocation;
	local Rotator SavedRotation;

	// Deserialize the location and set it
	SavedLocation.X = Data.GetFloatValue("Location_X");
	SavedLocation.Y = Data.GetFloatValue("Location_Y");
	SavedLocation.Z = Data.GetFloatValue("Location_Z");

	// Deserialize the rotation and set it
	SavedRotation.Pitch = Data.GetIntValue("Rotation_Pitch");
	SavedRotation.Yaw = Data.GetIntValue("Rotation_Yaw");
	SavedRotation.Roll = Data.GetIntValue("Rotation_Roll");

	bLocked = Data.GetBoolValue("bLocked");

	if (self.StaticMeshComponent != None)
	{
		self.StaticMeshComponent.SetRBPosition(SavedLocation);
		self.StaticMeshComponent.SetRBRotation(SavedRotation);
	}
}

DefaultProperties
{
	SlideSoundThreshold=500
	SlideSoundReplay=1

	//bCallRigidBodyWakeEvents=true
	bLocked=false;
	UseDefaultDoorBehavior=true;
	DescriptionText = "Door";
	ObjectType = OpenAble;
	SupportedEvents.Add(class'SeqEvent_Door')

	Begin Object Name=StaticMeshComponent0
		bNotifyRigidBodyCollision=false
	End Object
}