///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region SavingUtilityFunctions

Function GetGlobalDefaultsCheckTextQuery()

	Text = 
	"SELECT TOP 1
	|	TRUE AS IsGlobal
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.UseDefaults
	|	AND SourceQueryComponents.Defaults.Parent.Parent = VALUE(ChartOfCharacteristicTypes.SourceQueryComponents.EmptyRef)
	|	AND SourceQueryComponents.Ref IN HIERARCHY (&SourceArray)
	|";
	
	Return Text;
	
EndFunction // GetGlobalDefaultsCheckTextQuery()

Function GetGroupsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.IsFolder
	|	AND SourceQueryComponents.Parent = &ParentRef
	| 	AND SourceQueryComponents.Ref IN (&GroupsArray)
	|";
	
	Return Text;
	
EndFunction // GetGlobalDefaultsCheckTextQuery()

Function GetSourceTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Ref,
	|	SourceQueryComponents.Code AS Code,
	|	SourceQueryComponents.Description AS Description,
	|	SourceQueryComponents.IndexNum AS IndexNum,
	|	SourceQueryComponents.IsScript AS IsScript
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType = VALUE(Enum.ComponetQueryTypes.Source)
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|ORDER BY
	|	SourceQueryComponents.Description ASC
	|";
	
	Return Text;
	
EndFunction // GetSourceTextQuery()

Function GetSourceResultsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponentsResults.Result AS Result,
	|	SourceQueryComponentsResults.Name AS Name
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents.SourceResults AS SourceQueryComponentsResults
	|WHERE
	|	SourceQueryComponentsResults.Ref = &SourceRef
	|ORDER BY
	|	SourceQueryComponentsResults.Result.IndexNum ASC
	|";
	
	Return Text;

EndFunction // GetSourceResultsTextQuery()

Function GetSourceParametersTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponentsParameters.Parameter AS Parameter,
	|	SourceQueryComponentsParameters.Parameter.Code AS Code,
	|	SourceQueryComponentsParameters.Parameter.Description AS Description,
	|	SourceQueryComponentsParameters.Parameter.UseList AS UseList,
	|	SourceQueryComponentsParameters.Parameter.ValueType AS ValueType
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents.SourceParameters AS SourceQueryComponentsParameters
	|WHERE
	|	SourceQueryComponentsParameters.Ref = &SourceRef
	|";
	
	Return Text;

EndFunction // GetParametersTextQuery()

Function GetSourceEntryPointsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponentsEntryPoints.EntryPoint AS EntryPoint
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents.EntryPoints AS SourceQueryComponentsEntryPoints
	|WHERE
	|	SourceQueryComponentsEntryPoints.Ref = &SourceRef
	|";
	
	Return Text;

EndFunction // GetParametersTextQuery()
 
Function GetSourceParameterValuesTextQuery()

	Text = 
	"SELECT
	|	SourceQueryParametersValues.Ref AS Parameter,
	|	SourceQueryParametersValues.Value AS Value
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryParameters.Values AS SourceQueryParametersValues
	|WHERE
	|	SourceQueryParametersValues.Ref = &ParameterRef
	|";
	
	Return Text;

EndFunction // GetParameterValueTextQuery()

Function GetResultsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Result,
	|	SourceQueryComponents.Code AS Code,
	|	SourceQueryComponents.Description AS Description,
	|	SourceQueryComponents.IndexNum AS IndexNum,
	|	SourceQueryComponents.IsScript AS IsScript
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType = VALUE(Enum.ComponetQueryTypes.Result)
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.Parent = &SourceRef
	|ORDER BY
	|	SourceQueryComponents.IndexNum ASC
	|";
	
	Return Text;

EndFunction // GetResultsTextQuery()

Function GetDefaultsTextQuery()

	Text = 
	"SELECT TOP 1
	|	SourceQueryComponents.Ref AS Defaults,
	|	SourceQueryComponents.Code AS Code,
	|	SourceQueryComponents.Description AS Description
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType = VALUE(Enum.ComponetQueryTypes.Defaults)
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.Parent = &ParentRef
	|";
	
	Return Text;

EndFunction // GetDefaultsTextQuery()

Function GetFieldsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Field,
	|	SourceQueryComponents.Code AS Code,
	|	SourceQueryComponents.Description AS Description,
	|	SourceQueryComponents.IndexNum AS IndexNum,
	|	SourceQueryComponents.ValueType AS ValueType,
	|	SourceQueryComponents.UseDefaults AS UseDefaults,
	|	SourceQueryComponents.Defaults AS Defaults
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType = VALUE(Enum.ComponetQueryTypes.Field)
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.Parent = &ParentRef
	|ORDER BY
	|	SourceQueryComponents.IndexNum ASC
	|";
	
	Return Text;

EndFunction // GetResultsTextQuery()

Function GetFunctionsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Function,
	|	SourceQueryComponents.Code AS Code,
	|	SourceQueryComponents.Description AS Description,
	|	SourceQueryComponents.IndexNum AS IndexNum,
	|	SourceQueryComponents.SourceText AS SourceText,
	|	SourceQueryComponents.ValueType AS ValueType,
	|	SourceQueryComponents.UseDefaults AS UseDefaults,
	|	SourceQueryComponents.Defaults AS Defaults
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType = VALUE(Enum.ComponetQueryTypes.Function)
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.Parent = &ParentRef
	|ORDER BY
	|	SourceQueryComponents.IndexNum ASC
	|";
	
	Return Text;

EndFunction // GetFunctionsTextQuery()

Function GetConstantsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Constant,
	|	SourceQueryComponents.Code AS Code,
	|	SourceQueryComponents.Description AS Description,
	|	SourceQueryComponents.IndexNum AS IndexNum,
	|	SourceQueryComponents.ValueType AS ValueType,
	|	SourceQueryComponents.UseDefaults AS UseDefaults,
	|	SourceQueryComponents.Defaults AS Defaults,
	|	SourceQueryComponents.ConstantValue AS ConstantValue
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.ComponentType = VALUE(Enum.ComponetQueryTypes.Constant)
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|	AND SourceQueryComponents.Parent = &ParentRef
	|ORDER BY
	|	SourceQueryComponents.IndexNum ASC
	|";
	
	Return Text;

EndFunction // GetConstantsTextQuery()

Function GetFunctionFieldsTextQuery()

	Text = 
	"SELECT
	|	SourceQueryComponentsFunctionFields.Ref AS Function,
	|	SourceQueryComponentsFunctionFields.Field AS Field
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents.FunctionFields AS SourceQueryComponentsFunctionFields
	|WHERE
	|	SourceQueryComponentsFunctionFields.Ref = &FunctionRef
	|";
	
	Return Text;

EndFunction // GetFunctionFieldsTextQuery()

Function GetLinksTextQuery()

	Text = 
	"SELECT
	|	FieldQueryLinks.Ref AS Link,
	|	FieldQueryLinks.Code AS Code,
	|	FieldQueryLinks.LinkType AS LinkType,
	|	FieldQueryLinks.AxisType AS AxisType,
	|	FieldQueryLinks.Concept AS Concept,
	|	FieldQueryLinks.Concept.Name AS ConceptName,
	|	FieldQueryLinks.Concept.IsGroup AS ConceptIsGroup,
	|	FieldQueryLinks.Concept.ExtDimensionCount AS AxisTypesCount,
	|	FieldQueryLinks.UseSourceValue AS UseSourceValue,
	|	FieldQueryLinks.UseFieldLink AS UseFieldLink,
	|	FieldQueryLinks.FieldLink AS FieldLink,
	|	FieldQueryLinks.UseTotals AS UseTotals,
	|	FieldQueryLinks.Unique AS Unique,
	|	FieldQueryLinks.NegativeSign AS NegativeSign,
	|	FieldQueryLinks.AxisSetNumber AS AxisSetNumber,
	|	FieldQueryLinks.Comments AS Comments
	|FROM
	|	Catalog.FieldQueryLinks AS FieldQueryLinks
	|WHERE
	|	FieldQueryLinks.Owner = &ComponentRef
	|";
	
	Return Text;

