///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetAllAccountFlagArray() Export

	// vars
	FlagArray = New Array;
	
	AccountMetaData = Metadata.ChartsOfAccounts.velpo_Economic;
	For Each MetadataFlag In AccountMetaData.AccountingFlags Do
		FlagArray	.Add(MetadataFlag.Name);
	EndDo; 
	
	Return FlagArray;
	
EndFunction // GetAllAccountFlagArray()

Function GetAllPropertiesMap() Export
	
	ReturnMap = New Map;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Ref As Ref,
	|  PredefinedDataName AS Name
	|FROM
	|	ChartOfCharacteristicTypes.velpo_ObjectAttributes
	|WHERE
	|	Parent IN (VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.AssetsLiabilities), VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.Counterparties),VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.Ratings))
	|";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ReturnMap.Insert(Selection.Name, Selection.Ref);
	EndDo;
		
	Return ReturnMap;
	
EndFunction // GetCalculationUnloadFieldCache()

Function GetAllCashFlowMap() Export
	
	ReturnMap = New Map;
	
	Query = New Query;
	Query.Text =
	"SELECT
	|	Ref As Ref,
	|  PredefinedDataName AS Name
	|FROM
	|	ChartOfCharacteristicTypes.velpo_ObjectAttributes
	|WHERE
	|	Parent IN (VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.CashFlows))
	|";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ReturnMap.Insert(Selection.Name, Selection.Ref);
	EndDo;
		
	Return ReturnMap;
	
EndFunction // GetCalculationUnloadFieldCache()

Function GetAccountData(AccountRef) Export
	
	// import
	ServerCache = velpo_ServerCache;
	Strings = velpo_StringFunctionsClientServer;
	Economic = ChartsOfAccounts.velpo_Economic;
	Common = velpo_CommonFunctions;
	
	// vars
	AccountStructure = Economic.GetStructure();
	
	If Not ValueIsFilled(AccountRef) Then
		Return AccountStructure;
	EndIf;
	
	AccountStructure.Insert("Ref", AccountRef);
	AccountStructure.Insert("Name", Common.ObjectAttributeValue(AccountRef, "PredefinedDataName"));
	
	FlagArray = ServerCache.GetAllAccountFlagArray();
	FieldsString = Strings.StringFromSubstringArray(FlagArray, ",");
	
	Query = New Query;
	Query.SetParameter("AccountRef", AccountRef);
	Query.Text =
	"SELECT
	|	// 0
	|	" + FieldsString + "
	|FROM
	|	ChartOfAccounts.velpo_Economic
	|WHERE
	|	Ref = &AccountRef
	|;
	|SELECT
	|	// 1
	|	Ref AS Ref,
	|	PredefinedDataName AS Name,
	|	Description AS Description,
	|	ValueType AS ValueType,
	|	CASE
	|		WHEN Parent = VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.Calculations)
	|			THEN TRUE
	|		ELSE FALSE
	|	END IsCalculation,
	|	CASE
	|		WHEN Parent = VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.Unload)
	|			THEN TRUE
	|		ELSE FALSE
	|	END IsUnload,
	|	FALSE AS IsDimension,
	|	CASE
	|		WHEN Parent IN (VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.AssetsLiabilities), VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.Counterparties), VALUE(ChartOfCharacteristicTypes.velpo_ObjectAttributes.Ratings))
	|			THEN TRUE
	|		ELSE FALSE
	|	END IsProperty
	|FROM
	|	ChartOfCharacteristicTypes.velpo_ObjectAttributes
	|WHERE
	|	NOT IsFolder
	|	AND Predefined
	|ORDER BY
	|	Parent.Code ASC,
	|	Code ASC
	|;
	|SELECT
	|	// 2
	|	ExtDimensionType AS Ref,
	|	ExtDimensionType.PredefinedDataName AS Name,
	|	ExtDimensionType.Description AS Description,
	|	ExtDimensionType.ValueType AS ValueType,
	|	ID AS ID,
	|	FALSE AS IsCalculation,
	|	FALSE AS IsUnload,
	|	TRUE AS IsDimension,
	|	FALSE AS IsProperty 
	|FROM
	|	ChartOfAccounts.velpo_Economic.ExtDimensionTypes
	|WHERE
	|	Ref = &AccountRef
	|";
	ResultArray = Query.ExecuteBatch();
	
	StructureDescription = "Ref,Name,Description,ValueType,IsCalculation,IsUnload,IsDimension,IsProperty";
	
	// Flags
	TableFlags = ResultArray[0].Unload();
	LineFlags = TableFlags[0];
	TableProperties = ResultArray[1].Unload();
	TableProperties.Indexes.Add("Name");
	TableDimensions = ResultArray[2].Unload();
	TableDimensions.Indexes.Add("Name");
	
	Flags = TableFlags.Columns;
		
	For Each Flag In FlagArray Do
		AccountStructure.Flags.Insert(Flag, LineFlags[Flag]);
	EndDo; 
	
	// Properties
	For Each LineProperty In TableProperties Do
		If LineFlags[LineProperty.Name] Then
			AttributeStructure = New Structure(StructureDescription);
			FillPropertyValues(AttributeStructure, LineProperty);
			AccountStructure.Insert(LineProperty.Name,AttributeStructure);
			AccountStructure.Properties.Add(LineProperty.Name);
		EndIf;
	EndDo; 
	
	// Dimensions
	For Each LineDimension In TableDimensions Do
		DimensionStructure = New Structure(StructureDescription);
		FillPropertyValues(DimensionStructure, LineDimension);
		If LineDimension.ID Then
			AccountStructure.ObjectID = DimensionStructure;
		Else
			AccountStructure.Dimensions.Add(LineDimension.Name);	
			AccountStructure.Insert(LineDimension.Name, DimensionStructure);
		EndIf;
	EndDo; 
	
	Return AccountStructure;
	
