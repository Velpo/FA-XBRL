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
	                       
	Return ClientServer.GetObjectPropertiesStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText =
	"SELECT
	|	ObjectProperties.Period AS Period,
	|	ObjectProperties.ObjectID AS ObjectID,
	|	ObjectProperties.Attribute AS Attribute,
	|	ObjectProperties.Value AS Value
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_ObjectProperties.SliceLast(//{PERIOD}
	|																													,
	|																													//{FILTER}
	|																													) AS ObjectProperties
	|	//{JOIN}
	|";
	
	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	Server = velpo_Server;
	
	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	AccountRef = Undefined;
	AttributeRef = Undefined;
	
	If RowStructure.Property("Attribute", AttributeRef) Then
		If Not ValueIsFilled(AttributeRef) Then
			Return Value;
		EndIf;
	ElsIf RowStructure.Property("Account", AccountRef) Then
		AccountStructure = Economic.GetAccountData(AccountRef);
		Attribute = Undefined;
		If AccountStructure.Property(Name, Attribute) Then
			AttributeRef = Attribute.Ref;
		Else
			Return Value;
		EndIf;
	EndIf;
	
	CurrentStructure = Server.GetRegisterDimensions(ObjectProperties);
	FillPropertyValues(CurrentStructure, RowStructure);
	CurrentStructure.Attribute = AttributeRef;

	Return ObjectProperties.GetLast(Period, CurrentStructure).Value;		
		
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	Server = velpo_Server;
	
	Record = Server.CreateListRow(ObjectProperties, RowStructure, Period, Clone);
	If Clone Then
		Record.Attribute = Undefined;
	EndIf;
	Record.Write(False);
			
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	Server = velpo_Server;
	
	// vars
	AccountRef = Undefined;
	AttributeRef = Undefined;
	
	If RowStructure.Property("Attribute", AttributeRef) Then
		If Not ValueIsFilled(AttributeRef) Then
			Return;
		EndIf;
	ElsIf RowStructure.Property("Account", AccountRef) Then
		AccountStructure = Economic.GetAccountData(AccountRef);
		Attribute = Undefined;
		If AccountStructure.Property(Name, Attribute) Then
			AttributeRef = Attribute.Ref;
		Else
			Return;
		EndIf;
	EndIf;
	
	CurrentStructure = Server.GetRegisterDimensions(ObjectProperties);
	FillPropertyValues(CurrentStructure, RowStructure);
	CurrentStructure.Attribute = AttributeRef;
	
	Server.ChangeListRow(ObjectProperties, CurrentStructure, "Value", Period, Value);
	
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Common = velpo_CommonFunctions;

	// vars
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_ObjectProperties";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText();
	
	Common.SetDynamicListProperties(List, ListProperties);
	
EndProcedure

#EndIf