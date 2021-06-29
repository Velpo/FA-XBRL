///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Var ResultsCache Export;
	
#Region GeneretingData

Function GetQueryTextSources()

	Return
	"SELECT
	|	SourceQueryComponents.Ref AS Source,
	|	SourceQueryComponents.SourceText AS SourceText
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType = VALUE(Enum.ComponetQueryTypes.Source)
	|	AND SourceQueryComponents.Ref IN (SELECT Ref FROM ChartOfCharacteristicTypes.SourceQueryComponents.EntryPoints WHERE  EntryPoint = &EntryPoint)
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.IsScript = FALSE
	|	AND 
	|		CASE 
	|			WHEN &IsSourcesFilter 
	|				THEN SourceQueryComponents.Ref IN HIERARCHY (&SourcesValues)
	|			ELSE TRUE
	|		END
	|ORDER BY
	|	SourceQueryComponents.IndexNum ASC
	|";

EndFunction // GetQueryTextSources() 

Function GetQueryTextSourcesFields()

	Return
	"SELECT
	|	// 0 - fields
	|	CASE
	|		WHEN SourceQueryComponents.UseDefaults THEN SourceQueryComponents.Defaults
	|		ELSE SourceQueryComponents.Ref 
	|	END AS Field,
	|	SourceQueryComponents.Code AS FieldCode,
	|	CASE
	|		WHEN SourceQueryComponents.ComponentType = VALUE(Enum.velpo_ComponetQueryTypes.Field) THEN 0
	|		WHEN SourceQueryComponents.ComponentType = VALUE(Enum.velpo_ComponetQueryTypes.Function) THEN 1
	|		WHEN SourceQueryComponents.ComponentType = VALUE(Enum.velpo_ComponetQueryTypes.Constant) THEN 2
	|	END AS ComponentType,
	|	SourceQueryComponents.ValueType AS FieldType,
	|	CASE
	|		WHEN SourceQueryComponents.UseDefaults THEN SourceQueryComponents.Defaults.SourceText 
	|		ELSE SourceQueryComponents.SourceText 
	|	END AS SourceText,
	|	CASE
	|		WHEN SourceQueryComponents.UseDefaults THEN SourceQueryComponents.Defaults.ConstantValue 
	|		ELSE SourceQueryComponents.ConstantValue 
	|	END AS ConstantValue,
	|	SourceQueryComponents.IndexNum AS IndexNum
	|INTO
	|	TableFields
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType IN (VALUE(Enum.velpo_ComponetQueryTypes.Field), VALUE(Enum.velpo_ComponetQueryTypes.Function), VALUE(Enum.velpo_ComponetQueryTypes.Constant))
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.Parent = &Result
	|INDEX BY
	|	Field
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 1 - links
	|	FieldQueryLinks.Owner AS Field,
	|	FieldQueryLinks.Ref AS Link,
	|	CASE
	|		WHEN FieldQueryLinks.LinkType = VALUE(Enum.velpo_FieldQueryLinkTypes.Axis) THEN 0
	|		ELSE 1
	|	END AS LinkType,
	|	FieldQueryLinks.Axis AS AxisType,
	|	FieldQueryLinks.Concept AS Concept,
	|	FieldQueryLinks.Concept.DataType.ValueType AS DataType,
	//|	CASE
	//|		WHEN FieldQueryLinks.Concept.DataType = VALUE(Enum.ConceptTypes.Block) THEN TRUE
	//|		ELSE False
	//|	END 
	|	FALSE AS IsBlock,
	|	FieldQueryLinks.UseSourceValue AS UseSourceValue,
	|	FieldQueryLinks.UseFieldLink AS UseFieldLink,
	|	FieldQueryLinks.FieldLink AS FieldLink,
	|	FieldQueryLinks.UseTotals AS UseTotals,
	|	FieldQueryLinks.Unique AS Unique,
	|	FieldQueryLinks.AxisSetNumber AS AxisSetNumber,
	|	FieldQueryLinks.NegativeSign AS NegativeSign
	|INTO
	|	TableLinks
	|FROM
	|	Catalog.velpo_FieldQueryLinks AS FieldQueryLinks
	|
	|	INNER JOIN TableFields AS  TableFields
	|	ON FieldQueryLinks.Owner = TableFields.Field
	|INDEX BY
	|	Link
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 2 - axis links
	|	QueryFieldLinksAxisLinks.Ref AS Link,
	|	QueryFieldLinksAxisLinks.Otherwise AS Otherwise,
	|	QueryFieldLinksAxisLinks.FieldValue AS FieldValue,
	|	QueryFieldLinksAxisLinks.Axis AS Value
	|FROM
	|	Catalog.velpo_FieldQueryLinks.AxisLinks AS QueryFieldLinksAxisLinks
	|
	|	INNER JOIN TableLinks AS TableLinks
	|	ON QueryFieldLinksAxisLinks.Ref = TableLinks.Link
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 3 - Concept links
	|	QueryFieldLinksConceptLinks.Ref AS Link,
	|	QueryFieldLinksConceptLinks.Otherwise AS Otherwise,
	|	QueryFieldLinksConceptLinks.FieldValue AS FieldValue,
	|	QueryFieldLinksConceptLinks.Value AS Value
	|FROM
	|	Catalog.velpo_FieldQueryLinks.ConceptLinks AS QueryFieldLinksConceptLinks
	|
	|	INNER JOIN TableLinks AS TableLinks
	|	ON QueryFieldLinksConceptLinks.Ref = TableLinks.Link
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 4 - field filters
	|	QueryFieldLinksFieldFilters.Ref AS Link,
	|	CASE 
	|		WHEN QueryFieldLinksFieldFilters.FilterType = VALUE(Enum.velpo_FilterQueryTypes.And) THEN 0 
	|		ELSE 1 
	|	END AS FilterType,
	|	CASE
	|		WHEN QueryFieldLinksFieldFilters.Field.UseDefaults THEN QueryFieldLinksFieldFilters.Field.Defaults
	|		ELSE QueryFieldLinksFieldFilters.Field 
	|	END AS Field,
	|	CASE
	|		WHEN QueryFieldLinksFieldFilters.Field.UseDefaults THEN QueryFieldLinksFieldFilters.Field.Defaults.Code
	|		ELSE QueryFieldLinksFieldFilters.Field.Code
	|	END AS FieldCode,
	|	CASE
	|		WHEN QueryFieldLinksFieldFilters.Field.UseDefaults THEN QueryFieldLinksFieldFilters.Field.Defaults.ValueType
	|		ELSE QueryFieldLinksFieldFilters.Field.ValueType
	|	END AS FieldValueType,
	|	CASE
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.Equal) THEN 0
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.Greater) THEN 1
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.GreaterOrEqual) THEN 2
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.Less) THEN 3
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.LessOrEqual) THEN 4
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.NotEqual) THEN 5
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.NotContains) THEN 6
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.Contains) THEN 7
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.StartsWith) THEN 8
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.EndsWith) THEN 9
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.InHierarchy) THEN 10
	|		WHEN QueryFieldLinksFieldFilters.ComparisonType = VALUE(Enum.velpo_ComparisonQueryTypes.NotInHierarchy) THEN 11
	|		ELSE 0
	|	END AS ComparisonType,
	|	QueryFieldLinksFieldFilters.Value AS Value
	|FROM
	|	Catalog.velpo_FieldQueryLinks.FieldFilters AS QueryFieldLinksFieldFilters
	|
	|	INNER JOIN TableLinks AS TableLinks
	|	ON QueryFieldLinksFieldFilters.Ref = TableLinks.Link
	|ORDER BY
	|	QueryFieldLinksFieldFilters.Ref,
	|	QueryFieldLinksFieldFilters.LineNumber ASC
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 5 - Unique fields
	|	QueryFieldLinksUniqueFields.Ref AS Link,
	|	QueryFieldLinksUniqueFields.Field AS Field,
	|	QueryFieldLinksUniqueFields.Field.Code AS FieldCode,
	|	QueryFieldLinksUniqueFields.Field.ValueType AS FieldType
	|FROM
	|	Catalog.velpo_FieldQueryLinks.UniqueFields AS QueryFieldLinksUniqueFields
	|
	|	INNER JOIN TableLinks AS TableLinks
	|	ON QueryFieldLinksUniqueFields.Ref = TableLinks.Link
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 6 - fields
	|	Field,
	|	FieldCode,
	|	FieldType,
	|	ComponentType,
	|	SourceText,
	|	ConstantValue
	|FROM
	|	TableFields
	|ORDER BY
	|	ComponentType,
	|	IndexNum ASC
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 7 - links
	|	Field,
	|	Link,
	|	LinkType,
	|	AxisType,
	|	Concept,
	|	IsBlock,
	|	DataType,
	|	UseSourceValue,
	|	UseFieldLink,
	|	FieldLink,
	|	UseTotals,
	|	Unique,
	|	AxisSetNumber,
	|	NegativeSign
	|FROM
	|	TableLinks
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	// 8 - function parameters
	|	FunctionFields.Ref As Field,
	|	FunctionFields.Field AS FunctionField,
	|	FunctionFields.Field.Code AS FunctionFieldCode
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents.FunctionFields AS FunctionFields
	|
	|	INNER JOIN TableFields AS  TableFields
	|	ON FunctionFields.Ref = TableFields.Field
	|;
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT DISTINCT
	|	// 9 - result is in another source
	|	SourceResults.Result
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents.SourceResults AS SourceResults
	|WHERE
	|	SourceResults.Result = &Result
	|	AND SourceResults.Ref.DeletionMark = FALSE
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP
	|	// 10
	|	TableFields	
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|DROP
	|	// 11
	|	TableLinks	
	|";

