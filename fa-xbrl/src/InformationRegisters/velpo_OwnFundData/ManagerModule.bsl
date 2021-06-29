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
	OwnFundData = InformationRegisters.velpo_OwnFundData;
	Server = velpo_Server;
	
	Return Server.GetMaxRowNumber(OwnFundData, RowStructure,  Period);

EndFunction // GetMaxRowNumber

#EndRegion 

#Region Public

Function GetStructure() Export

	// import
	ClientServer = velpo_ClientServer; 
	
	Return ClientServer.GetOwnFundDataStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText(AccountStructure, OnlyData = False) Export
	
	// vars
	QueryText =
	"SELECT
	|	OwnFundData.Period AS Period,
	|	OwnFundData.BusinessUnit AS BusinessUnit,
	|	OwnFundData.Account AS Account,
	|	OwnFundData.RowNumber AS RowNumber,
	|	OwnFundData.ObjectID AS ObjectID,
	|	OwnFundData.MarketRate AS MarketRate,
	|	OwnFundData.BookValue AS BookValue,
	|	OwnFundData.ConsolidatedRating AS ConsolidatedRating,
	|	OwnFundData.CreditQualityGroup AS CreditQualityGroup,
	|	OwnFundData.CreditRating AS CreditRating,
	|	OwnFundData.CreditSpreadImpact AS CreditSpreadImpact,
	|	OwnFundData.DefaultRefundPrice AS DefaultRefundPrice,
	|	OwnFundData.EquityCover AS EquityCover,
	|	OwnFundData.ExchangeRateGrowthImpact AS ExchangeRateGrowthImpact,
	|	OwnFundData.ExchangeRateReductionImpact AS ExchangeRateReductionImpact,
	|	OwnFundData.ImpairmentAllowance AS ImpairmentAllowance,
	|	OwnFundData.InterestRateGrowthImpact AS InterestRateGrowthImpact,
	|	OwnFundData.InterestRateReductionImpact AS InterestRateReductionImpact,
	|	OwnFundData.ItemValue AS ItemValue,
	|	OwnFundData.MathematicalReserve AS MathematicalReserve,
	|	OwnFundData.OtherAssetPriceChangeImpact AS OtherAssetPriceChangeImpact,
	|	OwnFundData.Quantity AS Quantity,
	|	OwnFundData.RatingAgency AS RatingAgency,
	|	OwnFundData.OverdueDebt AS OverdueDebt,
	|	OwnFundData.RealEstatePriceChangeImpact AS RealEstatePriceChangeImpact,
	|	OwnFundData.ReservesCover AS ReservesCover,
	|	OwnFundData.UnearnedPremiumReserve AS UnearnedPremiumReserve,
	|	OwnFundData.ValueShareChangeImpact AS ValueShareChangeImpact,
	|	OwnFundData.Status AS Status
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_OwnFundData AS OwnFundData
	|	//{JOIN}
	|//{WHERE} OwnFundData.Period = &Period AND OwnFundData.BusinessUnit = &BusinessUnit
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
		|ON OwnFundData.Period = " + TableName + ".Period
		|	AND OwnFundData.BusinessUnit = " + TableName + ".BusinessUnit
		|	AND OwnFundData.Account = " + TableName + ".Account
		|	AND OwnFundData.RowNumber = " + TableName + ".RowNumber
		|	AND " + TableName + ".Dimension = VALUE(ChartOfCharacteristicTypes.velpo_DimensionIDTypes." + DimensionName + ")
		|";
	EndDo; 
	
	// Flags
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
			|ON OwnFundData.ObjectID = " + TableName + ".ObjectID
			|";
		Else
			Fields = Fields + ",
			|" + TableName + ".Value AS " + PropertyName;
			Join = Join + 
			"LEFT JOIN  InformationRegister.velpo_ObjectProperties.SliceLast AS " + TableName + "
			|ON OwnFundData.ObjectID = " + TableName + ".ObjectID
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
	OwnFundData = InformationRegisters.velpo_OwnFundData;
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	DimensionData = InformationRegisters.velpo_DimensionData;
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
		CurrentStructure = Server.GetRegisterDimensions(OwnFundData);
		FillPropertyValues(CurrentStructure, RowStructure);
		Return OwnFundData.Get(Period, CurrentStructure)[Name];		
	ElsIf Attribute.IsDimension Then
		Return DimensionData.GetFieldValue(RowStructure, Name, Period);
	Else
		Return ObjectProperties.GetFieldValue(RowStructure, Name, Period);
	EndIf;
	
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	OwnFundData = InformationRegisters.velpo_OwnFundData;
	ServerCache = velpo_ServerCache;
	Server = velpo_Server;
	
	AccountRef = RowStructure.Account;
	AccountStructure = Economic.GetAccountData(AccountRef);

	If ServerCache.CheckGroupAccount(AccountRef) Then
		Return Undefined;
	EndIf;
	
	Record = Server.CreateListRow(OwnFundData, RowStructure, Period, Clone);
	
	If Clone Then
		Record.ObjectID = AccountStructure.ObjectID.ValueType.AdjustValue(Undefined);
		Record.RowNumber = GetMaxRowNumber(RowStructure, Period);
	ElsIf Record.RowNumber = 0 Then
		Record.RowNumber = GetMaxRowNumber(RowStructure, Period);
	EndIf;
	
	Record.ObjectType = AccountStructure.ObjectID.Ref;
	Record.Status = 0;
	Record.Write(False);
			
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	OwnFundData = InformationRegisters.velpo_OwnFundData;
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	DimensionData = InformationRegisters.velpo_DimensionData;
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
		Server.ChangeListRow(OwnFundData, RowStructure, Name, Period, Value);
	ElsIf Attribute.IsDimension Then
		DimensionData.SetFieldValue(RowStructure, Name, Period, Value);
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
	AccountStructure = Economic.GetAccountData(Economic.OwnFunds);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_OwnFundData";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText(AccountStructure);
	
	Common.SetDynamicListProperties(List, ListProperties);
	
	RiskCalculations.AddDynamicListColumns(List, AccountStructure, AccountStructure.Dimensions);
	RiskCalculations.AddDynamicListColumns(List, AccountStructure, AccountStructure.Properties);
	
EndProcedure

#EndRegion 

#EndIf

 