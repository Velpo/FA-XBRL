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

	Return New Structure("Ref, ObjectID, Flags, Properties, Dimensions",,, New Structure,New Array,New Array); 	

EndFunction // GetStructure()

Function GetAccountData(AccountRef) Export

	// import
	Cache = velpo_ServerCache;
	
	Return Cache.GetAccountData(AccountRef);
	
EndFunction // GetAccountData()

Function GetAccountListByRef(AccountRef) Export
	
	// import
	Cache = velpo_ServerCache;
	
	Return Cache.GetAccountListByRef(AccountRef);

EndFunction // GetAccountListByRef()

Function GetAccountPropertiesByDimensionID(IDArray) Export

	// import
	Cache = velpo_ServerCache;
	EconomicItemAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	Strings = velpo_StringFunctionsClientServer;
	
	// vars
	PropertyMap = New Map;
	
	FlagArray = Cache.GetAllAccountFlagArray();
	FieldsString = Strings.StringFromSubstringArray(FlagArray, ",");
	AllPropertyMap = Cache.GetAllPropertiesMap();
	
	Query = New Query;
	Query.SetParameter("IDArray", IDArray);
	Query.Text = 
	"SELECT
	|	" + FieldsString + "
	|FROM
	|	ChartOfAccounts.velpo_Economic
	|WHERE
	|	Ref IN 
	|		(SELECT 
	|			Ref 
	|		FROM 
	|			ChartOfAccounts.velpo_Economic.ExtDimensionTypes 
	|		WHERE 
	|			ExtDimensionType IN (&IDArray) AND ID)
	|";
	
	Result = Query.Execute();
	Columns = Result.Columns;
	Selection = Result.Select();
	While Selection.Next() Do
		For Each Column In Columns Do
			Name = Column.Name;
			If AllPropertyMap[Name] = Undefined Then
				Continue;
			EndIf;
			If 	Selection[Name] Then
				PropertyMap.Insert(Name, EconomicItemAttributes[Name]);
			EndIf;
		EndDo; 		
	EndDo;
	
	Return PropertyMap;

EndFunction // GetAccountPropertiesByDimensionID()

Function GetZeroAccountMap() Export

	// import
	ResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;
	Economic = ChartsOfAccounts.velpo_Economic;
	
	ZeroMap = New Map;
	ZeroMap.Insert(Economic.CashOnHand, ResourceIndicators.Clause_3_1_19);
	ZeroMap.Insert(Economic.ParticipationShares, ResourceIndicators.Clause_3_1_5);
	ZeroMap.Insert(Economic.MortgageBackedSecurities, ResourceIndicators.Clause_3_1_10);
	ZeroMap.Insert(Economic.PromissoryNotes, ResourceIndicators.Clause_3_1_11);
	ZeroMap.Insert(Economic.DeferredTaxAssets, ResourceIndicators.Clause_3_1_18);
	ZeroMap.Insert(Economic.Things, ResourceIndicators.Clause_3_1_19);
	ZeroMap.Insert(Economic.LeaseAssets, ResourceIndicators.Clause_3_1_20);
	ZeroMap.Insert(Economic.IntangibleAssets, ResourceIndicators.Clause_3_1_21);
	ZeroMap.Insert(Economic.DeferredAcquisitionCosts, ResourceIndicators.Clause_3_1_22);
	ZeroMap.Insert(Economic.EstimatesOfFutureCashFlows, ResourceIndicators.Clause_4_3);
	ZeroMap.Insert(Economic.DeferredAcquisitionIncome, ResourceIndicators.Clause_4_3);

	Return ZeroMap;

EndFunction // GetZeroAccountMap()


#EndIf