EndFunction // GetQueryTextSources() 

Function GetQueryTextSourcesParameters()

	Return
	"SELECT
	|	QueryComponentsParameters.Ref AS Source,
	|	QueryComponentsParameters.Parameter AS Parameter,
	|	QueryComponentsParameters.Parameter.Code AS Code,
	|	QueryComponentsParameters.Parameter.UseList AS UseList
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents.SourceParameters AS QueryComponentsParameters
	|WHERE
	|	QueryComponentsParameters.Ref = &Source
	|	AND NOT QueryComponentsParameters.Parameter.Predefined
	|";

EndFunction // GetQueryTextSourcesParameters() 

Function GetQueryTextSourcesParametersByRefs()

	Return
	"SELECT
	|	QueryComponentsParameters.Ref AS Parameter,
	|	QueryComponentsParameters.Code AS Code,
	|	QueryComponentsParameters.UseList AS UseList
	|FROM
	|	ChartOfCharacteristicTypes.velpo_UserDefinedParameters AS QueryComponentsParameters
	|WHERE
	|	QueryComponentsParameters.Ref In (&ParameterRefs)
	|	AND NOT QueryComponentsParameters.Predefined
	|";

EndFunction // GetQueryTextSourcesParametersByRefs() 

Function GetQueryTextSourcesResults()

	Return
	"SELECT
	|	QueryComponentsResults.Ref AS Source,
	|	QueryComponentsResults.Result AS Result,
	|	QueryComponentsResults.Name AS Name
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents.SourceResults AS QueryComponentsResults
	|WHERE
	|	QueryComponentsResults.Ref = &Source
	|";

EndFunction // GetQueryTextSourcesResults() 

