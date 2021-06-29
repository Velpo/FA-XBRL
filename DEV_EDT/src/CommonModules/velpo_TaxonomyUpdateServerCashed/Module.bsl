///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
// Copyright (c) 2018, Velpo (Paul Tarasov)
//
// Subsystem:  Taxonomy Update
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region InterfaceProceduresAndFunctions

// Get / or \
//
//
Function GetOpositeSeparator()  Export

	LocalSeparator = GetClientPathSeparator();	

	Return ?(LocalSeparator ="/", "\", "/");
	
EndFunction // GetOpositeSeparator()

//  Get base attribs taxonomy
//
Function GetTaxonomyPackageAttribs() Export

	Return "Identifier,Name,Description,LicenseHref,LicenseName,PublicationDate,Publisher,PublisherCountry,PublisherURL,Version";   

EndFunction // GetTaxonomyPackageAttribs()

//  Get base attribs entry point
//
Function GetEntryPointAttribs() Export

	Return "Owner,Name,Description,Hrefs,Version,Language,RoleTypes,RoleTables";

EndFunction // GetEntryPointAttribs()

#EndRegion

#Region XDTOObjects

// XSD URi
//
Function GetXSDURi() Export
	
	Return "http://www.w3.org/2001/XMLSchema";
	
EndFunction

// Package URi
//
Function GetTaxonomyPackageURi() Export
	
	Return "http://xbrl.org/2016/taxonomy-package";
	
EndFunction

// Linkbase URi
//
Function GetLinkbaseURi() Export
	
	Return "http://www.xbrl.org/2003/linkbase";
	
EndFunction

// Linkbase URi
//
Function GetGenericURi() Export
	
	Return "http://velpo.com/generic";
	
EndFunction

// Catalog URi
//
Function GetCatalogURi() Export
	
	Return "urn:oasis:names:tc:entity:xmlns:xml:catalog";
	
EndFunction

//  XSD element Type
//
Function GetXSDElementType() Export
	
	Return XDTOFactory.Packages.Get(GetXSDURi()).RootProperties.Get("element").Type;
	
EndFunction

//  Package Type
//
Function GetTaxonomyPackageType() Export
	
	Return XDTOFactory.Type(GetTaxonomyPackageURi(), "taxonomyPackageType");
	
EndFunction

// Get linkbaseref type
//
Function LinkbaseRefType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("linkbaseRef").Type;
	
EndFunction // LinkbaseRef()

// Get roleType type
//
Function LinkbaseRoleType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("roleType").Type;
	
EndFunction // LinkbaseRef()

// Get roleRef type
//
Function RoleRefType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("roleRef").Type;
	
EndFunction // RoleRefType()

// Get arcroleRef type
//
Function ArcroleRefType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("arcroleRef").Type;
	
EndFunction // ArcroleRefType()

// Get definitionLink type
//
Function DefinitionLinkType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("definitionLink").Type;
	
EndFunction // DefinitionLinkType()

// Get presentationLink type
//
Function PresentationLinkType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("presentationLink").Type;
	
EndFunction // PresentationLink()

// Get calculationLink type
//
Function CalculationLinkType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("calculationLink").Type;
	
EndFunction // PresentationLink()

// Get footnoteLink type
//
Function FootnoteLinkType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("footnoteLink").Type;
	
EndFunction // FootnoteLinkType()

// Get referenceLink type
//
Function ReferenceLinkType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("referenceLink").Type;
	
EndFunction // ReferenceLinkType()

// Get labelLink type
//
Function LabelLinkType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("labelLink").Type;
	
EndFunction // LabelLinkType()

// Get labelLink type
//
Function GenLinkType() Export

	Return XDTOFactory.Packages.Get(GetGenericURi()).RootProperties.Get("link").Type;
	
EndFunction // GenLinkType()

//  Catalog Type
//
Function GetCatalogType() Export
	
	Return XDTOFactory.Type(GetCatalogURi(), "catalog");
	
EndFunction

// Get linkbaseref type
//
Function ArcroleType() Export

	Return XDTOFactory.Packages.Get(GetLinkbaseURi()).RootProperties.Get("arcroleType").Type;
	
EndFunction // LinkbaseRef()

#EndRegion

#Region URis

// <Function description>
//
//
// Parameters:
//  <Parameter1>  - <Type.Subtype> - <parameter description>
//                 <parameter description continued>
//  <Parameter2>  - <Type.Subtype> - <parameter description>
//                 <parameter description continued>
//
// Returns:
//   <Type.Subtype>   - <returned value description>
//
Function IsEnum(T)

	

EndFunction // IsEnum()

	
#EndRegion 

#Region SaveData

Function GetGenLinkStructureByLoc(GenLinkName) Export

	GenLinkArray = velpo_TaxonomyUpdateClientServerCached.GetGenLinkArray();
	For Each GenLink In GenLinkArray Do
		If 	GenLink.Loc = GenLinkName Then
			Return GenLink;
		EndIf;
	EndDo; 
	
	Return Undefined;

EndFunction // GetGenLinkStructureByLoc()

 

Function GetGenLinkArray() Export

	GenLinkArray= New Array;
	
	// severty
	GenLinkArray.Add(New Structure("Loc, TypeName", "error", "SeverityTypes"));
	GenLinkArray.Add(New Structure("Loc, TypeName", "warning", "SeverityTypes"));
	GenLinkArray.Add(New Structure("Loc, TypeName", "ok", "SeverityTypes"));
	
	// value asserations
	GenLinkArray.Add(New Structure("Loc, TypeName, AssertionFormulaType, SetExtAttribs", "valueAssertion", "AssertionFormulaDefinitions", PredefinedValue("Enum.AssertionFormulaTypes.ValueAssertion"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, AssertionFormulaType, SetExtAttribs", "existenceAssertion","AssertionFormulaDefinitions", PredefinedValue("Enum.AssertionFormulaTypes.ExistenceAssertion"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, AssertionFormulaType, SetExtAttribs", "consistencyAssertion", "AssertionFormulaDefinitions", PredefinedValue("Enum.AssertionFormulaTypes.ConsistencyAssertion"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, AssertionFormulaType, SetExtAttribs", "formula", "AssertionFormulaDefinitions", PredefinedValue("Enum.AssertionFormulaTypes.Formula"), True));
	
	// tables
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "table", "RoleTables", False));
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "breakdown", "Breakdowns", False));
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "aspectNode", "DefinitionNodes", True));
	GenLinkArray.Add(New Structure("Loc, TypeName, NodeType, SetExtAttribs", "conceptRelationshipNode", "DefinitionNodes", PredefinedValue("Enum.DefinitionNodeTypes.ConceptRelationship"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, NodeType, SetExtAttribs", "dimensionRelationshipNode", "DefinitionNodes", PredefinedValue("Enum.DefinitionNodeTypes.DimensionRelationship"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, NodeType, SetExtAttribs", "ruleNode", "DefinitionNodes", PredefinedValue("Enum.DefinitionNodeTypes.Rule"), True));
		
	// addtional data
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "function", "FunctionDefinitions", False));
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "equalityDefinition", "EqualityDefinitions", False));
	GenLinkArray.Add(New Structure("Loc, TypeName, VariableType, SetExtAttribs", "factVariable", "VaribleDefinitions",  PredefinedValue("Enum.VariableTypes.Fact"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, VariableType, SetExtAttribs", "generalVariable", "VaribleDefinitions",  PredefinedValue("Enum.VariableTypes.General"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "parameter", "ParameterDefinitions", False));
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "precondition", "PreconditionDefinitions", False));
	// TODO filters
			  
	// filters
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "aspectCover", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.AspectCover"), False));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "andFilter", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.andFilter"), False));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "orFilter", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.orFilter"), False));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "conceptName", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.ConceptName"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "conceptRelation", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.ConceptRelation"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "explicitDimension", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.ExplicitDimension"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "typedDimension", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.TypedDimension"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "general", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.General"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "matchConcept", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.MatchConcept"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "matchDimension", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.MatchDimension"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "periodStart", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.PeriodStart"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "periodStart", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.PeriodStart"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "periodEnd", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.PeriodEnd"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "periodInstant", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.PeriodInstant"), True));
	GenLinkArray.Add(New Structure("Loc, TypeName, FilterType, SetExtAttribs", "instantDuration", "FilterDefinitions",  PredefinedValue("Enum.FilterTypes.InstantDuration"), True));
	
	// links
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "message", "MessageLinks", False));
	GenLinkArray.Add(New Structure("Loc, TypeName, SetExtAttribs", "label", "LabelLinks", False));
	
	Return GenLinkArray;

EndFunction // GetGenLinkArray()

Function GetGenArcArray() Export

	GenArcArray= New Array;
	GenArcArray.Add("arc");
			GenArcArray.Add("tableBreakdownArc");
			GenArcArray.Add("breakdownTreeArc");
			GenArcArray.Add("definitionNodeSubtreeArc");
			GenArcArray.Add("tableParameterArc");
			GenArcArray.Add("variableArc");
			GenArcArray.Add("variableFilterArc");
			GenArcArray.Add("variableSetFilterArc");
			
			Return GenArcArray


EndFunction // GetGenLinkArray()


Function GetSeverityTypesMap() Export

	SeverityTypesMap = New Map;
	SeverityTypesMap.Insert("warning", PredefinedValue("Enum.SeverityTypes.Warning"));
	SeverityTypesMap.Insert("ok", PredefinedValue("Enum.SeverityTypes.OK"));
	SeverityTypesMap.Insert("error", PredefinedValue("Enum.SeverityTypes.Error"));
	
	Return SeverityTypesMap;

EndFunction // SeverityTypesMap()

Function GetAllTypes() Export

	Return Metadata.ChartsOfCharacteristicTypes.velpo_ValueDataTypes.Type;

EndFunction // GetAllTypes()

 

#EndRegion 

