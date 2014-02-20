class NFHUD extends HUD dependson(Dialog);


enum MessageType
{
	MESS_Hint,
	MESS_Pickup,
	MESS_Note,
};

struct NFMessage
{
	var MessageType MessageType;
	var float TimeAlife;
	var string Message;
	var Texture2D Icon;

	structdefaultproperties
	{
		TimeAlife=4
	}
};

struct Button
{
	var float X, Y, Width, Height;
	var string Text;
};

enum NoteBookPage
{
	NBP_Main,
	NBP_Notes,
	NBP_Memos,
	NBP_Diary
};

var bool ReadingNote;
var int NoteID;
var NoteBookPage PageOfNotebook;

struct BlinkingIcon
{
	var bool Up;
	var float Cooldown;
	var float Alpha;
};

var BlinkingIcon InventoryIconBlink, NoteBookIconBlink; 
var Texture2D NoteBookIcon, InventoryIcon;

var Vector2D mousePos;
var	const	color	BlackColor, BlueColor, YellowColor, LilaColor, GreyColor, OrangeColor;
var Texture2D DefaultCrosshair, InteractableCrosshair, ObserverableCrosshai, OpenCrosshair, PickupCrosshair;
var Texture2D MouseCursor;

var Font Mathilde, LastKingQuest, FaceYourFears, MathildeBig;

struct HitEffectsStruct
{
	var Texture2D TempHitEffect;
	var float FloatVisiblity;
	var Vector Position;
};

var array<HitEffectsStruct> HitEffects;

var Texture2D BloodSplat01, BloodSplat02, BloodSplat03;


var MaterialInstanceConstant PostProcessMaterial;
var MaterialEffect UnderWaterEffect;
var MaterialInstance AssignedMaterial;
var UberPostProcessEffect PostProccesControl;

/**Lerp Values to Interpolate our PostProcessing Effects**/
var float HealthLerp, VignetteLerp, DistortionLerp;

var array<NFMessage> NFMessages;

/** Used for Mouse Input **/
var string NameOfMouseDownObject;
var bool bMousePressed;
var bool bLastMousePressed;

// Used to play our Dialogs
var Dialog actualDialog;

var array<Button> NoteBookMainButtons;
var array<Button> NoteBookSubButtons;
var array<Button> MenuButtons;

var const  AudioComponent DialogPlayer;

var byte LastAlphaKeyPress;

var float OldTonemapperScale;

function MouseClick(byte FireModeNum, bool MouseDown)
{
	if(FireModeNum == 0)
	{
		if(MouseDown) NameOfMouseDownObject="";
		bMousePressed=MouseDown;
	}
	//`log("Last Mouse: " @bLastMousePressed@", new mouse: "@bMousePressed@", Name: "@NameOfMouseDownObject);
}

function PlayDialog(Dialog _dialog)
{
	local Dialog newDialog;
	local Notes newNote;
	local int i;
	local NFPawn bePawn;
	if(_dialog != none && _dialog.FullDialog.Length > 0)
	{
		if(actualDialog != none)
			actualDialog=none;
		newDialog = new class'Dialog';
		newDialog.FullDialog = _dialog.FullDialog;
		if(_dialog.NoteToAddToPlayer != none)
			newDialog.NoteToAddToPlayer = _dialog.NoteToAddToPlayer;
		else if(_dialog.LogTextIfNoNoteSpecified)
		{
			bePawn = NFPawn(PlayerOwner.Pawn);
			if(bePawn != none && bePawn.NFInventoryManager != none && NFGameInfo(WorldInfo.Game) != none)
			{
				newNote = new class'Notes';
				newNote.TypeOfNote = DiaryEntry;
				if(bePawn.NFInventoryManager.Diary.Length > 0)
					newNote.EntryNumber = bePawn.NFInventoryManager.Diary[0].EntryNumber +1;
				newNote.Headline = "Memories:"@NFGameInfo(WorldInfo.Game).ActualDate.ToString();
				//newNote.Text 
				for(i=0;i<newDialog.FullDialog.Length;i++)
					newNote.Text $= newDialog.FullDialog[i].Message$"\n";
				newDialog.NoteToAddToPlayer = newNote;
			}
		}
		actualDialog = newDialog;
		_dialog=none;
	}
}

event PostBeginPlay()
{
	local LocalPlayer LocalPlayer;
//	local MaterialEffect tempPostProcessEffect;
	super.PostBeginPlay();

	AssignedMaterial = new(None) Class'MaterialInstanceConstant';
    AssignedMaterial.SetParent( PostProcessMaterial);

	if (PostProccesControl == none || AssignedMaterial == none)
	{
		AssignedMaterial = new(None) Class'MaterialInstanceConstant';
		AssignedMaterial.SetParent( PostProcessMaterial);
		LocalPlayer = LocalPlayer(PlayerOwner.Player);
		if (LocalPlayer != None && LocalPlayer.PlayerPostProcess != None)
		{
		  PostProccesControl = UberPostProcessEffect(LocalPlayer.PlayerPostProcess.FindPostProcessEffect('Uber'));
		 // tempPostProcessEffect = MaterialEffect(LocalPlayer.PlayerPostProcess.FindPostProcessEffect('Horror'));
		 // tempPostProcessEffect.Material = AssignedMaterial;
		}
   }

   ///Set Up Buttons :D
	NoteBookMainButtons.AddItem(CreateNewButton("Notes",0,-100,200,60));
	NoteBookMainButtons.AddItem(CreateNewButton("Diary",0,0,200,60));
	NoteBookMainButtons.AddItem(CreateNewButton("Memos",0,100,200,60));
	NoteBookMainButtons.AddItem(CreateNewButton("Back",0,200,200,60));

	NoteBookSubButtons.AddItem(CreateNewButton("Back",0,-100,100,50));
	NoteBookSubButtons.AddItem(CreateNewButton("Last",-300,-100,100,50));
	NoteBookSubButtons.AddItem(CreateNewButton("Next",300,-100,100,50));

	MenuButtons.AddItem(CreateNewButton("Back",0,100,200,60));
//	MenuButtons.AddItem(CreateNewButton("Save1",-220,-100,200,60));
//	MenuButtons.AddItem(CreateNewButton("Save2",0,-100,200,60));
//	MenuButtons.AddItem(CreateNewButton("Save3",220,-100,200,60));
//	MenuButtons.AddItem(CreateNewButton("Load1",-220,0,200,60));
//	MenuButtons.AddItem(CreateNewButton("Load2",0,0,200,60));
//	MenuButtons.AddItem(CreateNewButton("Load3",220,0,200,60));
//	MenuButtons.AddItem(CreateNewButton("Options",0,100,200,60));
	MenuButtons.AddItem(CreateNewButton("Leave",0,0,200,60));
}

