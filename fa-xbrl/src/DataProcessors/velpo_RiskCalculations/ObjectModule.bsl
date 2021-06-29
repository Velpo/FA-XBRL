///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

Var ApprovedConsolidatedRatings;
Var MainCalculations;
Var ZeroMap;
Var ZeroAccountMap;
Var RaitingStructure;
	
#Region Private

Function GetQueryTextSources()

	Return
	"SELECT
	|	// 0
	|	ItemLinks.Ref AS LinkRef,
	|	CASE
	|		WHEN ItemLinks.LinkType = VALUE(Enum.velpo_ItemLinkTypes.Dimension)
	|			THEN 1
	|		WHEN ItemLinks.LinkType = VALUE(Enum.velpo_ItemLinkTypes.Attribute)
	|			THEN 2
	|	END AS LinkType,
	|	CASE
	|		WHEN ItemLinks.TableType = VALUE(Enum.velpo_ItemTableTypes.MainTable)
	|			THEN 1
	|		WHEN ItemLinks.TableType = VALUE(Enum.velpo_ItemTableTypes.CashFlow)
	|			THEN 2
	|	END AS TableType,
	|	ItemLinks.Result AS Result,
	|	ItemLinks.Owner.Code As FieldName,
	|	ItemLinks.Attribute.PredefinedDataName AS AttributeName,
	|	ItemLinks.Dimension.PredefinedDataName AS DimensionName,
	|	ItemLinks.Attribute AS Attribute,
	|	ItemLinks.Dimension AS Dimension,
	| 	ItemLinks.UseSourceValue AS UseSourceValue
	|INTO
	|	VT_ItemLinks
	|FROM
	|	Catalog.velpo_ItemLinks AS ItemLinks
	|WHERE
	|	ItemLinks.Account  = &Account
	|INDEX BY
	|	LinkRef
	|;
	|SELECT DISTINCT
	|	// 1
	|	Parent AS Ref,
	|	Ref AS Result,
	|	Ref.IndexNum AS IndexNum
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents
	|WHERE
	|	Ref IN (SELECT Result FROM VT_ItemLinks)
	|;
	|SELECT DISTINCT
	|	// 2
	|	ItemLinks.TableType
	|FROM
	|	VT_ItemLinks AS ItemLinks
	|;
	|SELECT
	|	// 3
	|	ItemLinks.LinkRef,
	|	ItemLinks.LinkType,
	|	ItemLinks.TableType,
	|	ItemLinks.Result,
	|	ItemLinks.FieldName,
	|	ItemLinks.AttributeName,
	|	ItemLinks.DimensionName,
	|	ItemLinks.Attribute,
	|	ItemLinks.Dimension,
	| 	ItemLinks.UseSourceValue
	|FROM
	|	VT_ItemLinks AS ItemLinks
	|ORDER BY
	|	TableType,
	|	LinkType,
	|	LinkRef
	|;
	|SELECT
	|	// 4
	|	Links.Ref AS LinkRef,
	|	Links.Otherwise AS Otherwise,
	|	Links.FieldValue AS FieldValue,
	|	Links.Value AS Value
	|FROM
	|	Catalog.velpo_ItemLinks.AttributeLinks AS Links
	|WHERE
	|	Links.Ref IN (SELECT LinkRef FROM VT_ItemLinks)
	|;
	|SELECT
	|	// 5
	|	Links.Ref AS LinkRef,
	|	Links.Otherwise AS Otherwise,
	|	Links.FieldValue AS FieldValue,
	|	Links.Value AS Value
	|FROM
	|	Catalog.velpo_ItemLinks.DimensionLinks AS Links
	|WHERE
	|	Links.Ref IN (SELECT LinkRef FROM VT_ItemLinks)
	|";

EndFunction // GetQueryTextSources() 

Function GetQueryTextForObjects(Text)
	
	QueryText = StrReplace(Text, "//{PERIOD}", "&Period"); 
 	QueryText = StrReplace(QueryText, "//{FILTER}", "VALUETYPE(ObjectID) IN (&ObjectTypes)"); 
	Return Chars.CR + ";" + Chars.CR + QueryText;

EndFunction // GetQueryTextForObjects()

Function GetQueryTextMargin()

	Return
	"SELECT
	|	// 0
	|	&Period AS Period,
	|	&BusinessUnit AS BusinessUnit,
	|	&Account AS Account,
	|	&ObjectType AS ObjectType,
	|	VALUE(Catalog.velpo_NormativeRatioItems.OwnFunds) AS ObjectID, 
	|	SUM(OwnFundData.ItemValue) AS ItemValue
	|FROM
	|	InformationRegister.velpo_OwnFundData AS OwnFundData
	|WHERE
	|	OwnFundData.Period = &Period
	|	AND OwnFundData.BusinessUnit = &BusinessUnit
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessUnit AS BusinessUnit,
	|	&Account AS Account,
	|	&ObjectType AS ObjectType,
	|	VALUE(Catalog.velpo_NormativeRatioItems.MinimumAuthorizedCapital) AS ObjectID,
	|	SUM(OwnFundData.ItemValue) AS ItemValue
	|FROM
	|	InformationRegister.velpo_OwnFundData AS OwnFundData
	|WHERE
	|	OwnFundData.Period = &Period
	|	AND OwnFundData.BusinessUnit = &BusinessUnit
	|	AND OwnFundData.Account = VALUE(ChartOfAccounts.velpo_Economic.Equity)
	|	AND OwnFundData.ObjectID = VALUE(Catalog.velpo_EquityComponents.MinimumAuthorizedCapital)
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessUnit AS BusinessUnit,
	|	&Account AS Account,
	|	&ObjectType AS ObjectType,
	|	VALUE(Catalog.velpo_NormativeRatioItems.LifeReserves) AS ObjectID,
	|	SUM(OwnFundData.ItemValue) AS ItemValue
	|FROM
	|	InformationRegister.velpo_OwnFundData AS OwnFundData
	|WHERE
	|	OwnFundData.Period = &Period
	|	AND OwnFundData.BusinessUnit = &BusinessUnit
	|	AND OwnFundData.Account = VALUE(ChartOfAccounts.velpo_Economic.Reserves)
	|	AND OwnFundData.ObjectID IN HIERARCHY (VALUE(Catalog.velpo_InsuranceReserves.LifeReserves))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessUnit AS BusinessUnit,
	|	&Account AS Account,
	|	&ObjectType AS ObjectType,
	|	VALUE(Catalog.velpo_NormativeRatioItems.ReinsuranceShareLifeReserves) AS ObjectID,
	|	SUM(OwnFundData.ItemValue) AS ItemValue
	|FROM
	|	InformationRegister.velpo_OwnFundData AS OwnFundData
	|WHERE
	|	OwnFundData.Period = &Period
	|	AND OwnFundData.BusinessUnit = &BusinessUnit
	|	AND OwnFundData.Account = VALUE(ChartOfAccounts.velpo_Economic.ReserveReinsuranceShares)
	|	AND OwnFundData.ObjectID IN HIERARCHY (VALUE(Catalog.velpo_InsuranceReserves.LifeReserves))
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessUnit AS BusinessUnit,
	|	&Account AS Account,
	|	&ObjectType AS ObjectType,
	|	VALUE(Catalog.velpo_NormativeRatioItems.FirstIndicator) AS ObjectID,
	|	SUM(NonLifeSolvencyMarginData.FirstIndicator * NonLifeSolvencyMarginData.CorrectionFactor) AS ItemValue
	|FROM
	|	InformationRegister.velpo_NonLifeSolvencyMarginData AS NonLifeSolvencyMarginData
	|WHERE
	|	NonLifeSolvencyMarginData.Period = &Period
	|	AND NonLifeSolvencyMarginData.BusinessUnit = &BusinessUnit
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessUnit AS BusinessUnit,
	|	&Account AS Account,
	|	&ObjectType AS ObjectType,
	|	VALUE(Catalog.velpo_NormativeRatioItems.SecondIndicator) AS ObjectID,
	|	SUM(NonLifeSolvencyMarginData.SecondIndicator * NonLifeSolvencyMarginData.CorrectionFactor) AS ItemValue
	|FROM
	|	InformationRegister.velpo_NonLifeSolvencyMarginData AS NonLifeSolvencyMarginData
	|WHERE
	|	NonLifeSolvencyMarginData.Period = &Period
	|	AND NonLifeSolvencyMarginData.BusinessUnit = &BusinessUnit
	|
	|UNION ALL
	|
	|SELECT
	|	&Period AS Period,
	|	&BusinessUnit AS BusinessUnit,
	|	&Account AS Account,
	|	&ObjectType AS ObjectType,
	|	VALUE(Catalog.velpo_NormativeRatioItems.ExceedOperatorLiability) AS ObjectID,
	|	SUM(NonLifeSolvencyMarginData.ExceedOperatorLiability) AS ItemValue
	|FROM
	|	InformationRegister.velpo_NonLifeSolvencyMarginData AS NonLifeSolvencyMarginData
	|WHERE
	|	NonLifeSolvencyMarginData.Period = &Period
	|	AND NonLifeSolvencyMarginData.BusinessUnit = &BusinessUnit
	|;
	|SELECT
	|	// 1
	|	SUM(OwnFundData.ItemValue) AS ItemValue
	|FROM
	|	InformationRegister.velpo_OwnFundData AS OwnFundData
	|WHERE
	|	OwnFundData.Period = &Period
	|	AND OwnFundData.BusinessUnit = &BusinessUnit
	|	AND OwnFundData.Account IN HIERARCHY (VALUE(ChartOfAccounts.velpo_Economic.Assets))
	|";

EndFunction // GetQueryTextMargin()

Function GetValueByNormativeRatioItem(Table, ObjectID)

	LineTable = Table.Find(ObjectID, "ObjectID");
	If LineTable = Undefined Or LineTable.ItemValue = Null Then
	    Return 0;
	Else
		Return LineTable.ItemValue;
	EndIf;
				
EndFunction // GetValueByItem()

Function GetTableRowStructure(Table)

	Columns = Table.Columns;
	Text = "";
	For Each Column In Columns Do
		Text = Text + ?(Text = "", "", ",") + Column.Name;
	EndDo; 
	
	Return New Structure(Text);
	
EndFunction // GetTableRowStructure()

Function GetTableData(SelectionResult)
	
	// import
	ReportConstruction = DataProcessors.velpo_ReportConstruction.Create();
	
	// vars
	TableData = Undefined;
	
	ReportConstruction.PeriodStart = BegOfDay(ThisObject.Period);
	ReportConstruction.PeriodEnd = EndOfDay(ThisObject.Period);
	ReportConstruction.BusinessUnit = ThisObject.BusinessUnit;
		
	TempTablesManager = New TempTablesManager;
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	// set source data
	QueryResults = ReportConstruction.GetSourceQueryResults(SelectionResult.Ref);
	Index = 0;
	For Each QueryResult In QueryResults  Do
		Index = Index + 1;
		If Index  <> SelectionResult.IndexNum Then
			Continue;
		EndIf;
		TableFields = ReportConstruction.GetFieldsCache(SelectionResult.Result, True);
		Selection = QueryResult.Select();
		While Selection.Next() Do
				ReportConstruction.GetFieldValues(SelectionResult.Result, Selection, TableFields, True); 
		EndDo;
		TableData = ReportConstruction.ResultsCache[SelectionResult.Result];
	EndDo;
	TempTablesManager.Close();
	
	Return TableData;
	
EndFunction // GetTableData()

Function CheckCounterpartyRating(CounterpartyRef, TableCounterparty)
	
	If Not ValueIsFilled(CounterpartyRef) Then
		Return True;
	EndIf;
	
	LineCounterparty = TableCounterparty.Find(CounterpartyRef, "ObjectID");
	If LineCounterparty = Undefined Then
		Return False;
	EndIf;
	
	If Not ValueIsFilled(LineCounterparty.ConsolidatedRating) Then
		Return False;
	EndIf;
		
	Return ApprovedConsolidatedRatings[LineCounterparty.ConsolidatedRating];
	
EndFunction

Function CheckCounterpartyBankrupt(CounterpartyRef, TableCounterparty)
	
	LineIssuer = TableCounterparty.Find(CounterpartyRef, "ObjectID");
			
	If LineIssuer <> Undefined Then
		// 3.1.14
		If LineIssuer.CounterpartyClause_3_1_14 = True Then
			Return True;
		EndIf;
	EndIf;
	
	Return False;
		
EndFunction

Function CheckPropertyFlag(RowData, PropertyName, AccountStructure) 

	Return (AccountStructure.Flags[PropertyName] And RowData[PropertyName] = True);
					
EndFunction

