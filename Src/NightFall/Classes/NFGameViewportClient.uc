class NFGameViewportClient extends UDKGameViewportClient;

function DrawTransition(Canvas Canvas)
{
	switch(Outer.TransitionType)
	{
		case TT_Loading:
			class'Engine'.static.RemoveAllOverlays();
			class'Engine'.static.AddOverlayWrapped(class'Engine'.Static.GetMediumFont(), LoadRandomLocalizedHintMessage("Generic","House"), 0.05, 0.92, 1.0, 1.0, 0.95 );
			break;
		case TT_Saving:
			DrawTransitionMessage(Canvas,SavingMessage);
			break;
		case TT_Connecting:
			DrawTransitionMessage(Canvas,ConnectingMessage);
			break;
		case TT_Precaching:
			DrawTransitionMessage(Canvas,PrecachingMessage);
			break;
		case TT_Paused:
			DrawTransitionMessage(Canvas,PausedMessage);
			break;
	}
}

DefaultProperties
{
	HintLocFileName="LoadingHints"
}