function Button CreateNewButton(string Text, float XPos, float YPos, float Width, float Height)
{
	local Button tempButton;
	tempButton.Text=Text;
	tempButton.X=XPos;
	tempButton.Y=YPos;
	tempButton.Width=Width;
	tempButton.Height=Height;
	return tempButton;
}

event PostRender()
{
	local NFPawn bePawn;
	local NFPlayerController beController;
	local float XL,YL,multiRenderDelta;
	local float PercentOfFear;
	multiRenderDelta = RenderDelta*10;

	if(PlayerOwner != none && PlayerOwner.Pawn != none && PlayerOwner.Pawn.Health > 0)
	{
		beController = NFPlayerController(PlayerOwner);
		if(beController != none)
		{
			Canvas.DeProject(vect2d(CenterX,CenterY),beController.outWorldOrigin,beController.outWorldDirection);
			//beController.outWorldOrigin+=beController.outWorldDirection*10;
			//beController.outWorldOrigin = beController.bePawn.GetPawnViewLocation();
			//beController.outWorldDirection = vector(beController.bePawn.GetViewRotation());
		}
		super.PostRender();
		bePawn = NFPawn(PlayerOwner.Pawn);
		if(AssignedMaterial != none && bePawn != none)
		{
			OldTonemapperScale = Lerp(OldTonemapperScale,bePawn.CharacterBrightness*0.6,RenderDelta*0.5);
		//	PostProccesControl.TonemapperToeFactor = OldTonemapperScale;

			PercentOfFear=bePawn.Illnes/float(100);
			HealthLerp=Lerp(HealthLerp,float(PlayerOwner.Pawn.Health)/float(PlayerOwner.Pawn.HealthMax),multiRenderDelta);
		    VignetteLerp=Lerp(VignetteLerp,FMax(1,FMax(2,(PercentOfFear*20))*FMax(0.5,(bePawn.tempPulse*0.02))),multiRenderDelta);
		    DistortionLerp=Lerp(DistortionLerp,PercentOfFear*0.15,multiRenderDelta);
			//PlayerOwner.PlayerCamera.SetFOV(Lerp(90,120,FMin(0,PercentOfFear*FMax(0.5,(bePawn.tempPulse*0.04)))));
			AssignedMaterial.SetScalarParameterValue('VignetteScale',VignetteLerp);
			AssignedMaterial.SetScalarParameterValue('DistortionScale',DistortionLerp);
			AssignedMaterial.SetScalarParameterValue('HitMaskBlendPower',HealthLerp);
		}
	}
	else if(AssignedMaterial != none)
	{
		HealthLerp=Lerp(HealthLerp,0,multiRenderDelta);
		VignetteLerp=Lerp(VignetteLerp,50,multiRenderDelta);
		DistortionLerp=Lerp(DistortionLerp,0.03f,multiRenderDelta);
		AssignedMaterial.SetScalarParameterValue('VignetteScale',VignetteLerp);
		AssignedMaterial.SetScalarParameterValue('DistortionScale',DistortionLerp);
		AssignedMaterial.SetScalarParameterValue('HitMaskBlendPower',HealthLerp);
		Canvas.Font=FaceYourFears;
		Canvas.SetDrawColorStruct(WhiteColor);
		Canvas.TextSize("'You're Dead!!!'",XL,YL);
		Canvas.SetPos(CenterX-(XL*0.5),CenterY);
		Canvas.DrawText("'You're Dead!!!'",true);
		DrawMenu();
	}
	mousePos = LocalPlayer(PlayerOwner.Player).ViewportClient.GetMousePosition();
	bLastMousePressed=bMousePressed;
	LastAlphaKeyPress=-1;
}

function DrawHUD()
{
	local NFPawn bePawn;
	local NFPlayerController bController;

	bController = NFPlayerController(PlayerOwner);
    super.DrawHUD();
   if(bController != none && (bController.PlayerUIState != PS_GamePlay))
   {
	 // PostProccesControl.SceneDesaturation=0.9;
	 // PostProccesControl.SceneColorize=vect(1.3,1.1,0.8);
	  switch(bController.PlayerUIState)
	  {
		 case PS_Inventory:
		 	DrawInventory(); 
		 //	DrawDateTime();
			bePawn = NFPawn(PlayerOwner.Pawn);
			if(bePawn != none)
			{
			//	DrawBarOutline(0,0,15,200,bePawn.Health,bePawn.HealthMax,RedColor,GreyColor);
				if(bePawn.OutOfBreath)
				//	DrawBarOutline(0,16,15,200,bePawn.tempPulse,bePawn.MaxPulse,OrangeColor,GreyColor);
			//	else
				//	DrawBarOutline(0,16,15,200,bePawn.tempPulse,bePawn.MaxPulse,YellowColor,GreyColor);
				//	DrawBarOutline(0,32,15,200,bePawn.Illnes,100,LilaColor,GreyColor);

					Canvas.Font = Mathilde;
					Canvas.SetDrawColorStruct(WhiteColor);
				//	Canvas.SetPos(0,48);
				//	Canvas.DrawText("HorrorMultiplier = " @ bePawn.HorrorMultiplier);
				//	Canvas.SetPos(0,60);
				//	Canvas.DrawText("Terrormeter = " @ bePawn.TerrorMeter);
				//	Canvas.SetPos(0,72);
			//		Canvas.DrawText("Brightness = " @ bePawn.CharacterBrightness);
			} 
		 	break;
		 case PS_Menu: DrawMenu(); break;
		 case PS_Notes: DrawNotes(); break;//DrawDateTime(); 
	  }
	  DrawMouseCursor();
   }
   else
   {
	 // PostProccesControl.SceneColorize=vect(1,1,1);
	 // PostProccesControl.SceneMidTones=vect(1,1,1);
	 // PostProccesControl.SceneDesaturation=0;

      DrawCrosshair();
	  UpdateInfoButtons();
	  DrawFocus();
	  HandleMessages();
	  UpdateDialog();
	  DrawHitMaterial();
   }
}