Function CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty)
	
	If CheckCounterpartyRating(RowData.CounterpartyID, TableCounterparty) Then
		Return True;
	EndIf;
	
	// 3.1.8
	If CheckPropertyFlag(RowData, "GuaranteeClause_3_1_8", AccountStructure) Then
		If CheckCounterpartyRating(RowData.GuarantorID, TableCounterparty) Then
			Return True;
		EndIf;
	EndIf;
		
	Return False;
	
EndFunction

Function InitializeRecordSet(Register, Clear = False, AccountRef = Undefined, RowNumber = Undefined, ObjectID = Undefined)
	
	RecordSet = Register.CreateRecordSet();
	RecordSet.Filter.Period.Set(ThisObject.Period);
	
	If RecordSet.Filter.Find("BusinessUnit") <> Undefined Then
		RecordSet.Filter.BusinessUnit.Set(ThisObject.BusinessUnit);
	EndIf;
	
	If AccountRef <> Undefined And RecordSet.Filter.Find("Account") <> Undefined Then
		RecordSet.Filter.Account.Set(AccountRef);
	EndIf;
	
	If RowNumber <> Undefined And RecordSet.Filter.Find("RowNumber") <> Undefined Then
		RecordSet.Filter.RowNumber.Set(RowNumber);
	EndIf;
	
	If ObjectID <> Undefined And RecordSet.Filter.Find("ObjectID") <> Undefined Then
		RecordSet.Filter.ObjectID.Set(ObjectID);
	EndIf;
	
	If Clear Then
		RecordSet.AdditionalProperties.Insert("ClearChildRows", False);
		RecordSet.Write(Clear);
	EndIf;

	Return RecordSet;

EndFunction // InitializeRecordSet()

Function InitializeRegisterSet(Register, Clear = False, AccountRef = Undefined, RowNumber = Undefined, ObjectID = Undefined)
	
	// import
	Common = velpo_CommonFunctions;
	Server = velpo_Server;
	Strings = velpo_StringFunctionsClientServer;
	
	// vars
	DimensionStructure = Server.GetRegisterDimensions(Register);
	DimensionArray = New Array;
	
	RecordSet = InitializeRecordSet(Register, Clear, AccountRef, RowNumber, ObjectID);
	
	RegisterSet = RecordSet.Unload();
	For Each DimensionElement In DimensionStructure  Do
		DimensionArray.Add(DimensionElement.Key);
	EndDo; 
	
	If RegisterSet.Columns.Find("Period") = Undefined Then
		RegisterSet.Columns.Add("Period", Common.DateTypeDescription(DateFractions.Date));
	EndIf;
	
	DimensionArray.Add("Period");
	RegisterSet.Indexes.Add(Strings.StringFromSubstringArray(DimensionArray, ","));
	
	Return RegisterSet;

EndFunction

Function GetLinkFieldValue(LinkRef, FieldValue, TableLinks)
	
	LinksArray = TableLinks.FindRows(New Structure("LinkRef", LinkRef));
	OtherwiseValue = Undefined;
	For Each Link In LinksArray Do
		If Link.FieldValue = 	FieldValue Then
			Return Link.Value;
		ElsIf Link.Otherwise Then
			OtherwiseValue = Link.Value;
		EndIf;
	EndDo;
	
	Return OtherwiseValue;
	
EndFunction // GetLinkFieldValue()

Function GetReserveBookValue(AccountRef, CurrencyID, InsuranceReserve, TableData, Regular = True)
	
	// import
	InsuranceReserves = Catalogs.velpo_InsuranceReserves;
	
	// vars
	BookValue = 0;
	
	FilterStructure = New Structure("Account,CurrencyID", AccountRef,CurrencyID);
	RowsArray = TableData.FindRows(FilterStructure);
	For Each Row In RowsArray Do
		If Regular Then
			If Not (InsuranceReserve = InsuranceReserves.IndirectCostsReserve
							Or InsuranceReserve = InsuranceReserves.DirectCostsReserve
							Or InsuranceReserve = InsuranceReserves.UnexpiredRiskReserve) Then
				BookValue = BookValue + Row.BookValue;
			EndIf;
		Else
			If Not (InsuranceReserve = InsuranceReserves.StabilizationReserve
							Or InsuranceReserve = InsuranceReserves.StabilizationReserveOSAGO
							Or InsuranceReserve = InsuranceReserves.StabilizationReserveAdequacy) Then
				BookValue = BookValue + Row.BookValue;
			EndIf;
		EndIf; 
	EndDo; 
	
	Return BookValue;

EndFunction // GetReserveBookValue()

Function GetAccountBookValue(AccountRef, CurrencyID, TableData)
	
	// vars
	BookValue = 0;
	
	FilterStructure = New Structure("Account,CurrencyID", AccountRef, CurrencyID);
	RowsArray = TableData.FindRows(FilterStructure);
	For Each Row In RowsArray Do
		BookValue = BookValue + Row.BookValue;
	EndDo; 
	
	Return BookValue;

EndFunction // GetAccountBookValue()

Function GetRatingSettingsData()
	
	//import 
	RegisterRatingSettings = InformationRegisters.velpo_RatingSettings;
	RatingAgencies = Enums.velpo_RatingAgencies;

	Query = New Query;
	Query.SetParameter("Period",  ThisObject.Period);
	Query.SetParameter("BusinessUnit",  ThisObject.BusinessUnit);
	Query.Text = StrReplace(RegisterRatingSettings.GetQueryText(), "//{PERIOD}", "&Period");
	TableRatingSettings = Query.Execute().Unload();
	
	For Each Element In RaitingStructure  Do
		TableRatingSettings.Indexes.Add(Element.Key);	
	EndDo; 

	Return TableRatingSettings;

EndFunction // GetRatingData()

Function GetConterpartyData(ObjectArray = Undefined)

	// import
	RegisterCounterparty = InformationRegisters.velpo_CounterpartyData;
	Economic = ChartsOfAccounts.velpo_Economic;

	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.SetParameter("ObjectArray", ObjectArray);
	
	TextCounterparty = StrReplace(RegisterCounterparty.GetQueryText(Economic.GetAccountData(Economic.Counterparties)), "//{WHERE}", "WHERE");
	If ObjectArray <> Undefined  Then
		TextCounterparty = TextCounterparty + " AND CounterpartyData.ObjectID IN (&ObjectArray)";
	EndIf;

	Query.Text = TextCounterparty;
	
	TableCounterpartySet = Query.Execute().Unload();
	TableCounterpartySet.Indexes.Add("ObjectID");
	
	Return TableCounterpartySet;

EndFunction // GetContrypartyData()

Function GetCashFlowData(AccountRef, RowArray = Undefined)

	// import
	CashFlows = InformationRegisters.velpo_CashFlows;
	Economic = ChartsOfAccounts.velpo_Economic;

	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.SetParameter("Account", AccountRef);
	Query.SetParameter("RowArray", RowArray);

	TextCashFlows = StrReplace(CashFlows.GetQueryText(), "//{PERIOD}", "&Period");
	TextCashFlows = StrReplace(TextCashFlows, "//{FILTER}", 
		"ObjectID IN (SELECT DISTINCT ObjectID FROM InformationRegister.velpo_OwnFundData WHERE Period = &Period AND BusinessUnit = &BusinessUnit AND Account = &Account //%AND RowNumber IN (&RowArray)
		|)");
	
	If  RowArray <> Undefined Then
		TextCashFlows = StrReplace(TextCashFlows, "//%AND", "AND");		
	EndIf;
		
	Query.Text = TextCashFlows;
		
	TableCashFlowSet = Query.Execute().Unload();
	TableCashFlowSet.Indexes.Add("ObjectID");
	
	Return TableCashFlowSet;

EndFunction // GetContrypartyData()

Function GetOwnFundData(AccountRef, RowArray = Undefined)

	// import
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	Economic = ChartsOfAccounts.velpo_Economic;
	
	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.SetParameter("Account", AccountRef);
	Query.SetParameter("RowArray", RowArray);
				
	TextOwnFunds = StrReplace(RegisterOwnFund.GetQueryText(Economic.GetAccountData(Economic.OwnFunds)), "//{WHERE}", "WHERE");
	TextOwnFunds = TextOwnFunds + " AND OwnFundData.Account = &Account";
		
	If RowArray <> Undefined  Then
		TextOwnFunds = TextOwnFunds + " AND OwnFundData.RowNumber IN (&RowArray)";
	EndIf;
		
	Query.Text = TextOwnFunds;
	TableData = Query.Execute().Unload();
	TableData.Indexes.Add("Account,CurrencyID,ObjectID");

	Return TableData;
	
EndFunction // GetOwnFundData()

Function CheckOwnFundData(AccountRef)

	// import
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	Economic = ChartsOfAccounts.velpo_Economic;

  	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.SetParameter("Account", AccountRef);
	
	TextOwnFunds = StrReplace(RegisterOwnFund.GetQueryText(Economic.GetAccountData(AccountRef), True), "//{WHERE}", "WHERE");
	TextOwnFunds = StrReplace(TextOwnFunds, "SELECT", "SELECT TOP 1");
	TextOwnFunds = TextOwnFunds + " AND OwnFundData.Account = &Account";
			
	Query.Text = TextOwnFunds;
	ResultQuery = Query.Execute();
	
	Return Not ResultQuery.IsEmpty();
	
EndFunction // CheckData()

Function GetObligatoryEntities()
		
	// import
	DimensionIDTypes = ChartsOfCharacteristicTypes.velpo_DimensionIDTypes;
	Common  = velpo_CommonFunctions; 
	
	// vars
	CacheCounterparty = New Map;
	LloydEntity = Undefined; 
	TableCounterparty = GetConterpartyData();
	TableCounterparty.Columns.Add("ObligatoryEntity", Common.ObjectAttributeValue(DimensionIDTypes.CounterpartyID, "ValueType"));
	
	// set ObligatoryEntity
	For Each RowConterparty In TableCounterparty Do
		
		If 	Not ValueIsFilled(RowConterparty.Identificator) Then
			Continue;
		EndIf;
		
		If  RowConterparty.IsLloydSyndicates Then
			If  LloydEntity = Undefined Then
				LloydEntity = RowConterparty.ObjectID;
			EndIf;
			ObligatoryEntity = LloydEntity;
		Else
			ObligatoryEntity = CacheCounterparty[RowConterparty.Identificator];
			If ObligatoryEntity = Undefined Then
				ObligatoryEntity = RowConterparty.ObjectID;
				CacheCounterparty.Insert(RowConterparty.Identificator, ObligatoryEntity);
			EndIf;
		EndIf;
		
		RowConterparty.ObligatoryEntity = ObligatoryEntity;
		
	EndDo; 
	
	Return TableCounterparty;

EndFunction // GetObligatiryEntities()

Function GetOwnFundConcentration()

	// import
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	
	// vars
	AccountStructure = New Structure("Dimensions, Properties", New Array, New Array);
	
	// dims
	AccountStructure.Dimensions.Add("CounterpartyID");
	AccountStructure.Dimensions.Add("GuarantorID");
	AccountStructure.Dimensions.Add("CreditOrganizationID");
	AccountStructure.Dimensions.Add("InsuranceReserveID");
	
	// properties
	AccountStructure.Properties.Add("IsOSGOP");
	AccountStructure.Properties.Add("IsOSOPO");
	AccountStructure.Properties.Add("ReinsuranceShareReserveClause_3_1_12_16_1");
	
	For Each PropertyName In 	AccountStructure.Properties Do
		AccountStructure.Insert(PropertyName, New Structure("IsCalculation,IsUnload,IsDimension,IsProperty",False,False,False, True));
	EndDo; 
	
	TextOwnFunds = StrReplace(RegisterOwnFund.GetQueryText(AccountStructure), "//{WHERE}", "WHERE");
	TextOwnFunds = TextOwnFunds + " AND OwnFundData.Account.Parent = VALUE(ChartOfAccounts.velpo_Economic.Assets)";

	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.Text = TextOwnFunds;
	
	TableOwnFundConcentration = Query.Execute().Unload();
		
	Return TableOwnFundConcentration;
	
EndFunction // GetQueryTextOwnFundConcentration()

Function AddMainRecord(RegisterSet, MainStructure)

	MainStructure.Insert("RowNumber", MainStructure.RowNumber + 1);
	Record = RegisterSet.Add();
	FillPropertyValues(Record, MainStructure);
	
	Return Record;
	
EndFunction

