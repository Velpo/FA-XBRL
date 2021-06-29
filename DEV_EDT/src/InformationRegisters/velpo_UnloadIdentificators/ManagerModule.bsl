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
	                       
	Return ClientServer.GetUnloadIdentificatorsStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText =
	"SELECT
	|	UnloadIdentificators.Period AS Period,
	|	UnloadIdentificators.ObjectID AS ObjectID,
	|	UnloadIdentificators.Identificator AS Identificator
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_UnloadIdentificators.SliceLast(//{PERIOD}
	|																													,
	|																													//{FILTER}
	|																													) AS UnloadIdentificators
	|	//{JOIN}
	|";
	
	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	UnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	Server = velpo_Server;
	
	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	AccountRef = Undefined;
	If RowStructure.Property("Account", AccountRef) Then
		AccountStructure = Economic.GetAccountData(AccountRef);
		Attribute = Undefined;
	
		If Not AccountStructure.Property(Name, Attribute) Then
			Return Value;
		EndIf;
	EndIf;
	
	CurrentStructure = Server.GetRegisterDimensions(UnloadIdentificators);
	FillPropertyValues(CurrentStructure, RowStructure);

	Return UnloadIdentificators.GetLast(Period, CurrentStructure).Identificator;		
		
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	UnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	Server = velpo_Server;
		
	Record = Server.CreateListRow(UnloadIdentificators, RowStructure, Period, Clone);
	Record.Write(False);
	
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	UnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	Server = velpo_Server; 
	
	// vars
	AccountRef = Undefined;
	If RowStructure.Property("Account", AccountRef) Then
		AccountStructure = Economic.GetAccountData(AccountRef);
		Attribute = Undefined;
	
		If Not AccountStructure.Property(Name, Attribute) Then
			Return;
		EndIf;
	EndIf;
	
	Server.ChangeListRow(UnloadIdentificators, RowStructure, Name, Period, Value);
	
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Common = velpo_CommonFunctions;

	// vars
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_UnloadIdentificators";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText();
	
	Common.SetDynamicListProperties(List, ListProperties);
	
EndProcedure

#EndIf