Function GetQueryTextSourcesResultsByRefs()

	Return
	"SELECT
	|	ResultRefs.Result AS Result,
	|	ResultRefs.Name AS Name
	|INTO
	|	TMP_ResultRefs_3db1ca3d_c4ec_4eca_9618_87afdc69801b
	|FROM
	|	&ResultRefs AS ResultRefs
	|;
	|SELECT
	|	Result,
	|	Name
	|FROM
	|	TMP_ResultRefs_3db1ca3d_c4ec_4eca_9618_87afdc69801b
	|;
	|DROP
	|	TMP_ResultRefs_3db1ca3d_c4ec_4eca_9618_87afdc69801b
	|";

EndFunction // GetQueryTextSourcesResultsByRefs() 

Function GetQueryTextSourcesParametersValues()

	Return
	"SELECT
	|	QueryParametersValues.Ref AS Parameter,
	|	QueryParametersValues.Value AS Value
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryParameters.Values AS QueryParametersValues
	|WHERE
	|	QueryParametersValues.Ref = &Parameter
	|";

EndFunction // GetQueryTextSourcesParametersValues() 

Function GetQueryFunctionValue(RowFunction, ValuesCollection)
	
	// set parameters
	TextSource = RowFunction.FieldCode + " = Undefined;";
	FunctionParametersArray = RowFunction.FunctionFields;
	Index = 0;
	For Each RowParameter In FunctionParametersArray Do
		TextSource = TextSource + ?(TextSource = "", "", Chars.LF) + RowParameter.FunctionFieldCode + " = ValuesCollection[FunctionParametersArray[" + Format(Index, "NZ=0; NG=")  +"].FunctionField];"; 
		Index = Index + 1; 
	EndDo; 
	// execute function
	TextSource = TextSource + RowFunction.SourceText + Chars.LF + "ValuesCollection.Insert(RowFunction.Field, " + RowFunction.FieldCode + ");";
	Try
		Execute(TextSource);
	Except
		Raise velpo_StringFunctionsClientServer.SubstituteParametersInString(NStr("ru = 'В функции [%1] возникли ошибки: %2'; en = 'Errors occured in function %1: %2'"), RowFunction.FieldCode, DetailErrorDescription(ErrorInfo()));
	EndTry;
	
	Return Undefined;
	
EndFunction

Function GetFieldValues(Result, SelectionResult, TableFields, SetCache = False) Export
	
	ValuesCollection = New Map;
	UserFunctionArray = New Array;
	
	// selection fields
	For Each RowField In TableFields Do
		If RowField.ComponentType = 0 Then //Field
			ValuesCollection.Insert(RowField.Field, SelectionResult[RowField.FieldCode]);
		ElsIf RowField.ComponentType = 2 Then //Constant
			ValuesCollection.Insert(RowField.Field, RowField.ConstantValue);
		Else
			UserFunctionArray.Add(RowField);
		EndIf;
	EndDo;
	
	// execute function
	For Each RowFunction In UserFunctionArray  Do
		FunctionValue = GetQueryFunctionValue(RowFunction, ValuesCollection);
		// was returned in code
		If FunctionValue <> Undefined Then
			ValuesCollection.Insert(RowFunction.Field, FunctionValue);
		EndIf;
	EndDo; 
	
	// cache result
	If SetCache Then
		TableCache = ResultsCache[Result];
		If TableCache <> Undefined Then
			LineTableCache = TableCache.Add();
			For Each LineFields In  TableFields Do
				LineTableCache[LineFields.FieldCode] = ValuesCollection[LineFields.Field];
			EndDo;
		EndIf;
	EndIf;
	
	Return ValuesCollection;
	
EndFunction // GetFieldValues()

Function CheckFieldFilters(FiltersArray, FieldValues)

	ResultTest = Undefined;
	IsGroup = False;
	CurIndex = 0;
	UBound = FiltersArray.UBound();
	For Each RowFieldFilter In FiltersArray Do
	 	FieldValue = FieldValues[RowFieldFilter.Field];
		ComparisonValue = RowFieldFilter.ComparisonType;
		FilterValue = RowFieldFilter.FilterType;
		If ComparisonValue = 0 Then // Equal
			Test = (FieldValue = RowFieldFilter.Value);
		ElsIf ComparisonValue = 1 Then // Greater
			Test = (FieldValue > RowFieldFilter.Value);
		ElsIf ComparisonValue = 2 Then // GreaterOrEqual
			Test = (FieldValue >= RowFieldFilter.Value);
		ElsIf ComparisonValue = 3 Then // Less
			Test = (FieldValue < RowFieldFilter.Value);
		ElsIf ComparisonValue =  4 Then // LessOrEqual
			Test = (FieldValue <= RowFieldFilter.Value);
		ElsIf ComparisonValue = 5 Then // NotEqual
			Test = (FieldValue <> RowFieldFilter.Value);
		ElsIf ComparisonValue = 6 Then // NotContains
			Test = (StrFind(FieldValue, RowFieldFilter.Value) = 0);
		ElsIf ComparisonValue = 7 Then // Contains
			Test = (StrFind(FieldValue, RowFieldFilter.Value) > 0);
		ElsIf ComparisonValue = 8 Then // StartsWith
			Test = (СтрНачинаетсяС(FieldValue, RowFieldFilter.Value));
		ElsIf ComparisonValue = 9 Then //EndsWith
			Test = (StrEndsWith(FieldValue, RowFieldFilter.Value));
		ElsIf ComparisonValue = 10 Then //InHierarchy
			Test = (velpo_BusinessReportingCashed.CheckInHierarchy(FieldValue, RowFieldFilter.Value));
		ElsIf ComparisonValue = 11 Then //NotInHierarchy
			Test = NOT (velpo_BusinessReportingCashed.CheckInHierarchy(FieldValue, RowFieldFilter.Value));
		EndIf;
						
		If ResultTest = Undefined Then
			If  FilterValue = 0 Then // And
				ResultTest = "True";
			Else
				ResultTest = "False";    // Or
			EndIf;
		EndIf;
		
		NextFiedIsEqual = False;
		
		If  FilterValue = 0 Then // And
			ResultTest = ResultTest + " And	 ";
		Else
			ResultTest = ResultTest + " Or ";
		EndIf;
		
		// test next element
		If CurIndex < UBound Then
			NextFiedIsEqual = (FieldValue = FieldValues[FiltersArray[CurIndex + 1].Field]); 
		EndIf;
		
		BracketB = "";
		BracketA = "";
		
		If NextFiedIsEqual And Not IsGroup Then
			IsGroup = True;
			BracketB = "(";
		ElsIf Not NextFiedIsEqual And IsGroup Then
			IsGroup = False;
			BracketA = ")";
		EndIf;
		
		ResultTest = ResultTest + BracketB + ?(Test, "True", "False") + BracketA;
		
		CurIndex = CurIndex + 1;
		
	EndDo; 
	
	If ResultTest = Undefined Then
		Return True;
	Else
		Return Eval(ResultTest);	
	EndIf;
	