Function CalculateConcentrationRisk()

	// import
	RegisterConcentrationData = InformationRegisters.velpo_ConcentrationData;
	ServerCache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;
	ConcentrationTypes = Enums.velpo_ConcentrationTypes;
	
	// vars
	AccountStructure = ServerCache.GetAccountData(Economic.Concentration);
	TextConcentration = StrReplace(RegisterConcentrationData.GetQueryText(AccountStructure), "//{WHERE}", "WHERE");
	ConcRe = 0;
	Corr = 1;
	
	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.Text = TextConcentration;
	
	TableData = Query.Execute().Unload();
	
	SqrtExpression = 0;
	For Each RowData In TableData Do
		
		If RowData.ObjectID = ConcentrationTypes.Reinsurer Then
			ConcRe = ConcRe + RowData.ConcentrationRiskImpact;
		Else
			SqrtExpression = SqrtExpression + Corr * Pow(RowData.ConcentrationRiskImpact, 2);
		EndIf;
	
	EndDo; 
	 
	 Return Sqrt(SqrtExpression) + Max(0, ConcRe);
	 
EndFunction // CalculateConcentrationRisk()

Function CalculateRiskExpression(TableData, RiskList, CoefArray)

	// import
	CatalogNormativeRatioItems = Catalogs.velpo_NormativeRatioItems;
	
	// vars
	RiskExpression = 0;
	i = 0;
	For Each Risk_i In RiskList Do
		j = 0;
		For Each Risk_j In  RiskList Do
			RiskExpression = RiskExpression + CoefArray[i][j] * Risk_i.Value * Risk_j.Value;
			j = j + 1;
		EndDo; 
		AddNormativeRatioItemValue(TableData, CatalogNormativeRatioItems[Risk_i.Presentation], Risk_i.Value);
		i = i + 1;
	EndDo; 

	Return RiskExpression;
	
EndFunction // Get()


Procedure AddCashFlows(RegisterSet, MainStructure, Table)

	// check
	If RegisterSet = Undefined Or Not ValueIsFilled(MainStructure.ObjectID) Then
		Return;
	EndIf;
	
	// import
	RegisterCashFlows = InformationRegisters.velpo_CashFlows;
	
	// vars
	SearchStructure = New Structure("Period, ObjectID, ScheduleDate");
	RowStructure = GetTableRowStructure(Table); 
	FillPropertyValues(SearchStructure, MainStructure);
	RowArray = Table.FindRows(SearchStructure);
	AddNewRow = False;
	
	If RowArray.Count() = 0 Then
		AddNewRow = True;
	Else
		CurrentRow = RowArray[0];
		If CurrentRow.Void Then
			RegisterCashFlows.DeleteListRow(MainStructure, MainStructure.Period);
			AddNewRow = True;
		ElsIf CurrentRow.CashFlow <> MainStructure.CashFlow Then
			FillPropertyValues(RowStructure, CurrentRow);
			RegisterCashFlows.SetFieldValue(RowStructure, "CashFlow", MainStructure.Period,  MainStructure.CashFlow);
		EndIf;
		Table.Delete(CurrentRow);
	EndIf;
	
	If AddNewRow Then
		If RegisterSet.FindRows(SearchStructure).Count() = 0 Then
			FillPropertyValues(RegisterSet.Add(), MainStructure);
		EndIf;
	EndIf;
	
EndProcedure

Procedure AddDimensions(RegisterSet, MainStructure, Elements, Table)

	// check
	If RegisterSet = Undefined Then
		Return;
	EndIf;
	
	// vars
	SearchStructure = New Structure("BusinessUnit, Account, ObjectID");
	
	FillPropertyValues(SearchStructure, MainStructure);
	RowArray = Table.FindRows(SearchStructure);
	For Each CurrentRow In RowArray Do
		If Elements[CurrentRow.Dimension] = Undefined Then
			Elements.Insert(CurrentRow.Dimension, CurrentRow.Value);
		EndIf;
	EndDo; 
		
	For Each Element In Elements Do
		Record = RegisterSet.Add();
		FillPropertyValues(Record, MainStructure);
		Record.Dimension = Element.Key;
		Record.Value = Element.Value;
	EndDo; 

EndProcedure

Procedure AddProperties(RegisterSet, MainStructure, Elements, Table)
	
	// check
	If RegisterSet = Undefined Or Not ValueIsFilled(MainStructure.ObjectID) Then
		Return;
	EndIf;
	
	// import
	RegisterObjectProperties = InformationRegisters.velpo_ObjectProperties;	
	
	// vars
	SearchStructure = New Structure("Period, ObjectID, Attribute");
	RowStructure = GetTableRowStructure(Table); 
	FillPropertyValues(SearchStructure, MainStructure);
	
	For Each Element In Elements Do
		SearchStructure.Insert("Attribute", Element.Key);
		RowArray = Table.FindRows(SearchStructure);
		If RowArray.Count() = 0 Then
			If RegisterSet.FindRows(SearchStructure).Count() = 0 Then
				Record = RegisterSet.Add();
				FillPropertyValues(Record, MainStructure);
				Record.Attribute = Element.Key;
				Record.Value = Element.Value;
			EndIf;
		Else
			CurrentRow = RowArray[0];
			If CurrentRow.Value <> Element.Value Then
				FillPropertyValues(RowStructure, CurrentRow);
				RegisterObjectProperties.SetFieldValue(RowStructure, "Value", MainStructure.Period,  Element.Value);
			EndIf;
		EndIf;
	
	EndDo; 

EndProcedure

Procedure AddUnloads(RegisterSet,  MainStructure, Elements, Table)

	// check
	If RegisterSet = Undefined Or Not ValueIsFilled(MainStructure.ObjectID)  Or Elements.Count() = 0 Then
		Return;
	EndIf;
	
	// import
	RegisterUnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	
	// vars
	SearchStructure = New Structure("Period, ObjectID");
	RowStructure = GetTableRowStructure(Table); 
	FillPropertyValues(SearchStructure, MainStructure);
	RowArray = Table.FindRows(SearchStructure);
	
	If RowArray.Count() = 0 Then
		If RegisterSet.FindRows(SearchStructure).Count() = 0 Then
			Record = RegisterSet.Add();
			FillPropertyValues(Record, MainStructure);
			FillPropertyValues(Record, Elements);
		EndIf;
	Else
		CurrentRow = RowArray[0];
		For Each Element In  Elements Do
			If CurrentRow[Element.Key]<> Element.Value Then
				FillPropertyValues(RowStructure, CurrentRow);
				RegisterUnloadIdentificators.SetFieldValue(RowStructure, Element.Key, MainStructure.Period,  Element.Value);
			EndIf;	
		EndDo; 
	EndIf;
   
EndProcedure

Procedure SetCashFlowsVoid(RegisterSet,  MainStructure, Elements, Table)
	
	// check
	If RegisterSet = Undefined Or Elements.Count() Then
		Return;
	EndIf;

	// import
	RegisterCashFlows = InformationRegisters.velpo_CashFlows;
	
	// vars
	SearchStructure = New Structure("ObjectID");
	RowStructure = GetTableRowStructure(Table); 
	
	For Each Element In  Elements Do
		SearchStructure.Insert("ObjectID", Element.Key);
		RowArray = Table.FindRows(SearchStructure);
		For Each CurrentRow In RowArray Do
			If Not CurrentRow.Void Then
				FillPropertyValues(RowStructure, CurrentRow);
				RegisterCashFlows.SetFieldValue(RowStructure, "Void", MainStructure.Period,  False);			
			EndIf;
		EndDo; 
	EndDo; 

EndProcedure

Procedure WriteRecordSet(Register, RegisterSet, Clear = False)

	If RegisterSet <> Undefined And (RegisterSet.Count() > 0 Or Clear) Then
		RecordSet = Register.CreateRecordSet();
		RecordSet.Load(RegisterSet);
		RecordSet.Write(Clear);
	EndIf;

EndProcedure

Procedure FillRegisterData(RegisterName, AccountStructure)
	
	// import
	CommonServer = velpo_CommonFunctions;
	ClientServer = velpo_ClientServer; 
	RegisterMain = InformationRegisters[RegisterName];
	RegisterCashFlows = InformationRegisters.velpo_CashFlows;
	RegisterDimensions = InformationRegisters.velpo_DimensionData;
	RegisterObjectProperties = InformationRegisters.velpo_ObjectProperties;
	RegisterUnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	RegisterDimensionData = InformationRegisters.velpo_DimensionData;
	RegisterCalculationData = InformationRegisters.velpo_CalculationData;
	
	// vars
	ObjectIDName =  AccountStructure.ObjectID.Name;
	ObjectType =  AccountStructure.ObjectID.Ref;
	ObjectValueType = CommonServer.ObjectAttributeValue(ObjectType, "ValueType");
	RegisterID = Mid(RegisterName, 7);
	ObjectMap = New Map;
	
	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("Account", AccountStructure.Ref);
	Query.SetParameter("ObjectTypes", ObjectValueType.Types());
			
	QueryText = GetQueryTextSources();
	
	HasProperties = (RegisterID = "OwnFundData" Or   RegisterID = "CounterpartyData");
	IsOwnFunds = (RegisterID = "OwnFundData");
	
	If HasProperties Then
		// add dimension
		QueryTextDimensions = GetQueryTextForObjects(RegisterDimensions.GetQueryText());
		QueryTextDimensions = StrReplace(QueryTextDimensions, "//{FIELDS}", ", Dimension.PredefinedDataName AS Name");
		QueryText = QueryText + QueryTextDimensions; 
		// add properties
		QueryTextProperties = GetQueryTextForObjects(RegisterObjectProperties.GetQueryText());
		QueryTextProperties = StrReplace(QueryTextProperties, "//{FIELDS}", ", Attribute.PredefinedDataName AS Name");
		QueryText = QueryText + QueryTextProperties;
		// add unload IDs
		QueryText = QueryText + GetQueryTextForObjects(RegisterUnloadIdentificators.GetQueryText());
	EndIf;
	
	If IsOwnFunds Then
		QueryText = QueryText + GetQueryTextForObjects(RegisterCashFlows.GetQueryText());
	EndIf;
	
	Query.Text = QueryText;
	QueryArray = Query.ExecuteBatch();
	
	TableTypes = QueryArray[2].Unload();
	TableItemLinks = QueryArray[3].Unload();
	TableAttributeLinks = QueryArray[4].Unload();
	TableDimensionLinks = QueryArray[5].Unload();
	TableDimensions = Undefined;
	TableProperties = Undefined;
	TableUnload = Undefined;
	TableCashFlow = Undefined;
	
	TableItemLinks.Indexes.Add("TableType, Result");
	TableAttributeLinks.Indexes.Add("LinkRef");
	TableDimensionLinks.Indexes.Add("LinkRef");
	
	If HasProperties Then
		TableProperties = QueryArray[7].Unload();
		TableProperties.Indexes.Add("Period, ObjectID, Attribute");
		TableUnload = QueryArray[8].Unload();
		TableUnload.Indexes.Add("Period, ObjectID");
	EndIf;
	
	If IsOwnFunds Then
		TableDimensions = QueryArray[6].Unload();
		TableDimensions.Indexes.Add("BusinessUnit, Account, ObjectID");

		TableCashFlow = QueryArray[9].Unload();
		TableCashFlow.Indexes.Add("Period, ObjectID, ScheduleDate");
		TableCashFlow.Indexes.Add("ObjectID");
	EndIf;
	
	SelectionResult = QueryArray[1].Select();
		
	MainStructure = New Structure;
	MainStructure.Insert("Period", ThisObject.Period);
	MainStructure.Insert("BusinessUnit", ThisObject.BusinessUnit);
	MainStructure.Insert("Account", AccountStructure.Ref);
	MainStructure.Insert("ObjectType", ObjectType);
	MainStructure.Insert("RowNumber", 0);	
		
	BeginTransaction();
	
	MainSet = InitializeRegisterSet(RegisterMain, True, AccountStructure.Ref);
	
	If IsOwnFunds Then
		DimensionSet = InitializeRegisterSet(RegisterDimensionData, True, AccountStructure.Ref);
		CalculationSet = InitializeRegisterSet(RegisterCalculationData, True, AccountStructure.Ref);
		CashFlowSet = InitializeRegisterSet(RegisterCashFlows);
	EndIf;
	
	If HasProperties Then
		ObjectPropertySet = InitializeRegisterSet(RegisterObjectProperties);
		UnloadIdentificatorSet = InitializeRegisterSet(RegisterUnloadIdentificators);
	EndIf;

	While SelectionResult.Next() Do
		
		// data
		TableData = GetTableData(SelectionResult);
		If TableData = Undefined Then
			Continue;
		EndIf;
		
		// table type
		For Each RowTableType In TableTypes Do
			
			ItemLinkArray = TableItemLinks.FindRows(New Structure("TableType, Result", RowTableType.TableType, SelectionResult.Result));
			
			If ItemLinkArray.Count() = 0 Then
				Continue;
			EndIf;
			
			// data
			For Each RowData In TableData Do
				
				MainStructure.Insert("ObjectID", Undefined);
				UnloadStructure = New Structure;
				DimensionMap = New Map;
				PropertyMap = New Map;
																
				// set field 
				For Each FieldLink In ItemLinkArray Do
					FieldValue = RowData[FieldLink.FieldName];
					If FieldLink.UseSourceValue Then
						Value = FieldValue;
					ElsIf FieldLink.LinkType = 1 Then 
						Value = GetLinkFieldValue(FieldLink.LinkRef, FieldValue, TableDimensionLinks);
					ElsIf FieldLink.LinkType = 2 Then 
						Value = GetLinkFieldValue(FieldLink.LinkRef, FieldValue, TableAttributeLinks);
					EndIf;
					
					// Dimension
					If FieldLink.LinkType = 1 Then 
						If ObjectIDName = FieldLink.DimensionName Then
							Value = ObjectValueType.AdjustValue(Value);
							MainStructure.Insert("ObjectID", Value);
							If ValueIsFilled(Value) Then
								ObjectMap.Insert(Value, True);
							EndIf;
						EndIf;
						DimensionMap.Insert(FieldLink.Dimension, Value);
					// Attribute
					Else
						AttributeData = AccountStructure[FieldLink.AttributeName];
						If AttributeData.IsProperty Then
							PropertyMap.Insert(FieldLink.Attribute, Value);
						ElsIf AttributeData.IsUnload Then
							UnloadStructure.Insert(FieldLink.AttributeName, Value);
						Else
							MainStructure.Insert(FieldLink.AttributeName, Value);	
						EndIf;
					EndIf;
				EndDo;
				
				// 1 - main, 2 - cash flow
				If RowTableType.TableType = 1 Then
					AddMainRecord(MainSet, MainStructure);
					// add rest
					AddDimensions(DimensionSet, MainStructure, DimensionMap, TableDimensions);
					AddProperties(ObjectPropertySet, MainStructure, PropertyMap, TableProperties);
					AddUnloads(UnloadIdentificatorSet,  MainStructure, UnloadStructure, TableUnload);
				Else
					AddCashFlows(CashFlowSet, MainStructure, TableCashFlow);
				EndIf;

			EndDo;
			
			If  RowTableType.TableType = 1 Then
				WriteRecordSet(RegisterMain, MainSet);
				If IsOwnFunds Then
					WriteRecordSet(RegisterDimensions, DimensionSet);
				EndIf;
				If HasProperties Then
					WriteRecordSet(RegisterObjectProperties, ObjectPropertySet);
					WriteRecordSet(RegisterUnloadIdentificators, UnloadIdentificatorSet);
				EndIf;
				// cash flow - set void and 
			Else
				SetCashFlowsVoid(CashFlowSet,  MainStructure, ObjectMap, TableCashFlow); 
				WriteRecordSet(RegisterCashFlows, CashFlowSet);
			EndIf;
			
		EndDo;
			
	EndDo;
		
	CommitTransaction();
	