EndFunction // GetLinksTextQuery()

Function GetConceptAxisTypesTextQuery()

	Text = 
	"SELECT
	|	ChartReportingExtDimensionTypes.Ref AS Concept,
	|	ChartReportingExtDimensionTypes.ExtDimensionType AS AxisType
	|FROM
	|	ChartOfAccounts.Reporting.ExtDimensionTypes AS ChartReportingExtDimensionTypes
	|WHERE
	|	ChartReportingExtDimensionTypes.Ref = &ConceptRef
	|";
	
	Return Text;

EndFunction // GetLinksTextQuery()

Function GetLinkSettingsTextQuery()

	Text = 
	"SELECT
	|	FieldQueryLinksAxisLinks.Ref AS Link,
	|	FieldQueryLinksAxisLinks.Otherwise AS Otherwise,
	|	FieldQueryLinksAxisLinks.FieldValue AS FieldValue,
	|	FieldQueryLinksAxisLinks.Axis AS Axis,
	|	FieldQueryLinksAxisLinks.Axis.AxisValueType AS AxisValueType
	|FROM
	|	Catalog.FieldQueryLinks.AxisLinks AS FieldQueryLinksAxisLinks
	|WHERE
	|	FieldQueryLinksAxisLinks.Ref = &LinkRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FieldQueryLinksConceptLinks.Ref AS Link,
	|	FieldQueryLinksConceptLinks.Otherwise AS Otherwise,
	|	FieldQueryLinksConceptLinks.FieldValue AS FieldValue,
	|	FieldQueryLinksConceptLinks.Value AS Value
	|FROM
	|	Catalog.FieldQueryLinks.ConceptLinks AS FieldQueryLinksConceptLinks
	|WHERE
	|	FieldQueryLinksConceptLinks.Ref = &LinkRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FieldQueryLinksFieldFilters.Ref AS Link,
	|	FieldQueryLinksFieldFilters.FilterType AS FilterType,
	|	FieldQueryLinksFieldFilters.Field AS Field,
	|	FieldQueryLinksFieldFilters.ComparisonType AS ComparisonType,
	|	FieldQueryLinksFieldFilters.Value AS Value
	|FROM
	|	Catalog.FieldQueryLinks.FieldFilters AS FieldQueryLinksFieldFilters
	|WHERE
	|	FieldQueryLinksFieldFilters.Ref = &LinkRef
	|;
	|
	|////////////////////////////////////////////////////////////////////////////////
	|SELECT
	|	FieldQueryLinksUniqueFields.Ref AS Link,
	|	FieldQueryLinksUniqueFields.LineNumber AS LineNum,
	|	FieldQueryLinksUniqueFields.Field AS Field
	|FROM
	|	Catalog.FieldQueryLinks.UniqueFields AS FieldQueryLinksUniqueFields
	|WHERE
	|	FieldQueryLinksUniqueFields.Ref = &LinkRef
	|ORDER BY
	|	FieldQueryLinksUniqueFields.LineNumber ASC
	|";
	
	Return Text;

EndFunction // GetLinkSettingsTextQuery()

Function GetSerializedValueXDTO(Value)

	Serializer = velpo_BusinessReportingCashed.GetXDTOSerializer();
	Try
		Return Serializer.WriteXDTO(Value);
	Except
		Return Undefined;
	EndTry;

EndFunction // GetTypeDescriptionXDTO()

Function CheckGlobalDefaults(SourceArray)
	
	Query = New Query;
	Query.SetParameter("SourceArray", SourceArray);
	Query.Text = GetGlobalDefaultsCheckTextQuery();
	Return Not Query.Execute().IsEmpty();
	
EndFunction // GetGlobalDefaults()

Function GetValuePackage(XDTOTypes, Value)
	
	ValuePack = XDTOFactory.Create(XDTOTypes.ValueType);
	TypeOfValue = TypeOf(Value);
	
	If velpo_CommonFunctions.IsReference(TypeOfValue) Then
		ValuePack.Type  = "Ref";
		ValuePack.ValueRef = GetRefPackage(XDTOTypes, Value);
	ElsIf TypeOfValue = Type("String") Then
		ValuePack.Type  = "String";
		ValuePack.ValueString = Value;
	ElsIf TypeOfValue = Type("Date") Then
		ValuePack.Type  = "Date";
		ValuePack.ValueDate = Value;
	ElsIf TypeOfValue = Type("Number") Then
		ValuePack.Type  = "Number";
		ValuePack.ValueNumber = Value;
	ElsIf TypeOfValue = Type("Boolean") Then
		ValuePack.Type  = "Boolean";
		ValuePack.ValueBoolean = Value;
	Else
		Return Undefined;
	EndIf;
	
	Return ValuePack;
	
EndFunction

