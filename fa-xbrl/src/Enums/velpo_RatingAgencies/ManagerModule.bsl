///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Function GetStructure() Export

	// import
	RatingAgencies = Enums.velpo_RatingAgencies;
	
	RaitingStructure = New Structure;
	RaitingStructure.Insert("StandardAndPoors", RatingAgencies.StandardAndPoors);
	RaitingStructure.Insert("MoodysInvestorsService", RatingAgencies.MoodysInvestorsService);
	RaitingStructure.Insert("FitchRatings", RatingAgencies.FitchRatings);
	RaitingStructure.Insert("ExpertRA", RatingAgencies.ExpertRA);
	RaitingStructure.Insert("ACRA", RatingAgencies.ACRA);
	RaitingStructure.Insert("AM_Best", RatingAgencies.AM_Best);

	Return RaitingStructure;

EndFunction // GetStructure()

	
#EndIf