EndFunction

Function GetAccountColumns(AccountRef) Export
	
	// import
	ServerCache = velpo_ServerCache;
	
	// vars
	AccountStructure = ServerCache.GetAccountData(AccountRef);
	ReturnMap = New Map;
	
	If AccountStructure.ObjectID <> Undefined Then
		ReturnMap.Insert("ObjectID", AccountStructure.ObjectID);
	EndIf;
	
	For Each PropertyName In AccountStructure.Properties Do
		ReturnMap.Insert(PropertyName, AccountStructure[PropertyName]);
	EndDo; 
	
	For Each DimensionName In AccountStructure.Dimensions Do
		ReturnMap.Insert(DimensionName, AccountStructure[DimensionName]);
	EndDo; 
	
	Return ReturnMap;
	
EndFunction // GetAccountColumns()

Function GetAccountListByRef(AccountRef) Export
	
	// import
	ServerCache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;

	// vars
	UseDoubleParent = (AccountRef = Economic.OwnFunds);
	UseParent = ServerCache.CheckGroupAccount(AccountRef);
	ReturnList = New ValueList;
			
	If UseParent Then
		Query = New Query;
		Query.SetParameter("AccountRef", AccountRef);
		QueryText =
		"SELECT
		|	Ref AS Ref
		|FROM
		|	ChartOfAccounts.velpo_Economic
		|WHERE
		|	Parent = &AccountRef
		|";
		If UseDoubleParent Then
			QueryText = QueryText + 
			"UNION ALL
			|
			|SELECT
			|	Ref AS Ref
			|FROM
			|	ChartOfAccounts.velpo_Economic
			|WHERE
			|	Parent.Parent = &AccountRef
			|";
		EndIf;
		Query.Text = QueryText; 
		ReturnList.LoadValues(Query.Execute().Unload().UnloadColumn("Ref"));
	EndIf;
	
	// always add cuurent account
	ReturnList.Add(AccountRef);
	
	Return ReturnList;
	