EndFunction // CheckFieldFilters()

Function GetLinkMap(LinkArray, FieldValue)
	
	OtherWiseValue = Undefined;
	ReturnValue = Undefined;
	For Each RowLink In LinkArray Do
		If 	RowLink.FieldValue = FieldValue Then
			ReturnValue = RowLink.Value;
			Break;
		EndIf;
		If RowLink.Otherwise Then
			OtherWiseValue = RowLink.Value;
		EndIf;
	EndDo; 
	
	If  ReturnValue = Undefined Then
		ReturnValue = OtherWiseValue;
	EndIf;
	
	Return ReturnValue;

EndFunction // GetLinkMap()

Function GetTableData(LinkResults, Index, FieldName)
	
	Table = LinkResults[Index].Unload();
	Table.Indexes.Add(FieldName);
	
	Return Table;
	
EndFunction

Function GetFieldsCache(Result, ForCache = False) Export 
	
	Query = New Query;
	Query.SetParameter("Result", Result);
	Query.Text = GetQueryTextSourcesFields();
	LinkResults = Query.ExecuteBatch();

	// tables
	TableAxisLinks = GetTableData(LinkResults, 2, "Link");
	TableConceptLinks = GetTableData(LinkResults, 3, "Link");
	TableFieldFilters = GetTableData(LinkResults, 4, "Link");
	TableUniqueFields = GetTableData(LinkResults, 5, "Link");
	TableFunctionFields = GetTableData(LinkResults, 8, "Field");
	TableResultsCache = GetTableData(LinkResults, 9, "Result");
	
	TableFields = GetTableData(LinkResults, 6, "Field");
	TableFields.Columns.Add("FunctionFields");
	TableFields.Columns.Add("Links");
	TableFields.Columns.Add("SimpleFilters");
	TableFields.Columns.Add("SimpleFiltersCount", velpo_CommonFunctions.NumberTypeDescription(30));
	TableFields.Columns.Add("LinksCount", velpo_CommonFunctions.NumberTypeDescription(30));
	
	TableLinks = GetTableData(LinkResults, 7, "Field");
	TableLinks.Columns.Add("FieldFilters");
	TableLinks.Columns.Add("UniqueFields");
	TableLinks.Columns.Add("UniqueIndex", velpo_CommonFunctions.StringTypeDescription(0));
	TableLinks.Columns.Add("AxisLinks");
	TableLinks.Columns.Add("ConceptLinks");
	TableLinks.Columns.Add("FieldFiltersCount", velpo_CommonFunctions.NumberTypeDescription(30));
	
	If (TableResultsCache.Count() > 0 Or ForCache) And ResultsCache[Result] = Undefined Then
		TableCache = New ValueTable;
	Else
		TableCache = Undefined;
	EndIf;
	
	// selection fields
	For Each RowField In TableFields Do
		
		FieldSearchStructure = New Structure("Field", RowField.Field);
		RowField.FunctionFields = TableFunctionFields.FindRows(FieldSearchStructure);
		
		If TableCache <> Undefined Then
			TableCache.Columns.Add(RowField.FieldCode, RowField.FieldType);
		EndIf;
				
		// check links
		FullLinksArray = TableLinks.FindRows(FieldSearchStructure);
		SimpleFilters = New Map;
		LinkArray = New Array;
		
		For Each RowLink In FullLinksArray  Do
			LinkSearchStructure = New Structure("Link", RowLink.Link);
			// unique
			RowsUniqueFieldsArray = TableUniqueFields.FindRows(LinkSearchStructure);
			UniqueFieldsTable = New ValueTable;
			UniqueIndex = "";
			For Each RowUniqueField In RowsUniqueFieldsArray  Do
				UniqueFieldsTable.Columns.Add(RowUniqueField.FieldCode, RowUniqueField.FieldType);
				UniqueIndex = UniqueIndex + ?(UniqueIndex = "", "", ",") + RowUniqueField.FieldCode;
			EndDo; 
			UniqueFieldsTable.Indexes.Add(UniqueIndex);
			RowLink.UniqueFields = UniqueFieldsTable;
			RowLink.UniqueIndex = UniqueIndex;
			// filters field
			RowsFieldFiltersArray = TableFieldFilters.FindRows(LinkSearchStructure);
			RowLink.FieldFilters = RowsFieldFiltersArray;
			RowLink.FieldFiltersCount = RowsFieldFiltersArray.Count();
			// set simple filter
			IsSimpleFilter = False;
			If RowLink.FieldFiltersCount > 0 Then
				FilterArray = New Array;
				IsSimpleFilter = True;
				For Each RowFieldFilter In RowsFieldFiltersArray Do
					If RowFieldFilter.ComparisonType <> 0 Or RowFieldFilter.FilterType <> 0 Then // Equal and And
						IsSimpleFilter = False;
						Break;
					EndIf;
					If FilterArray.Find(RowFieldFilter.Field) = Undefined Then
						FilterArray.Add(RowFieldFilter.Field);
					Else
						IsSimpleFilter = False;
						Break;
					EndIf;
				EndDo;
				If IsSimpleFilter Then
					IsNewFilter = True;
					For Each SimpleFiltersMap In SimpleFilters Do
						If velpo_CommonFunctionsClientServer.ValueListsEqual(SimpleFiltersMap.Key, FilterArray) Then
							IsNewFilter = False;
							Break;
						EndIf;
					EndDo;
					If IsNewFilter Then
						FilterTable = New ValueTable;
						FilterTable.Columns.Add("RowLink");
						FilterFields = New Map;
						FilterIndex = "";
					Else
						FilterTable = SimpleFiltersMap.Value.Table;
					EndIf;
					RowFilterTable = FilterTable.Add();
					RowFilterTable.RowLink = RowLink;
					For Each RowFieldFilter In RowsFieldFiltersArray Do
						If IsNewFilter Then
							FilterTable.Columns.Add(RowFieldFilter.FieldCode, RowFieldFilter.FieldValueType);
							FilterFields.Insert(RowFieldFilter.Field, RowFieldFilter.FieldCode);
							FilterIndex = FilterIndex + ?(FilterIndex = "", "", ",") + RowFieldFilter.FieldCode;
						EndIf;
						RowFilterTable[RowFieldFilter.FieldCode] = RowFieldFilter.Value;
					EndDo;
					If IsNewFilter Then
						FilterTable.Indexes.Add(FilterIndex);
						SimpleFilterStructure = New Structure;
						SimpleFilterStructure.Insert("FieldsCodes", FilterFields);
						SimpleFilterStructure.Insert("Table", FilterTable);
						SimpleFilters.Insert(FilterArray, SimpleFilterStructure);
					EndIf;
				EndIf;		
			EndIf;
			If Not IsSimpleFilter Then
				LinkArray.Add(RowLink); 
			EndIf;
			RowLink.AxisLinks = TableAxisLinks.FindRows(LinkSearchStructure);
			RowLink.ConceptLinks = TableConceptLinks.FindRows(LinkSearchStructure);
		EndDo;
		
		RowField.Links = LinkArray;
		RowField.LinksCount = LinkArray.Count();
		RowField.SimpleFilters = SimpleFilters;
		RowField.SimpleFiltersCount = SimpleFilters.Count();
		
	EndDo;
	
	If TableCache <> Undefined Then
		ResultsCache.Insert(Result, TableCache); 	
	EndIf;
	
	Return TableFields; 
	
