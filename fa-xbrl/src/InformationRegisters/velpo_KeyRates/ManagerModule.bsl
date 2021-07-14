///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Public

Function GetStructure() Export

	Return New Structure("Period, CurrencyCode"); 	

EndFunction // GetItemStructure()

Function GetAverageRateText() Export
	
	Text =	
	"SELECT
	|	Period,
	|	Rate
	|FROM
	|	InformationRegister.velpo_KeyRates
	|WHERE
	|	Period BETWEEN &BegOfMonth And &EndOfMonth
	|	And CurrencyCode = &CurrencyCode
	|ORDER BY
	|	Period ASC	
	|";

	Return Text;
	
EndFunction // GetMaxRowNumber

Function GetKeyRate(Period, CurrencyCode) Export

	// import
	ServerCache =  velpo_ServerCache;
		
	Return ServerCache.GetKeyRate(Period, CurrencyCode);

EndFunction // GetRate()

Function GetAverageKeyRate(Period, CurrencyCode) Export

	// import
	ServerCache =  velpo_ServerCache;
		
	Return ServerCache.GetAverageKeyRate(Period, CurrencyCode);
	
EndFunction // GetAverageRate()

 #EndRegion
	
#EndIf