Function GetRefPackage(XDTOTypes, Ref)
	
	TypeOfRef = TypeOf(Ref);
	
	If Not velpo_CommonFunctions.IsReference(TypeOfRef) Then
		Return Undefined;
	EndIf;

	RefMeta = Ref.MetaData(); 
	
	RefPack = XDTOFactory.Create(XDTOTypes.RefType);
	RefPack.TypeName = RefMeta.Name;
	If velpo_CommonFunctions.IsEnum(RefMeta) Then
		RefPack.Type = velpo_CommonFunctions.TypeNameEnums();
		Try
			RefPack.ValueName = velpo_CommonFunctions.EnumValueName(Ref);
		Except
		EndTry;
	Else
		RefPack.ID = Ref.UUID();
		CheckPredefined = False;
		
		If velpo_CommonFunctions.IsCatalog(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameCatalogs();
			CheckPredefined = True;
		ElsIf velpo_CommonFunctions.IsDocument(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameDocuments();
		ElsIf velpo_CommonFunctions.IsChartOfCharacteristicTypes(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameChartsOfCharacteristicTypes();
			CheckPredefined = True;
		ElsIf velpo_CommonFunctions.IsChartOfAccounts(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameChartsOfAccounts();
			CheckPredefined = True;
		ElsIf velpo_CommonFunctions.IsChartOfCalculationTypes(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameChartsOfCalculationTypes();
			CheckPredefined = True;
		ElsIf velpo_CommonFunctions.IsExchangePlan(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameExchangePlans();
		ElsIf velpo_CommonFunctions.IsBusinessProcess(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameBusinessProcesses();
		ElsIf velpo_CommonFunctions.IsTask(RefMeta) Then
			RefPack.Type = velpo_CommonFunctions.TypeNameTasks();
		EndIf;
		
		If ValueIsFilled(Ref) Then
			If velpo_CommonFunctions.HasObjectAttribute("Code",  RefMeta) Then
				RefPack.Code = velpo_CommonFunctions.ObjectAttributeValue(Ref, "Code");
			EndIf;
			If velpo_CommonFunctions.HasObjectAttribute("Name",  RefMeta) Then
				RefPack.Name = velpo_CommonFunctions.ObjectAttributeValue(Ref, "Name");
			EndIf;
			Try
				If CheckPredefined And velpo_CommonFunctions.ObjectAttributeValue(Ref, "Predefined")  Then
					RefPack.PredefinedName = velpo_CommonFunctions.PredefinedName(Ref);
				EndIf;
			Except
				
			EndTry;
		EndIf;
		
	EndIf;
	
	RefPack.SerializedValue = GetSerializedValueXDTO(Ref);
	
	Return RefPack;
	
EndFunction // GetRefPackage()

Function GetSourceResultsPackage(XDTOTypes, SourceRef)

	SourceResultsListPack = XDTOFactory.Create(XDTOTypes.SourceResultsListType); 
	
	Query = New Query;
	Query.SetParameter("SourceRef", SourceRef);
	Query.Text = GetSourceResultsTextQuery();
	SelectionResults = Query.Execute().Select();
	While SelectionResults.Next() Do
		SourceResultPack = XDTOFactory.Create(XDTOTypes.SourceResultType); 
		FillPropertyValues(SourceResultPack, SelectionResults, "Name");
		SourceResultPack.ResultRef = GetRefPackage(XDTOTypes, SelectionResults.Result);
		SourceResultsListPack.Result.Add(SourceResultPack);
	EndDo;
	
	Return SourceResultsListPack; 
	
EndFunction // GetSourceResultsPackage()

Function GetSourceParametersPackage(XDTOTypes, SourceRef)

	SourceParametersListPack = XDTOFactory.Create(XDTOTypes.SourceParametersListType); 
	
	Query = New Query;
	Query.SetParameter("SourceRef", SourceRef);
	Query.Text = GetSourceParametersTextQuery();
	SelectionParameters = Query.Execute().Select();
	While SelectionParameters.Next() Do
		
		SourceParameterPack = XDTOFactory.Create(XDTOTypes.SourceParameterType); 
		FillPropertyValues(SourceParameterPack, SelectionParameters, "Code, Description, UseList");
		SourceParameterPack.ID = SelectionParameters.Parameter.UUID();
		SourceParameterPack.ValueType = GetSerializedValueXDTO(SelectionParameters.ValueType); 
		
		ValuesPack = XDTOFactory.Create(XDTOTypes.ValuesListType); 
		Query.SetParameter("ParameterRef", SelectionParameters.Parameter);
		Query.Text = GetSourceParameterValuesTextQuery();
		SelectionValues = Query.Execute().Select();
		While SelectionValues.Next() Do
			ValuesPack.Value.Add(GetValuePackage(XDTOTypes, SelectionValues.Value));
		EndDo;
		
		SourceParameterPack.Values = ValuesPack;
		
		SourceParametersListPack.Parameter.Add(SourceParameterPack);
	EndDo;
	
	Return SourceParametersListPack; 
	
EndFunction // GetParametersPackage()

Function GetEntryPointsRefsPackage(XDTOTypes, SourceRef)

	RefsListPack = XDTOFactory.Create(XDTOTypes.RefsListType); 
	Query = New Query;
	Query.SetParameter("SourceRef", SourceRef);
	Query.Text = GetSourceEntryPointsTextQuery();
	SelectionRefs = Query.Execute().Select();
	While SelectionRefs.Next() Do
		RefPack = GetRefPackage(XDTOTypes, SelectionRefs.EntryPoint);
		RefsListPack.Ref.Add(RefPack);
	EndDo;
	
	Return RefsListPack; 
	
EndFunction // GetEntryPointsRefsPackage()

Function GetConceptAxisTypes(XDTOTypes, ConceptRef)

	AxisTypesListPack = XDTOFactory.Create(XDTOTypes.AxisTypesListType); 

	Query = New Query;
	Query.SetParameter("ConceptRef", ConceptRef);
	Query.Text = GetConceptAxisTypesTextQuery();
	SelectionAxisTypes = Query.Execute().Select();
	While SelectionAxisTypes.Next() Do
		AxisTypeRef = GetRefPackage(XDTOTypes, SelectionAxisTypes.AxisType);
		AxisTypesListPack.AxisTypeRef.Add(AxisTypeRef);
	EndDo;
	
	Return AxisTypesListPack; 

EndFunction // GetConceptDime()

Function GetLinksPackage(XDTOTypes, ComponentRef)

	LinksListPack = XDTOFactory.Create(XDTOTypes.LinksListType); 
	
	Query = New Query;
	Query.SetParameter("ComponentRef", ComponentRef);
	Query.Text = GetLinksTextQuery();
	SelectionLinks = Query.Execute().Select();
	While SelectionLinks.Next() Do
		
		LinkPack = XDTOFactory.Create(XDTOTypes.LinkType); 
		LinkPack.ID = SelectionLinks.Link.UUID();
		LinkPack.Code = SelectionLinks.Code;
		LinkPack.UseSourceValue = SelectionLinks.UseSourceValue;
		LinkPack.UseFieldLink = SelectionLinks.UseFieldLink;
		LinkPack.UseTotals = SelectionLinks.UseTotals;
		LinkPack.Unique = SelectionLinks.Unique;
		LinkPack.NegativeSign = SelectionLinks.NegativeSign;
		LinkPack.AxisSetNumber = SelectionLinks.SetNumber;
		LinkPack.Comments = SelectionLinks.Comments;
		
		// if we need to set up field link
		If SelectionLinks.UseFieldLink И ValueIsFilled(SelectionLinks.FieldLink) Then
			LinkPack.FieldLinkRef = GetRefPackage(XDTOTypes, SelectionLinks.FieldLink);
		EndIf;
				
		LinkPack.Type = XDTOFactory.Create(XDTOTypes.LinkTypes, velpo_CommonFunctions.EnumValueName(SelectionLinks.LinkType));
		
		// type axis or concept
		If SelectionLinks.LinkType = Enums.velpo_FieldQueryLinkTypes.AxisType Then
			LinkPack.AxisTypeRef = GetRefPackage(XDTOTypes, SelectionLinks.AxisType);
		Else
			ConceptPack= XDTOFactory.Create(XDTOTypes.ConceptType);
			ConceptPack.ID = SelectionLinks.Concept.UUID();
			ConceptPack.Name = SelectionLinks.ConceptName;
			ConceptPack.IsGroup = SelectionLinks.ConceptIsGroup;
			ConceptPack.AxisTypesCount = SelectionLinks.AxisTypesCount;
			ConceptPack.AxisTypes = GetConceptAxisTypes(XDTOTypes,  SelectionLinks.Concept);
			LinkPack.Concept = ConceptPack;
		EndIf;
			
		//  tables
		Query.SetParameter("LinkRef", SelectionLinks.Link);	
		Query.Text = GetLinkSettingsTextQuery();
		QueryResults = Query.ExecuteBatch();
		
		// AxisLinks
		AxisLinksListPack = XDTOFactory.Create(XDTOTypes.AxisLinksListType); 
		SelectionAxisLinks = QueryResults[0].Select();
		While SelectionAxisLinks.Next() Do
			AxisLinkPack = XDTOFactory.Create(XDTOTypes.AxisLinkType); 	
			AxisLinkPack.Otherwise = SelectionAxisLinks.Otherwise;
			AxisLinkPack.FieldValue = GetValuePackage(XDTOTypes, SelectionAxisLinks.FieldValue);
			// Axis
			AxisPack = XDTOFactory.Create(XDTOTypes.AxisType); 	
			AxisPack.ID = SelectionAxisLinks.Axis.UUID();
			AxisPack.Type = "Ref";
			If SelectionAxisLinks.AxisValueType <> Null Then
				Try
					AxisPack.Type = velpo_CommonFunctions.EnumValueName(SelectionAxisLinks.AxisValueType);
				Except
				EndTry;
			EndIf;
			AxisPack.Value = GetValuePackage(XDTOTypes, Catalogs.AxisMembers.GetAxisValue(SelectionAxisLinks.Axis));
			AxisLinkPack.Axis = AxisPack;
			AxisLinksListPack.AxisLink.Add(AxisLinkPack);
		EndDo;
		LinkPack.AxisLinks = AxisLinksListPack; 
		
		// ConceptLinks
		ConceptLinksListPack = XDTOFactory.Create(XDTOTypes.ConceptLinksListType); 
		SelectionConceptLinks = QueryResults[1].Select();
		While SelectionConceptLinks.Next() Do
			ConceptLinkPack = XDTOFactory.Create(XDTOTypes.ConceptLinkType); 	
			ConceptLinkPack.Otherwise = SelectionConceptLinks.Otherwise;
			ConceptLinkPack.FieldValue = GetValuePackage(XDTOTypes, SelectionConceptLinks.FieldValue);
			ConceptLinkPack.Value = GetValuePackage(XDTOTypes, SelectionConceptLinks.Value);
			ConceptLinksListPack.ConceptLink.Add(ConceptLinkPack);
		EndDo;
		LinkPack.ConceptLinks = ConceptLinksListPack; 
		
		// FieldFilters
		FieldFiltersListPack = XDTOFactory.Create(XDTOTypes.FieldFiltersListType); 
		SelectionFieldFilters = QueryResults[2].Select();
		While SelectionFieldFilters.Next() Do
			FieldFilterPack = XDTOFactory.Create(XDTOTypes.FieldFilterType); 
			FieldFilterPack.Type = velpo_CommonFunctions.EnumValueName(SelectionFieldFilters.FilterType);
		
			FieldFilterPack.FieldRef = GetRefPackage(XDTOTypes, SelectionFieldFilters.Field);
			FieldFilterPack.ComparisonType = velpo_CommonFunctions.EnumValueName(SelectionFieldFilters.ComparisonType);
			FieldFilterPack.Value = GetValuePackage(XDTOTypes, SelectionFieldFilters.Value);
			
			FieldFiltersListPack.FieldFilter.Add(FieldFilterPack);
		EndDo;
		LinkPack.FieldFilters = FieldFiltersListPack; 
		
		// Unique fields
		UniqueFieldsListPack = XDTOFactory.Create(XDTOTypes.UniqueFieldsListType); 
		SelectionUniqueFields = QueryResults[3].Select();
		While SelectionUniqueFields.Next() Do
			UniqueFieldPack = XDTOFactory.Create(XDTOTypes.UniqueFieldType); 
			UniqueFieldPack.LineNum = SelectionUniqueFields.LineNum;
			UniqueFieldPack.FieldRef = GetRefPackage(XDTOTypes, SelectionUniqueFields.Field);
			UniqueFieldsListPack.UniqueField.Add(UniqueFieldPack);
		EndDo;
		LinkPack.UniqueFields = UniqueFieldsListPack; 
		LinksListPack.Link.Add(LinkPack);
	EndDo;
	
	Return LinksListPack; 
	
EndFunction // GetParametersPackage()

Function GetFieldsPackage(XDTOTypes, ParentRef)

	FieldsListPack = XDTOFactory.Create(XDTOTypes.FieldsListType); 
	
	Query = New Query;
	Query.SetParameter("ParentRef", ParentRef);
	Query.Text = GetFieldsTextQuery();
	SelectionFields = Query.Execute().Select();
	While SelectionFields.Next() Do

		FieldPack = XDTOFactory.Create(XDTOTypes.FieldType); 
		FillPropertyValues(FieldPack, SelectionFields, "Code, Description, IndexNum, UseDefaults");
		FieldPack.ID = SelectionFields.Field.UUID();
		FieldPack.ValueType = GetSerializedValueXDTO(SelectionFields.ValueType);
		
		// set up defaults
		If SelectionFields.UseDefaults Then
			FieldPack.DefaultsRef = GetRefPackage(XDTOTypes, SelectionFields.Defaults);
		EndIf;
		
		// set links
		FieldPack.Links =  GetLinksPackage(XDTOTypes, SelectionFields.Field); 
		
		FieldsListPack.Field.Add(FieldPack);
	EndDo;
	
	Return FieldsListPack; 
	
EndFunction // GetParametersPackage()

Function GetFunctionsPackage(XDTOTypes, ParentRef)

	FunctionsListPack = XDTOFactory.Create(XDTOTypes.FunctionsListType); 
	
	Query = New Query;
	Query.SetParameter("ParentRef", ParentRef);
	Query.Text = GetFunctionsTextQuery();
	SelectionFunctions = Query.Execute().Select();
	While SelectionFunctions.Next() Do
		
		FunctionPack = XDTOFactory.Create(XDTOTypes.FunctionType); 
		FillPropertyValues(FunctionPack, SelectionFunctions, "Code, Description, SourceText, IndexNum, UseDefaults");
		FunctionPack.ID = SelectionFunctions.Function.UUID();
		FunctionPack.ValueType = GetSerializedValueXDTO(SelectionFunctions.ValueType);
		
		// set up defaults
		If SelectionFunctions.UseDefaults And ValueIsFilled(SelectionFunctions.DefaultsCode) Then
			FunctionPack.DefaultsRef = GetRefPackage(XDTOTypes, SelectionFunctions.Defaults);
		EndIf;
		
		// set field refs
		RefsListPack = XDTOFactory.Create(XDTOTypes.RefsListType); 
		Query.SetParameter("FunctionRef", SelectionFunctions.Function);
		Query.Text = GetFunctionFieldsTextQuery();
		SelectionFields = Query.Execute().Select();
		While SelectionFields.Next() Do
			RefPack = GetRefPackage(XDTOTypes, SelectionFields.Field);
			RefsListPack.Ref.Add(RefPack);
		EndDo;
		// set fields
		FunctionPack.FieldRefs = RefsListPack;
		
		// set links
		FunctionPack.Links =  GetLinksPackage(XDTOTypes, SelectionFunctions.Function); 
		
		FunctionsListPack.Function.Add(FunctionPack);
		
	EndDo;
	
	Return FunctionsListPack; 
	
EndFunction // GetParametersPackage()

Function GetConstantsPackage(XDTOTypes, ParentRef)

	ConstantsListPack = XDTOFactory.Create(XDTOTypes.ConstantsListType); 
	          
	Query = New Query;
	Query.SetParameter("ParentRef", ParentRef);
	Query.Text = GetConstantsTextQuery();
	SelectionConstants = Query.Execute().Select();
	While SelectionConstants.Next() Do

		ConstantPack = XDTOFactory.Create(XDTOTypes.ConstantType); 
		FillPropertyValues(ConstantPack, SelectionConstants, "Code, Description, IndexNum, UseDefaults");
		ConstantPack.ID = SelectionConstants.Constant.UUID();
		ConstantPack.ValueType = GetSerializedValueXDTO(SelectionConstants.ValueType);
		ConstantPack.Value = GetValuePackage(XDTOTypes, SelectionConstants.ConstantValue);
		
		// set up defaults
		If SelectionConstants.UseDefaults Then
			ConstantPack.DefaultsRef = GetRefPackage(XDTOTypes, SelectionConstants.Defaults);
		EndIf;

		// set links
		ConstantPack.Links =  GetLinksPackage(XDTOTypes, SelectionConstants.Constant); 
		
		ConstantsListPack.Constant.Add(ConstantPack);
	EndDo;
	
	Return ConstantsListPack; 
	
EndFunction // GetConstantsPackage()

Function GetResultsPackage(XDTOTypes, SourceRef)

	ResultsListPack = XDTOFactory.Create(XDTOTypes.ResultsListType); 
	Query = New Query;
	Query.SetParameter("SourceRef", SourceRef);
	Query.Text = GetResultsTextQuery();
	SelectionResults = Query.Execute().Select();
	While SelectionResults.Next() Do
		ResultPack = XDTOFactory.Create(XDTOTypes.ResultType); 
		FillPropertyValues(ResultPack, SelectionResults, "Code, Description, IndexNum, IsScript");
		ResultPack.ID = SelectionResults.Result.UUID();
		// set fields 
		ResultPack.Fields = GetFieldsPackage(XDTOTypes, SelectionResults.Result); 
		// set functions
		ResultPack.Functions = GetFunctionsPackage(XDTOTypes, SelectionResults.Result); 
		// set constants
		ResultPack.Constants = GetConstantsPackage(XDTOTypes, SelectionResults.Result); 
		// set list
		ResultsListPack.Result.Add(ResultPack);
	EndDo;

	Return ResultsListPack; 

EndFunction // GetResultsPackage()

Function GetDefaultsPackage(XDTOTypes, ParentRef)

	DefaultsPack = Undefined;
	
	Query = New Query;
	Query.SetParameter("ParentRef", ParentRef);
	Query.Text = GetDefaultsTextQuery();
	SelectionDefaults = Query.Execute().Select();
	If SelectionDefaults.Next() Then
		DefaultsPack = XDTOFactory.Create(XDTOTypes.DefaultsType); 
		FillPropertyValues(DefaultsPack, SelectionDefaults, "Code, Description");
		DefaultsPack.ID = SelectionDefaults.Defaults.UUID();
		// set fields 
		DefaultsPack.Fields = GetFieldsPackage(XDTOTypes, SelectionDefaults.Defaults); 
		// set functions
		DefaultsPack.Functions = GetFunctionsPackage(XDTOTypes, SelectionDefaults.Defaults); 
		// set constants
		DefaultsPack.Constants = GetConstantsPackage(XDTOTypes, SelectionDefaults.Defaults); 
	EndIf;

	Return DefaultsPack;
	
EndFunction // GetDefaultsPackage()

Function GetSourcePackage(XDTOTypes, SourceRef)

	// set package
  	SourcePack = XDTOFactory.Create(XDTOTypes.SourceType);
	SourceStructure = velpo_CommonFunctions.ObjectAttributeValues(SourceRef, "Code, Description, Parent, SourceText, IndexNum, IsScript");  
	FillPropertyValues(SourcePack, SourceStructure, "Code, Description, SourceText, IndexNum, IsScript");
	SourcePack.ID = SourceRef.UUID();
	
	// set group
	If ValueIsFilled(SourceStructure.Parent) Then
		SourcePack.GroupRef = GetRefPackage(XDTOTypes, SourceStructure.Parent);
	EndIf;
		
	// set parameters
	SourcePack.SourceParameters = GetSourceParametersPackage(XDTOTypes, SourceRef);
	
	// set source results
	SourcePack.SourceResults = GetSourceResultsPackage(XDTOTypes, SourceRef);

	// set defaults 
	SourcePack.Defaults = GetDefaultsPackage(XDTOTypes, SourceRef);

	// set entry points
	SourcePack.EntryPointsRefs = GetEntryPointsRefsPackage(XDTOTypes, SourceRef);
	
	// set results
	SourcePack.Results = GetResultsPackage(XDTOTypes, SourceRef);
	
	Return SourcePack;
	
EndFunction // GetSourcePackage()

Function GetGroupPackage(XDTOTypes, ParentRef, GroupsArray)

	GroupStructure = velpo_CommonFunctions.ObjectAttributeValues(ParentRef, "Code, Description");  
		
	GroupPack = XDTOFactory.Create(XDTOTypes.GroupType);
	FillPropertyValues(GroupPack, GroupStructure, "Code, Description");
		
	// set id and froup
	GroupPack.ID = ParentRef.UUID();
	GroupPack.Groups =  GetGroupsPackage(XDTOTypes, ParentRef, GroupsArray); 
		
	// set defaults 
	GroupPack.Defaults = GetDefaultsPackage(XDTOTypes, ParentRef);

	Return GroupPack;
		
EndFunction // GetGroupPackage()

Function GetGroupsPackage(XDTOTypes, ParentRef, GroupsArray)
	
	GroupListPack = XDTOFactory.Create(XDTOTypes.GroupListType); 
	
	Query = New Query;
	Query.SetParameter("ParentRef", ParentRef);
	Query.SetParameter("GroupsArray", GroupsArray);
	Query.Text = GetGroupsTextQuery();
	SelectionGroups = Query.Execute().Select();
	
	While SelectionGroups.Next() Do
		GroupListPack.Group.Add(GetGroupPackage(XDTOTypes, SelectionGroups.Ref, GroupsArray))
	EndDo;

	Return GroupListPack; 
	
EndFunction // GetGroupsPackage()

Function SetGroupsBySource(Ref, GroupsArray)
	
	ParentRef = velpo_CommonFunctions.ObjectAttributeValue(Ref, "Parent");  
	If ValueIsFilled(ParentRef) Then
		If  GroupsArray.Find(ParentRef) = Undefined Then
			GroupsArray.Add(ParentRef);
			SetGroupsBySource(ParentRef, GroupsArray);
		EndIf;
	EndIf;
	
EndFunction // SetGroupsBySource()

#EndRegion

#Region PutingUtilityFunctions

Function GetPackageRef(Pack, Manager = Undefined, Parent = Undefined, Owner = Undefined, GetByRef = True)
	
	Ref = Undefined;
	
	If Pack = Undefined Then
		Return Ref;
	EndIf;
	
	PropertiesPack = Pack.Properties(); 
	
	If Manager = Undefined And PropertiesPack.Get("SerializedValue") <> Undefined Then
		Try
			Manager = Eval(Pack.Type + "." + Pack.TypeName);
		Except
			Return GetUnSerializedValueXDTO(Pack.SerializedValue); 
		EndTry;
	EndIf;
		
	If PropertiesPack.Get("Type") <> Undefined And Pack.Type = velpo_CommonFunctions.TypeNameEnums() Then
		Try
			Ref = Manager[Pack.ValueName];
		Except
			Ref = GetUnSerializedValueXDTO(Pack.SerializedValue); 
		EndTry;
	Else
		
		If Ref = Undefined And PropertiesPack.Get("PredefinedName") <> Undefined And ValueIsFilled(Pack.PredefinedName) Then
			Try
				Ref = Manager[Pack.PredefinedName];
			Except
			EndTry;
		EndIf;
		
		If Ref = Undefined And PropertiesPack.Get("Name") <> Undefined And ValueIsFilled(Pack.Name) Then
			If Owner = Undefined Then 
				Ref = Manager.FindByAttribute("Name", Pack.Name, Parent);
			Else
				Ref = Manager.FindByAttribute("Name", Pack.Name, Parent, Owner);
			EndIf;
			If Ref =  Manager.EmptyRef() Then
				Ref = Undefined;
			EndIf;
		EndIf;
		
		If Ref = Undefined And PropertiesPack.Get("Code") <> Undefined And ValueIsFilled(Pack.Code) Then
			If Owner = Undefined Then
				Ref = Manager.FindByCode(Pack.Code, Parent);
			Else
				Ref = Manager.FindByCode(Pack.Code,, Parent, Owner);
			EndIf;
			If Ref =  Manager.EmptyRef() Then
				Ref = Undefined;
			EndIf;
		EndIf;
		
		If Ref= Undefined And GetByRef Then
			Ref = Manager.GetRef(New UUID(Pack.ID));
		EndIf;
		
	EndIf;
	               
	Return Ref;

EndFunction // GetPackageRef()

Function GetPackageObj(Pack, Manager = Undefined, IsGroup = Undefined, Parent = Undefined, Owner = Undefined)
	
	If Manager = Undefined Then
		Manager = Eval(Pack.Type + "." + Pack.Name);
	EndIf;
	
	Ref = GetPackageRef(Pack, Manager, Parent, Owner, False);
		
	If Ref = Undefined Then
		Ref = Manager.GetRef(New UUID(Pack.ID));
		Obj = Ref.GetObject();
		If Obj = Undefined Then
			If  IsGroup = Undefined OR IsGroup = False Then
				Obj = Manager.CreateItem();
			Else
				Obj = Manager.CreateFolder();
			EndIf;
			Obj.SetNewObjectRef(Ref);
		EndIf;
	Else
		Obj = Ref.GetObject();
		If IsGroup <> Undefined AND Obj.IsFolder <> IsGroup Then
			Obj.Delete();
			Obj  = GetPackageObj(Pack, Manager, IsGroup, Parent);
		EndIf;
	EndIf;
	               
	Return Obj;

EndFunction // GetPackageObj()

Function GetPackageVal(Pack)
	
	If Pack = Undefined Then
		Return Undefined;
	EndIf;
	
	If Pack.Type  = "Ref"  Then
		Return GetPackageRef(Pack.ValueRef);
	ElsIf Pack.Type  = "String" Then
		Return Pack.ValueString;
	ElsIf Pack.Type  = "Date" Then
		Return Pack.ValueDate;
	ElsIf Pack.Type  = "Number" Then
		Return Pack.ValueNumber;
	ElsIf Pack.Type  = "Boolean" Then
		Return Pack.ValueBoolean;
	Else
		Return Undefined;
	EndIf;
	
EndFunction

Function GetConceptRef(Pack)
	
	Manager = ChartsOfAccounts.velpo_Reporting;
	Ref = Undefined;
	
	AxisTypeArray = New Array;
	
	AxisTypesPack = Pack.AxisTypes;
	If AxisTypesPack <> Undefined Then
		For Each AxisTypeRef In AxisTypesPack.AxisTypeRef Do
			AxisTypeArray.Add(GetPackageRef(AxisTypeRef, ChartsOfCharacteristicTypes.velpo_HypercubeAxes));
		EndDo; 
	EndIf;
		
	Select = Manager.Select(, New Structure("Name", Pack.Name));
	While Select.Next() Do
		If Pack.IsGroup And Select.IsGroup Then
			Ref = Select.Ref;
			Break;
		ElsIf Select.IsGroup = Pack.IsGroup And Select.ExtDimensionCount = Pack.AxisTypesCount Then
			DimensionsArray = New Array;
			// check dimensions
			Query = New Query;
			Query.SetParameter("ConceptRef", Select.Ref);
			Query.Text = GetConceptAxisTypesTextQuery();
			SelectionDimensions = Query.Execute().Select();
			While SelectionDimensions.Next() Do
				DimensionsArray.Add(SelectionDimensions.AxisType);
			EndDo;
			// check if they are the same
			If velpo_CommonFunctionsClientServer.ValueListsEqual(AxisTypeArray, DimensionsArray) THen
				Ref = Select.Ref;
				Break;
			EndIf;
		EndIf;	
	EndDo;
	
	If Ref = Undefined Then
		Ref = Manager.GetRef(New UUID(Pack.ID));
	EndIf;
	               
	Return Ref;

EndFunction // GetPackageRef()

Function GetUnSerializedValueXDTO(Value)

	Serializer = velpo_BusinessReportingCashed.GetXDTOSerializer();
	Try
		Return Serializer.ReadXDTO(Value);
	Except
		Return Undefined;
	EndTry;

EndFunction // GetTypeDescriptionXDTO()

Procedure PutLinksPackage(LinksPack, ComponentRef, ParentRef)
	
	// get link packs
	For Each LinkPack In LinksPack.Link Do
		
		// link
		LinkObj = GetPackageObj(LinkPack, Catalogs.velpo_FieldQueryLinks,,, ComponentRef);
		FillPropertyValues(LinkObj, LinkPack, "Code, UseSourceValue, UseFieldLink, UseTotals, Unique, NegativeSign, AxisSetNumber, Comments"); 
		LinkObj.LinkType = Enums.velpo_FieldQueryLinkTypes[LinkPack.Type];
		LinkObj.Owner = ComponentRef; 
		LinkObj.Result = ParentRef; 
		If LinkObj.UseFieldLink Then
			LinkObj.FieldLink =	GetPackageRef(LinkPack.FieldLinkRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, ParentRef);
		EndIf;
				
		// clear all
		LinkObj.AxisLinks.Clear();
		LinkObj.ConceptLinks.Clear();
		LinkObj.FieldFilters.Clear();
		LinkObj.UniqueFields.Clear();
		
		// set axis type or concept
		If LinkObj.LinkType = Enums.velpo_FieldQueryLinkTypes.AxisType Then
			
			// axis type
			LinkObj.AxisType = GetPackageRef(LinkPack.AxisTypeRef, ChartsOfCharacteristicTypes.velpo_HypercubeAxes);
			
			// set AxisLinks
			AxisLinksPack = LinkPack.AxisLinks;
			If AxisLinksPack  <> Undefined Then
				For Each AxisLinkPack In AxisLinksPack.AxisLink Do
					AxisLinkLine = LinkObj.AxisLinks.Add();					
					AxisLinkLine.Otherwise = AxisLinkPack.Otherwise;
					AxisLinkLine.FieldValue = GetPackageVal(AxisLinkPack.FieldValue);
					AxisPack = AxisLinkPack.Axis;
					AxisValueType = Enums._DEL_AxisValueTypes[AxisPack.Type];
					AxisLinkLine.Axis = Catalogs.AxisMembers.GetAxis(LinkObj.AxisType, GetPackageVal(AxisPack.Value)); 
				EndDo; 
			EndIf;
		Else                                                    
			
			// concept
			LinkObj.Concept = GetConceptRef(LinkPack.Concept);
			LinkObj.DataType = velpo_CommonFunctions.ObjectAttributeValue(LinkObj.Concept, "DataType");
			
			// set ConceptLinks
			ConceptLinksPack = LinkPack.ConceptLinks;
			If ConceptLinksPack <> Undefined Then
				For Each ConceptLinkPack In ConceptLinksPack.ConceptLink Do
					ConceptLinkLine = LinkObj.ConceptLinks.Add();					
					ConceptLinkLine.Otherwise = ConceptLinkPack.Otherwise;
					ConceptLinkLine.FieldValue = GetPackageVal(ConceptLinkPack.FieldValue);
					ConceptLinkLine.Value = GetPackageVal(ConceptLinkPack.Value);
				EndDo; 
			EndIf;

		EndIf;
		
		// set filters
		FieldFiltersPack = LinkPack.FieldFilters;
		If FieldFiltersPack <> Undefined Then
			For Each FieldFilterPack In FieldFiltersPack.FieldFilter Do
				FieldFilterLine = LinkObj.FieldFilters.Add();					
				FieldFilterLine.FilterType = Enums.velpo_FilterQueryTypes[FieldFilterPack.Type];
				FieldFilterLine.Field = GetPackageRef(FieldFilterPack.FieldRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, ParentRef);
				FieldFilterLine.ComparisonType = Enums.velpo_ComparisonQueryTypes[FieldFilterPack.ComparisonType];
				FieldFilterLine.Value = GetPackageVal(FieldFilterPack.Value);
			EndDo; 
		EndIf;
		
		// set unique fields
		UniqueFieldsPack = LinkPack.UniqueFields;
		If UniqueFieldsPack <> Undefined Then
			UniqueFieldsTable = LinkObj.UniqueFields.UnloadColumns();
			UniqueFieldsTable.Columns.Add("LineNum", velpo_CommonFunctions.NumberTypeDescription(10));
			For Each UniqueFieldPack In UniqueFieldsPack.UniqueField Do
				UniqueFieldLine = UniqueFieldsTable.Add();
				UniqueFieldLine.LineNum = UniqueFieldPack.LineNum;
				UniqueFieldLine.Field = GetPackageRef(UniqueFieldPack.FieldRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, ParentRef);
			EndDo; 
			UniqueFieldsTable.Sort("LineNum ASC");
			LinkObj.UniqueFields.Load(UniqueFieldsTable);
		EndIf;

		LinkObj.DeletionMark = False;
		LinkObj.Write();
		
	EndDo;
		
EndProcedure
	
Procedure PutFieldsPackage(FieldsPack, ParentRef)
	
	// get field packs
	For Each FieldPack In FieldsPack.Field Do
		
		// field
		FieldObj = GetPackageObj(FieldPack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, False, ParentRef);
		FillPropertyValues(FieldObj, FieldPack, "Code, Description, IndexNum, UseDefaults"); 
		FieldObj.ComponentType = Enums.velpo_ComponetQueryTypes.Field;
		Try
			FieldObj.ValueType = GetUnSerializedValueXDTO(FieldPack.ValueType);
		Except
		EndTry;
		
		If FieldObj.UseDefaults And FieldPack.DefaultsRef <> Undefined Then
			FieldObj.Defaults = GetPackageRef(FieldPack.DefaultsRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents);			
		Else
			FieldObj.Defaults = Undefined;
		EndIf;
				
		FieldObj.Parent = ParentRef; 
		FieldObj.DeletionMark = False;
		FieldObj.Write();
		FieldRef = FieldObj.Ref;
		
		// set links
		LinksPack = FieldPack.Links;
		If LinksPack <> Undefined Then
			PutLinksPackage(LinksPack, FieldRef, ParentRef);	
		EndIf;
		
	EndDo;

EndProcedure

Procedure PutFunctionsPackage(FunctionsPack, ParentRef)
		
	// get function packs
	For Each FunctionPack In FunctionsPack.Function Do
		
		// function
		FunctionObj = GetPackageObj(FunctionPack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, False, ParentRef);
		FillPropertyValues(FunctionObj, FunctionPack, "Code, Description, SourceText, IndexNum, UseDefaults"); 
		FunctionObj.ComponentType = Enums.velpo_ComponetQueryTypes.Function;
		Try
			FunctionObj.ValueType = GetUnSerializedValueXDTO(FunctionPack.ValueType);
		Except
		EndTry;
		
		If FunctionObj.UseDefaults And FunctionsPack.DefaultsRef <> Undefined Then
			FunctionObj.Defaults = GetPackageRef(FunctionsPack.DefaultsRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents);			
		Else
			FunctionObj.Defaults = Undefined;
		EndIf;

		FunctionObj.Parent = ParentRef;
		FunctionObj.DeletionMark = False;
		
		// set fields
		FunctionObj.FunctionFields.Clear();
		FieldRefsPack = FunctionPack.FieldRefs;
		If FieldRefsPack <> Undefined Then
			For Each FieldRefPack In FieldRefsPack.Ref Do
				FunctionFieldLine = FunctionObj.FunctionFields.Add();
				FunctionFieldLine.Field = GetPackageRef(FieldRefPack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, ParentRef);
			EndDo; 
		EndIf;
		FunctionObj.Write();
		FunctionRef = FunctionObj.Ref;
				
		// set links
		LinksPack = FunctionPack.Links;
		If LinksPack <> Undefined Then
			PutLinksPackage(LinksPack, FunctionRef, ParentRef);	
		EndIf;
		
	EndDo;

EndProcedure

Procedure PutConstantsPackage(ConstantsPack, ParentRef)
		
	// get constants pack
	For Each ConstantPack In ConstantsPack.Constant Do
		
		// constant
		ConstantObj = GetPackageObj(ConstantPack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, False, ParentRef);
		FillPropertyValues(ConstantObj, ConstantPack, "Code, Description, IndexNum, UseDefaults"); 
		ConstantObj.ComponentType = Enums.velpo_ComponetQueryTypes.Constant;
		Try
			ConstantObj.ValueType = GetUnSerializedValueXDTO(ConstantPack.ValueType);
		Except
		EndTry;
		ConstantObj.ConstantValue = GetPackageVal(ConstantPack.Value);
		ConstantObj.Parent = ParentRef;
		ConstantObj.DeletionMark = False;
		
		If ConstantObj.UseDefaults And ConstantPack.DefaultsRef <> Undefined Then
			ConstantObj.Defaults = GetPackageRef(ConstantPack.DefaultsRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents);			
		Else
			ConstantObj.Defaults = Undefined;
		EndIf;

		ConstantObj.Write();
		ConstantRef = ConstantObj.Ref;
				
		// set links
		LinksPack = ConstantPack.Links;
		If LinksPack <> Undefined Then
			PutLinksPackage(LinksPack, ConstantRef, ParentRef);	
		EndIf;
		
	EndDo;

EndProcedure

Procedure PutDefaultsPackage(DefaultsPack, ParentRef)
	
	If DefaultsPack = Undefined Then
		Return;
	EndIf;
	
	// defaults
	DefaultsObj = GetPackageObj(DefaultsPack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, True, ParentRef);
	FillPropertyValues(DefaultsObj, DefaultsPack, "Code, Description"); 
	DefaultsObj.ComponentType = Enums.velpo_ComponetQueryTypes.Defaults;
	DefaultsObj.Parent = ParentRef; 
	DefaultsObj.DeletionMark = False;
	DefaultsObj.Write();
	DefaultsRef = DefaultsObj.Ref;
	
	// set fields
	FieldsPack = DefaultsPack.Fields;
	If FieldsPack <> Undefined Then
		PutFieldsPackage(FieldsPack, DefaultsRef);
	EndIf;
		
	// set functions
	FunctionsPack = DefaultsPack.Functions;
	If FunctionsPack <> Undefined Then
		PutFunctionsPackage(FunctionsPack, DefaultsRef);
	EndIf;
	
	// set constants
	ConstantsPack = DefaultsPack.Constants;
	If ConstantsPack <> Undefined Then
		PutConstantsPackage(ConstantsPack, DefaultsRef);
	EndIf;
		
EndProcedure

Procedure PutGroupsPackage(GroupsPack, ParentRef)
	
	If GroupsPack = Undefined Then
		Return;
	EndIf;
	
	For Each GroupPack In GroupsPack.Group Do
		
		GroupObj = GetPackageObj(GroupPack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, True, ParentRef);
		FillPropertyValues(GroupObj, GroupPack, "Code, Description"); 
		
		GroupObj.ComponentType = Enums.velpo_ComponetQueryTypes.Group;
		GroupObj.Parent = ParentRef; 
		GroupObj.DeletionMark = False;
		GroupObj.Write();
		
		GroupRef = GroupObj.Ref;
		
		PutDefaultsPackage(GroupPack.Defaults, GroupRef);
		PutGroupsPackage(GroupPack.Groups, GroupRef);
		
	EndDo; 
		
EndProcedure

Procedure PutResultsPackage(ResultsPack, SourceRef)

	// get result packs
	For Each ResultPack In ResultsPack.Result Do
		
		// result
		ResultObj = GetPackageObj(ResultPack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, True, SourceRef);
		FillPropertyValues(ResultObj, ResultPack, "Code, Description, IndexNum, IsScript"); 
		ResultObj.ComponentType = Enums.velpo_ComponetQueryTypes.Result;
		ResultObj.Parent = SourceRef; 
		ResultObj.DeletionMark = False;
		ResultObj.Write();
		ResultRef = ResultObj.Ref;
		
		// set fields
		FieldsPack = ResultPack.Fields;
		If FieldsPack <> Undefined Then
			PutFieldsPackage(FieldsPack, ResultRef);
		EndIf;
		
		// set functions
		FunctionsPack = ResultPack.Functions;
		If FunctionsPack <> Undefined Then
			PutFunctionsPackage(FunctionsPack, ResultRef);
		EndIf;
		
		// set constants
		ConstantsPack = ResultPack.Constants;
		If ConstantsPack <> Undefined Then
			PutConstantsPackage(ConstantsPack, ResultRef);
		EndIf;
		
	EndDo; 
		
EndProcedure

Procedure PutSourcePackage(SourcePack)

	// find by code and ID ans fill it
	SourceObj = GetPackageObj(SourcePack, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, True);
	
	// set main
	FillPropertyValues(SourceObj, SourcePack, "Code, Description, IndexNum, IsScript, SourceText"); 
	SourceObj.ComponentType = Enums.velpo_ComponetQueryTypes.Source;
	
	// set group
	SourceObj.Parent = GetPackageRef(SourcePack.GroupRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents);
	
	// set source results
	SourceObj.SourceResults.Clear();
	ResultsPack = SourcePack.SourceResults;
	If ResultsPack <> Undefined Then
		For Each ResultPack In ResultsPack.Result Do
			ResultsLine = SourceObj.SourceResults.Add();
			ResultsLine.Result = GetPackageRef(ResultPack.ResultRef, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents, SourceObj.Parent);	
			ResultsLine.Name = ResultPack.Name;
		EndDo; 
	EndIf;
	
	// set parameters
	SourceObj.SourceParameters.Clear();
	ParametersPack = SourcePack.SourceParameters;
	If  ParametersPack <> Undefined Then
		For Each ParameterPack In ParametersPack.Parameter  Do
			ParameterObj = GetPackageObj(ParameterPack, ChartsOfCharacteristicTypes.velpo_UserDefinedParameters);
			FillPropertyValues(ParameterObj, ParameterPack, "Code, Description, UseList");
			Try
				ParameterObj.ValueType = GetUnSerializedValueXDTO(ParameterPack.ValueType);
			Except
			EndTry;
			ParameterObj.Values.Clear();
			For Each Value In ParameterPack.Values.Value Do
				ValueLine = ParameterObj.Values.Add();
				ValueLine.Value = Value;
			EndDo; 
			ParameterObj.Write();
			ParametersLine = SourceObj.SourceParameters.Add();
			ParametersLine.Parameter = ParameterObj.Ref;
		EndDo; 		
	EndIf;
	
	// set entry points
	SourceObj.EntryPoints.Clear();
	EntryPointsRefsPack = SourcePack.EntryPointsRefs;
	If  EntryPointsRefsPack <> Undefined Then
		For Each EntryPointsRefPack In EntryPointsRefsPack.Ref  Do
			EntryPointRef = GetPackageRef(EntryPointsRefPack, Catalogs.velpo_EntryPoints);
			If EntryPointRef <> Undefined Then
				EntryPointsLine = SourceObj.EntryPoints.Add();
				EntryPointsLine.EntryPoint = EntryPointRef;
			EndIf;
		EndDo;
	EndIf;
	
	// set it
	SourceObj.Write();
	SourceRef = SourceObj.Ref;
	
	// set deletion mark
	ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.SetDeletionMarkForItems(SourceRef);
	
	// put defaults
	PutDefaultsPackage(SourcePack.Defaults, SourceRef);
	
	// put results	
	PutResultsPackage(SourcePack.Results, SourceRef);	

EndProcedure

#EndRegion

#Region MainFunctions

Function GetSourceValueList() Export
	
	ResultValueList = New ValueList;
	
	Query = New Query;
	Query.Text = GetSourceTextQuery();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ResultValueList.Add(Selection.Ref, Selection.Description, True);
	EndDo;
	
	Return ResultValueList; 
			
EndFunction

Function GetSettingsData(SourceArray) Export

	TmpFilePath = GetTempFileName("xml");
	
	XDTOTypes = New Structure;
	// get all names
	Package = XDTOFactory.Packages.Get("http://velpo.com/fa_xbrl/source-query-components-settings");
	For each PackageType In Package Do
		XDTOTypes.Insert(PackageType.Name, PackageType);
	EndDo;  
	
	SourceListType = Package.RootProperties.Get("SourceList").Type;  
	SourceListPack = XDTOFactory.Create(SourceListType);
	
	// check if need to set up global defaults
	If CheckGlobalDefaults(SourceArray) Then
		SourceListPack.Defaults = GetDefaultsPackage(XDTOTypes, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.EmptyRef());
	EndIf;
	
	// get each package
	GroupsArray = New Array;
	For Each SourceRef In SourceArray Do
		// get source
		SourceListPack.Source.Add(GetSourcePackage(XDTOTypes, SourceRef));	
		// get all groups
		SetGroupsBySource(SourceRef, GroupsArray);
	EndDo; 
	
	// get groups
	SourceListPack.Groups = GetGroupsPackage(XDTOTypes, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.EmptyRef(), GroupsArray);
	
	// set version
	SourceListPack.Version = Package.RootProperties.Get("Version").DefaultValue.Value;
	
	// get text
	Writer = New XMLWriter;
	Writer.OpenFile(TmpFilePath, "UTF-8");
	XDTOFactory.WriteXML(Writer, SourceListPack, "SourceList",,XMLForm.Element);
	Writer.Close();
	
	BinaryData = New BinaryData(TmpFilePath); 
	Return PutToTempStorage(BinaryData);
	
EndFunction // GetSettingsData()

Procedure PutSettingData(Location) Export
	
	// set file
	TempFileName = GetTempFileName("xml");
	BData = GetFromTempStorage(Location);
	BData.Записать(TempFileName);
	
	Reader = New XMLReader;
	Reader.OpenFile(TempFileName);
	
	Package = XDTOFactory.Packages.Get("http://velpo.com/fa_xbrl/source-query-components-settings");
	SourceListType = Package.RootProperties.Get("SourceList").Type;
	SourceList = XDTOFactory.ReadXML(Reader, SourceListType);
	
	BeginTransaction();
	
	PutDefaultsPackage(SourceList.Defaults, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.EmptyRef());
	
	PutGroupsPackage(SourceList.Groups, ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.EmptyRef());
	
	For Each SourcePack In SourceList.Source Do
		PutSourcePackage(SourcePack);
	EndDo;  
	 	
	CommitTransaction();
	
	Reader.Close();

EndProcedure // PutSettingData()

#EndRegion

#EndIf