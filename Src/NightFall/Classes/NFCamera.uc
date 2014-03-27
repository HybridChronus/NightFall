class NFCamera extends Camera;

var NFCameraProperties CameraProperties;
var Rotator CameraRot,EaseIn,EaseOut;
var float CameraRotation, LerpFOV;




function UpdateViewTarget(out TViewTarget OutVT, float DeltaTime)
{
	local CameraActor	CamActor;
	local Pawn          TPawn;

	// Don't update outgoing viewtarget during an interpolation 
	if( PendingViewTarget.Target != None && OutVT == ViewTarget && BlendParams.bLockOutgoing )
	{
		return;
	}

	// Default FOV on viewtarget
	OutVT.POV.FOV = DefaultFOV;

	// Viewing through a camera actor.
	CamActor = CameraActor(OutVT.Target);
	if( CamActor != None )
	{
		CamActor.GetCameraView(DeltaTime, OutVT.POV);

		// Grab aspect ratio from the CameraActor.
		bConstrainAspectRatio	= bConstrainAspectRatio || CamActor.bConstrainAspectRatio;
		OutVT.AspectRatio		= CamActor.AspectRatio;

		// See if the CameraActor wants to override the PostProcess settings used.
		CamOverridePostProcessAlpha = CamActor.CamOverridePostProcessAlpha;
		CamPostProcessSettings = CamActor.CamOverridePostProcess;
	}
	else
	{
		TPawn = Pawn(OutVT.Target);
		if( TPawn == None || !TPawn.CalcCamera(DeltaTime, OutVT.POV.Location, OutVT.POV.Rotation, OutVT.POV.FOV) )
		{
			OutVT.Target.GetActorEyesViewPoint(OutVT.POV.Location, OutVT.POV.Rotation);
			if(CameraProperties.Direction != 0)
			{
			EaseIn.Yaw = CameraProperties.MaxRotation * CameraProperties.Direction * DegToUnrRot;
			CameraRot = RLerp(CameraRot,EaseIn,CameraProperties.SizeOfForwardSteps / 100,true);
			}
			else
			{
			CameraRot = RLerp(CameraRot,EaseOut,CameraProperties.SizeOfBackwardsSteps / 100,true);

			}
			OutVT.POV.Rotation+= CameraRot;
			// Take into account Mesh Translation so it takes into account the PostProcessing we do there.
			if ((TPawn != None) && (TPawn.Mesh != None))
			{
				OutVT.POV.Location += (TPawn.Mesh.Translation - TPawn.default.Mesh.Translation) >> OutVT.Target.Rotation;
			}
		}
	}


	ApplyCameraModifiers(DeltaTime, OutVT.POV);
}

/**
 * Lock FOV to a specific value.
 * A value of 0 to beyond 170 will unlock the FOV setting.
 */
 /*
function SetFOV(float NewFOV)
{
	if( NewFOV < 1 || NewFOV > 170 )
	{
		bLockedFOV = FALSE;
		return;
	}

	bLockedFOV	= TRUE;
	LerpFOV = NewFOV;
	//LockedFOV	= NewFOV;
}

function Tick(float DeltaTime)
{
	LockedFOV = Lerp(LockedFOV,LerpFOV,DeltaTime);
}

function float GetFOVAngle()
{
	if( bLockedFOV )
	{
		return LockedFOV;
	}

	return CameraCache.POV.FOV;
}
*/
DefaultProperties
{
	CameraProperties=NFCameraProperties'Main.Character.NFCameraProperties'
}