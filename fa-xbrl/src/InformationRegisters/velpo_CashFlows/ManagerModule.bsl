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
	                       
	Return ClientServer.GetCashFlowsStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText = 
	"SELECT
	|	CashFlows.Period AS Period,
	|	CashFlows.ObjectID AS ObjectID,
	|	CashFlows.ScheduleDate AS ScheduleDate,
	|	CashFlows.CashFlow AS CashFlow,
	|	CashFlows.Void AS Void
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_CashFlows.SliceLast(//{PERIOD}
	|																										,
	|																										//{FILTER}
	|																										) AS CashFlows
	|	//{JOIN}
	|";

	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	CashFlows = InformationRegisters.velpo_CashFlows;
	Server = velpo_Server;
	
	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	ScheduleDate = Undefined;
	
	If RowStructure.Property("ScheduleDate", ScheduleDate) Then
		If Not ValueIsFilled(ScheduleDate) Then
			Return Value;
		EndIf;
	EndIf;
	
	CurrentStructure = Server.GetRegisterDimensions(CashFlows);
	FillPropertyValues(CurrentStructure, RowStructure);
	CurrentStructure.ScheduleDate = ScheduleDate;

	Return CashFlows.GetLast(Period, CurrentStructure).CashFlow;
	
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	CashFlows = InformationRegisters.velpo_CashFlows;
	Server = velpo_Server;
	
	// vars
	Record = Server.CreateListRow(CashFlows, RowStructure, Period, Clone);
	If Clone Then
		Record.ScheduleDate = Undefined;
	EndIf;
	Record.Write(False);
			
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Function DeleteListRow(RowStructure, Period) Export
	
	// import
	CashFlows = InformationRegisters.velpo_CashFlows;
	Server = velpo_Server;
		
	// vars
	BeginTransaction();
	
	CurrentStructure = Server.GetRegisterDimensions(CashFlows);
	FillPropertyValues(CurrentStructure, RowStructure);
	
	If Not ValueIsFilled(RowStructure.ScheduleDate) Then
		Record = CashFlows.CreateRecordManager();
		FillPropertyValues(Record, RowStructure);
		Record.Delete();
	ElsIf  RowStructure.Period < Period Then
		Record = Server.CreateListRow(CashFlows, RowStructure, Period, False);
		Record.Void = True; 
		Record.Write(False);
	ElsIf RowStructure.Period = Period Then
		CurrentVoid = GetFieldValue(RowStructure, "Void", Period);
		SetFieldValue(RowStructure, "Void", Period, Not CurrentVoid);
		Record = CashFlows.CreateRecordManager();
		Record.Period = Period;
		FillPropertyValues(Record, CurrentStructure);
	Else
		RollbackTransaction();
		Return Undefined;
	EndIf;
	
	CommitTransaction();
	
	Return Record;
		
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	CashFlows = InformationRegisters.velpo_CashFlows;
	Server = velpo_Server;
	
	// vars
	CurrentStructure = Server.GetRegisterDimensions(CashFlows);
	FillPropertyValues(CurrentStructure, RowStructure);
	
	Server.ChangeListRow(CashFlows, CurrentStructure, Name, Period, Value);
	
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Common = velpo_CommonFunctions;

	// vars
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_CashFlows";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText();
	
	Common.SetDynamicListProperties(List, ListProperties);
	
EndProcedure

#EndIf