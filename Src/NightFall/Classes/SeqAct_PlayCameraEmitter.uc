class SeqAct_PlayCameraEmitter extends SequenceAction;

var() const archetype NFCameraEmitter CameraEmitter;
var() const bool ReplaceOld;

var() const float LifeSpan;

event Activated()
{
	local SeqVar_Object obj;
	local NFPawn bePawn;
	local NFPlayerController bePC;

	foreach LinkedVariables(class'SeqVar_Object', obj)
	{
		bePawn = NFPawn(obj.GetObjectValue());
		if(CameraEmitter != none && bePawn != none && bePawn.NFController != none)
			bePawn.NFController.ClientSpawnCameraEffectPerArchetype(CameraEmitter,ReplaceOld,LifeSpan);
		else
		{
			bePC = NFPlayerController(obj.GetObjectValue());
			if(CameraEmitter != none && bePC != none)
				bePawn.NFController.ClientSpawnCameraEffectPerArchetype(CameraEmitter,ReplaceOld,LifeSpan);
		}

	}
}

defaultproperties
{
	ObjName="Spawn Camera Emitter"
	ObjCategory="NF"
	bCallHandler=false
	InputLinks(0)=(LinkDesc="In")
	OutputLinks(0)=(LinkDesc="Out")
}