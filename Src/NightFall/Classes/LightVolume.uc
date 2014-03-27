class LightVolume extends Volume
	ClassGroup(NF)
   AutoExpandCategories(NF)
   placeable;

/** How Much this Area Should Increase our Character Brightness **/
var(NF) const float AdditionalBrightness;

event Touch(Actor Other, PrimitiveComponent OtherComp, vector HitLocation, vector HitNormal)
{
	local NFPawn BP;
	if(AdditionalBrightness <= 0) return;
	BP = NFPawn(Other);
	if(BP != none)
	{
		BP.AddCharacterBrightness(AdditionalBrightness);
	}
}

event UnTouch(Actor Other)
{
	local NFPawn BP;
	if(AdditionalBrightness <= 0) return;
	BP = NFPawn(Other);
	if(BP != none)
	{
		BP.AddCharacterBrightness(-AdditionalBrightness);
	}
}


DefaultProperties
{
	bMovable=true
	bStatic=false
	AdditionalBrightness=0.01
}