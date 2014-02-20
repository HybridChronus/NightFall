class ItemBehave_AddNotes extends ItemBehavior;

var(NF) const archetype array<Notes> NodesAdded;

var(NF) const bool RemoveAfterUse;

function Used(NFPlayerController User, NFItem Instigator)
{
	local Notes tempNote;
	if(User != none && User.bePawn != none && User.bePawn.NFInventoryManager != none)
	{
		if(RemoveAfterUse)
			User.bePawn.NFInventoryManager.RemoveInventory(Instigator);
		foreach NodesAdded(tempNote)
			User.bePawn.NFInventoryManager.AddNote(tempNote);
	}
}

DefaultProperties
{
}