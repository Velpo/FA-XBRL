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
	ClientServer = velpo_ClientServer; 
	                       
	Return ClientServer.GetCalculationDataStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText =
	"SELECT
	|	CalculationData.Period AS Period,
	|	CalculationData.BusinessUnit AS BusinessUnit,
	|	CalculationData.Account AS Account,
	|	CalculationData.RowNumber AS RowNumber,
	|	CalculationData.Resource AS Resource,
	|	CalculationData.Indicator AS Indicator,
	|	CalculationData.Value AS Value
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_CalculationData AS CalculationData
	|	//{JOIN}
	|";

	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	CalculationData = InformationRegisters.velpo_CalculationData;
	Server = velpo_Server; 

	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	CurrentStructure = Server.GetRegisterDimensions(CalculationData);
	FillPropertyValues(CurrentStructure, RowStructure);
	Return CalculationData.Get(Period, CurrentStructure)[Name];		
		
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	CalculationData = InformationRegisters.velpo_CalculationData;
	Server = velpo_Server;
		
	// vars
	Record = Server.CreateListRow(CalculationData, RowStructure, Period, Clone);
	If Clone Then
		Record.Indicator = Undefined;
	EndIf;
	Record.Write(False);
	
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	CalculationData = InformationRegisters.velpo_CalculationData;
	Server = velpo_Server; 
	
	Server.ChangeListRow(CalculationData, RowStructure, Name, Period, Value);
	
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Common = velpo_CommonFunctions;
	
	// vars
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_CalculationData";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText();
	
	Common.SetDynamicListProperties(List, ListProperties);
	
EndProcedure

Procedure DeleteRows(RowStructure, Period) Export
	
	// import
	Server = velpo_Server;
	CalculationData = InformationRegisters.velpo_CalculationData;
	
	Server.DeleteRows(CalculationData, RowStructure, Period);

EndProcedure

#EndIf