EndFunction

Function CheckUniqueFieldsData(Link, SelectionResult)
	
	// not check unique
	If Not Link.Unique Then
		Return True;
	EndIf;
	// set seek structure
	UniqueStructure = New Structure(Link.UniqueIndex);
	FillPropertyValues(	UniqueStructure, SelectionResult);
	RowsUniqueArray = Link.UniqueFields.FindRows(UniqueStructure);
	If RowsUniqueArray.Count() = 0 Then
		StrUniqueFields = Link.UniqueFields.Add();
		FillPropertyValues(StrUniqueFields, UniqueStructure);
		Return True;
	Else
		Return False;
	EndIf;
	
EndFunction // CheckUniqueFieldsData()
  
Procedure AddConceptDataCollection(RowLink, FieldMap, AxleCollection, ConceptsCollection, SetNumberCollection)
	
	// set number
	SetNumberStructure = SetNumberCollection[RowLink.AxisSetNumber];
	If SetNumberStructure = Undefined Then
		SetNumberStructure = New Structure("Axises, Concepts", New Map, New Map);
		SetNumberCollection.Insert(RowLink.AxisSetNumber, SetNumberStructure);
	EndIf;

	// set value
	If RowLink.LinkType = 0 Then //AxisType
		AxisLinksArray = RowLink.AxisLinks;
		AxisValue = ?(RowLink.UseSourceValue, Catalogs.AxisMembers.GetAxis(RowLink.AxisType, FieldMap.Value), GetLinkMap(AxisLinksArray, FieldMap.Value));
		If AxisValue <>  Undefined  Then
			AxleValueMap = AxleCollection[RowLink.AxisType];
			If AxleValueMap = Undefined Then
				AxleValueMap = New Map;
				AxleCollection.Insert(RowLink.AxisType, AxleValueMap);
			EndIf;
			AxleValueMap.Insert(RowLink, AxisValue);
		EndIf;
		SetNumberStructure.Axises.Insert(RowLink.AxisType, RowLink);
	Else   // Concept
		ConceptLinksArray = RowLink.ConceptLinks;
		ConceptValue = ?(RowLink.UseSourceValue, FieldMap.Value, GetLinkMap(ConceptLinksArray, FieldMap.Value));
		If ConceptValue <>  Undefined And ConceptValue <> Null  Then
			If RowLink.IsBlock Then
				ConceptValue = String(ConceptValue);
			Else
				ConceptValue = RowLink.DataType.AdjustValue(ConceptValue);
				If RowLink.NegativeSign Then
					ConceptValue = -1 * ConceptValue;
				EndIf;
			EndIf;
			ConceptsValueMap = ConceptsCollection[RowLink.Concept];
			If ConceptsValueMap = Undefined Then
				ConceptsValueMap = New Map;
				ConceptsCollection.Insert(RowLink.Concept, ConceptsValueMap);
			EndIf;
			ConceptsValueMap.Insert(RowLink, ConceptValue);
		EndIf;
		SetNumberStructure.Concepts.Insert(RowLink.Concept, RowLink);
	EndIf;
		
