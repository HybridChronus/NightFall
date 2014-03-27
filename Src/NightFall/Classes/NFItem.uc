class NFItem extends Object
	ClassGroup(NF)
	placeable;

var(NF) const int MaxStackSize;

var(NF) const Texture2D Icon;
var(NF) const string ItemName;
var(NF) const string Description;
var(NF) const string AdditionalInfo;
var(NF) const SoundCue PickUpSound;
var(NF) const SoundCue UseSound;

/**How should the item behave on use :) **/
var(NF) const editinline ItemBehavior newBehavior <DisplayName=Item Behavior>;

var int RealStackSize;

function Used(NFPlayerController User)
{
	if(newBehavior != none && User != none)
	{
		newBehavior.Used(User,self);
		if(UseSound != none)
			User.PlaySound(UseSound, false, true,,, true);
	}
}

function string GetToolTip()
{
	return ItemName$"\n"$Description$"\n"$AdditionalInfo;
	//return GetHtmlColorCode("BDBDBD")$"<b>"$ItemName $"</b></font><br>"$ Description$"<br><i>"$GetHtmlColorCode("#F7D358")$AdditionalInfo$"</i>"$Chr(34);
}

function string GetTexturePath()
{
	return "img://"$Icon.GetPackageName()$"."$Icon.Outer.Name$"."$Icon.Name;
}

function String GetHtmlColorCode(string ColorCode)
{
	return "<font color="$Chr(34)$ColorCode$Chr(34)$">";
}

DefaultProperties
{
	RealStackSize=1
	MaxStackSize=5
	ItemName="Default"
	Description="EEEHHHmmmM"
}