exec function AddHitEffect()
{
	local HitEffectsStruct tempEffect;
	tempEffect.TempHitEffect = BloodSplat01;
	tempEffect.FloatVisiblity=1;
	tempEffect.Position.X = FRand()*(SizeX-tempEffect.TempHitEffect.SizeX*2);
	tempEffect.Position.Y = FRand()*(SizeY-tempEffect.TempHitEffect.SizeY*2);
	HitEffects.AddItem(tempEffect);
}


function DrawHitMaterial()
{
	local HitEffectsStruct tempEffect;
	foreach HitEffects(tempEffect)
	{
		tempEffect.FloatVisiblity-=RenderDelta;
		Canvas.SetPos(tempEffect.Position.X,tempEffect.Position.Y,0);
		Canvas.SetDrawColor(255,255,255,tempEffect.FloatVisiblity*255);
		Canvas.DrawTexture(tempEffect.TempHitEffect,2);

		if(tempEffect.FloatVisiblity <= 0)
			HitEffects.RemoveItem(tempEffect);
	}
}

function UpdateDialog()
{
	local Color DrawColor,DrawColorShadow;
	local float XL,YL;
	local int Idx;
	local array<SequenceObject> Events;
	local SeqEvent_Dialog SpawnedEvent;
	local SeqEvent_DialogAnswer SpawnedEvent2;
	local string tempString;
	DrawColor=WhiteColor;
	DrawColorShadow=BlackColor;
	Canvas.Font=MathildeBig;
	if(actualDialog != none && actualDialog.FullDialog.Length > 0)
	{
		if(actualDialog.TimeRunnedThisDialogStep <  actualDialog.FullDialog[0].DisplayLength+actualDialog.FullDialog[0].Delay)
		{
			if(!actualDialog.SoundWasPlayed && DialogPlayer != none && actualDialog.FullDialog[0].SoundToPlay != none)
			{
				actualDialog.SoundWasPlayed=true;
				DialogPlayer.SoundCue = actualDialog.FullDialog[0].SoundToPlay;
				DialogPlayer.FadeIn(0.1,1);
			}

			actualDialog.TimeRunnedComplete+=RenderDelta;

			if(actualDialog.FullDialog[0].Answers.Length <= 0 || actualDialog.AnswerSelected > 0)
			{
				actualDialog.TimeRunnedThisDialogStep+=RenderDelta;

				DrawColor.A = FloatToByte(FClamp(actualDialog.FullDialog[0].DisplayLength-actualDialog.TimeRunnedThisDialogStep,0,1),false);
				DrawColorShadow.A = DrawColor.A;

				if(actualDialog.FullDialog[0].TriggerKismet && actualDialog.FullDialog[0].TriggerKismetTime > actualDialog.TimeRunnedThisDialogStep)
				{
					actualDialog.FullDialog[0].TriggerKismet=false;

					if (class'Worldinfo'.static.GetWorldInfo().GetGameSequence() != None)
					{
						class'Worldinfo'.static.GetWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_Dialog',TRUE,Events);
						for (Idx = 0; Idx < Events.Length; Idx++)
						{
							SpawnedEvent = SeqEvent_Dialog(Events[Idx]);
							if (SpawnedEvent != None)
							{
								if(SpawnedEvent.Parameter != '' && SpawnedEvent.Parameter != actualDialog.FullDialog[0].KismetCommand) continue;
								else SpawnedEvent.CheckActivate(PlayerOwner,PlayerOwner);
							}
						}
					}
				}

				Canvas.StrLen(actualDialog.FullDialog[0].Message,XL,YL);
				Canvas.SetPos(CenterX-(XL*0.5)+1,SizeY-140-(YL*0.5)+1);
				Canvas.SetDrawColorStruct(DrawColorShadow);
				Canvas.DrawText(actualDialog.FullDialog[0].Message);
				Canvas.SetPos(CenterX-(XL*0.5),SizeY-140-(YL*0.5));
				Canvas.SetDrawColorStruct(DrawColor);
				Canvas.DrawText(actualDialog.FullDialog[0].Message);

				for(Idx = 0; Idx < actualDialog.FullDialog[0].Answers.Length; Idx++)
				{
					tempString=(Idx+1)$"."@actualDialog.FullDialog[0].Answers[Idx];
					Canvas.StrLen(tempString,XL,YL);
					Canvas.SetPos(CenterX-(XL*0.5)+1,SizeY-100-(YL*0.5)+1 +(Idx*20));
					Canvas.SetDrawColorStruct(DrawColorShadow);
					Canvas.DrawText(tempString);
					Canvas.SetPos(CenterX-(XL*0.5),SizeY-100-(YL*0.5) +(Idx*20));
					if(Idx+1 == actualDialog.AnswerSelected)
						Canvas.SetDrawColor(255,155,0,DrawColor.A);
					else
						Canvas.SetDrawColorStruct(DrawColor);
					Canvas.DrawText(tempString);
				}
			}
			else
			{
				Canvas.StrLen(actualDialog.FullDialog[0].Message,XL,YL);
				Canvas.SetPos(CenterX-(XL*0.5)+1,SizeY-140-(YL*0.5)+1);
				Canvas.SetDrawColorStruct(DrawColorShadow);
				Canvas.DrawText(actualDialog.FullDialog[0].Message);
				Canvas.SetPos(CenterX-(XL*0.5),SizeY-140-(YL*0.5));
				Canvas.SetDrawColorStruct(DrawColor);
				Canvas.DrawText(actualDialog.FullDialog[0].Message);

				for(Idx = 0; Idx < actualDialog.FullDialog[0].Answers.Length; Idx++)
				{
					tempString=(Idx+1)$"."@actualDialog.FullDialog[0].Answers[Idx];
					Canvas.StrLen(tempString,XL,YL);
					Canvas.SetPos(CenterX-(XL*0.5)+1,SizeY-100-(YL*0.5)+1 +(Idx*20));
					Canvas.SetDrawColorStruct(DrawColorShadow);
					Canvas.DrawText(tempString);
					Canvas.SetPos(CenterX-(XL*0.5),SizeY-100-(YL*0.5) +(Idx*20));
					Canvas.SetDrawColorStruct(DrawColor);
					Canvas.DrawText(tempString);

					if(LastAlphaKeyPress == Idx+1)
					{
						 actualDialog.AnswerSelected=Idx+1;

						 actualDialog.FullDialog[0].DisplayLength = 1.5;
						 actualDialog.FullDialog[0].Delay = 0;
					}
				}
			}

		}
		else
		{
			if(actualDialog.AnswerSelected > 0 && class'Worldinfo'.static.GetWorldInfo().GetGameSequence() != None)
			{
				class'Worldinfo'.static.GetWorldInfo().GetGameSequence().FindSeqObjectsByClass(class'SeqEvent_DialogAnswer',TRUE,Events);
				for (Idx = 0; Idx < Events.Length; Idx++)
				{
					SpawnedEvent2 = SeqEvent_DialogAnswer(Events[Idx]);
					if (SpawnedEvent2 != None)
					{
						if(SpawnedEvent2.Parameter != '' && SpawnedEvent2.Parameter != actualDialog.FullDialog[0].KismetCommand) continue;
						else
						{
							//SpawnedEvent2.GivenID = actualDialog.AnswerSelected;
							SpawnedEvent2.ForceActivateOutput((SpawnedEvent2.CorrectAnswerID==actualDialog.AnswerSelected) ? 0 : 1);
						}
					}
				}
			}
			actualDialog.AnswerSelected=-1;
			actualDialog.SoundWasPlayed=false;
			actualDialog.TimeRunnedThisDialogStep=0;
			actualDialog.FullDialog[0].SoundToPlay=none;
			actualDialog.FullDialog.RemoveItem(actualDialog.FullDialog[0]);
			if(actualDialog.FullDialog.Length <= 0)
			{
				if(actualDialog.NoteToAddToPlayer != none && PlayerOwner != none && NFPawn(PlayerOwner.Pawn) != none && NFPawn(PlayerOwner.Pawn).NFInventoryManager != none)
					NFPawn(PlayerOwner.Pawn).NFInventoryManager.AddNote(actualDialog.NoteToAddToPlayer);
				actualDialog = none;
			}
		}
	}
}
/*
function DrawDateTime()
{
	local NFGameInfo BeGameInfo;
	local float XL,YL;
	local string TempString;
	BeGameInfo = NFGameInfo(WorldInfo.Game);
	if(BeGameInfo != none)
	{
		Canvas.Font = FaceYourFears;
		TempString = BeGameInfo.ActualDate.ToTimeString(true);
		Canvas.TextSize(TempString,XL,YL);
		Canvas.SetDrawColor(255, 255, 255, 100);
		Canvas.SetPos(CenterX-(XL*0.5f), 0);
		Canvas.DrawText(TempString,true);
		TempString = BeGameInfo.ActualDate.ToDateString(true);
		Canvas.TextSize(TempString,XL,YL);
		Canvas.SetPos(CenterX-(XL*0.5f), YL);
		Canvas.DrawText(TempString,true);
	}
}
*/
function DrawBar(float X, float Y, float height, float length, float Percent, Color c)
{
	Canvas.SetDrawColorStruct(c);
    Canvas.SetPos(X, Y);
	Canvas.DrawRect(length*Percent,height);
}