EndProcedure // RefreshaDataAtServer()

Procedure AddNormativeRatioItemValue(Table, ObjectID, ItemValue)

	LineTable = Table.Add();
	LineTable.Period = ThisObject.Period;
	LineTable.BusinessUnit = ThisObject.BusinessUnit;
	LineTable.ObjectID = ObjectID;
	LineTable.ItemValue = ItemValue;
	
EndProcedure

Procedure AddCalculationData(Table, AccountRef, RowNumber, Resource, Indicator, Value)

	LineTable = Table.Add();
	LineTable.Period = ThisObject.Period;
	LineTable.BusinessUnit = ThisObject.BusinessUnit;
	LineTable.Account = AccountRef;
	LineTable.RowNumber = RowNumber;
	LineTable.Resource = Resource;
	LineTable.Indicator = Indicator;
	LineTable.Value = Value;
		
EndProcedure

Procedure AddConcentrationRecord(TableConcentrationSet, TableDimensionSet, TableObligatoryEntities, MainStructure, TotalAssets)

   	// import
	ServerCache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;
	ConcentrationTypes = Enums.velpo_ConcentrationTypes;
	
	
	// vars
	If  MainStructure.ObjectID = ConcentrationTypes.ObligatoryEntity
		Or MainStructure.ObjectID = ConcentrationTypes.Reinsurer Then
		
		If Not ValueIsFilled(MainStructure.Value) Then
			Return;
		EndIf;
		
		RowObligatoryEntities = TableObligatoryEntities.Find(MainStructure.Value, "ObjectID");
		If RowObligatoryEntities = Undefined Then
			Return;
		EndIf;
		
		If  MainStructure.ObjectID = ConcentrationTypes.ObligatoryEntity
			And (RowObligatoryEntities.IsNationalReinsuranceCompany = True
				Or RowObligatoryEntities.IsRussianFederation = True) Then
			Return;
		EndIf;
		
		SearchStructure = New Structure("ObjectID, Value");	
		
	Else
		
		SearchStructure = New Structure("ObjectID");	
		
	EndIf;
	
	FillPropertyValues(SearchStructure, MainStructure);
	
	RowConcentrationArray = TableConcentrationSet.FindRows(SearchStructure);
	If RowConcentrationArray.Count() = 0 Then
		RowConcentration = AddMainRecord(TableConcentrationSet, MainStructure);
		
		If  MainStructure.ObjectID = ConcentrationTypes.ObligatoryEntity
			Or MainStructure.ObjectID = ConcentrationTypes.Reinsurer Then
			
			FillPropertyValues(TableDimensionSet.Add(), MainStructure);
			
			RowConcentration.ConcentrationFactor = ServerCache.GetConcentrationFactor(ThisObject.Period, 
																																		MainStructure.ObjectID, 
																																		RowObligatoryEntities.IsMemberOECD,
																																		RowObligatoryEntities.IsReinsurerPaymentTransferred,
																																		RowObligatoryEntities.CreditQualityGroup,
																																		RowObligatoryEntities.HasLifeInsuranceLicense);
		Else
			
			// real estate
			RowConcentration.ConcentrationFactor = ServerCache.GetConcentrationFactor(ThisObject.Period, MainStructure.ObjectID);
			
		EndIf;
	Else
		
		RowConcentration = RowConcentrationArray[0];
		
	EndIf;
	
	RowConcentration.ConcentrationRiskAssetValue = RowConcentration.ConcentrationRiskAssetValue + MainStructure.ItemValue; 
	RowConcentration.ConcentrationRiskImpact =  RowConcentration.ConcentrationRiskAssetValue - (RowConcentration.ConcentrationFactor / 100) * TotalAssets;
	
	If MainStructure.ObjectID = ConcentrationTypes.ObligatoryEntity
		Or MainStructure.ObjectID = ConcentrationTypes.RealEstate Then
		
		RowConcentration.ConcentrationRiskImpact = Max(0, RowConcentration.ConcentrationRiskImpact);
		
	EndIf;

EndProcedure

Procedure SetZeroItemValue(RowData, Indicator, TableCalculationSet)
	
	// import
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
		
	AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, Indicator, 0);
	RowData.ItemValue = 0;

EndProcedure

Procedure SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;

	If AccountStructure.Flags.MarketRate Then
		RowData.ItemValue = RowData.MarketRate * ?(RowData.Quantity = 0, 1, RowData.Quantity);
		AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_3_11, RowData.ItemValue);
	Else
		SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
	EndIf;
	
EndProcedure

Procedure SetBookValueToItem(RowData, AccountStructure, TableCalculationSet)
	
	// import
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;

	ItemValue = 0;
	For Each MainElement In  MainCalculations Do
		MainName = MainElement.Key;
		Indicator = MainElement.Value;
		If MainName = "BookValue" Then
			CurrentValue =  RowData.BookValue + ?(AccountStructure.Flags["ImpairmentAllowance"], RowData.ImpairmentAllowance, 0);
		ElsIf AccountStructure.Flags[MainName] Then
			CurrentValue =  -1 * RowData[MainName];
		Else
			CurrentValue =  0;
		EndIf;
		
		If CurrentValue = 0 Then
			Continue;
		EndIf;
		
		ItemValue = ItemValue + CurrentValue;
		AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, Indicator, CurrentValue);	
	EndDo; 
	RowData.ItemValue = Max(ItemValue, 0);
	
EndProcedure

Procedure SetPresentValue(RowData, AccountStructure, TableCalculationSet, TableCashFlowSet)

	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;

	CashFlowArray = TableCashFlowSet.FindRows(New Structure("ObjectID", RowData.ObjectID));
	CurrentEnd = BegOfDay(ThisObject.Period);
	PresentValue = 0;
	MarketRate = RowData.MarketRate / 100;
	For Each LineCashFlow In CashFlowArray Do
		If LineCashFlow.ScheduleDate <  CurrentEnd Then
			Continue;
		EndIf;
		Term = (LineCashFlow.ScheduleDate - CurrentEnd) / 86400;
		PresentValue = PresentValue + LineCashFlow.CashFlow /  Pow(1 + MarketRate, Term / 365);
	EndDo; 
	RowData.ItemValue = Round(PresentValue, 2);
	AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_3_11, RowData.ItemValue);

EndProcedure

Procedure CalculateCashEquivalentsDeposits(RowData, AccountStructure, TableCounterparty, TableCalculationSet, TableCashFlowSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	PaymentTypes = Enums.velpo_PaymentTypes;
	YesNoNone = Enums.velpo_YesNoNone;
	
	// 3.1.12.1
	If Not CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_12, TableCalculationSet);	
		Return;
	EndIf;
	
	// 3.1.14
	If CheckCounterpartyBankrupt(RowData.CounterpartyID, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_14, TableCalculationSet);		
		Return;
	EndIf;
	
	// 3.1.15
	If CheckPropertyFlag(RowData, "CashDepositClause_3_1_15", AccountStructure) Then 
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_15, TableCalculationSet);		
		Return;
	EndIf;
	
	If AccountStructure.Name = "CashEquivalents" Then
		SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
	Else
		// 3.1.9
		If RowData.SubordinatedDepositLoanClause_3_1_9 = YesNoNone.No Then
			SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_9, TableCalculationSet);		
			Return;
		EndIf;
		// 3.2
		If CheckPropertyFlag(RowData, "ReturnDepositClause_3_2", AccountStructure) Then 
			ReturnRate = RowData["ReturnRate"] ;
			If ReturnRate = Null Then
				Coefficient = 0;
			Else
				Coefficient = PaymentTypes.GetDifferentiatedCoefficient(RowData["ReturnRate"] / 100, RowData["OpenDate"], RowData["CloseDate"]);	
			EndIf;
			NominalValue = RowData["NominalValue"];
			If NominalValue = Null Then
				NominalValue = 0;
			EndIf;
			InterestAccrued = Round(NominalValue * Coefficient, 2);
			RowData.ItemValue = NominalValue + InterestAccrued;
			AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.NominalValue, NominalValue);
			AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.InterestAccrued, InterestAccrued);	
		Else
			SetPresentValue(RowData, AccountStructure, TableCalculationSet, TableCashFlowSet);
		EndIf;
	EndIf;
	
EndProcedure

Procedure CalculateSharesInvestmentFundShares(RowData, AccountStructure, TableCounterparty, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	RelatedParties = Enums.velpo_RelatedParties;
	YesNoNone = Enums.velpo_YesNoNone;
	
	// 3.1.12.1
	If Not CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_12, TableCalculationSet);	
		Return;	
	EndIf;
	
	// 3.1.1
	If Not CheckPropertyFlag(RowData, "SecurityClause_3_1_1", AccountStructure) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_1, TableCalculationSet);
		Return;	
	EndIf;
	
	// 3.1.2
	If CheckPropertyFlag(RowData, "SecurityClause_3_1_2", AccountStructure) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_2, TableCalculationSet);
		Return;
	EndIf;
			
	If AccountStructure.Name = "Shares" Then
		// 3.1.3
		If RowData.PercentInAuthorizedCapital > 10 Then
			SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_3, TableCalculationSet);		
			Return;
		EndIf;
		// 3.1.4
		LineIssuer = TableCounterparty.Find(RowData.CounterpartyID, "ObjectID");
		If LineIssuer.RelatedParty = RelatedParties.OsnObshhGrSvyazLiczMember  Then
			SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_4, TableCalculationSet);
			Return;
		EndIf;
	Else
		// 3.1.6
		If RowData.MutualFundClause_3_1_6  = YesNoNone.No Then
			SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_6, TableCalculationSet);
			Return;
		EndIf;
	EndIf;			
	
	// 3.1.14
	If CheckCounterpartyBankrupt(RowData.CounterpartyID,  TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_14, TableCalculationSet);		
		Return;
	EndIf;
	
	// 3.1.24
	If RowData.FinancialInstrumentClause_3_1_24  = YesNoNone.Yes Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_24, TableCalculationSet);
		Return;
	EndIf;
	
	// market value
	SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet);
		