EndFunction // GetAccountListByRef()

Function CheckGroupAccount(AccountRef) Export

	// import
	Economic = ChartsOfAccounts.velpo_Economic;

	Return  (AccountRef = Economic.OwnFunds Or AccountRef = Economic.Assets OR AccountRef = Economic.Liabilities);
	
EndFunction // CheckGroupAccount()

Function GetPremiumTransferDeadline(Period) Export

	// vars
	LocalPeriod = BegOfDay(Period);
	
	If LocalPeriod >= '2021-07-01' And LocalPeriod <= '2021-12-31' Then
		Return 30;
	ElsIf LocalPeriod >= '2022-01-01' And LocalPeriod <= '2022-06-30' Then
		Return 20;
	Else
		Return 10;
	EndIf;
	
EndFunction // GetPremiumTransferDeadline()

Function GetConcentrationFactor(Period, ConcentrationType, 
						IsMemberOECD = Undefined, IsReinsurerPaymentTransferred = Undefined, CreditQualityGroup = Undefined, HasLifeInsuranceLicense = Undefined) Export

	// import
	ConcentrationTypes = Enums.velpo_ConcentrationTypes;
	CreditQualityGroups = Enums.velpo_CreditQualityGroups;

	// vars	
	LocalPeriod = BegOfDay(Period);
	
	If  ConcentrationType = ConcentrationTypes.RealEstate Then
		Return 25;
	ElsIf ConcentrationType = ConcentrationTypes.Reinsurer Then
		If HasLifeInsuranceLicense = True Then
			Return 20;
		Else
			Return 60;
		EndIf;
	ElsIf  IsMemberOECD = True
			And IsReinsurerPaymentTransferred = True
			And (CreditQualityGroup = CreditQualityGroups.GruppaKredKach01Member
				Or CreditQualityGroup = CreditQualityGroups.GruppaKredKach02Member
				Or CreditQualityGroup = CreditQualityGroups.GruppaKredKach03Member
				Or CreditQualityGroup = CreditQualityGroups.GruppaKredKach04Member
				Or CreditQualityGroup = CreditQualityGroups.GruppaKredKach05Member
				Or CreditQualityGroup = CreditQualityGroups.GruppaKredKach06Member) Then
		Return 50;
			
	ElsIf LocalPeriod >= '2021-07-01' And LocalPeriod <= '2021-12-31' Then
		Return 20;
	ElsIf LocalPeriod >= '2022-01-01' And LocalPeriod <= '2022-06-30' Then
		Return 15;
	ElsIf LocalPeriod >= '2022-07-01' And LocalPeriod <= '2022-12-31' Then
		Return 12.5;
	Else
		Return 10;
	EndIf;
	
EndFunction // GetConcentrationFactor()

Function GetRisk1CorrectionArray() Export
	
	// import
	Strings = velpo_StringFunctionsClientServer;
	
	Array_i = New Array;
	Array_i.Add(Strings.SplitStringIntoSubstringArray("1,0,0,0,0,0,0"));
	Array_i.Add(Strings.SplitStringIntoSubstringArray("0,1,1,1,1,1,1"));
	Array_i.Add(Strings.SplitStringIntoSubstringArray("0,1,1,1,0.75,1,1"));
	Array_i.Add(Strings.SplitStringIntoSubstringArray("0,1,1,1,1,1,1"));
	Array_i.Add(Strings.SplitStringIntoSubstringArray("0,1,0.75,1,1,1,1"));
	Array_i.Add(Strings.SplitStringIntoSubstringArray("0,1,1,1,1,1,1"));
	Array_i.Add(Strings.SplitStringIntoSubstringArray("0,1,1,1,1,1,1"));
	
	For i = 0 To Array_i.UBound() Do
		Array_j = Array_i[i];
		For j = 0 To Array_j.UBound() Do
			Array_j[j] = Number(Array_j[j]);
		EndDo;
	EndDo; 
	
	Return Array_i;

