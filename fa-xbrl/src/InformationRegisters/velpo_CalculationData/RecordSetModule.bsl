///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Function AddRecord(RowStructure) Export

	Record = ThisObject.Add();
	FillPropertyValues(Record, RowStructure);
	
	Return Record;
	
EndFunction // AddRecord()
      
#EndIf