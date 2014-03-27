/**If performance should lower try this with KActorFromStatic and make all our Kactors static **/
class PhysGrabber extends Actor
	ClassGroup(NF)
	placeable;

var(NF) float	WeaponImpulse;
var(NF) float	HoldDistanceMin;
var(NF) float	HoldDistanceMax;

var(NF) float objRotationRate;

var(NF) float ThrowImpulse;
var(NF) float	ChangeHoldDistanceIncrement;

var(NF) RB_Handle PhysicsGrabber;

var	float HoldDistance;
var	Quat HoldOrientation;

var NFPlayerController Owner;

var LastInteractableObject Door;

function Init(NFPlayerController NFController)
{
	//StaticMeshComponent.BodyInstance.GetBodyMass()
	Owner=NFController;
}
//
simulated function StartFire(byte FireModeNum,LastInteractableObject targetObject)
{
	local actor						HitActor;
	local float						HitDistance;
	local Quat						PawnQuat, InvPawnQuat, ActorQuat;
	local SkeletalMeshComponent		SkelComp;
	local StaticMeshComponent HitComponent;
	local KActorFromStatic NewKActor;

	if ( Role < ROLE_Authority || Owner == none || (FireModeNum != 2 && FireModeNum !=0)) return;
	if(Door.Interactable != none) Door.Interactable = none;
	HitActor = Actor(targetObject.Interactable);

	if(Owner.Pawn.Base == HitActor) return;

	HitDistance = VSize(targetObject.HitLocation - targetObject.StartLocation);
	HitComponent = StaticMeshComponent(targetObject.HitInfo.HitComponent);

	if ( (HitComponent != None) ) 
	{
		if(targetObject.HitInfo.PhysMaterial != none)
		{
			if(targetObject.HitInfo.PhysMaterial.ImpactSound != none)
				PlaySound(targetObject.HitInfo.PhysMaterial.ImpactSound,,,,targetObject.HitLocation);

			if(targetObject.HitInfo.PhysMaterial.ImpactEffect != none)
				WorldInfo.MyEmitterPool.SpawnEmitter(targetObject.HitInfo.PhysMaterial.ImpactEffect, targetObject.HitLocation, rotator(targetObject.HitNormal), none);
		}

		if( HitComponent.CanBecomeDynamic() )
		{
			NewKActor = class'KActorFromStatic'.Static.MakeDynamic(HitComponent);
			if ( NewKActor != None )
				HitActor = NewKActor;
		}
	}

	// POKE
	if(FireModeNum == 2)
	{
		if ( PhysicsGrabber.GrabbedComponent == None )
		{
			if( HitActor != None && HitActor != WorldInfo &&targetObject.HitInfo.HitComponent != None )
				targetObject.HitInfo.HitComponent.AddImpulse(Owner.outWorldDirection * targetObject.HitInfo.HitComponent.BodyInstance.GetBodyMass() * WeaponImpulse, targetObject.HitLocation, targetObject.HitInfo.BoneName);
		}
		else
		{
			PhysicsGrabber.GrabbedComponent.AddImpulse(Owner.outWorldDirection * ThrowImpulse, , PhysicsGrabber.GrabbedBoneName);
			PhysicsGrabber.ReleaseComponent();
		}
	}
	// GRAB
	else if(FireModeNum == 0)
	{
		if( HitActor != None && HitActor != WorldInfo && targetObject.HitInfo.HitComponent != None && HitDistance > HoldDistanceMin && HitDistance < HoldDistanceMax )
		{
			if(targetObject.Interactable.GetType() == OpenAble)
			{
				Door = targetObject;
				return;
			}

			// If grabbing a bone of a skeletal mesh, dont constrain orientation.
			SkelComp = SkeletalMeshComponent(targetObject.HitInfo.HitComponent);
			PhysicsGrabber.GrabComponent(targetObject.HitInfo.HitComponent, targetObject.HitInfo.BoneName, targetObject.HitLocation, (SkelComp == None));

			// If we succesfully grabbed something, store some details.
			if (PhysicsGrabber.GrabbedComponent != None)
			{
				HoldDistance	= HitDistance;
				PawnQuat		= QuatFromRotator( rotator(owner.outWorldDirection) );
				InvPawnQuat		= QuatInvert( PawnQuat );

				if ( targetObject.HitInfo.BoneName != '' )
					ActorQuat = SkelComp.GetBoneQuaternion(targetObject.HitInfo.BoneName);
				else
					ActorQuat = QuatFromRotator( PhysicsGrabber.GrabbedComponent.Owner.Rotation );

				HoldOrientation = QuatProduct(InvPawnQuat, ActorQuat);
			}
		}
	}
}

