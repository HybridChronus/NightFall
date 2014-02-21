class NFMapInfo extends UDKMapInfo
	hidecategories(Object)
	editinlinenew;

var() const SoundCue AmbientSoundtrack;

var() const EditInline DateTime StartDate;

var() const bool LanternAllowed;

simulated function Initialize()
{
}

DefaultProperties
{
	LanternAllowed=true;
}
