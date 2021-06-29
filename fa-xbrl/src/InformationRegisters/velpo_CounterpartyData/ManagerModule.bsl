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
	                       
	Return ClientServer.GetCounterpartyDataStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText(AccountStructure, OnlyData = False) Export
	
	QueryText =
	"SELECT
	|	CounterpartyData.Period AS Period,
	|	CounterpartyData.BusinessUnit AS BusinessUnit,
	|	CounterpartyData.ObjectID AS ObjectID,
	|	CounterpartyData.ConsolidatedRating AS ConsolidatedRating,
	|	CounterpartyData.CreditQualityGroup AS CreditQualityGroup,
	|	CounterpartyData.CreditRating AS CreditRating,
	|	CounterpartyData.RatingAgency AS RatingAgency,
	|	CounterpartyData.Risk2Category AS Risk2Category,
	|	CounterpartyData.Account AS Account,
	|	CounterpartyData.Status AS Status
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_CounterpartyData AS CounterpartyData
	|	//{JOIN}
	|//{WHERE} CounterpartyData.Period = &Period AND CounterpartyData.BusinessUnit = &BusinessUnit
	|";
	
	If OnlyData Then
		Return QueryText;
	EndIf;
	
	Fields = "";
	Join = "";
	
	For Each PropertyName In AccountStructure.Properties Do
		PropertyData = AccountStructure[PropertyName];
		
		If PropertyData.IsCalculation Then
			Continue;
		EndIf;
		
		TableName = "Table_" + PropertyName;
		
		If PropertyData.IsUnload Then
			Fields = Fields + ",
			|" + TableName + "." + PropertyName + " AS " + PropertyName;
			Join = Join + 
			"LEFT JOIN  InformationRegister.velpo_UnloadIdentificators.SliceLast AS " + TableName + "
			|ON CounterpartyData.ObjectID = " + TableName + ".ObjectID
			|";
		Else
			Fields = Fields + ",
			|" + TableName + ".Value AS " + PropertyName;
			Join = Join + 
			"LEFT JOIN  InformationRegister.velpo_ObjectProperties.SliceLast AS " + TableName + "
			|ON CounterpartyData.ObjectID = " + TableName + ".ObjectID
			|	AND " + TableName + ".Attribute = VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes." + PropertyName + ")
			|";
		EndIf;
		
	EndDo; 
		
	QueryText = StrReplace(QueryText, "//{FIELDS}", Fields);
	QueryText = StrReplace(QueryText, "//{JOIN}", Join);

	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	CounterpartyData = InformationRegisters.velpo_CounterpartyData;
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	UnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	Server = velpo_Server; 

	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
	Attribute = Undefined;
	
	If Not AccountStructure.Property(Name, Attribute) Then
		Return Value;
	EndIf;
	
	If Attribute.IsUnload Then
		Return UnloadIdentificators.GetFieldValue(RowStructure, Name, Period);
	ElsIf Attribute.IsCalculation Then
		CurrentStructure = Server.GetRegisterDimensions(CounterpartyData);
		FillPropertyValues(CurrentStructure, RowStructure);
		Return CounterpartyData.Get(Period, CurrentStructure)[Name];		
	Else
		Return ObjectProperties.GetFieldValue(RowStructure, Name, Period);
	EndIf;
	
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	CounterpartyData = InformationRegisters.velpo_CounterpartyData;
	Server = velpo_Server;
		
	// vars
	RowStructure.Account = Economic.Counterparties;
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
	
	Record = Server.CreateListRow(CounterpartyData, RowStructure, Period, Clone);
	If Clone Then
		Record.ObjectID = AccountStructure.ObjectID.ValueType.AdjustValue(Undefined);
	EndIf;
	Record.ObjectType = AccountStructure.ObjectID.Ref;
	Record.Status = 0;
	Record.Write(False);
			
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	CounterpartyData = InformationRegisters.velpo_CounterpartyData;
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	UnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	Server = velpo_Server; 
	
	// vars
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
	Attribute = Undefined;
	
	If Not AccountStructure.Property(Name, Attribute) Then
		Return;
	EndIf;
	
	If Attribute.IsUnload Then
		UnloadIdentificators.SetFieldValue(RowStructure, Name, Period, Value);
	ElsIf Attribute.IsCalculation Or RowStructure.Property(Name) Then
		Server.ChangeListRow(CounterpartyData, RowStructure, Name, Period, Value);
	Else
		ObjectProperties.SetFieldValue(RowStructure, Name, Period, Value);
	EndIf;
	
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Cache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;
	Common = velpo_CommonFunctions;
	RiskCalculations = DataProcessors.velpo_RiskCalculations;

	// vars
	AccountStructure = Economic.GetAccountData(Economic.Counterparties);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_CounterpartyData";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText(AccountStructure);
	
	Common.SetDynamicListProperties(List, ListProperties);
	
	RiskCalculations.AddDynamicListColumns(List, AccountStructure, AccountStructure.Properties);

EndProcedure

#EndIf