EndFunction // GetRisk1CorrectionArray()

Function GetСorrelationRisk12CorrectionArray() Export

	Array_i = New Array;
	
	Array_1_j = New Array;
	Array_1_j.Add(1);
	Array_1_j.Add(0.25);
	
	Array_2_j = New Array;
	Array_2_j.Add(0.25);
	Array_2_j.Add(1);
	
	Array_i.Add(Array_1_j);
	Array_i.Add(Array_2_j);
	
	Return Array_i;

EndFunction // GetCorrection()

 
Function GetTaxRate() Export

	Return 20;
	
EndFunction // GetTaxRate()

Function GetKeyRate(Period, CurrencyCode) Export

	// import
	KeyRates = InformationRegisters.velpo_KeyRates;
	
	// vars
	SearchStructure = New Structure("CurrencyCode", CurrencyCode);
	
	RateData = KeyRates.GetLast(Period, SearchStructure);
	
	Return RateData.Rate;

EndFunction // GetRate()

Function GetAverageKeyRate(Period, CurrencyCode) Export

	// import
	KeyRates = InformationRegisters.velpo_KeyRates;
	
	// vars
	BeginMonth = BegOfMonth(Period);
	EndMonth = BegOfDay(EndOfMonth(Period));
	Term = Int((EndMonth - BeginMonth) / 86400 + 1) ;
	Dividend = 0;
	
	Query = New Query;
	Query.SetParameter("BegOfMonth", BeginMonth);
	Query.SetParameter("EndOfMonth", EndMonth);
	Query.SetParameter("CurrencyCode", CurrencyCode);
	Query.Text = KeyRates.GetAverageRateText();
	Selection = Query.Execute().Select();
	CurrentPeriod = BeginMonth; 
	CurrentRate = 0;
	While Selection.Next() Do
		Dividend = Dividend + Int((Selection.Period - CurrentPeriod) / 86400 + 1) *  Selection.Rate;
		CurrentPeriod = Selection.Period + 1;
		CurrentRate = Selection.Rate;
	EndDo;
	
	If CurrentPeriod <  EndMonth Then
		Dividend = Dividend + Int((EndMonth - CurrentPeriod) / 86400 + 1) *  CurrentRate;
	EndIf;
	
	Return Dividend / Term;

EndFunction // GetAverageKeyRate()

Function GetMarketRate(Period, AccountRef, CurrencyCode, BeginOfPeriod, EndOfPeriod) Export

	// import
	MarketRates = InformationRegisters.velpo_MarketRates;
	FrequencyTypes = Enums.velpo_FrequencyTypes;
	
	// vars
	SearchStructure = New Structure("Account,CurrencyCode", AccountRef, CurrencyCode);
	
	RateData = MarketRates.GetLast(Period, SearchStructure);
	
	If ValueIsFilled(EndOfPeriod) Then
		MonthCount = FrequencyTypes.GetDurationByItem(FrequencyTypes.Month, BeginOfPeriod, EndOfPeriod);
		If MonthCount > 36 Then
			ColumnName = "MoreThan3Years";	
		ElsIf MonthCount > 12 Then
			ColumnName = "BetweenYearAnd3Years";
		Else
			TermDays = Int((EndOfPeriod - BeginOfPeriod) / 86400 + 1);
			If TermDays > 180 Then
				ColumnName = "Between181AndYear";
			ElsIf TermDays > 90 Then
				ColumnName = "Between91And180";
			ElsIf TermDays > 30 Then
				ColumnName = "Between31And90";
			Else
				ColumnName = "LessThan30";
			EndIf;
		EndIf;
	Else
		ColumnName = "MoreThan3Years";
	EndIf;
	
	Return RateData[ColumnName];

EndFunction // GetMarketRate()

 