EndProcedure

Procedure CalculateBonds(RowData, AccountStructure, TableCounterparty, TableCalculationSet )
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	YesNoNone = Enums.velpo_YesNoNone;
	
	// 3.1.8
	If Not ApprovedConsolidatedRatings[RowData.ConsolidatedRating] 
		And  Not CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_8, TableCalculationSet);	
		Return;	
	EndIf;
	
	// 3.1.14
	If CheckCounterpartyBankrupt(RowData.CounterpartyID, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_14, TableCalculationSet);		
		Return;
	EndIf;

	// 3.1.24
	If RowData.FinancialInstrumentClause_3_1_24  = YesNoNone.Yes Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_24, TableCalculationSet);
		Return;
	EndIf;
	
	// 3.7
	If CheckPropertyFlag(RowData, "BondClause_3_7", AccountStructure) Then 
		// minimum payment
		RowData.ItemValue = ?(ValueIsFilled(RowData.MinimumPayment), RowData.MinimumPayment, 0) * RowData.Quantity;
		AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.MinimumPayment, RowData.ItemValue);	
	Else
		// market value
		SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet);
	EndIf;
	
EndProcedure

Procedure CalculateIssuedLoans(RowData, AccountStructure, TableCounterparty, TableCalculationSet, TableCashFlowSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	YesNoNone = Enums.velpo_YesNoNone;
	
	// 3.1.12.1
	If Not CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_12, TableCalculationSet);	
		Return;	
	EndIf;
	
	// 3.1.14
	If CheckCounterpartyBankrupt(RowData.CounterpartyID, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_14, TableCalculationSet);		
		Return;
	EndIf;
	
	// 3.1.9
	If RowData.SubordinatedDepositLoanClause_3_1_9 = YesNoNone.No Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_9, TableCalculationSet);		
		Return;
	EndIf;
	
	// present value
	SetPresentValue(RowData, AccountStructure, TableCalculationSet, TableCashFlowSet);
	
EndProcedure

Procedure CalculateClaimRights(RowData, AccountStructure, TableCounterparty, TableCalculationSet, TableCashFlowSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	ServerCache = velpo_ServerCache;
	
	// vars
	CheckRating = True;
	
	// 3.1.17
	If AccountStructure.Name = "TaxClaimRights" Then
		If Not CheckPropertyFlag(RowData, "MonetaryReturnClause", AccountStructure) Then
			SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_17, TableCalculationSet);
			Return;
		EndIf;
	EndIf;
	
	// 3.1.14
	If CheckCounterpartyBankrupt(RowData.CounterpartyID, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_14, TableCalculationSet);		
		Return;
	EndIf;
	
	// 3.1.16
	If AccountStructure.Name = "MedicalOrganizationClaimRights" Then
		LineCounterparty = TableCounterparty.Find(RowData.CounterpartyID, "ObjectID");
		If LineCounterparty = Undefined Or 
			Not LineCounterparty.IsMedicalOrganization = True Then
			SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_16, TableCalculationSet);		
			Return;
		ElsIf LineCounterparty.IsMedicalOrganization = True Then
			CheckRating = False;
		EndIf;
	EndIf;
	
	// 3.1.12.2
	If AccountStructure.Name = "InfrastructureOrganizationClaimRights" Then
		
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_2", AccountStructure) Then
			CheckRating = False;
		EndIf;
		
	// 3.1.12.3
	ElsIf (AccountStructure.Name = "CentralDepositoryClaimRights"
			OR AccountStructure.Name = "СentralСounterpartyClaimRights") Then
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_3", AccountStructure) Then
			CheckRating = False;
		EndIf;

	// 3.1.12.4
	ElsIf AccountStructure.Name = "StockBrokerClaimRights" Then
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_4", AccountStructure) Then
			CheckRating = False;
		EndIf;
	
	// 3.1.12.5
	ElsIf AccountStructure.Name = "SpecializedDepositoryClaimRights" Then
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_5", AccountStructure) Then
			CheckRating = False;
		EndIf;
	
	// 3.1.12.6
	ElsIf AccountStructure.Name = "SpecializedDepositoryClaimRights" Then
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_6", AccountStructure) Then
			CheckRating = False;
		EndIf;
			
	// 3.1.12.7
	ElsIf AccountStructure.Name = "AgentBrokerClaimRights" Then
		If ValueIsFilled(RowData.PremiumTransferDeadline) Then
			If RowData.PremiumTransferDeadline <= ServerCache.GetPremiumTransferDeadline(ThisObject.Period) Then
				CheckRating = False;
			EndIf;
		Else
			CheckRating = False;
		EndIf;
		
	// 3.1.12.8
	ElsIf AccountStructure.Name = "InsurerClaimRights" Then
		
		CheckRating = False;
		
	// 3.1.12.9
	ElsIf AccountStructure.Name = "LifeInsurerReturnLoanClaimRights" Then
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_9", AccountStructure) Then
			CheckRating = False;
		EndIf;

	// 3.1.12.11 (1)
	ElsIf AccountStructure.Name = "DirectDamageClaimRights" Then
		CheckRating = False;
		
	// 3.1.12.11 (1,2)
	ElsIf AccountStructure.Name = "ReinsurerClaimRights" Then
		If CheckPropertyFlag(RowData, "IsOSGOP", AccountStructure)
			Or CheckPropertyFlag(RowData, "IsOSOPO", AccountStructure) 
			Or CheckPropertyFlag(RowData, "SettlementClause_3_1_12_11_2_3", AccountStructure) Then
			CheckRating = False;
		EndIf;
		
	// 3.1.12.11 (3)
	ElsIf AccountStructure.Name = "SubrogationRegressionClaimRights" Then
		If CheckPropertyFlag(RowData, "CourtDecisionClause_3_1_12_11_3", AccountStructure) Then
			CheckRating = False;
		EndIf;
	
	// 3.1.12.12 
	ElsIf AccountStructure.Name = "OverpaidSocialInsuranceClaimRights" Then
		If CheckPropertyFlag(RowData, "MonetaryReturnClause", AccountStructure) Then
			CheckRating = False;
		EndIf;
	
	// 3.1.12.14 / 3.1.12.15
	ElsIf AccountStructure.Name = "AdvanceReinsuranceClaimRights" Then
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_14", AccountStructure) Then
			CheckRating = False;
		EndIf;
		If CheckPropertyFlag(RowData, "ClaimRightClause_3_1_12_15", AccountStructure) Then
			CheckRating = False;
		EndIf;
		
	EndIf;
	
	// 3.1.12.1
	If CheckRating And Not CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_12, TableCalculationSet);	
		Return;	
	EndIf;
	
	// 3.4
	If  AccountStructure.Name =  "AgentBrokerClaimRights"
		Or AccountStructure.Name =  "ReinsurerClaimRights"
		Or AccountStructure.Name =  "SubrogationRegressionClaimRights"
		Or AccountStructure.Name =  "OverpaidSocialInsuranceClaimRights"
		Or AccountStructure.Name =  "MedicalOrganizationClaimRights"
		Or AccountStructure.Name =  "TaxClaimRights" Then
		
		SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
	
	// 3.5 
	ElsIf AccountStructure.Name = "OwnershipTransferClaimRights" Then
		
		If  ValueIsFilled(RowData.RealEstateValue) 
			And (RowData.BookValue - RowData.ImpairmentAllowance) < RowData.RealEstateValue Then
			RowData.ItemValue = (RowData.BookValue - RowData.ImpairmentAllowance);
			AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_3_5,  RowData.ItemValue);
		Else
			SetZeroItemValue(RowData, ChartResourceIndicators.Clause_1_4_3, TableCalculationSet);
		EndIf;
		
	// 3.9
	ElsIf AccountStructure.Name = "AdvanceReinsuranceClaimRights"  Then
		
		RowData.ItemValue = Min((RowData.BookValue - RowData.ImpairmentAllowance), ?(ValueIsFilled(RowData.MainContractLiabilityClause_3_9), RowData.MainContractLiabilityClause_3_9, 0));
		AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_3_9,  RowData.ItemValue);
		
	// 3.10
	ElsIf AccountStructure.Name = "InsurerClaimRights"  Then
		
		// 3.1.12.1
		If CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
			
			SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
			
		Else
			If RowData.UnearnedPremiumReserve > 0 Or RowData.MathematicalReserve > 0 Then
				SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
			Else
				SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_10, TableCalculationSet);
			EndIf;
			
			If RowData.UnearnedPremiumReserve > 0 And RowData.ItemValue > RowData.UnearnedPremiumReserve Then
				RowData.ItemValue = RowData.UnearnedPremiumReserve;
				AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_3_10,  (RowData.ItemValue - RowData.UnearnedPremiumReserve));	
			ElsIf RowData.MathematicalReserve > 0 And RowData.ItemValue > RowData.MathematicalReserve Then
				RowData.ItemValue = RowData.MathematicalReserve;
				AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_3_10,  (RowData.ItemValue - RowData.MathematicalReserve));	
			EndIf;
		EndIf;
				
	// present value
	ElsIf  AccountStructure.Flags.CashFlow Then
		SetPresentValue(RowData, AccountStructure, TableCalculationSet, TableCashFlowSet);
		
	// fair value
	Else
		SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet);
	EndIf;
	
EndProcedure

Procedure CalculateReserveReinsuranceShares(RowData, AccountStructure, TableCounterparty, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	InsuranceReserves = Catalogs.velpo_InsuranceReserves;

	// vars
	CheckRating = True;
	
	// 3.1.14
	If CheckCounterpartyBankrupt(RowData.CounterpartyID, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_14, TableCalculationSet);		
		Return;
	EndIf;
	
	// 3.1.12.16
	If CheckPropertyFlag(RowData, "ReinsuranceShareReserveClause_3_1_12_16_1", AccountStructure) Then
		CheckRating = False;
	EndIf;
	If CheckPropertyFlag(RowData, "IsLocatedInRussia", AccountStructure) Then
		CheckRating = False;
	EndIf;
		
	// 3.1.12.1
	If CheckRating And Not CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_12, TableCalculationSet);	
		Return;	
	EndIf;
	
	// 3.8
	If RowData.InsuranceReserveID = InsuranceReserves.IndirectCostsReserve
		Or RowData.InsuranceReserveID = InsuranceReserves.DirectCostsReserve
		Or RowData.InsuranceReserveID = InsuranceReserves.UnexpiredRiskReserve Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_8, TableCalculationSet);	
	Else
         SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
	EndIf;
	
EndProcedure

Procedure CalculateGoods(RowData, AccountStructure, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	
	// 3.1.2
	If CheckPropertyFlag(RowData, "SecurityClause_3_1_2", AccountStructure) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_2, TableCalculationSet);
		Return;
	EndIf;

	// market value
	SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet);
		
EndProcedure

Procedure CalculateRealEstates(RowData, AccountStructure, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	
	// 3.6
	If Not CheckPropertyFlag(RowData, "RealEstateClause_3_6", AccountStructure) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_19, TableCalculationSet);
		Return;
	EndIf;
	
	// 3.13
	If ValueIsFilled(RowData.EstimationReportDate) 
		And Not CheckPropertyFlag(RowData, "EstimatorClause_3_13", AccountStructure) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_13, TableCalculationSet);
		Return;
	EndIf;
	
	 // market value
	SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet);
	
EndProcedure

Procedure CalculateOtherAssets(RowData, AccountStructure, TableCounterparty, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	
	// 3.1.12.1
	If Not CheckCounterpartyGuarantorСonditions(RowData, AccountStructure, TableCounterparty) Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_1_12, TableCalculationSet);	
		Return;	
	EndIf;
	
	 // market value
	SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet);
	
EndProcedure

Procedure CalculateLeaseLiabilities(RowData, AccountStructure, TableData, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	Economic = ChartsOfAccounts.velpo_Economic;
		
	// vars
	AssetBookValue = 0;
	FilterStructure = New Structure("Account,CurrencyID,ObjectID");
	FillPropertyValues(FilterStructure, RowData);
	FilterStructure.Account = Economic.LeaseAssets;

	DataArray = TableData.FindRows(FilterStructure);
	For Each LineData In DataArray Do
		AssetBookValue = AssetBookValue+ LineData.BookValue;
	EndDo; 
			
	RowData.ItemValue = RowData.BookValue - AssetBookValue;
	AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_4_2, RowData.ItemValue);
		