EndProcedure

Procedure SetCurrentAxleArray(ReturnAxleArray, AxleTypeArray, Val Index,  Val UBound, AxleArrayCollection, AxleCollection = Undefined)
	
	AxleType = AxleTypeArray[Index];
	AxisValuesArray = AxleArrayCollection[AxleType];
	
	For Each AxisValues In AxisValuesArray Do
		If Index = 0 Then
			AxleCollection = New Map;
		EndIf;
		AxleCollection.Insert(AxleType, AxisValues);
		If  Index < UBound Then
			SetCurrentAxleArray(ReturnAxleArray, AxleTypeArray, Index + 1,  UBound, AxleArrayCollection, AxleCollection);
		ElsIf Index = UBound Then
			CopyAxleCollection = velpo_CommonFunctionsClientServer.CopyMap(AxleCollection);
			ReturnAxleArray.Add(CopyAxleCollection);			
		EndIf;
	EndDo;
	
EndProcedure

Procedure SetConceptData(DocumentXBRL, Result, SummarizedDataCollection, SelectionResult, TableFields, SetCache = False)
	
	AxleCollection = New Map;
	ConceptsCollection = New Map;
	FieldValues = GetFieldValues(Result, SelectionResult, TableFields, SetCache); 
	SetNumberCollection = New Map;
	
	// selection
	For Each FieldMap In FieldValues Do
		RowField = TableFields.Find(FieldMap.Key, "Field");
		// simple links
		If RowField.SimpleFiltersCount > 0 Then
			SimpleFilters = RowField.SimpleFilters;
			For Each SimpleFiltersMap In  SimpleFilters Do
				FilterStructure = New Structure;
				SimpleFiltersFields = SimpleFiltersMap.Key;
				FieldsCodes = SimpleFiltersMap.Value.FieldsCodes;
				Table = SimpleFiltersMap.Value.Table;
				For Each SimpleFilterField In SimpleFiltersFields Do
					FilterStructure.Insert(FieldsCodes[SimpleFilterField], FieldValues[SimpleFilterField]);
				EndDo;
				SimpleLinksArray = Table.FindRows(FilterStructure);
				If SimpleLinksArray.Count() > 0 Then
					For Each RowSimpleLink In SimpleLinksArray Do
						If CheckUniqueFieldsData(RowSimpleLink.RowLink, SelectionResult) Then
							AddConceptDataCollection(RowSimpleLink.RowLink, FieldMap, AxleCollection, ConceptsCollection, SetNumberCollection);	
						EndIf;
					EndDo;
				EndIf;
			EndDo;
		EndIf;
		// complex links
		If RowField.LinksCount > 0 Then
			LinksArray = RowField.Links;
			For Each RowLink In LinksArray Do
				// check unique
				If Not CheckUniqueFieldsData(RowLink, SelectionResult) Then
					Continue;
				EndIf;
				// check filter
				If RowLink.FieldFiltersCount > 0 Then
					FieldFiltersArray = RowLink.FieldFilters;
					If Not CheckFieldFilters(FieldFiltersArray, FieldValues) Then
						Continue;
					EndIf;
				EndIf;
				// add
				AddConceptDataCollection(RowLink, FieldMap, AxleCollection, ConceptsCollection, SetNumberCollection);
			EndDo; 
		EndIf;
	EndDo; 
	
	SetNumberCollectionCount = SetNumberCollection.Count();
	If SetNumberCollectionCount = 0 Then
		SetNumberCollection.Insert(0, New Structure("Axises, Concepts", New Map, New Map));
	EndIf;
	
	// set Concepts
	For Each ConceptData In ConceptsCollection Do
		ConceptDataValueCollection = ConceptData.Value;
		For Each ConceptsValueData In ConceptDataValueCollection Do
			For Each SetNumberData In SetNumberCollection Do 
				SetNumberDataAxisesCount = SetNumberData.Value.Axises.Count();
				SetNumberDataConceptsCount = SetNumberData.Value.Concepts.Count();
				If SetNumberCollectionCount > 1 And 	SetNumberData.Key = 0 Then
					Continue;
				ElsIf ConceptsValueData.Key.AxisSetNumber <> 0 And  SetNumberData.Key <> ConceptsValueData.Key.AxisSetNumber Then
					Continue;
				ElsIf ConceptsValueData.Key.AxisSetNumber = 0 And SetNumberData.Key > 0 And SetNumberDataConceptsCount > 0 And SetNumberData.Value.Concepts[ConceptData.Key] = Undefined Then
					Continue;
				EndIf;
				// get all variants of axle
				AxleArrayCollection = New Map;
				For Each AxleData In AxleCollection Do
					AxleDataValueCollection = AxleData.Value;
					For Each AxleValueData In AxleDataValueCollection Do
						// if number of set not equal to iteration and it's not zero (zero for all)
						If SetNumberData.Key <> AxleValueData.Key.AxisSetNumber And AxleValueData.Key.AxisSetNumber > 0 Then
							Continue;
						EndIf;
						// check the axle is only for special field
						If (AxleValueData.Key.UseFieldLink And AxleValueData.Key.FieldLink <> ConceptsValueData.Key.Field) Then
							Continue;
						EndIf;
						// set it
						AxleArray = AxleArrayCollection[AxleData.Key];
						If AxleArray = Undefined Then
							AxleArray = New Array;
							AxleArrayCollection.Insert(AxleData.Key, AxleArray);
						EndIf;
						AxleArray.Add(AxleValueData.Value);
					EndDo; 
				EndDo;
				// set up current axle collection
				AxleTypeArray = New Array;
				CurrentAxleArray = New Array;
				UBound = -1;
				For Each AxleArray In AxleArrayCollection Do
					AxleTypeArray.Add(AxleArray.Key);
					UBound = UBound + 1;
				EndDo;
				If UBound = -1 Then
					CurrentAxleArray.Add(New Map);
				Else
					SetCurrentAxleArray(CurrentAxleArray, AxleTypeArray, 0, UBound, AxleArrayCollection);
				EndIf;
				
				// get axle
				ConceptAxisTypesArray = velpo_BusinessReportingCashed.GetAxisTypeArray(ConceptData.Key);
				
				// Iterate all axle collections 
				For Each CurrentAxleCollection In CurrentAxleArray Do
					
					// concept axis
					If velpo_BusinessReportingCashed.GetConceptVariantType(ConceptData.Key)  = Enums.velpo_ConceptTypes.Measure Then
						If SetNumberData.Key > 0 And CurrentAxleCollection.Count() = 0 And ConceptAxisTypesArray.Count() > 0 Then
							Continue;
						EndIf;
						CurrentConceptAxle = New Map;
						For Each ConceptAxisType In ConceptAxisTypesArray Do
							ValueAxleCollection = CurrentAxleCollection[ConceptAxisType];
							If ValueAxleCollection = Undefined Then
								ValueAxleCollection = Catalogs.AxisMembers.EmptyRef();
							EndIf;
							CurrentConceptAxle.Insert(ConceptAxisType, ValueAxleCollection);
						EndDo;
					Else
						CurrentConceptAxle = CurrentAxleCollection; 
					EndIf;
										
					// check if it need to  Summarize value
					If ConceptsValueData.Key.UseTotals Then
						AxleValueDataCollection = SummarizedDataCollection[ConceptData.Key];
						If AxleValueDataCollection = Undefined Then
							AxleValueDataCollection = New Map;
							SummarizedDataCollection.Insert(ConceptData.Key, AxleValueDataCollection);
						EndIf;
						FlagFoundEqual = False;
						For Each AxleValue In AxleValueDataCollection Do
							If velpo_CommonFunctions.IsEqualData(AxleValue.Key, CurrentConceptAxle) Then
								AxleValueDataCollection[AxleValue.Key] = AxleValue.Value + ConceptsValueData.Value;
								FlagFoundEqual = True;
								Break;
							EndIf;
						EndDo;
						If Not FlagFoundEqual Then
							AxleValueDataCollection.Insert(CurrentConceptAxle, ConceptsValueData.Value);
						EndIf;
					Else
						DocumentXBRL	.SetConcept(ConceptData.Key, ConceptsValueData.Value, CurrentConceptAxle); 
					EndIf;
				EndDo;
			EndDo; 
		EndDo;
	EndDo; 

