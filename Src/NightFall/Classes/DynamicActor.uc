class DynamicActor extends Actor
   ClassGroup(NF)
   AutoExpandCategories(NF)
   placeable;

// Expose to Unrealscript and Unreal Editor
var(NF) const EditInline Instanced array<PrimitiveComponent> PrimitiveComponents;

function PostBeginPlay()
{
  local int i;
  
  // Check the primitive components array to see if we need to add any components into the components array.
  if (PrimitiveComponents.Length > 0)
  {
    for (i = 0; i < PrimitiveComponents.Length; ++i)
    {
      if (PrimitiveComponents[i] != None)
      {
        AttachComponent(PrimitiveComponents[i]);
      }
    }
  }
}

DefaultProperties
{
	Begin Object Class=SpriteComponent Name=Sprite
    Sprite=Texture2D'EditorResources.S_Actor'
   HiddenGame=True
   AlwaysLoadOnClient=False
   AlwaysLoadOnServer=False
  End Object
  Components.Add(Sprite)
}