final operator(22) rotator >> (rotator A, rotator B)
{
	local vector X, Y, Z;

	GetAxes(A, X, Y, Z);
	X = X >> B;
	Y = Y >> B;
	Z = Z >> B;
	return OrthoRotation(X, Y, Z);
}

simulated function RotateObject(Rotator RotationAdded, Vector RotationVect, float DeltaTime)
{
	local KActor temp;
	local Vector vec2;
	if(Door.Interactable != none)
	{
		if(VSize(Door.HitLocation-Owner.outWorldOrigin) > HoldDistanceMax+90)
		{
			Stopfire(0);
			return;
		}
		temp = KActor(Door.Interactable);
		if(temp != none)
		{
			//vec2 = (Door.HitNormal*RotationVect);
			//DrawDebugLine(Door.HitLocation,Door.HitLocation+(Door.HitNormal*20),255,0,0,false);
			vec2 = (Door.HitNormal*RotationVect);
			//DrawDebugLine(Door.HitLocation,Door.HitLocation+(vec2*20),0,0,255,false);
			temp.StaticMeshComponent.AddForce(vec2*5*DeltaTime,Door.HitLocation);
		
			//`log(RotationVect);
		}
	}
	else if ( PhysicsGrabber.GrabbedComponent != None )
		HoldOrientation=QuatFromRotator(QuatToRotator(HoldOrientation)>>(RotationAdded*DeltaTime*objRotationRate));
}

simulated function StopFire(byte FireModeNum)
{
	if(Door.Interactable != none) Door.Interactable = none;
	if ( PhysicsGrabber.GrabbedComponent != None )
	{
		PhysicsGrabber.ReleaseComponent();
	}
}

simulated function bool ZoomOut()
{
	HoldDistance += ChangeHoldDistanceIncrement;
	HoldDistance = FMin(HoldDistance, HoldDistanceMax);
	return false;
}

simulated function bool ZoomIn()
{
	HoldDistance -= ChangeHoldDistanceIncrement;
	HoldDistance = FMax(HoldDistance, HoldDistanceMin);
	return false;
}

simulated function Tick( float DeltaTime )
{
	local vector	NewHandlePos;
	local Quat		PawnQuat, NewHandleOrientation;

	if(Owner == none || PhysicsGrabber.GrabbedComponent == None) return;

	PhysicsGrabber.GrabbedComponent.WakeRigidBody( PhysicsGrabber.GrabbedBoneName );

	if(InteractableInterface(PhysicsGrabber.GrabbedComponent.Owner).GetType() == OpenAble)
	{
		PawnQuat				= QuatFromRotator( Owner.Rotation );
		NewHandleOrientation	= QuatProduct(PawnQuat, HoldOrientation);
		PhysicsGrabber.SetOrientation( NewHandleOrientation );
	}
	else if(Owner.Pawn.Base != PhysicsGrabber.GrabbedComponent.Owner)
	{
		NewHandlePos	= Owner.outWorldOrigin + (HoldDistance * Owner.outWorldDirection);
		PhysicsGrabber.SetLocation( NewHandlePos );

		// Update handle orientation on grabbed actor.
		PawnQuat				= QuatFromRotator( Owner.Rotation );
		NewHandleOrientation	= QuatProduct(PawnQuat, HoldOrientation);
		PhysicsGrabber.SetOrientation( NewHandleOrientation );
	}
	else
	{
		Owner.StopFire(0);
	}
}

DefaultProperties
{
	objRotationRate=30
	HoldDistanceMin=50.0
	HoldDistanceMax=750.0
	WeaponImpulse=2000.0
	ThrowImpulse=100.0
	ChangeHoldDistanceIncrement=50.0

	Begin Object Class=RB_Handle Name=RB_Handle0
		LinearDamping=1.0
		LinearStiffness=50.0
		AngularDamping=1.0
		AngularStiffness=50.0
	End Object
	Components.Add(RB_Handle0)
	PhysicsGrabber=RB_Handle0
}