class NFCameraProperties extends Object
    HideCategories(Object);

var(Camera) const Name EyeSocketName,OverHeadSocketName;
var(Camera) const int MaxRotation;
var(Camera) const float SizeofForwardSteps,SizeOfBackwardsSteps;
var(Camera) Vector CameraPOSOffset;
var(Camera) Rotator CameraROTOffset;
var int Direction;
var bool IsTPP;
var Name ActiveSocket;

defaultproperties
{
}