EndProcedure

Procedure CalculateReserves(RowData, AccountStructure, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	InsuranceReserves = Catalogs.velpo_InsuranceReserves;
	
	If RowData.InsuranceReserveID = InsuranceReserves.AdditionalPartUnearnedPremiumReserve
		Or RowData.InsuranceReserveID = InsuranceReserves.IndirectCostsReserve
		Or RowData.InsuranceReserveID = InsuranceReserves.DirectCostsReserve
		Or RowData.InsuranceReserveID = InsuranceReserves.UnexpiredRiskReserve Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_4_3, TableCalculationSet);
	Else
		 SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
	EndIf;
		
EndProcedure 

Procedure CalculateDeferredTaxLiabilities(RowData, AccountStructure, TableData, TableCalculationSet)
	
	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;	
	ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	Economic = ChartsOfAccounts.velpo_Economic;
	ServerCache = velpo_ServerCache;
	
	// vars
	DeferredTaxLiabilities =  RowData.BookValue;
	TaxRate = ServerCache.GetTaxRate() / 100;
		
	ReservesRegular = GetReserveBookValue(Economic.Reserves, RowData.CurrencyID, RowData.InsuranceReserveID, TableData)
											- GetReserveBookValue(Economic.ReserveReinsuranceShares, RowData.CurrencyID, RowData.InsuranceReserveID, TableData);
											
	ReservesStandart =  GetReserveBookValue(Economic.Reserves, RowData.CurrencyID, RowData.InsuranceReserveID, TableData, False)
												- GetReserveBookValue(Economic.ReserveReinsuranceShares, RowData.CurrencyID, RowData.InsuranceReserveID, TableData, False)
												+ GetReserveBookValue(Economic.ReservesAdjustments, RowData.CurrencyID, RowData.InsuranceReserveID, TableData, False)
												- GetReserveBookValue(Economic.ReinsuranceShareReservesAdjustments, RowData.CurrencyID, RowData.InsuranceReserveID, TableData, False)
												- GetAccountBookValue(Economic.EstimatesOfFutureCashFlows, RowData.CurrencyID, TableData);								 
	
	DeferredAcquisitionCosts = GetAccountBookValue(Economic.DeferredAcquisitionCosts, RowData.CurrencyID, TableData);
	DeferredAcquisitionIncome = GetAccountBookValue(Economic.DeferredAcquisitionIncome, RowData.CurrencyID, TableData);
	
	RowData.ItemValue = Max(DeferredTaxLiabilities - Max(TaxRate * (ReservesRegular - (ReservesStandart - DeferredAcquisitionCosts + DeferredAcquisitionIncome)), 0), 0); 
	AddCalculationData(TableCalculationSet, RowData.Account, RowData.RowNumber, ChartObjectAttributes.ItemValue, ChartResourceIndicators.Clause_4_4, RowData.ItemValue);

EndProcedure

Procedure CalculateOwnFundRowMarketRate(RowData)
	
	// import
	ServerCache = velpo_ServerCache;
	
	RowData.MarketRate = ServerCache.GetMarketRate(ThisObject.Period, RowData.Account, RowData.CurrencyID,  RowData.OpenDate, RowData.CloseDate)
		+  (ServerCache.GetKeyRate(ThisObject.Period, RowData.CurrencyID)
		- ServerCache.GetAverageKeyRate(ThisObject.Period, RowData.CurrencyID));
		
EndProcedure

Procedure CalculateOwnFundRowItemValue(RowData, AccountStructure, TableData, TableCounterparty, TableCalculationSet, TableCashFlowSet)

	// import
	ChartResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;
	
	IsZero = False;
	ZeroIndicator = ZeroAccountMap[RowData.Account];
	
	// check account is 0
	If ZeroIndicator <> Undefined Then
		IsZero = True;
	Else
		// check property is 0
		For Each Element In ZeroMap Do
			PropertyName = Element.Key;
			If CheckPropertyFlag(RowData, PropertyName, AccountStructure) Then
				ZeroIndicator = Element.Value;
				IsZero = True;
				Break;
			EndIf;
		EndDo; 
	EndIf;
	
	If IsZero Then
		SetZeroItemValue(RowData, ZeroIndicator, TableCalculationSet);
	ElsIf AccountStructure.Name = "CashEquivalents" Or AccountStructure.Name = "Deposits" Then
		CalculateCashEquivalentsDeposits(RowData, AccountStructure, TableCounterparty, TableCalculationSet, TableCashFlowSet);
	ElsIf AccountStructure.Name = "Shares" Or AccountStructure.Name = "InvestmentFundShares" Then
		CalculateSharesInvestmentFundShares(RowData, AccountStructure, TableCounterparty, TableCalculationSet);
	ElsIf AccountStructure.Name = "Bonds"Then
		CalculateBonds(RowData, AccountStructure, TableCounterparty, TableCalculationSet);
	ElsIf AccountStructure.Name = "DepositoryReceipts"Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_1_4_1, TableCalculationSet);
	ElsIf AccountStructure.Name = "DerivativeAssets"Then
		// TODO
	ElsIf AccountStructure.Name = "IssuedLoans"Then
		CalculateIssuedLoans(RowData, AccountStructure, TableCounterparty, TableCalculationSet, TableCashFlowSet);	
	ElsIf StrEndsWith(AccountStructure.Name, "ClaimRights") Then
		CalculateClaimRights(RowData, AccountStructure, TableCounterparty, TableCalculationSet, TableCashFlowSet);	
	ElsIf AccountStructure.Name = "ReserveReinsuranceShares" Then
		CalculateReserveReinsuranceShares(RowData, AccountStructure, TableCounterparty, TableCalculationSet);	
	ElsIf AccountStructure.Name = "ReinsuranceShareReservesAdjustments" Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_3_8, TableCalculationSet);
	ElsIf AccountStructure.Name = "MedicalInsuranceFunds"Then
		SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);
	ElsIf AccountStructure.Name = "Goods"Then
		CalculateGoods(RowData, AccountStructure, TableCalculationSet);
	ElsIf AccountStructure.Name = "RealEstates"Then
		CalculateRealEstates(RowData, AccountStructure, TableCalculationSet); 
	ElsIf AccountStructure.Name = "OtherAssets"Then
		CalculateOtherAssets(RowData, AccountStructure, TableCounterparty, TableCalculationSet);
	ElsIf AccountStructure.Name = "LeaseLiabilities"Then
		CalculateLeaseLiabilities(RowData, AccountStructure, TableData, TableCalculationSet);
	ElsIf AccountStructure.Name = "Reserves"Then
		CalculateReserves(RowData, AccountStructure, TableCalculationSet);
	ElsIf AccountStructure.Name = "ReservesAdjustments"Then
		SetZeroItemValue(RowData, ChartResourceIndicators.Clause_4_3, TableCalculationSet);
	ElsIf AccountStructure.Name = "DeferredTaxLiabilities"Then
		CalculateDeferredTaxLiabilities(RowData, AccountStructure, TableData, TableCalculationSet);
	ElsIf AccountStructure.Name = "GuarantyAndSureties"
		Or AccountStructure.Name = "OtherOffBalanceLiabilities"Then
		SetBookValueToItem(RowData, AccountStructure, TableCalculationSet);	
	ElsIf AccountStructure.Name = "DerivativeLiabilities"Then
		// TODO
	Else
		SetMarketRateToItem(RowData, AccountStructure, TableCalculationSet)
	EndIf;

EndProcedure
 
Procedure CalculateRowCreditQuility(RowData, TableRatingSettings)
	
	// import
	CreditQualityGroups = Enums.velpo_CreditQualityGroups;
	
	CurrentRow = Undefined;
	CurrentRowNumber = 99999;
	CurrentAgency = Undefined;
	CurrentRating = Undefined;
	For Each Element In RaitingStructure Do		
		RaitingValue = RowData[Element.Key];
		If ValueIsFilled(RaitingValue) Then
			RaitingArray = TableRatingSettings.FindRows(New Structure(Element.Key, RaitingValue));
			If RaitingArray.Count() > 0 Then
				Row = RaitingArray[0];
				NewRowNumber = Row.RowNumber;
				If NewRowNumber < CurrentRowNumber Then
					CurrentRow = Row;
					CurrentRowNumber = NewRowNumber;
					CurrentRating = RaitingValue;
					CurrentAgency = Element.Value;
				EndIf;
			EndIf;
		EndIf;
	EndDo;	
	If CurrentRow <> Undefined Then
		RowData.CreditQualityGroup = CurrentRow.CreditQualityGroup; 	
		RowData.ConsolidatedRating = CurrentRow.ConsolidatedRating;
		RowData.CreditRating = String(CurrentRating);
		RowData.RatingAgency = CurrentAgency;
	EndIf;
	If RowData.CounterpartyType = Enums.velpo_CounterpartyTypes.FlMember Then
		RowData.CreditQualityGroup = CreditQualityGroups.GruppaKredKach15Member;
	EndIf;
	If Not ValueIsFilled(RowData.CreditQualityGroup) Then
		RowData.CreditQualityGroup = CreditQualityGroups.GruppaKredKach18Member;
	EndIf;

EndProcedure

#EndRegion

#Region Public

// fill registers

Procedure FillCounterpartyData() Export

	// import
	ServerCache = velpo_ServerCache;
	
	// vars
	AccountStructure = ServerCache.GetAccountData(ChartsOfAccounts.velpo_Economic.Counterparties);
	
	FillRegisterData("velpo_CounterpartyData", AccountStructure);
	CalculateCounterpartyCreditQuility();
	CreateCounterpartyIdentificators();
	
EndProcedure

Procedure FillOwnFundData(AccountRef) Export

	// import
	ServerCache = velpo_ServerCache;
	
	// vars
	AccountList = ServerCache.GetAccountListByRef(AccountRef);

	For Each ItemList In AccountList Do
		
		If ServerCache.CheckGroupAccount(ItemList.Value) Then
			Continue;
		EndIf;
		
		AccountStructure = ServerCache.GetAccountData(ItemList.Value);
		FillRegisterData("velpo_OwnFundData", AccountStructure);
		CalculateOwnFunds(ItemList.Value);
		
	EndDo; 
	
EndProcedure
 
Procedure FillNonLifeSolvencyMarginData() Export
	
	// import
	ServerCache = velpo_ServerCache;
	
	// vars
	AccountStructure = ServerCache.GetAccountData(ChartsOfAccounts.velpo_Economic.NonLifeSolvencyMargin);
	
	FillRegisterData("velpo_NonLifeSolvencyMarginData", AccountStructure);
	
EndProcedure

// calculate conterparties

Procedure CalculateCounterpartyCreditQuility(ObjectArray = Undefined) Export

	// import
	RegisterCounterparty = InformationRegisters.velpo_CounterpartyData;
	Economic = ChartsOfAccounts.velpo_Economic;
	
	// vars
	TableRatingSettings = GetRatingSettingsData();
	
	TableData = GetConterpartyData(ObjectArray);	
	HasObjectArray = (Not ObjectArray = Undefined);

	BeginTransaction();

	CounterpartySet = InitializeRegisterSet(RegisterCounterparty, Not HasObjectArray);
		
	For Each RowData In TableData Do
		
		CalculateRowCreditQuility(RowData, TableRatingSettings);
		
		Record = CounterpartySet.Add();
		FillPropertyValues(Record, RowData); 

	EndDo;	
		
	// delete row number
	If HasObjectArray  Then
		For Each Object In ObjectArray  Do
			InitializeRecordSet(RegisterCounterparty, True, Economic.Counterparties,, Object);
		EndDo; 
	EndIf;
		
	WriteRecordSet(RegisterCounterparty, CounterpartySet);
		
	CommitTransaction();
	
EndProcedure // CreditQuilityCalculationAtServer()