function DrawBarOutline(float X, float Y, float height, float length, float value, float maxValue, Color c, Color OutlineColor)
{
    local float tempStepValue;
	tempStepValue = maxValue/length*4;
	Canvas.SetDrawColorStruct(c);
    Canvas.SetPos(X+1, Y+1);
	Canvas.DrawRect(value*tempStepValue,height);
	Canvas.SetPos(X, Y);
	Canvas.SetDrawColorStruct(WhiteColor);
	Canvas.DrawBox(length+2,height+2);
}

function DrawFocus()
{
	local NFPlayerController NFPC;
	local float XL,YL;
	NFPC = NFPlayerController(PlayerOwner);
	if(NFPC != none && NFPC.lastFocusObject != none && NFPC.lastFocusObject.CanSeeMe())
	{
		Canvas.Font = LastKingQuest;
		Canvas.SetDrawColorStruct(WhiteColor);
		Canvas.TextSize("'Hold 'V' to Focus'",XL,YL);
		Canvas.SetPos(CenterX-(XL*0.5),Canvas.SizeY-YL-50);
		Canvas.DrawText("'Hold 'V' to Focus'",true);
	}
}



function DrawCrosshair()
{
	local NFPlayerController NFPC;
	local float XL,YL;
	local Vector loc, norm;
	local Actor traceHit;
	local TraceHitInfo hitInfo;
	local Texture2D IconToDraw;
	IconToDraw = DefaultCrosshair;
	NFPC = NFPlayerController(PlayerOwner);
	if(NFPC != none && NFPC.PhysGrabber != none && NFPC.PhysGrabber.PhysicsGrabber.GrabbedComponent == none)
	{
		traceHit = trace(loc, norm, NFPC.outWorldOrigin+(NFPC.outWorldDirection*250 ), NFPC.outWorldOrigin, true,vect(2,2,2), hitInfo,TRACEFLAG_Bullet);
		if(traceHit != none)
		{
				NFPC.lastTracedObject.Interactable = InteractableInterface(traceHit);
				if(NFPC.lastTracedObject.Interactable != none)
				{
					NFPC.lastTracedObject.HitLocation = loc;
					NFPC.lastTracedObject.HitInfo = hitInfo;
					NFPC.lastTracedObject.StartLocation = NFPC.outWorldOrigin;
					NFPC.lastTracedObject.HitNormal = norm;
					NFPC.lastTracedObject.TraceDirection = NFPC.outWorldDirection;
					Canvas.Font = LastKingQuest;
					Canvas.SetDrawColorStruct(WhiteColor);
					Canvas.TextSize(NFPc.lastTracedObject.Interactable.GetDescriptionText(),XL,YL);
					Canvas.SetPos(CenterX-(XL*0.5),CenterY+100);
					Canvas.DrawText(NFPc.lastTracedObject.Interactable.GetDescriptionText(),true);

					switch(NFPC.lastTracedObject.Interactable.GetType())
					{
						case Pickup: IconToDraw = PickupCrosshair; break;
						case OpenAble: IconToDraw = OpenCrosshair; break;
						case ObserveAble: IconToDraw = ObserverableCrosshai; break;
						default: IconToDraw = InteractableCrosshair; break;
					}
				}
				else
					NFPC.lastTracedObject.Interactable=none;
			}
			else
				NFPC.lastTracedObject.Interactable=none;
	}
	Canvas.SetDrawColor(255, 255, 255, 230);
	Canvas.SetPos(CenterX-(IconToDraw.SizeX*0.5),CenterY-(IconToDraw.SizeY*0.5));
	Canvas.DrawTexture(IconToDraw,1);
}

