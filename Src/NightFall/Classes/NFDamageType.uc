class NFDamageType extends DamageType;

var bool AddHorror;
var bool AddTerror;

var localized string     	DeathString;	 			// string to describe death by this type of damage and bring up a death message

/** This is the Camera Effect you get when you die from this Damage Type **/
var const archetype UDKEmitCameraEffect DeathCameraEffectVictim;
/** This is the Camera Effect you get when you cause from this Damage Type **/
var const archetype UDKEmitCameraEffect DeathCameraEffectInstigator;

/** camera anim played instead of the default damage shake when taking this type of damage */
var const archetype CameraAnim DamageCameraAnim;


DefaultProperties
{
}