EndProcedure // SetConceptData()

Function GetSourceQueryResults(Source, ChangeDates = True) Export

	// set new query
	TempTablesManager = New TempTablesManager;
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	// set source data
	SetSourceData(Query, Source, ChangeDates);
	// get results
	QueryResults = Query.ExecuteBatch();
	// close temp tables
	TempTablesManager.Close();

	Return QueryResults; 
	
EndFunction

Procedure SetSourceData(Query, Source, ChangeDates = True) Export
	
	IsSourceRef = (TypeOf(Source) = Type("ChartOfCharacteristicTypesRef.velpo_SourceQueryComponents"));
	
	If ChangeDates Then 
		If ValueIsFilled(ThisObject.EntryPoint) Then
			Quarterly = velpo_CommonFunctions.ObjectAttributeValue(ThisObject.EntryPoint, "Quarterly");
			PeriodStart = ?(Quarterly, BegOfQuarter(ThisObject.PeriodEnd), BegOfMonth(ThisObject.PeriodEnd));
		Else
			PeriodStart = ThisObject.PeriodStart;
		EndIf;
	
		If IsSourceRef Then
			//Monthly = CommonFunctions.ObjectAttributeValue(Source, "Monthly");
			Monthly = velpo_CommonFunctions.ObjectAttributeValue(Source, "Quarterly"); // заменить наименование реквизита
			PeriodStart = ?(Monthly, BegOfMonth(ThisObject.PeriodEnd), ThisObject.PeriodStart);
		EndIf;
		
		ThisObject.PeriodStart = PeriodStart;
		
	EndIf;
	
	// set parameters
	Query.SetParameter("BeginOfPeriod", ThisObject.PeriodStart);
	Query.SetParameter("EndOfPeriod", EndOfDay(ThisObject.PeriodEnd));
	Query.SetParameter("BeginBoundary", New Boundary(ThisObject.PeriodStart, BoundaryType.Including));
	Query.SetParameter("EndBoundary", New Boundary(EndOfDay(ThisObject.PeriodEnd), BoundaryType.Including));
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
			
	// set parameters
	If IsSourceRef Then
		Query.SetParameter("Source", Source);
		Query.Text = GetQueryTextSourcesParameters();
	Else
		Query.SetParameter("ParameterRefs", Source.SourceParameters.Unload().UnloadColumn("Parameter"));
		Query.Text = GetQueryTextSourcesParametersByRefs();
	EndIf;
	SelectionParameters = Query.Execute().Select();
	
	While SelectionParameters.Next() Do
		Query.SetParameter("Parameter", SelectionParameters.Parameter);
		Query.Text = GetQueryTextSourcesParametersValues();
		SelectionValues = Query.Execute().Select();
		If SelectionParameters.UseList Then
			ValueArray = New Array;
			While SelectionValues.Next() Do
				ValueArray.Add(SelectionValues.Value);
			EndDo;
			Query.SetParameter(SelectionParameters.Code, ValueArray);
		Else
			SelectionValues.Next();
			Query.SetParameter(SelectionParameters.Code, SelectionValues.Value);
		EndIf;
	EndDo;
	
	// set results
	If IsSourceRef Then
		Query.Text = GetQueryTextSourcesResults();
	Else
		Query.SetParameter("ResultRefs", Source.SourceResults.Unload());
		Query.Text = GetQueryTextSourcesResultsByRefs();
	EndIf;
	SelectionResults = Query.Execute().Select();
	
	While SelectionResults.Next() Do
		TableDataCache = ResultsCache[SelectionResults.Result];
		If TableDataCache = Undefined Then
			TempResultAttribs = velpo_CommonFunctions.ObjectAttributeValues(SelectionResults.Result, "Parent, IndexNum");
			TempQueryResults = GetSourceQueryResults(TempResultAttribs.Parent, False);
			Index = 1;
			For Each TempQueryResult In TempQueryResults Do
				If Index = TempResultAttribs.IndexNum Then
					TempSelectionResult = TempQueryResult.Select();
					//  cache
					TableFields = GetFieldsCache(SelectionResults.Result, True);
					While TempSelectionResult.Next() Do
						FieldValues = GetFieldValues(SelectionResults.Result, TempSelectionResult, TableFields, True); 
					EndDo;
					TableDataCache = ResultsCache[SelectionResults.Result];
					Break;
				EndIf;
				Index = Index + 1;
			EndDo;
		EndIf;
		Query.SetParameter(SelectionResults.Name, TableDataCache);
		Columns = TableDataCache.Columns;
		TextTempTable = "SELECT ";
		FirstColumn = True;
		For Each Column In Columns Do
			TextTempTable = TextTempTable + ?(FirstColumn,"", ",") + SelectionResults.Name + "." + Column.Name + " AS " + Column.Name;
			FirstColumn = False;
		EndDo;
		TextTempTable = TextTempTable + " INTO " + SelectionResults.Name + " FROM &" + SelectionResults.Name + " AS " + SelectionResults.Name;
		Query.Text = TextTempTable;
		Query.Execute();
	EndDo;
	
	// set text
	If IsSourceRef Then
		Query.Text = velpo_CommonFunctions.ObjectAttributeValue(Source, "SourceText");
	EndIf;
	