function UpdateInfoButtons()
{
	if(InventoryIcon != none && (InventoryIconBlink.Cooldown > 0  || (InventoryIconBlink.Cooldown < 0 && InventoryIconBlink.Alpha > 0)))
	{
		InventoryIconBlink.Cooldown-=RenderDelta;
		if(InventoryIconBlink.Up)
		{
			InventoryIconBlink.Alpha+=RenderDelta;
			if(InventoryIconBlink.Alpha >= 1)
				InventoryIconBlink.Up=false;
		}
		else
		{
			InventoryIconBlink.Alpha-=RenderDelta;
			if(InventoryIconBlink.Alpha <= 0)
				InventoryIconBlink.Up=true;
		}
		Canvas.SetDrawColor(255,255,255,FloatToByte(InventoryIconBlink.Alpha));
		Canvas.SetPos(SizeX-100,SizeY-100);
		Canvas.DrawTexture(InventoryIcon,1);
	}
	if(NoteBookIcon != none && (NoteBookIconBlink.Cooldown > 0  || (NoteBookIconBlink.Cooldown < 0 && NoteBookIconBlink.Alpha > 0)))
	{
		NoteBookIconBlink.Cooldown-=RenderDelta;
		if(NoteBookIconBlink.Up)
		{
			NoteBookIconBlink.Alpha+=RenderDelta;
			if(NoteBookIconBlink.Alpha >= 1)
				NoteBookIconBlink.Up=false;
		}
		else
		{
			NoteBookIconBlink.Alpha-=RenderDelta;
			if(NoteBookIconBlink.Alpha <= 0)
				NoteBookIconBlink.Up=true;
		}
		Canvas.SetDrawColor(255,255,255,FloatToByte(NoteBookIconBlink.Alpha));
		Canvas.SetPos(SizeX-164,SizeY-100);
		Canvas.DrawTexture(NoteBookIcon,1);
	}
}


function DrawMouseCursor()
{
	Canvas.SetDrawColor(255, 255, 255, 230);
	Canvas.SetPos(mousePos.x, mousePos.y);
	Canvas.DrawTexture(MouseCursor,1);
}

function AddMessage(MessageType typeOfMessage, optional string Text, optional Texture2D image, optional float fadeLength = 4)
{
	local NFMessage message;

	message.MessageType = typeOfMessage;
	message.Message = Text;
	message.Icon = image;
	message.TimeAlife = FClamp(fadeLength,0.5,4);
	NFMessages.AddItem(message);
}

function HandleMessages()
{
	local Color DrawColor;
	local int i;
	local float XL,YL, YOffset;

	Canvas.Font = Mathilde;
	for(i=0;i<NFMessages.Length;i++)
	{
		if(NFMessages[i].MessageType==MESS_Hint)
			DrawColor=OrangeColor;
		else
			DrawColor=WhiteColor;
		NFMessages[i].TimeAlife-=RenderDelta;
		YOffset=40+NFMessages[i].TimeAlife*43;
		if(NFMessages[i].TimeAlife <= 1)
			DrawColor.A= FloatToByte(NFMessages[i].TimeAlife,false);
		Canvas.SetDrawColorStruct(DrawColor);

		if(NFMessages[i].Message != "")
		{
			Canvas.TextSize(NFMessages[i].Message,XL,YL);
			if(NFMessages[i].Icon != none)
			{
				Canvas.SetPos( CenterX-(NFMessages[i].Icon.SizeX*0.10) - (XL*0.5), YOffset-(NFMessages[i].Icon.SizeY*0.10));
				Canvas.DrawTexture(NFMessages[i].Icon,0.2);
				Canvas.SetPos( CenterX+(NFMessages[i].Icon.SizeX*0.10) - (XL*0.5), YOffset-(YL*0.5));
				Canvas.DrawText(NFMessages[i].Message);
			}
			else
			{
				Canvas.SetPos( CenterX-(XL*0.5), YOffset-(YL*0.5));
				Canvas.DrawText(NFMessages[i].Message);
			}
		}
		else if(NFMessages[i].Icon != none)
		{
			Canvas.SetPos( CenterX-(NFMessages[i].Icon.SizeX*0.10), YOffset-(NFMessages[i].Icon.SizeY*0.10));
			Canvas.DrawTexture(NFMessages[i].Icon,0.2);
		}

		if(NFMessages[i].TimeAlife <= 0)
			NFMessages.RemoveItem(NFMessages[i]);
	}
}

