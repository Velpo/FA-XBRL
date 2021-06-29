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

	Return New Structure("Period, Account,CurrencyCode,BeginOfPeriod,EndOfPeriod"); 	

EndFunction // GetItemStructure()
	
Function GetMarketRate(Period, AccountRef, CurrencyCode, BeginOfPeriod, EndOfPeriod) Export

	// import
	ServerCache =  velpo_ServerCache;
	
	Return ServerCache.GetMarketRate(Period, AccountRef, CurrencyCode, BeginOfPeriod, EndOfPeriod);
	
EndFunction // GetMarketRate()
	
#EndIf