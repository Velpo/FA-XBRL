///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Function GetTermByItem(FrequencyItem) Export
	
	// import
	FrequencyTypes = Enums.velpo_FrequencyTypes;
	
	If  FrequencyItem = FrequencyTypes.Month Then
		Return 1;
	ElsIf FrequencyItem = FrequencyTypes.Quarter Then
		Return 3;
	ElsIf FrequencyItem = FrequencyTypes.HalfYear Then
		Return 6;
	Else
		Return 12;
	EndIf;
		
EndFunction // GetTermByItem()

Function GetDurationByItem(FrequencyItem, BeginOfPeriod, EndOfPeriod) Export
	
	If ValueIsFilled(BeginOfPeriod) And ValueIsFilled(EndOfPeriod) Then
		Duration = ((Year(EndOfPeriod) - Year(BeginOfPeriod)) * 12 + Month(EndOfPeriod) - Month(BeginOfPeriod)) / GetTermByItem(FrequencyItem);
		If (Duration - Int(Duration)) > 0 Then
			Duration = Int(Duration) + 1;
		EndIf;
		Return Duration;
	Else
		Return 0;
	EndIf;
	
EndFunction // GetTermByItem()

	
#EndIf