function DrawMenu()
{
	local float XL,YL;
	local int i;
	local Color BlackTransparent;
	local string nameOfHoveredButton;
	Canvas.TextSize("Pause Menu",XL,YL);
	Canvas.Font = LastKingQuest;
	Canvas.SetDrawColorStruct(WhiteColor);
	Canvas.SetPos(CenterX-XL,50);
	Canvas.DrawText("Pause Menu");
	BlackTransparent = BlackColor;
	BlackTransparent.A = 155;
	for(i = 0; i < MenuButtons.Length; i++)
	{
		Canvas.SetPos(CenterX+MenuButtons[i].X-(MenuButtons[i].Width*0.5),CenterY+MenuButtons[i].Y-(MenuButtons[i].Height*0.5));
		Canvas.SetDrawColorStruct(BlackTransparent);
		Canvas.DrawRect(MenuButtons[i].Width,MenuButtons[i].Height);

		Canvas.SetDrawColorStruct(GreyColor);
		Canvas.SetPos(CenterX+MenuButtons[i].X-(MenuButtons[i].Width*0.5),CenterY+MenuButtons[i].Y-(MenuButtons[i].Height*0.5));
		Canvas.DrawBox(MenuButtons[i].Width,MenuButtons[i].Height);

		Canvas.StrLen(MenuButtons[i].Text,XL,YL);
		if((mousePos.X > (CenterX+MenuButtons[i].X-(MenuButtons[i].Width*0.5)) && mousePos.X < (CenterX+MenuButtons[i].X+(MenuButtons[i].Width*0.5))) && (mousePos.Y > (CenterY+MenuButtons[i].Y-(MenuButtons[i].Height*0.5)) && mousePos.Y < (CenterY+MenuButtons[i].Y+(MenuButtons[i].Height*0.5))))
		{
			if(bMousePressed)
				Canvas.SetDrawColorStruct(OrangeColor);
			else
				Canvas.SetDrawColorStruct(WhiteColor);
			nameOfHoveredButton=MenuButtons[i].Text;
		}
		Canvas.SetPos(CenterX+MenuButtons[i].X-(XL*0.5),CenterY+MenuButtons[i].Y-(YL*0.5));
		Canvas.DrawText(MenuButtons[i].Text);
	}

	if(nameOfHoveredButton != "")
	{
		if(bMousePressed && !bLastMousePressed)
			NameOfMouseDownObject=nameOfHoveredButton;
		else if(!bMousePressed && bLastMousePressed && NameOfMouseDownObject == nameOfHoveredButton)
		{
			if(nameOfHoveredButton == "Leave")
				ConsoleCommand("Open NFTAMenu");
		else if(NFPlayerController(PlayerOwner) != none)
			{
				if(nameOfHoveredButton == "Back" )
					NFPlayerController(PlayerOwner).OpenMenu();
				else if(nameOfHoveredButton == "Save1")
					NFPlayerController(PlayerOwner).SaveGame("1\\SaveGame1");
				else if(nameOfHoveredButton == "Save2")
					NFPlayerController(PlayerOwner).SaveGame("2\\SaveGame2");
				else if(nameOfHoveredButton == "Save3")
					NFPlayerController(PlayerOwner).SaveGame("3\\SaveGame3");
				else if(nameOfHoveredButton == "Load1")
					NFPlayerController(PlayerOwner).LoadGame("1\\SaveGame1");
				else if(nameOfHoveredButton == "Load2")
					NFPlayerController(PlayerOwner).LoadGame("2\\SaveGame2");
				else if(nameOfHoveredButton == "Load3")
					NFPlayerController(PlayerOwner).LoadGame("3\\SaveGame3");
			}
		}
	}
}

function DrawNotes()
{
	local float XL,YL;
	local string tempString;
	switch(PageOfNotebook)
	{
		case NBP_Memos: tempString = "Memos "; break;
		case NBP_Notes: tempString = "Notes "; break;
		case NBP_Diary: tempString = "Diary "; break;
		default: tempString = "Notebook "; break;
	}

	Canvas.StrLen(tempString,XL,YL);
	Canvas.Font = LastKingQuest;
	Canvas.SetDrawColorStruct(WhiteColor);
	Canvas.SetPos(CenterX-XL,80);
	Canvas.DrawText(tempString);

	switch(PageOfNotebook)
	{
		case NBP_Main:
			DrawNoteMainPage();
		break;
		default: 
			DrawNoteSubPage();
		break;
	}
}

function DrawNoteMainPage()
{
	local int i;
	local Color BlackTransparent;
	local float XL,YL;
	local string nameOfHoveredButton;
	BlackTransparent = BlackColor;
	BlackTransparent.A = 155;
	for(i = 0; i < NoteBookMainButtons.Length; i++)
	{
		Canvas.SetPos(CenterX+NoteBookMainButtons[i].X-(NoteBookMainButtons[i].Width*0.5),CenterY+NoteBookMainButtons[i].Y-(NoteBookMainButtons[i].Height*0.5));
		Canvas.SetDrawColorStruct(BlackTransparent);
		Canvas.DrawRect(NoteBookMainButtons[i].Width,NoteBookMainButtons[i].Height);

		Canvas.SetDrawColorStruct(GreyColor);
		Canvas.SetPos(CenterX+NoteBookMainButtons[i].X-(NoteBookMainButtons[i].Width*0.5),CenterY+NoteBookMainButtons[i].Y-(NoteBookMainButtons[i].Height*0.5));
		Canvas.DrawBox(NoteBookMainButtons[i].Width,NoteBookMainButtons[i].Height);

		Canvas.StrLen(NoteBookMainButtons[i].Text,XL,YL);
		if((mousePos.X > (CenterX+NoteBookMainButtons[i].X-(NoteBookMainButtons[i].Width*0.5)) && mousePos.X < (CenterX+NoteBookMainButtons[i].X+NoteBookMainButtons[i].X+(NoteBookMainButtons[i].Width*0.5))) && (mousePos.Y > (CenterY+NoteBookMainButtons[i].Y-(NoteBookMainButtons[i].Height*0.5)) && mousePos.Y < (CenterY+NoteBookMainButtons[i].Y+(NoteBookMainButtons[i].Height*0.5))))
		{
			if(bMousePressed)
				Canvas.SetDrawColorStruct(OrangeColor);
			else
				Canvas.SetDrawColorStruct(WhiteColor);
			nameOfHoveredButton=NoteBookMainButtons[i].Text;
		}
		Canvas.SetPos(CenterX+NoteBookMainButtons[i].X-(XL*0.5),CenterY+NoteBookMainButtons[i].Y-(YL*0.5));
		Canvas.DrawText(NoteBookMainButtons[i].Text);
	}

	if(nameOfHoveredButton != "")
	{
		if(bMousePressed && !bLastMousePressed)
			NameOfMouseDownObject=nameOfHoveredButton;
		else if(!bMousePressed && bLastMousePressed && NameOfMouseDownObject == nameOfHoveredButton)
		{
			if(nameOfHoveredButton == "Notes")
				PageOfNotebook=NBP_Notes;
			else if(nameOfHoveredButton == "Diary")
				PageOfNotebook=NBP_Diary;
			else if(nameOfHoveredButton == "Memos")
				PageOfNotebook=NBP_Memos;
			else if(nameOfHoveredButton == "Back"&& NFPlayerController(PlayerOwner) != none)
				NFPlayerController(PlayerOwner).OpenNotes();
		}
	}
}

