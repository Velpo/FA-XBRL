#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Function GetApprovedConsolidatedRatings() Export

	// import
	ConsolidatedRatings = Enums.velpo_ConsolidatedRatings;
	
	ApprovedConsolidatedRatings = New Map;
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.AAA, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.AA_plus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.AA, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.AA_minus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.A_plus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.A, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.A_minus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.BBB_plus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.BBB, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.BBB_minus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.BB_plus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.BB, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.BB_minus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.B_plus, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.B, True);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.B_minus, False);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.CCC_plus_C_minus, False);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.NotRated, False);
	ApprovedConsolidatedRatings.Insert(ConsolidatedRatings.D, False);

	Return ApprovedConsolidatedRatings; 
	
EndFunction

#EndIf