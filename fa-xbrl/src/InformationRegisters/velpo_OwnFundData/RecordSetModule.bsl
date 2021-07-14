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
      
Procedure OnWrite(Cancel, Replacing)
	
	// if not delete
	If ThisObject.Count() > 0 Then
		Return;	
	EndIf;
	
	ClearChildRows = True;
	If ThisObject.AdditionalProperties.Property("ClearChildRows", ClearChildRows) Then
		If Not ClearChildRows Then
			Return;
		EndIf;
	EndIf;
	
	// import
	CalculationData = InformationRegisters.velpo_CalculationData;
	DimensionData = InformationRegisters.velpo_DimensionData;
	
	RowStructure =  New Structure;
	Period = Undefined;
	For Each Element In ThisObject.Filter Do
		RowStructure.Insert(Element.Name, Element.Value);
		If Element.Name = "Period" Then
			Period = Element.Value;
		EndIf;
	EndDo; 
	
	CalculationData.DeleteRows(RowStructure, Period);
	DimensionData.DeleteRows(RowStructure, Period);
	
EndProcedure
	
#EndIf