Procedure CreateCounterpartyIdentificators(ObjectArray = Undefined) Export

	// import
	RegisterUnloadIdentificators = InformationRegisters.velpo_UnloadIdentificators;
	Economic = ChartsOfAccounts.velpo_Economic;

	// vars
	TableData = GetConterpartyData(ObjectArray);
	HasObjectArray = (Not ObjectArray = Undefined);
	
	BeginTransaction();

	UnloadIdentificatorsSet = InitializeRegisterSet(RegisterUnloadIdentificators, Not HasObjectArray);

	For Each RowData In TableData Do
		
		Record = UnloadIdentificatorsSet.Add();
		FillPropertyValues(Record, RowData); 

		Identificator = Undefined;
		
		If RowData.CounterpartyType = Enums.velpo_CounterpartyTypes.FlMember Then
			
			If  RowData.CountryСode = Enums.velpo_CountryСodes.Strana_643RusRossiyaMember Then
				INN = ?(ValueIsFilled(RowData.INN), RowData.INN, "000000000000");
				InsuranceNumber = ?(ValueIsFilled(RowData.InsuranceNumber),RowData.InsuranceNumber, "000-000-00000");
				If Not ValueIsFilled(RowData.INN) И Not ValueIsFilled(RowData.InsuranceNumber) Then
					DocumentNumber = ?(ValueIsFilled(RowData.DocumentNumber),"_" + RowData.DocumentNumber, "");
				Else
					DocumentNumber = "";
				EndIf;
				Identificator = "643" + "_" +  INN + "_" + InsuranceNumber + DocumentNumber;
			Else		
				Identificator = String(RowData.CountryСode)  + "_" +  RowData.TIN + "_КН" + RowData.NonResidentCode;
			EndIf;
			
		ElsIf RowData.CounterpartyType = Enums.velpo_CounterpartyTypes.YulMember Then
			
			If  RowData.CountryСode = Enums.velpo_CountryСodes.Strana_643RusRossiyaMember Then
				Identificator =  "643" + "_" +  RowData.INN + "_" + RowData.OGRN;
			Else
				Identificator = String(RowData.CountryСode)  + "_" +  RowData.TIN + "_КН" + RowData.NonResidentCode;
			EndIf;
			
		ElsIf RowData.CounterpartyType = Enums.velpo_CounterpartyTypes.Ip_Member Then
			
			Identificator =  "643" + "_" +  RowData.INN + "_" + RowData.OGRNIP;
			
		EndIf;
		
		If Identificator <> Undefined Then
			Record.Identificator  = Identificator;
		EndIf;
		
	EndDo;
	
	// delete row number
	If HasObjectArray  Then
		For Each Object In ObjectArray  Do
			InitializeRecordSet(RegisterUnloadIdentificators, True, Economic.Counterparties,, Object);
		EndDo; 
	EndIf;
	
	WriteRecordSet(RegisterUnloadIdentificators, UnloadIdentificatorsSet);
		
	CommitTransaction();

EndProcedure // CreateIdentificatorAtServer()

// calculate own funds

Procedure CalculateOwnFundCreditQuility(AccountRef, RowArray = Undefined) Export

	// import
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	ServerCache = velpo_ServerCache;
	
	// vars
	TableRatingSettings = GetRatingSettingsData();
	HasRowArray = (Not RowArray = Undefined);
	AccountList = ServerCache.GetAccountListByRef(AccountRef);
	
	For Each ItemList In AccountList Do
		
		If ServerCache.CheckGroupAccount(ItemList.Value) Then
			Continue;
		EndIf;
		
		AccountStructure = ServerCache.GetAccountData(ItemList.Value);
		Flags = AccountStructure.Flags;
		
		If Not (Flags.CreditRating
				And Flags.CreditQualityGroup
				And Flags.ConsolidatedRating
				And Flags.RatingAgency) Then
			Continue;
		EndIf;
		
		If Not CheckOwnFundData(AccountStructure.Ref) Then
			Continue;
		EndIf;
		
		TableData = GetOwnFundData(AccountRef, RowArray);
		
		BeginTransaction();

		TableOwnFundSet = InitializeRegisterSet(RegisterOwnFund, Not HasRowArray, AccountStructure);
		
		For Each RowData In TableData Do
			
			CalculateRowCreditQuility(RowData, TableRatingSettings);
			
			Record = TableOwnFundSet.Add();
			FillPropertyValues(Record, RowData); 
			
		EndDo;
		
		// delete row number
		If HasRowArray  Then
			For Each RowNumber In RowArray  Do
				InitializeRecordSet(RegisterOwnFund, True, AccountRef, RowNumber);
			EndDo; 
		EndIf;
		
		// write data
		WriteRecordSet(RegisterOwnFund, TableOwnFundSet);
		
		CommitTransaction();
		
	EndDo;

	
EndProcedure // CreditQuilityCalculationAtServer()

Procedure CreateOwnFundIdentificators(AccountRef, RowArray = Undefined) Export


EndProcedure // CreateIdentificatorAtServer()

Procedure CalculateMarketRate(AccountRef, RowArray = Undefined) Export

	// import
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	ServerCache = velpo_ServerCache;
	
	// vars
	HasRowArray = (Not RowArray = Undefined);
	AccountList = ServerCache.GetAccountListByRef(AccountRef);
	
	For Each ItemList In AccountList Do
		
		If ServerCache.CheckGroupAccount(ItemList.Value) Then
			Continue;
		EndIf;
		
		AccountStructure = ServerCache.GetAccountData(ItemList.Value);
		Flags = AccountStructure.Flags;
		
		If Not (Flags.CashFlow
				And Flags.MarketRate
				And Flags.OpenDate
				And Flags.CloseDate) Then
			Continue;
		EndIf;
		
		If Not CheckOwnFundData(AccountStructure.Ref) Then
			Continue;
		EndIf;
		
		TableData = GetOwnFundData(AccountRef, RowArray);
		
		BeginTransaction();

		TableOwnFundSet = InitializeRegisterSet(RegisterOwnFund, Not HasRowArray, AccountStructure);
		
		For Each RowData In TableData Do
			
			CalculateOwnFundRowMarketRate(RowData);
			
			Record = TableOwnFundSet.Add();
			FillPropertyValues(Record, RowData); 
			
		EndDo;
		
		// delete row number
		If HasRowArray  Then
			For Each RowNumber In RowArray  Do
				InitializeRecordSet(RegisterOwnFund, True, AccountRef, RowNumber);
			EndDo; 
		EndIf;
		
		// write data
		WriteRecordSet(RegisterOwnFund, TableOwnFundSet);
		
		CommitTransaction();
		
	EndDo;
	
EndProcedure

Procedure CalculateItemValue(AccountRef, RowArray = Undefined) Export
	
	// import
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	RegisterCalculationData = InformationRegisters.velpo_CalculationData;
	ServerCache = velpo_ServerCache;

	// vars
	TableCounterparty = GetConterpartyData();
	HasRowArray = (Not RowArray = Undefined);
		
	// vars
	AccountList = ServerCache.GetAccountListByRef(AccountRef);
	
	For Each ItemList In AccountList Do
		
		If ServerCache.CheckGroupAccount(ItemList.Value) Then
			Continue;
		EndIf;
		
		AccountStructure = ServerCache.GetAccountData(ItemList.Value);
		Flags = AccountStructure.Flags;

		If Not CheckOwnFundData(AccountStructure.Ref) Then
			Continue;
		EndIf;
		
		TableData = GetOwnFundData(AccountRef, RowArray);
		TableCashFlowSet = GetCashFlowData(AccountRef, RowArray); 
		
		BeginTransaction();
			
		TableOwnFundSet = InitializeRegisterSet(RegisterOwnFund, Not HasRowArray, AccountStructure);
		TableCalculationSet = InitializeRegisterSet(RegisterCalculationData, Not HasRowArray, AccountStructure);
		
		For Each RowData In TableData Do
			
			// item value
			CalculateOwnFundRowItemValue(RowData, AccountStructure, TableData, TableCounterparty, TableCalculationSet, TableCashFlowSet);
					
			Record = TableOwnFundSet.Add();
			FillPropertyValues(Record, RowData); 
			
		EndDo;
		
		// delete row number
		If HasRowArray  Then
			For Each RowNumber In RowArray  Do
				InitializeRecordSet(RegisterOwnFund, True, AccountStructure.Ref, RowNumber);
				InitializeRecordSet(RegisterCalculationData, True, AccountStructure.Ref, RowNumber);
			EndDo; 
		EndIf;
		
		// write data
		WriteRecordSet(RegisterOwnFund, TableOwnFundSet);
		WriteRecordSet(RegisterCalculationData, TableCalculationSet);
		
		CommitTransaction();
		
	EndDo;
	
EndProcedure

Procedure CalculateOwnFunds(AccountRef, RowArray = Undefined) Export
	
	// import
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	RegisterCalculationData = InformationRegisters.velpo_CalculationData;
	ServerCache = velpo_ServerCache;

	// vars
	TableCounterparty = GetConterpartyData();
	TableRatingSettings = GetRatingSettingsData();
	HasRowArray = (Not RowArray = Undefined);
		
	// vars
	AccountList = ServerCache.GetAccountListByRef(AccountRef);

	For Each ItemList In AccountList Do
		
		If ServerCache.CheckGroupAccount(ItemList.Value) Then
			Continue;
		EndIf;
		
		AccountStructure = ServerCache.GetAccountData(ItemList.Value);
		Flags = AccountStructure.Flags;

		If Not CheckOwnFundData(AccountStructure.Ref) Then
			Continue;
		EndIf;
		
		TableData = GetOwnFundData(AccountRef, RowArray);
		TableCashFlowSet = GetCashFlowData(AccountRef, RowArray); 
		
		BeginTransaction();

		TableOwnFundSet = InitializeRegisterSet(RegisterOwnFund, Not HasRowArray, AccountStructure);
		TableCalculationSet = InitializeRegisterSet(RegisterCalculationData, Not HasRowArray, AccountStructure);
		
		For Each RowData In TableData Do
			
			// credit rating
			If (Flags.CreditRating And Flags.CreditQualityGroup And Flags.ConsolidatedRating And Flags.RatingAgency) Then
				CalculateRowCreditQuility(RowData, TableRatingSettings);	
			EndIf;

			// market rate
			If (Flags.CashFlow And Flags.MarketRate	And Flags.OpenDate And Flags.CloseDate) Then
				CalculateOwnFundRowMarketRate(RowData);
			EndIf;
			
			// item value
			CalculateOwnFundRowItemValue(RowData, AccountStructure, TableData, TableCounterparty, TableCalculationSet, TableCashFlowSet);
					
			Record = TableOwnFundSet.Add();
			FillPropertyValues(Record, RowData); 
			
		EndDo;
		
		// delete row number
		If HasRowArray  Then
			For Each RowNumber In RowArray  Do
				InitializeRecordSet(RegisterOwnFund, True, AccountStructure.Ref, RowNumber);
				InitializeRecordSet(RegisterCalculationData, True, AccountStructure.Ref, RowNumber);
			EndDo; 
		EndIf;
		
		// write data
		WriteRecordSet(RegisterOwnFund, TableOwnFundSet);
		WriteRecordSet(RegisterCalculationData, TableCalculationSet);
		
		CommitTransaction();

	EndDo;

EndProcedure

// risk calculation

