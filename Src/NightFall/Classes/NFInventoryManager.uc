class NFInventoryManager extends Object;

// Holds our Items
var array<NFItem> Items;

var array<Notes> Notebook;
var array<Notes> Memos;
var array<Notes> Diary;

var NFHUD HUD;
var NFPlayerController Owner;
var NFPawn bePawn;

var const int InventorySpaces;

var SoundCue NewNoteSound;

function InitInventory(NFHUD _HUD,NFPlayerController _Owner, NFPawn _bePawn)
{
	if(_HUD != none)
		HUD = _HUD;

	if(_Owner != none)
		Owner = _Owner;

	if(_bePawn != none)
		bePawn = _bePawn;

	StartingInventory();
}

//@params ItemToCheck item specified in the U_WorldItemPickup class
//@params AmountWantingToAdd the int amount that is specified in the U_WorldItemPickUp class
//
//returns false if there is space in the inventory returns true if there is not enough space.

function bool CheckInventorySize(NFItem ItemToCheck)
{
  local int i;
  local NFItem foundItem;

  for (i=0;i<Items.Length;i++)
  {
      //When the iterator reaches a class that macthes the one that you want add it to itemamountininventory
     if (Items[i].ItemName == ItemToCheck.ItemName)
      {
		foundItem = Items[i];
		break;
      }

   }
   
   if( foundItem != none && foundItem.RealStackSize >= foundItem.MaxStackSize)
   {
	  if(HUD != none)
		 HUD.AddMessage(MESS_Pickup,"Im already carrying the max Number of this Item");
	  else if(NFHud(Owner.myHUD) != none)
		 NFHud(Owner.myHUD).AddMessage(MESS_Pickup,"Im already carrying the max Number of this Item");
      return false;
   }
   if(i>InventorySpaces)
   {
	  if(HUD != none)
		 HUD.AddMessage(MESS_Pickup,"My Inventory is Full");
	  else if(NFHud(Owner.myHUD) != none)
		 NFHud(Owner.myHUD).AddMessage(MESS_Pickup,"My Inventory is Full");
	  return false;
   }
   return true;
}

function int HasItem(NFItem ItemToCheck)
{
  local int i;
  local NFItem foundItem;

  for (i=0;i<Items.Length;i++)
  {
     if (Items[i].ItemName == ItemToCheck.ItemName)
      {
		foundItem = Items[i];
		break;
      }

   }
   
   if( foundItem != none)
	   return foundItem.RealStackSize;
   else
	 return 0;
}

//default stuff in the beggining of the game (you always have a herb on game start incase the player saves the game with low low health.)
function StartingInventory()
{
    // AddInventory(new class'NFItem');
}

//Add items to the current inventory
function AddInventory(NFItem ItemType, optional int Amount = 1)
{
	local int i;
	local NFItem foundItem;
	for (i=0;i<Items.Length;i++)
    {
		 //When the iterator reaches a class that macthes the one that you want add it to itemamountininventory
		 if (Items[i].ItemName == ItemType.ItemName)
		 {
			foundItem = Items[i];
			break;
		 }
    }
	if(foundItem != none)
		foundItem.RealStackSize=Clamp(foundItem.RealStackSize+Amount,0,foundItem.MaxStackSize); 
	else
	{
		ItemType.RealStackSize = Clamp(Amount,0,ItemType.MaxStackSize); 
		Items.AddItem(ItemType);
	}

	if(ItemType.PickUpSound != none && Owner != none)
		Owner.PlaySound(ItemType.PickUpSound, false, true,,, true);
		

	if(HUD != none)
	{
		HUD.InventoryIconBlink.Cooldown = 5;
		HUD.AddMessage(MESS_Pickup,"Picked Up:"@ItemType.ItemName,ItemType.Icon);
	}
	else if(NFHud(Owner.myHUD) != none)
	{
		NFHud(Owner.myHUD).InventoryIconBlink.Cooldown = 5;
		NFHud(Owner.myHUD).AddMessage(MESS_Pickup,"Picked Up:"@ItemType.ItemName,ItemType.Icon);
	}
}

//Remove items from the current inventory either when used or dropped.
function RemoveInventory(NFItem ItemToRemove, optional int Amount = 1)
{
     local int			i;

     for (i=0;i<Items.Length;i++)
     {
         //When the iterator reaches a class that macthes the one that you want to use or remove. 
         // Remove it [i] and then use it.
         if (Items[i].ItemName == ItemToRemove.ItemName)
         {
			 if(Items[i].RealStackSize >= 1)
				Items[i].RealStackSize-= Amount;
			if(Items[i].RealStackSize < 1)
				Items.RemoveItem(Items[i]);
			break;
         }
     }
}

