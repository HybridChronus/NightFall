class NFCameraEmitter extends UDKEmitCameraEffect;

function Tick(float DeltaTime)
{
	local vector CamLoc;
	local rotator CamRot;
	if(PlayerController(Owner) != none)
	{
		PlayerController(Owner).GetPlayerViewPoint(CamLoc, CamRot);
		UpdateLocation(CamLoc, CamRot, PlayerController(Owner).DesiredFOV);
	}
	super.Tick(DeltaTime);
}

DefaultProperties
{
//	DistFromCamera=10

	
//	Begin Object Name=ParticleSystemComponent0
	//	MotionBlurInstanceScale=0
//	End Object

	//bPostUpdateTickGroup=true
	//bAlwaysTick=true
//	TickGroup=TG_PostUpdateWork
}