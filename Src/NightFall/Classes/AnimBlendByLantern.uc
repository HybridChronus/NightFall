class AnimBlendByLantern extends AnimNodeBlendPerBone;

var(NF) const float BlendTime;

function ChangeLanternState(bool LanternOut)
{
	if(LanternOut)
	{
		SetBlendTarget(1,BlendTime);
	}
	else
	{
		SetBlendTarget(0,BlendTime);
	}
}

DefaultProperties
{
	BlendTime=0.2
	CategoryDesc="NF"
	Children(0)=(Name="Default",Weight=1.0)
	Children(1)=(Name="Lantern")
	bFixNumChildren=true
	NodeName="BlendByLantern"
}
