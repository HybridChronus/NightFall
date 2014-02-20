class SeqVar_DateTime extends SeqVar_Object;

function Object GetObjectValue()
{
	if(NFGameInfo(GetWorldInfo().Game) != none)
	{
		return NFGameInfo(GetWorldInfo().Game).ActualDate;
	}
}

DefaultProperties
{
    ObjName = "DateTime"
    ObjCategory = "NF"
    ObjColor=(R=0,G=255,B=255,A=255)
	SupportedClasses=(class'DateTime')
}