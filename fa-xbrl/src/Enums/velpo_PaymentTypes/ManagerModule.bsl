///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Function GetAnnuityCoefficient(Val RatePercent, Val Duration) Export
			
	Return RatePercent/(1-pow(1+RatePercent, -Duration));
	
EndFunction // GetAnnuityCoefficient()

Function GetDifferentiatedCoefficient(Val RatePercent, Val BeginOfPeriod, Val EndOfPeriod) Export
	
	// import
	FrequencyTypes = Enums.velpo_FrequencyTypes;
	
	// vars
	LeapYear1 = IsLeapYear(BeginOfPeriod);
	LeapYear2 = IsLeapYear(EndOfPeriod);
	BeginOfPeriod = BegOfDay(BeginOfPeriod);
	EndOfPeriod = BegOfDay(EndOfPeriod);
	
	If  AddMonth(BeginOfPeriod, 12) < EndOfPeriod Then
		Duration  = FrequencyTypes.GetDurationByItem(FrequencyTypes.Year, BeginOfPeriod, EndOfPeriod);
		Coefficient = 0;
		For i = 1 To Duration Do
			CurrentBegin = AddMonth(BeginOfPeriod, 12 * i - 12);
			CurrentEnd = AddMonth(BeginOfPeriod, 12 * i);
			If CurrentEnd > EndOfPeriod Then
				CurrentEnd = EndOfPeriod;
			EndIf;
			Coefficient = Coefficient + GetDifferentiatedCoefficient(RatePercent, CurrentBegin, CurrentEnd); 
		EndDo; 	
		Return Coefficient;
	ElsIf LeapYear1 = LeapYear2 Then
		Return RatePercent * ((EndOfPeriod - BeginOfPeriod) / 86400)  / GetYearDuration(LeapYear1);  //365
	Else
		Return RatePercent * (((BegOfDay(EndOfYear(BeginOfPeriod)) - BeginOfPeriod) / 86400)  / GetYearDuration(LeapYear1) + 
					   ((EndOfPeriod - BegOfYear(EndOfPeriod)) / 86400)  / GetYearDuration(LeapYear2));
	EndIf;

EndFunction // GetDifferentiatedCoefficient()

Function IsLeapYear(Period) Export

	Return (Year(Period) % 4 = 0);
	
EndFunction // IsLeapYear()

Function GetYearDuration(IsLeap)

	Return ?(IsLeap, 366, 365); 

EndFunction // GetYearDuration()

#EndIf