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
	                       
	Return ClientServer.GetNonLifeSolvencyMarginDataStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText =
	"SELECT
	|	NonLifeSolvencyMarginData.Period AS Period,
	|	NonLifeSolvencyMarginData.BusinessUnit AS BusinessUnit,
	|	NonLifeSolvencyMarginData.ObjectID AS ObjectID,
	|	NonLifeSolvencyMarginData.ClaimPayment_12Month AS ClaimPayment_12Month,
	|	NonLifeSolvencyMarginData.ClaimPayment_36Month AS ClaimPayment_36Month,
	|	NonLifeSolvencyMarginData.CorrectionFactor AS CorrectionFactor,
	|	NonLifeSolvencyMarginData.Deduction_12Month AS Deduction_12Month,
	|	NonLifeSolvencyMarginData.ExceedOperatorLiability AS ExceedOperatorLiability,
	|	NonLifeSolvencyMarginData.FirstIndicator AS FirstIndicator,
	|	NonLifeSolvencyMarginData.IncurredButNotReportedReserve AS IncurredButNotReportedReserve,
	|	NonLifeSolvencyMarginData.IncurredButNotReportedReserve_12Month AS IncurredButNotReportedReserve_12Month,
	|	NonLifeSolvencyMarginData.IncurredButNotReportedReserve_36Month AS IncurredButNotReportedReserve_36Month,
	|	NonLifeSolvencyMarginData.OutstandingClaimsReserve AS OutstandingClaimsReserve,
	|	NonLifeSolvencyMarginData.OutstandingClaimsReserve_12Month AS OutstandingClaimsReserve_12Month,
	|	NonLifeSolvencyMarginData.OutstandingClaimsReserve_36Month AS OutstandingClaimsReserve_36Month,
	|	NonLifeSolvencyMarginData.IncomingReinsurancePremium_12Month AS IncomingReinsurancePremium_12Month,
	|	NonLifeSolvencyMarginData.Premium_12Month AS Premium_12Month,
	|	NonLifeSolvencyMarginData.ReinsurancePremium_12Month AS ReinsurancePremium_12Month,
	|	NonLifeSolvencyMarginData.ReinsuranceShareClaimPayment_12Month AS ReinsuranceShareClaimPayment_12Month,
	|	NonLifeSolvencyMarginData.ReinsuranceShareIncurredButNotReportedReserve AS ReinsuranceShareIncurredButNotReportedReserve,
	|	NonLifeSolvencyMarginData.ReinsuranceShareIncurredButNotReportedReserve_12Months AS ReinsuranceShareIncurredButNotReportedReserve_12Months,
	|	NonLifeSolvencyMarginData.ReinsuranceShareOutstandingClaimsReserve AS ReinsuranceShareOutstandingClaimsReserve,
	|	NonLifeSolvencyMarginData.ReinsuranceShareOutstandingClaimsReserve_12Month AS ReinsuranceShareOutstandingClaimsReserve_12Month,
	|	NonLifeSolvencyMarginData.SecondIndicator AS SecondIndicator,
	|	NonLifeSolvencyMarginData.SubrogationRegression_36Months AS SubrogationRegression_36Months,
	|	NonLifeSolvencyMarginData.Account AS Account,
	|	NonLifeSolvencyMarginData.ObjectType AS ObjectType,
	|	CAST(NonLifeSolvencyMarginData.ObjectID AS Catalog.velpo_InsuranceTypeGroups).Code AS Code
	|FROM
	|	InformationRegister.velpo_NonLifeSolvencyMarginData AS NonLifeSolvencyMarginData
	|
	|//{WHERE} NonLifeSolvencyMarginData.Period = &Period AND NonLifeSolvencyMarginData.BusinessUnit = &BusinessUnit
	|";

	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	NonLifeSolvencyMarginData = InformationRegisters.velpo_NonLifeSolvencyMarginData;
	Server = velpo_Server; 

	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	CurrentStructure = Server.GetRegisterDimensions(NonLifeSolvencyMarginData);
	FillPropertyValues(CurrentStructure, RowStructure);
	
	Return NonLifeSolvencyMarginData.Get(Period, CurrentStructure)[Name];		
	
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	NonLifeSolvencyMarginData = InformationRegisters.velpo_NonLifeSolvencyMarginData;
	Server = velpo_Server;
		
	// vars
	RowStructure.Account = Economic.NonLifeSolvencyMargin;
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
			
	Record = Server.CreateListRow(NonLifeSolvencyMarginData, RowStructure, Period, Clone);
	If Clone Then
		Record.ObjectID = AccountStructure.ObjectID.ValueType.AdjustValue(Undefined);
	EndIf;
	Record.ObjectType = AccountStructure.ObjectID.Ref;
	Record.Write(False);
	
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	NonLifeSolvencyMargin = InformationRegisters.velpo_NonLifeSolvencyMarginData;
	Server = velpo_Server; 
	
	// vars
	Server.ChangeListRow(NonLifeSolvencyMargin, RowStructure, Name, Period, Value);
	
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Cache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;
	Common = velpo_CommonFunctions;
	RiskCalculations = DataProcessors.velpo_RiskCalculations;

	// vars
	AccountStructure = Economic.GetAccountData(Economic.NonLifeSolvencyMargin);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_NonLifeSolvencyMarginData";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText();
	
	Common.SetDynamicListProperties(List, ListProperties);
	
	RiskCalculations.AddDynamicListColumns(List, AccountStructure, AccountStructure.Properties);

EndProcedure

#EndIf