function DrawNoteSubPage()
{
	local int i;
	local Color BlackTransparent;
	local float XL,YL;
	local string nameOfHoveredButton;
	local array<Notes> tempNoteArray;
	BlackTransparent = BlackColor;
	BlackTransparent.A = 155;

	if(NFPawn(PlayerOwner.Pawn) != none && NFPawn(PlayerOwner.Pawn).NFInventoryManager != none)
	{
		switch(PageOfNotebook)
		{
		case NBP_Memos: tempNoteArray = NFPawn(PlayerOwner.Pawn).NFInventoryManager.Memos; break;
		case NBP_Notes: tempNoteArray = NFPawn(PlayerOwner.Pawn).NFInventoryManager.Notebook; break;
		case NBP_Diary: tempNoteArray = NFPawn(PlayerOwner.Pawn).NFInventoryManager.Diary; break;
		}
	}

	if(ReadingNote)
	{
		for(i = 0; i < tempNoteArray.Length; i++)
		{ 
			if(NoteID == tempNoteArray[i].EntryNumber)
			{
				DrawNote(tempNoteArray[i]);
				break;
			}
		}
	}
	else
		nameOfHoveredButton=DrawDiaryEntries(tempNoteArray);
	Canvas.Font = Mathilde;
	for(i = 0; i < NoteBookSubButtons.Length; i++)
	{
		Canvas.SetPos(CenterX+NoteBookSubButtons[i].X-(NoteBookSubButtons[i].Width*0.5),SizeY+NoteBookSubButtons[i].Y-(NoteBookSubButtons[i].Height*0.5));
		Canvas.SetDrawColorStruct(BlackTransparent);
		Canvas.DrawRect(NoteBookSubButtons[i].Width,NoteBookSubButtons[i].Height);

		Canvas.SetDrawColorStruct(GreyColor);
		Canvas.SetPos(CenterX+NoteBookSubButtons[i].X-(NoteBookSubButtons[i].Width*0.5),SizeY+NoteBookSubButtons[i].Y-(NoteBookSubButtons[i].Height*0.5));
		Canvas.DrawBox(NoteBookSubButtons[i].Width,NoteBookSubButtons[i].Height);

		Canvas.StrLen(NoteBookSubButtons[i].Text,XL,YL);
		if((mousePos.X > (CenterX+NoteBookSubButtons[i].X-(NoteBookSubButtons[i].Width*0.5)) && mousePos.X < (CenterX+NoteBookSubButtons[i].X+NoteBookSubButtons[i].X+(NoteBookSubButtons[i].Width*0.5))) && (mousePos.Y > (SizeY+NoteBookSubButtons[i].Y-(NoteBookSubButtons[i].Height*0.5)) && mousePos.Y < (SizeY+NoteBookSubButtons[i].Y+(NoteBookSubButtons[i].Height*0.5))))
		{
			if(bMousePressed)
				Canvas.SetDrawColorStruct(OrangeColor);
			else
				Canvas.SetDrawColorStruct(WhiteColor);
			if(nameOfHoveredButton == "")
				nameOfHoveredButton=NoteBookSubButtons[i].Text;
		}
		Canvas.SetPos(CenterX+NoteBookSubButtons[i].X-(XL*0.5),SizeY+NoteBookSubButtons[i].Y-(YL*0.5));
		Canvas.DrawText(NoteBookSubButtons[i].Text);
	}

	if(nameOfHoveredButton != "")
	{
		if(bMousePressed && !bLastMousePressed)
			NameOfMouseDownObject=nameOfHoveredButton;
		else if(!bMousePressed && bLastMousePressed && NameOfMouseDownObject == nameOfHoveredButton)
		{
			if(nameOfHoveredButton == "Back")
			{
				if(ReadingNote)
				{
					NoteID=0;
					ReadingNote=false;
					if(DialogPlayer != none && DialogPlayer.IsPlaying())
						DialogPlayer.Stop();
				}
				else
					PageOfNotebook=NBP_Main;
			}
			/*else if(nameOfHoveredButton == 'Diary')
				PageOfNotebook=NBP_Diary;
			else if(nameOfHoveredButton == 'Memos')
				PageOfNotebook=NBP_Memos;*/
			else if(!ReadingNote)
			{
				for(i = 0; i < tempNoteArray.Length; i++)
				{
					if(nameOfHoveredButton == tempNoteArray[i].Headline)
					{
						NoteID=tempNoteArray[i].EntryNumber;
						ReadingNote=true;
						if(DialogPlayer != none && tempNoteArray[i].SoundToPlay != none)
						{
							DialogPlayer.SoundCue = tempNoteArray[i].SoundToPlay;
							DialogPlayer.FadeIn(0.5,1);
						}
						break;
					}
				}
			}
		}
	}
}

function DrawNote(Notes NotetoDraw)
{
	local Color BlackTransparent;
	local float XL,YL;
	BlackTransparent = BlackColor;
	BlackTransparent.A = 155;
	Canvas.Font = LastKingQuest;

	Canvas.StrLen(NotetoDraw.Headline,XL,YL);
	Canvas.Font = LastKingQuest;
	Canvas.SetDrawColorStruct(WhiteColor);
	Canvas.SetPos(CenterX-(XL*0.5),140);
	Canvas.DrawText(NotetoDraw.Headline);


	Canvas.Font = Mathilde;
	Canvas.SetPos(100,200);
	Canvas.SetDrawColorStruct(BlackTransparent);
	Canvas.DrawRect(SizeX-200,SizeY-400);

	Canvas.SetDrawColorStruct(GreyColor);
	Canvas.SetPos(100,200);
	Canvas.DrawBox(SizeX-200,SizeY-400);

	Canvas.SetDrawColorStruct(WhiteColor);
	Canvas.SetPos(100+10,200);
	Canvas.DrawText(NotetoDraw.Text);
}

function string DrawDiaryEntries(array<Notes> NoteArray)
{
	local Color BlackTransparent;
	local float XL,YL, Y;
	local Notes tempNote;
	local Notes HoveredNote;
	BlackTransparent = BlackColor;
	BlackTransparent.A = 155;
	Y = 200;
	Canvas.Font = Mathilde;
	foreach NoteArray(tempNote)
	{
		Canvas.TextSize(tempNote.Headline,XL,YL);
		Canvas.SetPos(CenterX-(XL*0.5)-10,Y-(YL*0.5)-10);
		Canvas.SetDrawColorStruct(BlackTransparent);
		Canvas.DrawRect(XL+20,YL+20);

		Canvas.SetDrawColorStruct(GreyColor);
		Canvas.SetPos(CenterX-(XL*0.5)-10,Y-(YL*0.5)-10);
		Canvas.DrawBox(XL+20,YL+20);

		if((mousePos.X > (CenterX-(XL*0.5)-10) && mousePos.X < (CenterX+(XL*0.5)+10)) && (mousePos.Y > (Y-(YL*0.5)-10) && mousePos.Y < (Y+(YL*0.5)+10)))
		{
			if(bMousePressed)
				Canvas.SetDrawColorStruct(OrangeColor);
			else
				Canvas.SetDrawColorStruct(WhiteColor);
				HoveredNote=tempNote;
		}

		Canvas.SetPos(CenterX-(XL*0.5),Y-(YL*0.5));
		Canvas.DrawText(tempNote.Headline);
		Y+= 37;
	}

	if(HoveredNote != none)
		return HoveredNote.Headline;
	else
		return "";
}