function AddNote(Notes NoteEntry)
{
	local int i;
	local bool found;

	switch(NoteEntry.TypeOfNote)
	{
		case Memo: 
				for (i=0;i<Memos.Length;i++)
				{
					 if (Memos[i].EntryNumber == NoteEntry.EntryNumber)
					 {
						found = true;
						break;
					 }
				}
				if(!found)
				{
					Memos.AddItem(NoteEntry);
					Memos.Sort(SortNotes);
					if(HUD != none)
					{
						HUD.NoteBookIconBlink.Cooldown = 5;
						HUD.AddMessage(MESS_Note,"New Memo:"@NoteEntry.Headline);
					}
					else if(NFHud(Owner.myHUD) != none)
					{
						NFHud(Owner.myHUD).NoteBookIconBlink.Cooldown = 5;
						NFHud(Owner.myHUD).AddMessage(MESS_Note,"New Memo:"@NoteEntry.Headline);
					}
				}
			break;
		case DiaryEntry: 
				for (i=0;i<Diary.Length;i++)
				{
					 if (Diary[i].EntryNumber == NoteEntry.EntryNumber)
					 {
						found = true;
						break;
					 }
				}
				if(!found)
				{
					Diary.AddItem(NoteEntry);
					Diary.Sort(SortNotes);
					if(HUD != none)
					{
						HUD.NoteBookIconBlink.Cooldown = 5;
						HUD.AddMessage(MESS_Note,"New Diary Entry:"@NoteEntry.Headline);
					}
					else if(NFHud(Owner.myHUD) != none)
					{
						NFHud(Owner.myHUD).NoteBookIconBlink.Cooldown = 5;
						NFHud(Owner.myHUD).AddMessage(MESS_Note,"New Diary Entry:"@NoteEntry.Headline);
					}
				}
			break;
		case Note: 
				for (i=0;i<Notebook.Length;i++)
				{
					 if (Notebook[i].EntryNumber == NoteEntry.EntryNumber)
					 {
						found = true;
						break;
					 }
				}
				if(!found)
				{
					Notebook.AddItem(NoteEntry);
					Notebook.Sort(SortNotes);
					if(HUD != none)
					{
						HUD.NoteBookIconBlink.Cooldown = 5;
						HUD.AddMessage(MESS_Note,"New Note:"@NoteEntry.Headline);
					}
					else if(NFHud(Owner.myHUD) != none)
					{
						NFHud(Owner.myHUD).NoteBookIconBlink.Cooldown = 5;
						NFHud(Owner.myHUD).AddMessage(MESS_Note,"New Note:"@NoteEntry.Headline);
					}
				}
			break;
	}

	if(!found && NewNoteSound != none && Owner != none)
		Owner.PlaySound(NewNoteSound, false, true,,, true);
}

delegate int SortNotes(Notes a, Notes b)
{
	return a.EntryNumber-b.EntryNumber;
} 

function JSonObject Serialize()
{
	local JSonObject PJSonObject;
	local int i;

    PJSonObject = new class'JSonObject';

    if (PJSonObject == None)
    {
		`Warn(Self$" could not be serialized for saving the game state.");
		return none;
    }

	PJSonObject.SetIntValue("ItemsCarried",Items.Length);

	for(i=0;i<Items.Length;i++)
	{
		PJSonObject.SetStringValue("ItemObjectArchetype"$i, PathName(Items[i]));
		PJSonObject.SetIntValue("ItemStacks"$i,Items[i].RealStackSize);
	}

	PJSonObject.SetIntValue("NotesCarried",Notebook.Length);
	for(i=0;i<Notebook.Length;i++)
		PJSonObject.SetStringValue("NoteObjectArchetype"$i, PathName(Notebook[i]));

	PJSonObject.SetIntValue("DiaryCarried",Diary.Length);
	for(i=0;i<Diary.Length;i++)
	{
		PJSonObject.SetStringValue("DiaryObjectArchetype"$i, PathName(Diary[i]));
		PJSonObject.SetStringValue("DiaryText"$i,Diary[i].Text);
		PJSonObject.SetStringValue("DiaryHeadLine"$i,Diary[i].Headline);
		PJSonObject.SetIntValue("DiaryEntryNumber"$i,Diary[i].EntryNumber);
	}

	PJSonObject.SetIntValue("MemosCarried",Memos.Length);
	for(i=0;i<Memos.Length;i++)
		PJSonObject.SetStringValue("MemoObjectArchetype"$i, PathName(Memos[i]));

	return PJSonObject;
}

function Deserialize(JSonObject Data)
{
	local int i, LoopLenght;
	local NFItem tempItem;
	local Notes tempNote;
	
	LoopLenght = Data.GetIntValue("ItemsCarried");

	for(i=0;i<LoopLenght;i++)
	{
		tempItem = NFItem(DynamicLoadObject(Data.GetStringValue("ItemObjectArchetype"$i), class'NFItem'));
		tempItem.RealStackSize = Data.GetIntValue("ItemStacks"$i);

		Items.AddItem(tempItem);
	}

	LoopLenght = Data.GetIntValue("NotesCarried");
	for(i=0;i<LoopLenght;i++)
	{
		tempNote = Notes(DynamicLoadObject(Data.GetStringValue("NoteObjectArchetype"$i), class'Notes'));
		Notebook.AddItem(tempNote);
	}

	LoopLenght = Data.GetIntValue("DiaryCarried");
	for(i=0;i<LoopLenght;i++)
	{
		tempNote=none;
		tempNote = Notes(DynamicLoadObject(Data.GetStringValue("DiaryObjectArchetype"$i), class'Notes'));
		if(tempNote == none)
		{
			tempNote = new class'Notes';
			tempNote.Text = Data.GetStringValue("DiaryText"$i);
			tempNote.Headline = Data.GetStringValue("DiaryHeadLine"$i);
			tempNote.EntryNumber = Data.GetIntValue("DiaryEntryNumber"$i);
		}
		Diary.AddItem(tempNote);
	}

	LoopLenght = Data.GetIntValue("MemosCarried");
	for(i=0;i<LoopLenght;i++)
	{
		tempNote = Notes(DynamicLoadObject(Data.GetStringValue("MemoObjectArchetype"$i), class'Notes'));
		Memos.AddItem(tempNote);
	}
}

DefaultProperties
{
//	NewNoteSound=
	InventorySpaces=21;
}