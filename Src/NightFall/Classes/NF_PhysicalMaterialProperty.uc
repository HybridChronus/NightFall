class NF_PhysicalMaterialProperty extends PhysicalMaterialPropertyBase;

var(NF) const name MaterialName;
var(NF) const SoundCue FootstepSoundWalk;
var(NF) const SoundCue FootstepSoundSneak;
var(NF) const SoundCue FootstepSoundRunning;

var(NF) const ParticleSystem FootstepParticles;

var(NF) const SoundCue DestroyedSound;
var(NF) const ParticleSystem DestroyedParticles;

var(NF) const float MakeNoiseMultiplier;

DefaultProperties
{
	MakeNoiseMultiplier=1
}