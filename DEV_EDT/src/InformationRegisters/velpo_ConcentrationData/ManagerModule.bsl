///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
#Region Private

Function GetMaxRowNumber(RowStructure, Period)
	
	// import
	ConcentrationData = InformationRegisters.velpo_ConcentrationData;
	Server = velpo_Server;
	
	Return Server.GetMaxRowNumber(ConcentrationData, RowStructure,  Period);

EndFunction // GetMaxRowNumber

#EndRegion 

#Region Public

Function GetStructure() Export

	// import
	ClientServer = velpo_ClientServer; 
	
	Return ClientServer.GetConcentrationDataStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText(AccountStructure, OnlyData = False) Export
	
	// vars
	QueryText =
	"SELECT
	|	ConcentrationData.Period AS Period,
	|	ConcentrationData.BusinessUnit AS BusinessUnit,
	|	ConcentrationData.Account AS Account,
	|	ConcentrationData.RowNumber AS RowNumber,
	|	ConcentrationData.ObjectID AS ObjectID,
	|	ConcentrationData.ConcentrationRiskAssetValue AS ConcentrationRiskAssetValue,
	|	ConcentrationData.ConcentrationRiskImpact AS ConcentrationRiskImpact,
	|	ConcentrationData.ConcentrationFactor AS ConcentrationFactor
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_ConcentrationData AS ConcentrationData
	|	//{JOIN}
	|//{WHERE} ConcentrationData.Period = &Period AND ConcentrationData.BusinessUnit = &BusinessUnit
	|";
	
	If OnlyData Then
		Return QueryText;
	EndIf;
	
	Fields = "";
	Join = "";
		
	// Dimensions
	For Each DimensionName In AccountStructure.Dimensions Do
		TableName = "Table_" + DimensionName;
		Fields = Fields + ",
		|" + TableName + ".Value AS " + DimensionName;
		Join = Join + 
		"LEFT JOIN  InformationRegister.velpo_DimensionData AS " + TableName + "
		|ON ConcentrationData.Period = " + TableName + ".Period
		|	AND ConcentrationData.BusinessUnit = " + TableName + ".BusinessUnit
		|	AND ConcentrationData.Account = " + TableName + ".Account
		|	AND ConcentrationData.RowNumber = " + TableName + ".RowNumber
		|	AND " + TableName + ".Dimension = VALUE(ChartOfCharacteristicTypes.velpo_DimensionIDTypes." + DimensionName + ")
		|";
	EndDo; 
	
	QueryText = StrReplace(QueryText, "//{FIELDS}", Fields);
	QueryText = StrReplace(QueryText, "//{JOIN}", Join);

	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	ConcentrationData = InformationRegisters.velpo_ConcentrationData;
	DimensionData = InformationRegisters.velpo_DimensionData;
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
				
	If Attribute.IsDimension Then
		Return DimensionData.GetFieldValue(RowStructure, Name, Period);
	Else
		CurrentStructure = Server.GetRegisterDimensions(ConcentrationData);
		FillPropertyValues(CurrentStructure, RowStructure);
		Return ConcentrationData.Get(Period, CurrentStructure)[Name];		
	EndIf;
	
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	ConcentrationData = InformationRegisters.velpo_ConcentrationData;
	ServerCache = velpo_ServerCache;
	Server = velpo_Server;
	
	AccountRef = RowStructure.Account;
	AccountStructure = Economic.GetAccountData(AccountRef);

	If ServerCache.CheckGroupAccount(AccountRef) Then
		Return Undefined;
	EndIf;
	
	Record = Server.CreateListRow(ConcentrationData, RowStructure, Period, Clone);
	
	If Clone Then
		Record.ObjectID = AccountStructure.ObjectID.ValueType.AdjustValue(Undefined);
		Record.RowNumber = GetMaxRowNumber(RowStructure, Period);
	ElsIf Record.RowNumber = 0 Then
		Record.RowNumber = GetMaxRowNumber(RowStructure, Period);
	EndIf;
	
	Record.ObjectType = AccountStructure.ObjectID.Ref;
	Record.Write(False);
			
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	ConcentrationData = InformationRegisters.velpo_ConcentrationData;
	DimensionData = InformationRegisters.velpo_DimensionData;
	Server = velpo_Server; 
	
	// vars
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
	Attribute = Undefined;
	
	If Not AccountStructure.Property(Name, Attribute) Then
		Return;
	EndIf;
	
	If Attribute.IsCalculation Or RowStructure.Property(Name) Then
		Server.ChangeListRow(ConcentrationData, RowStructure, Name, Period, Value);
	ElsIf Attribute.IsDimension Then
		DimensionData.SetFieldValue(RowStructure, Name, Period, Value);
	Else
		Server.ChangeListRow(ConcentrationData, RowStructure, Name, Period, Value);
	EndIf;
		
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Cache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;
	Common = velpo_CommonFunctions;
	RiskCalculations = DataProcessors.velpo_RiskCalculations;

	// vars
	AccountStructure = Economic.GetAccountData(Economic.Concentration);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_ConcentrationData";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText(AccountStructure);
	
	Common.SetDynamicListProperties(List, ListProperties);
	
	RiskCalculations.AddDynamicListColumns(List, AccountStructure, AccountStructure.Dimensions);
	RiskCalculations.AddDynamicListColumns(List, AccountStructure, AccountStructure.Properties);
	
EndProcedure

#EndRegion 

#EndIf

 