EndProcedure // SetSourceData()

Procedure GenerateResult(Result, Data, SetCache = False) Export
	
	//  cache
	TableFields = GetFieldsCache(Result);
	
	// document
	DocumentXBRL = Documents.velpo_Fact.Create(ThisObject.PeriodStart, ThisObject.PeriodEnd, ThisObject.BusinessUnit, Result);
	SummarizedDataCollection = New Map;
	
	// selection
	If TypeOf(Data) = Type("QueryResultSelection") Then
		While Data.Next() Do
			SetConceptData(DocumentXBRL, Result, SummarizedDataCollection, Data, TableFields, SetCache);
		EndDo;
	// value table
	Else
		For Each Line In Data Do
			SetConceptData(DocumentXBRL, Result, SummarizedDataCollection, Line, TableFields, SetCache);
		EndDo;
	EndIf;
	
	For Each ConcepData In SummarizedDataCollection Do
		ConcepDataCollection = ConcepData.Value;
		For Each AxleValueData In ConcepDataCollection Do
			DocumentXBRL	.SetConcept(ConcepData.Key, AxleValueData.Value, AxleValueData.Key); 	
		EndDo;
	EndDo;
	
	DocumentXBRL.Write(DocumentWriteMode.Posting);
	
EndProcedure

Procedure GenerateSource(Source) Export
	
	QueryResults = GetSourceQueryResults(Source);

	// get link
	Index  = 0;
	For Each QueryResult In QueryResults  Do
		Index = Index + 1;
		If QueryResult = Undefined Then
			Continue;
		ElsIf QueryResult.Columns.Count() = 1 And (QueryResult.Columns[0].Name = "Count" Or QueryResult.Columns[0].Name = "Количество") Then
			Continue;
		EndIf;
		// find result index
		RefResult = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.FindByAttribute("IndexNum", Index, Source);
		If Not ValueIsFilled(RefResult) Then
			Raise String(Source) + "___" + String(QueryResult) + "___" + String(Index);
		EndIf;
		// if script then continue
		If velpo_CommonFunctions.ObjectAttributeValue(RefResult, "IsScript") Then
			Continue;
		EndIf;
		// set source
		TableDataCache = ResultsCache[RefResult];
		If TableDataCache = Undefined Then
			SelectionResult = QueryResult.Select();
			GenerateResult(RefResult, SelectionResult, True);
		Else
			GenerateResult(RefResult, TableDataCache);
		EndIf;
	EndDo;
	
EndProcedure

Procedure GenerateData() Export
	
	Message(CurrentDate());
	//BeginTransaction();
	
	// delete all for this period	
	velpo_BusinessReportingServer.SetZeroMeasureBalance(ThisObject.PeriodStart, ThisObject.PeriodEnd, ThisObject.BusinessUnit);
	
	SourcesValues = ThisObject.Sources.UnloadColumn("Source");
	
	// get sources text
	Query = New Query;
	Query.SetParameter("SourcesValues", SourcesValues);
	Query.SetParameter("IsSourcesFilter", (SourcesValues.Count()>0));
	Query.SetParameter("EntryPoint",  ThisObject.EntryPoint);
	Query.Text = GetQueryTextSources();

	// iteration
	SelectionSource = Query.Execute().Select();
	While SelectionSource.Next() Do
		ЗаписьЖурналаРегистрации("ДобавлениеФактов", УровеньЖурналаРегистрации.Информация,,, Строка(SelectionSource.Source));
		GenerateSource(SelectionSource.Source);
	EndDo;
	// set data
	velpo_BusinessReportingServer.FillDataInCubes();
	
	//CommitTransaction();
	
	Message(CurrentDate());
	
EndProcedure

#EndRegion

ResultsCache = New Map;

#EndIf