function DrawInventory()
{
	local NFPawn BePawn;
	local NFItem tempItem;
	local float X, Y, XL, YL;
	local string tempString;
	local float StartPosX, StartPosY;
	local NFItem HoveredItem;
	local Color BlackTransparent, WhiteTransparent;
	BlackTransparent = BlackColor;
	WhiteTransparent = WhiteColor;
	WhiteTransparent.A = 100;
	BlackTransparent.A = 155;
	StartPosX=CenterX-224;
	StartPosY=CenterY-96;

	Canvas.TextSize("Inventory",XL,YL);
	Canvas.Font = LastKingQuest;
	Canvas.SetDrawColorStruct(WhiteColor);
	Canvas.SetPos(CenterX-(XL*0.5),StartPosY-50);
	Canvas.DrawText("Inventory");

	Canvas.SetPos(StartPosX,StartPosY);
	Canvas.SetDrawColorStruct(BlackTransparent);
	Canvas.DrawRect(448,192);
	X=0;
	Y=0;
	BePawn = NFPawn(PlayerOwner.Pawn);
	Canvas.Font = Mathilde;
	Canvas.SetDrawColorStruct(WhiteTransparent);
	if(BePawn != none && BePawn.NFInventoryManager != none)
	{
		foreach BePawn.NFInventoryManager.Items(tempItem)
		{
			Canvas.SetPos(StartPosX+X,StartPosY+Y);
			if(tempItem.Icon!= none)
			{
				if((mousePos.X > (StartPosX+X) && mousePos.X < (StartPosX+X+tempItem.Icon.SizeX*0.5)) && (mousePos.Y > (StartPosY+Y) && mousePos.Y < (StartPosY+Y+tempItem.Icon.SizeY*0.5)))
				{
					if(bMousePressed)
						Canvas.SetDrawColorStruct(OrangeColor);
					else
						Canvas.SetDrawColorStruct(WhiteColor);
					HoveredItem=tempItem;
				}
				Canvas.DrawTexture(tempItem.Icon,0.5);
				tempString=tempItem.RealStackSize$"/"$tempItem.MaxStackSize;
				Canvas.SetDrawColorStruct(WhiteTransparent);
				Canvas.TextSize(tempString,XL,YL);
				Canvas.SetPos((StartPosX+X)+(tempItem.Icon.SizeX*0.5)-XL,(StartPosY+Y)+(tempItem.Icon.SizeY*0.5)-YL);
				Canvas.DrawText(tempString);
				X+=tempItem.Icon.SizeX*0.5;
				if(X> 360)
				{
					X=0;
					Y+=tempItem.Icon.SizeY*0.5;
				}
			}
		}

		Canvas.SetPos(StartPosX,StartPosY);
		Canvas.SetDrawColorStruct(GreyColor);
		Canvas.DrawBox(448,192);

		if(HoveredItem != none)
		{
			if(bMousePressed && !bLastMousePressed)
				NameOfMouseDownObject=HoveredItem.ItemName;
			else if(!bMousePressed && bLastMousePressed && NameOfMouseDownObject == HoveredItem.ItemName)
				HoveredItem.Used(BePawn.NFController);

			Canvas.SetDrawColorStruct(BlackTransparent);
			Canvas.SetPos(mousePos.X+10,mousePos.Y+10);
			Canvas.StrLen(HoveredItem.GetToolTip(),XL,YL);
			Canvas.DrawRect(XL+10,YL+10);
			Canvas.SetDrawColorStruct(GreyColor);
			Canvas.SetPos(mousePos.X+10,mousePos.Y+10);
			Canvas.DrawBox(XL+10,YL+10);
			Canvas.SetDrawColorStruct(WhiteColor);
			Canvas.SetPos(mousePos.X+15,mousePos.Y+15);
			Canvas.DrawText(HoveredItem.GetToolTip());
		}
	}
}
function DisplayConsoleMessages();
function DisplayLocalMessages();
function DisplayKismetMessages();


DefaultProperties
{
	begin object Class=AudioComponent Name=DialogAudioComponent
		bReverb=false
	end object
	DialogPlayer=DialogAudioComponent
	Components.Add(DialogAudioComponent)

	BloodSplat01=Texture2D'Main.HUD.Hiteffect.damage_bloodsplat0'
	BloodSplat02=Texture2D'Main.HUD.Hiteffect.damage_bloodsplat1'
	BloodSplat03=Texture2D'Main.HUD.Hiteffect.damage_bloodsplat2'
 
	NoteBookIcon=Texture2D'Main.HUD.Icons.hud_quest_added'
	InventoryIcon=Texture2D'Main.HUD.Icons.hud_item_added'
	MathildeBig=Font'Main.Fonts.NFFont'
	Mathilde=Font'Main.Fonts.NFFont'
	LastKingQuest=Font'Main.Fonts.NFFont'
	FaceYourFears=Font'Main.Fonts.NFFont'
	PostProcessMaterial=MaterialInstanceConstant'Main.PostProcessing.Materials.Horror_Main_INST'
	DefaultCrosshair=Texture2D'Main.HUD.reticle'
	InteractableCrosshair=Texture2D'Main.HUD.Icons.HandIcon'
	ObserverableCrosshai=Texture2D'Main.HUD.Icons.Observe'
	OpenCrosshair=Texture2D'Main.HUD.Icons.HandIcon'
	PickupCrosshair=Texture2D'Main.HUD.Icons.HandIcon'
	MouseCursor=Texture2D'Main.HUD.Icons.CursorIcon'
	BlackColor=(R=0,G=0,B=0,A=255)
	BlueColor=(R=0,G=0,B=255,A=255)
	YellowColor=(R=255,G=255,B=0,A=255)
	LilaColor=(R=80,G=0,B=100,A=255)
	GreyColor=(R=110,G=110,B=110,A=255)
	OrangeColor=(R=255,G=155,B=0,A=255)

	LastAlphaKeyPress=0
	
}