Procedure CalculateConcentration() Export
	
	// import
	RegisterConcentrationData = InformationRegisters.velpo_ConcentrationData;
	RegisterDimensionData = InformationRegisters.velpo_DimensionData;
	RegisterOwnFund = InformationRegisters.velpo_OwnFundData;
	ServerCache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;
	ConcentrationTypes = Enums.velpo_ConcentrationTypes;
	InsuranceReserves = Catalogs.velpo_InsuranceReserves;
	DimensionIDTypes = ChartsOfCharacteristicTypes.velpo_DimensionIDTypes;
	
	// vars
	AccountStructure = ServerCache.GetAccountData(Economic.Concentration);
	ObjectType =  AccountStructure.ObjectID.Ref;
	TotalAssets = 0;
	
	MainStructure = New Structure;
	MainStructure.Insert("Period", ThisObject.Period);
	MainStructure.Insert("BusinessUnit", ThisObject.BusinessUnit);
	MainStructure.Insert("Account", AccountStructure.Ref);
	MainStructure.Insert("Dimension", DimensionIDTypes.CounterpartyID);
	MainStructure.Insert("ObjectID", Undefined);
	MainStructure.Insert("Value", Undefined);
	MainStructure.Insert("ObjectType", ObjectType);
	MainStructure.Insert("RowNumber", 0);
	MainStructure.Insert("ItemValue", 0);
		
	TableObligatoryEntities = GetObligatoryEntities();
	TableData = GetOwnFundConcentration();
	
	TotalAssets = TableData.Total("ItemValue");
	
	BeginTransaction();
	
	TableConcentrationSet = InitializeRegisterSet(RegisterConcentrationData, True, AccountStructure.Ref);
	TableConcentrationSet.Columns.Add("Value", TableObligatoryEntities.Columns.ObligatoryEntity.ValueType);
	TableConcentrationSet.Indexes.Add("ObjectID, Value");
	TableDimensionSet = InitializeRegisterSet(RegisterDimensionData, True, AccountStructure.Ref);
		
	For Each RowData In TableData Do
		
		MainStructure.ItemValue = RowData.ItemValue;
		
		// OutstandingClaimsReserve
		If (RowData.Account = Economic.ReserveReinsuranceShares
			Or RowData.Account = Economic.ReinsuranceShareReservesAdjustments) 
			And RowData.InsuranceReserveID = InsuranceReserves.OutstandingClaimsReserve Then
			
			Continue;
			
		// InfrastructureOrganizationClaimRights or DirectDamageClaimRights, OSOGO, OSOPO
		ElsIf RowData.Account = Economic.InfrastructureOrganizationClaimRights 
			Or RowData.Account = Economic.DirectDamageClaimRights
			Or RowData.IsOSGOP = True 
			Or RowData.IsOSOPO = True
			Or RowData.ReinsuranceShareReserveClause_3_1_12_16_1 = True Then 
			
			Continue;
			
		// RealEstates
		ElsIf RowData.Account = Economic.RealEstates Then
			
		 	MainStructure.ObjectID = ConcentrationTypes.RealEstate;
			MainStructure.Value = Undefined;
						
			AddConcentrationRecord(TableConcentrationSet, TableDimensionSet, TableObligatoryEntities, MainStructure, TotalAssets);
	
			
		// ReinsurerClaimRights
		ElsIf RowData.Account = Economic.ReinsurerClaimRights Then
			
			MainStructure.ObjectID = ConcentrationTypes.Reinsurer;
			MainStructure.Value = RowData.CounterpartyID;
						
			AddConcentrationRecord(TableConcentrationSet, TableDimensionSet, TableObligatoryEntities, MainStructure, TotalAssets);
			
		Else
			
			MainStructure.ObjectID = ConcentrationTypes.ObligatoryEntity;
			
			// CounterpartyID
			MainStructure.Value = RowData.CounterpartyID;
			AddConcentrationRecord(TableConcentrationSet, TableDimensionSet, TableObligatoryEntities, MainStructure, TotalAssets);
			
			// GuarantorID
			MainStructure.Value = RowData.GuarantorID;
			AddConcentrationRecord(TableConcentrationSet, TableDimensionSet, TableObligatoryEntities, MainStructure, TotalAssets);
			
			If RowData.Account = Economic.StockBrokerClaimRights Then
				MainStructure.Value = RowData.CreditOrganizationID;
				AddConcentrationRecord(TableConcentrationSet, TableDimensionSet, TableObligatoryEntities, MainStructure, TotalAssets);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	WriteRecordSet(RegisterConcentrationData, TableConcentrationSet);
	WriteRecordSet(RegisterDimensionData, TableDimensionSet);
	
	CommitTransaction();

EndProcedure

// solvency calculation

Procedure CalculateSolvencyIndicators() Export

	//import
	RegisterNonLifeSolvencyMargin = InformationRegisters.velpo_NonLifeSolvencyMarginData;
	InsuranceTypeGroups = Catalogs.velpo_InsuranceTypeGroups;
	CommonFunctions = velpo_CommonFunctions;
	Economic = ChartsOfAccounts.velpo_Economic;
		
	//vars
	TextQuery = StrReplace(RegisterNonLifeSolvencyMargin.GetQueryText(), "//{WHERE}", "WHERE"); 
	StartDate = CommonFunctions.ObjectAttributeValue(ThisObject.BusinessUnit, "StartDate");
	IsLess36Month = (ValueIsFilled(StartDate) And StartDate > BegOfMonth(AddMonth(ThisObject.Period, -36)));
	
	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.Text = TextQuery;
	TableData = Query.Execute().Unload();
	For Each LineData In TableData Do
		
		// Ki
		
		If LineData.ClaimPayment_12Month = 0 Then
			LineData.CorrectionFactor = 1;
		Else
			LineData.CorrectionFactor = 
			((LineData.ClaimPayment_12Month - LineData.ReinsuranceShareClaimPayment_12Month)
			+ (LineData.OutstandingClaimsReserve - LineData.OutstandingClaimsReserve_12Month)
			- (LineData.ReinsuranceShareOutstandingClaimsReserve - LineData.ReinsuranceShareOutstandingClaimsReserve_12Month)
			+ (LineData.IncurredButNotReportedReserve - LineData.IncurredButNotReportedReserve_12Month)
			- (LineData.ReinsuranceShareIncurredButNotReportedReserve - LineData.ReinsuranceShareIncurredButNotReportedReserve_12Months))
			/ 
			((LineData.ClaimPayment_12Month)
			+ (LineData.OutstandingClaimsReserve - LineData.OutstandingClaimsReserve_12Month)
			+ (LineData.IncurredButNotReportedReserve - LineData.IncurredButNotReportedReserve_12Month));
			
		EndIf;
		
		// check
		If LineData.ObjectID = InsuranceTypeGroups.Group_1
			OR LineData.ObjectID = InsuranceTypeGroups.Group_2 Then
			LineData.CorrectionFactor = Min(Max(LineData.CorrectionFactor, 0.85), 1);
		ElsIf LineData.ObjectID = InsuranceTypeGroups.Group_3 Then
			LineData.CorrectionFactor = Min(Max(LineData.CorrectionFactor, 0.95), 1);
		ElsIf LineData.ObjectID = InsuranceTypeGroups.Group_7
			OR LineData.ObjectID = InsuranceTypeGroups.Group_7_1 Then
			LineData.CorrectionFactor = Min(Max(LineData.CorrectionFactor, 0.95), 1);
		ElsIf LineData.ObjectID = InsuranceTypeGroups.Group_7_2 Then
			LineData.CorrectionFactor = Min(Max(LineData.CorrectionFactor, 0.5), 1);
		ElsIf LineData.ObjectID = InsuranceTypeGroups.Group_5
			OR LineData.ObjectID = InsuranceTypeGroups.Group_11
			OR LineData.ObjectID = InsuranceTypeGroups.Group_13
			OR LineData.ObjectID = InsuranceTypeGroups.Group_17 Then
			LineData.CorrectionFactor = Min(Max(LineData.CorrectionFactor, 0.15), 1);
		Else
			LineData.CorrectionFactor = Min(Max(LineData.CorrectionFactor, 0.5), 1);
		EndIf;
		
		// N1
		
		LineData.FirstIndicator = 0.16 * (LineData.Premium_12Month + LineData.IncomingReinsurancePremium_12Month - LineData.ReinsurancePremium_12Month - LineData.Deduction_12Month);
		
		// N2
		
		If IsLess36Month Then
			LineData.SecondIndicator = 0;
		Else
			LineData.SecondIndicator = 0.23 * 1 / 3 * 
			((LineData.ClaimPayment_36Month + LineData.SubrogationRegression_36Months)
			+ (LineData.OutstandingClaimsReserve - LineData.OutstandingClaimsReserve_36Month)
			+ (LineData.IncurredButNotReportedReserve - LineData.IncurredButNotReportedReserve_36Month));
		EndIf;
		
	EndDo;
	
	BeginTransaction();
		
	// save
	WriteRecordSet(RegisterNonLifeSolvencyMargin, TableData, True);
		
	CommitTransaction();
	
EndProcedure

Procedure CalculateSolvencyMargin() Export

	//import
	RegisterNormativeRatio = InformationRegisters.velpo_NormativeRatioData;
	RegisterCashFlows = InformationRegisters.velpo_CashFlows;
	CatalogNormativeRatioItems = Catalogs.velpo_NormativeRatioItems;
	Economic = ChartsOfAccounts.velpo_Economic;
	ServerCache = velpo_ServerCache; 
	
	//vars
	AccountStructure = Economic.GetAccountData(Economic.NormativeRatio);
	AccountRef = AccountStructure.Ref;
	ObjectType  = AccountStructure.ObjectID.Ref;
	
	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.SetParameter("Account",AccountRef);
	Query.SetParameter("ObjectType", ObjectType);
	Query.Text = GetQueryTextMargin(); 
	
	QueryArray = Query.ExecuteBatch();
	
	TableData = QueryArray[0].Unload();
	TableData.Indexes.Add("ObjectID");
	
	// calculate CorrectionFactor
	LifeReserve = GetValueByNormativeRatioItem(TableData, CatalogNormativeRatioItems.LifeReserves);
	ReinsuranceShareLifeReserve = GetValueByNormativeRatioItem(TableData, CatalogNormativeRatioItems.ReinsuranceShareLifeReserves);
	If LifeReserve = 0 Then
		CorrectionFactor = 0;
	Else
		CorrectionFactor = Round((LifeReserve - ReinsuranceShareLifeReserve) / LifeReserve, 6);
	EndIf;
	AddNormativeRatioItemValue(TableData, CatalogNormativeRatioItems.CorrectionFactor, CorrectionFactor);
	
	// calculate LifeSolvencyMargin
	LifeSolvencyMargin = 0.5 * LifeReserve * CorrectionFactor;
	AddNormativeRatioItemValue(TableData, CatalogNormativeRatioItems.LifeSolvencyMargin, LifeSolvencyMargin);
	
	// calculate NonLifeSolvencyMargin
	N1 = GetValueByNormativeRatioItem(TableData, CatalogNormativeRatioItems.FirstIndicator);
	N2 = GetValueByNormativeRatioItem(TableData, CatalogNormativeRatioItems.SecondIndicator);
	ExceedOperatorLiability = GetValueByNormativeRatioItem(TableData, CatalogNormativeRatioItems.ExceedOperatorLiability);
	NonLifeSolvencyMargin = Max(N1, N2) + ExceedOperatorLiability;
	AddNormativeRatioItemValue(TableData, CatalogNormativeRatioItems.NonLifeSolvencyMargin, NonLifeSolvencyMargin);
	
	// calculate SolvencyMargin
	SolvencyMargin = LifeSolvencyMargin + NonLifeSolvencyMargin; 
	AddNormativeRatioItemValue(TableData, CatalogNormativeRatioItems.SolvencyMargin, SolvencyMargin);
	
	// calculate NormaiveRatio
	OwnFunds = GetValueByNormativeRatioItem(TableData, CatalogNormativeRatioItems.OwnFunds);
	MinimumAuthorizedCapital = GetValueByNormativeRatioItem(TableData, CatalogNormativeRatioItems.MinimumAuthorizedCapital);
	
	// TODO
	EsidualValue = 0;
		
	// risks 1
	CoefRisk1Array = ServerCache.GetRisk1CorrectionArray();
	
	RiskList = New ValueList;
	RiskList.Add(CalculateConcentrationRisk(), "ConcentrationRisk" );
	RiskList.Add(1, "CreditSpreadRisk");
	RiskList.Add(1, "InterestRateRisk");
	RiskList.Add(1, "ValueShareRisk");
	RiskList.Add(1, "ExchangeRateRisk");
	RiskList.Add(1, "RealEstatePriceRisk");
	RiskList.Add(1, "OtherAssetPriceRisk");
	
	Risk1Expression = CalculateRiskExpression(TableData, RiskList, CoefRisk1Array);
	
	// risk impact
	CoefRisk12Array = ServerCache.GetСorrelationRisk12CorrectionArray();
	
	RiskList = New ValueList;
	RiskList.Add(Sqrt(Risk1Expression), "Risk1");
	RiskList.Add(1, "Risk2");
		
	RiskImpactExpression = CalculateRiskExpression(TableData, RiskList, CoefRisk12Array);
	
	RiskImpactEstimate = Sqrt(RiskImpactExpression);
	AddNormativeRatioItemValue(TableData, CatalogNormativeRatioItems.RiskImpactEstimate, RiskImpactEstimate);
	
	Divider = Max(MinimumAuthorizedCapital, SolvencyMargin + RiskImpactEstimate);
	If Divider = 0 Then
		NormaiveRatio = 0;
	Else
		NormaiveRatio = (OwnFunds + EsidualValue) / Divider;
	EndIf;
	
	AddNormativeRatioItemValue(TableData, CatalogNormativeRatioItems.NormaiveRatio, NormaiveRatio);
	
	// fill common data
	TableData.FillValues(AccountRef, "Account");
	TableData.FillValues(ObjectType, "ObjectType");
	
	BeginTransaction();
			
	// save
	WriteRecordSet(RegisterNormativeRatio, TableData, True);
	
	CommitTransaction();
	
EndProcedure

#EndRegion

// import
ConsolidatedRatings = Enums.velpo_ConsolidatedRatings;
ChartObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
RatingAgencies = Enums.velpo_RatingAgencies;
Economic = ChartsOfAccounts.velpo_Economic;

// vars
ApprovedConsolidatedRatings = ConsolidatedRatings.GetApprovedConsolidatedRatings();
MainCalculations = ChartObjectAttributes.GetMainCalculationAttributeMap();
ZeroMap = ChartObjectAttributes.GetZeroAttributeMap();
ZeroAccountMap = Economic.GetZeroAccountMap();
RaitingStructure = RatingAgencies.GetStructure();

#EndIf
