///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
// Copyright (c) 2018, Velpo (Paul Tarasov)
//
// Subsystem:  Taxonomy Update
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Common

//  Check if enum
//
Function IsEnum(Type)
		
	Return (Type <> Undefined And Type.NamespaceURI = "http://xbrl.org/2014/extensible-enumerations" And Type.LocalName = "enumerationItemType");

EndFunction // IsEnum()

//  Check if Hypercube
//
Function IsHypercube(SubstitutionGroup)
	
	Return (SubstitutionGroup <> Undefined And SubstitutionGroup.NamespaceURI = "http://xbrl.org/2005/xbrldt" And SubstitutionGroup.LocalName = "hypercubeItem");

EndFunction // IsHypercube()

//  Check if Axis
//
Function IsAxis(SubstitutionGroup)
	
	Return (SubstitutionGroup <> Undefined And SubstitutionGroup.NamespaceURI = "http://xbrl.org/2005/xbrldt" And SubstitutionGroup.LocalName = "dimensionItem");

EndFunction // IsHypercube()

//  Check if Domain maember
//
Function IsMember(Type)
	
	Return (Type <> Undefined And type.NamespaceURI = "http://www.xbrl.org/dtr/type/non-numeric" And type.LocalName = "domainItemType");

EndFunction // IsHypercube()

#EndRegion

#Region Import

// Check if filename is local
//
Function IsLocalXMLFile(FilePath)

	Return (FindFiles(FilePath).Count() > 0);
	
EndFunction // IsLocalXMLFile()

// Check href
//
Function IsHrefXMLPath(FilePath)

	Return (StrFind(FilePath, "#") > 0);

EndFunction // IsHrefXMLPath()

// Check if path is web
//
Function IsWebXMLPath(FilePath)
	
	Return (StrStartsWith(FilePath, "http://") Or StrStartsWith(FilePath, "https://"));
	
EndFunction // IsWebXMLPath()

// Change  ../ in FilePath with source dir
//
//
// Parameters:
//  FilePath  - String - file path with ../ 
//  SourceDirectoryPath  - String - current source
//
// Returns:
//   String   - corrent local path
//
Function GetLocalDirectoryPath(RootVar, Val LocalPath, Val SourcePath)
	
	If  StrStartsWith(LocalPath, SourcePath) Then
		Return LocalPath;
	EndIf;
	
	If  IsWebXMLPath(LocalPath)  Then
		Return GetLocalSourceFile(RootVar, LocalPath);
	Else
		LocalSeparator = GetClientPathSeparator();
		LocalPath = GetNormalizedPathWithSeporator(LocalPath);
		FilePathArray = velpo_StringFunctionsClientServer.SplitStringIntoSubstringArray(LocalPath, LocalSeparator, True);
		// file
		If  FilePathArray.Count() <=1 Then
			Return SourcePath	+ LocalPath;
		// path
		Else
			SourceDirectoryPathArray = velpo_StringFunctionsClientServer.SplitStringIntoSubstringArray(SourcePath, LocalSeparator, True);
			UpLevelCount = 0;
			
			EndFilePath = "";
			For Each SubFilePath In FilePathArray Do
				If SubFilePath = ".." Then
					UpLevelCount = UpLevelCount + 1;	
				Else
					EndFilePath = EndFilePath + LocalSeparator + SubFilePath;
				EndIf;
			EndDo;
			// no parents
			If UpLevelCount = 0 Then
				Return SourcePath	+ LocalPath;
			Else
				If  StrEndsWith(LocalPath, LocalSeparator) Then
					EndFilePath = EndFilePath + LocalSeparator;
				EndIf;
				IndexCount = SourceDirectoryPathArray.UBound() - UpLevelCount; 
				ResultFilePath = "";
				For Index = 0 To IndexCount Do
					ResultFilePath = ResultFilePath + ?(IsBlankString(ResultFilePath), "", LocalSeparator) + SourceDirectoryPathArray[Index];
				EndDo; 
				// rewrite
				Return ResultFilePath + EndFilePath;	
			EndIf;
		EndIf;
	EndIf;
	
EndFunction // GetLocalDirectoryPath()

//  Get normalized path according to seporator
//
Function GetNormalizedPathWithSeporator(Path)
	
	If  IsWebXMLPath(Path) Then
		Return Path;
	Else
		OpositeSeporator = velpo_TaxonomyUpdateClientServerCached.GetOpositeSeparator();
		Return StrReplace(Path, OpositeSeporator, GetClientPathSeparator()); 
	EndIf;

EndFunction // GetNormolizedStringWithSeporator()

//  Get local rewrite path
//
// SchemaLocation - string  - path to XML/XSD
//  SourceDirectoryPath  - String - current source
// RewritePrefixMap - Map - catalog rewrite pathes
//
// Returns:
//   String   - path to XML/XSD
//
Function GetRewritePath(RootVar, Val SourcePath)
	
	For Each rewrite In RootVar.RewritePrefix Do
		If StrStartsWith(SourcePath, rewrite.Key)  Then
			ReturnPath =  StrReplace(SourcePath, rewrite.Key, rewrite.Value);
			Return GetNormalizedPathWithSeporator(ReturnPath);
		EndIf;
	EndDo; 
	
	//If  StrStartsWith(SourcePath, "http://www.") Then
	//	Return GetRewritePath(RootVar, StrReplace(SourcePath, "http://www.", "http://"));
	//Else
		Return SourcePath;
	//EndIf;

EndFunction // GetLocalReWiritePath()

//  Get all varibles for import
//
//
Function GetTaxonomyVariable(TaxonomyStructure, EntryPointsArray, Val SourcePath)

	RootVar = New Structure;
	RootVar.Insert("Taxonomy", velpo_CommonFunctionsClientServer.CopyStructure(TaxonomyStructure));
	RootVar.Insert("EntryPoints", velpo_CommonFunctionsClientServer.CopyArray(EntryPointsArray));
	RootVar.Insert("Path", SourcePath);
	RootVar.Insert("SchemaLocations", New Map);
	RootVar.Insert("RoleRefs",  New Map);
	RootVar.Insert("QNames", New Map);
	RootVar.Insert("Schemas",  New Map);
	RootVar.Insert("ArcroleTypes",  New Map);
	RootVar.Insert("RoleTypes",  New Map);
	RootVar.Insert("Elements",  New Map);
	RootVar.Insert("Linkbases",  New Map);
	RootVar.Insert("DefaultRoles",  New Map);
	RootVar.Insert("LinkHrefs",  New Map);
	RootVar.Insert("SeverityHrefs",  New Map);
	RootVar.Insert("LanguageRefs",  New Map);
	RootVar.Insert("TaxonomyRef",  Undefined);
				
	Return RootVar;

EndFunction // GetTaxonomyVariables()

//  Get all varibles for import
//
//
Function GetSchemaVariable(TargetNamespace, SchemaNamespace, Val SourcePath, Val Href)

	SchemaVar = New Structure;
	SchemaVar.Insert("TargetNamespace",  TargetNamespace);
	SchemaVar.Insert("SchemaNamespace",  SchemaNamespace);
	SchemaVar.Insert("Path",  SourcePath);
	SchemaVar.Insert("Href",  Href);
	SchemaVar.Insert("Schemas",  New Map);
	SchemaVar.Insert("Linkbases",  New Map);
	SchemaVar.Insert("RoleTypes",  New Map);
	SchemaVar.Insert("Elements",  New Map);
	
	Return SchemaVar;

EndFunction // GetTaxonomyVariables()

//  Get all varibles for import
//
//
Function GetLinkbaseVariable(SchemaNamespace, Val SourcePath, Val Href)

	LinkbaseVar = New Structure;
	LinkbaseVar.Insert("SchemaNamespace",  SchemaNamespace);
	LinkbaseVar.Insert("Path",  SourcePath);
	LinkbaseVar.Insert("Href",  Href);
	LinkbaseVar.Insert("RoleRefs",  New Map);
	LinkbaseVar.Insert("ArcroleRefs",  New Map);
	LinkbaseVar.Insert("DefinitionLinks",  New Map);
	LinkbaseVar.Insert("PresentationLinks",  New Map);
	LinkbaseVar.Insert("CalculationLinks",  New Map);
	LinkbaseVar.Insert("FootnoteLinks",  New Map);
	LinkbaseVar.Insert("LabelLinks",  New Map);
	LinkbaseVar.Insert("ReferenceLinks",  New Map);
	LinkbaseVar.Insert("GenLinks",  New Map);
	LinkbaseVar.Insert("IsDone",  False);
	LinkbaseVar.Insert("IsOverried",  False);
	
	Return LinkbaseVar;

EndFunction // GetTaxonomyVariables()

//  Get all varibles for Link role
//
//
Function GetLinkroleVariable()

	LinkRoleVar = New Structure;
	LinkRoleVar.Insert("XDTOObject",  Undefined);
	LinkRoleVar.Insert("IsDone",  False);
	LinkRoleVar.Insert("IsOverried",  False);
	
	Return LinkRoleVar;

EndFunction // GetTaxonomyVariables()

//  Check rewrite path and return XML/XSD
//
// SchemaLocation - string  - path to XML/XSD
//  SourceDirectoryPath  - String - current source
// RewritePrefixMap - Map - catalog rewrite pathes
//
// Returns:
//   String   - path to XML/XSD
//
Function GetLocalSourceFile(RootVar, Val SourcePath)
	
	// check rewrite
	FilePath = GetRewritePath(RootVar, SourcePath);
	// href
	If IsHrefXMLPath(FilePath) Then
		Return FilePath;
	// check local file
	ElsIf IsLocalXMLFile(FilePath) Then
		Return FilePath;
	Else
		FilePath = SourcePath;
	EndIf;
	// check web
	If FilePath = SourcePath And IsWebXMLPath(SourcePath) Then
		XMLFileStructure = velpo_GetFilesFromInternet.DownloadFileAtServer(SourcePath);
		If XMLFileStructure.Status Then 
			FilePath = XMLFileStructure.Path;
			RootVar.RewritePrefix.Insert(SourcePath, FilePath);
		EndIf;
	EndIf;
	Return FilePath;
	
EndFunction // GetLocalSourceFile()

// Main Taxonomy import function.
//
Function ImportEntryPoints(RootVar, ErrorsOccurredOnImport = False)
	
	// iteration for each entry point
	For Each EntryPoint In RootVar.EntryPoints Do
		EntryPoint.Insert("Schemas",  New Map);
		// iteration for EP XSD
		For Each SchemaLocation In EntryPoint.Hrefs Do
			// set schema
			SourceFilePath= GetLocalSourceFile(RootVar, SchemaLocation);
			SchemaData = GetSchemaData(RootVar, SourceFilePath);
			EntryPoint.Schemas.Insert(SchemaLocation, SchemaData);
		EndDo; 
	EndDo; 
		
EndFunction

// Get prefix by namespace
//
Function GetElementQName(RootVar, SchemaComponent, SchemaData)

	Prefix = SchemaData.SchemaNamespace[SchemaComponent.NamespaceURI];
	If Prefix = Undefined Then
		Prefix = "";
	EndIf;
	
	Return Prefix  + ":" + SchemaComponent.Name;
	
EndFunction // GetPrefixByNamespace()

//  Get namespace
//
Function GetNamespace(DOMElement, TargetNamespace = "")
	
	SchemaNamespace = New Map;
	// namespace prefix
	AttributeCollections = DOMElement.Attributes;
	For Each SchemaAttrib In AttributeCollections Do
		If SchemaAttrib.Prefix = "xmlns" Then
			SchemaNamespace.Insert(SchemaAttrib.Value, SchemaAttrib.LocalName); 			
		ElsIf SchemaAttrib.NodeName = "targetNamespace" Then
			TargetNamespace = SchemaAttrib.Value;
		EndIf;
	EndDo; 

	Return SchemaNamespace;
	
EndFunction // GetNameSpace()

// Set all data from XSD
//
Function GetSchemaData(RootVar, SourceFilePath)
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(SourceFilePath);
	
	DOMBuilder = Новый DOMBuilder;
	DocumentDOM = DOMBuilder.Read(XMLReader);
	
	XMLSchemaBuilder = Новый XMLSchemaBuilder;
	SchemaObject = XMLSchemaBuilder.CreateXMLSchema(DocumentDOM);

	SchemaFile = New File(SourceFilePath);
	SchemaLocation = SchemaFile.Path;
	
	TargetNamespace = "";
	SchemaNamespace = GetNamespace(DocumentDOM.DocumentElement, TargetNamespace);
	
	// check if we've got it
	SchemaData = RootVar.Schemas[SourceFilePath];
	If  SchemaData <> Undefined Then
		Return 	SchemaData;
	EndIf;
	
	// schema
	SchemaData = GetSchemaVariable(TargetNamespace, 
																				SchemaNamespace, 
																				SchemaLocation,
																				SourceFilePath);
			
	// components
	For Each SchemaComponent In SchemaObject.Components Do
		// annotation
		If SchemaComponent.ComponentType = XSComponentType.Annotation Then 
			If SchemaComponent.AppInfos <> Undefined And SchemaComponent.AppInfos.Count() > 0 Then
				For Each AppInfo In SchemaComponent.AppInfos Do
					AppInfosChildNodes = AppInfo.DOMElement.ChildNodes;
					For Each AppInfosNode In AppInfosChildNodes Do
						NodeReader = New DOMNodeReader;
						NodeReader.Open(AppInfosNode);
						If AppInfosNode.LocalName = "arcroleType" Then
							XDTOArcroleType = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.ArcroleType());
							RootVar.ArcroleTypes.Insert(SourceFilePath + "#" + XDTOArcroleType.id, XDTOArcroleType);
						ElsIf AppInfosNode.LocalName = "linkbaseRef" Then
							XDTOLinkbaseRef = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.LinkbaseRefType());
							LinkbasePath = GetLocalDirectoryPath(RootVar, XDTOLinkbaseRef.href, SchemaLocation);
							SchemaData.Linkbases.Insert(LinkbasePath, GetLinkbaseData(RootVar, LinkbasePath));
						ElsIf AppInfosNode.LocalName = "roleType" Then
							XDTORoleType = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.LinkbaseRoleType());
							RoleTypeData = New Structure("XDTOObject", XDTORoleType);
							RootVar.RoleTypes.Insert(SourceFilePath + "#" + XDTORoleType.id, RoleTypeData); 
							SchemaData.RoleTypes.Insert(SourceFilePath + "#" + XDTORoleType.id, RoleTypeData); 
						EndIf;
					EndDo; 					
				EndDo; 
			EndIf;
		// import
		ElsIf SchemaComponent.ComponentType = XSComponentType.Import Then
			ChildSchemaLocation = GetLocalDirectoryPath(RootVar, SchemaComponent.SchemaLocation, SchemaLocation);
			SchemaData.Schemas.Insert(ChildSchemaLocation, GetSchemaData(RootVar, ChildSchemaLocation));
		// element
		ElsIf SchemaComponent.ComponentType = XSComponentType.ElementDeclaration Then
			ChildElementData = GetSchemaElement(RootVar, SchemaComponent, SchemaData, SourceFilePath);
			SchemaData.Elements.Insert(SchemaComponent.Name, ChildElementData);
		EndIf;
	EndDo; 
	
	// add to root
	RootVar.Schemas.Insert(SourceFilePath, SchemaData); 
	RootVar.SchemaLocations.Insert(TargetNamespace, SourceFilePath); 
	
	Return SchemaData;
	
EndFunction //GetSchemaData()

// Get import component schema
//
Function GetLinkbaseData(RootVar, SourceFilePath)
	
	LinkbaseData = RootVar.Linkbases[SourceFilePath];
	If  LinkbaseData <> Undefined Then
		Return LinkbaseData;
	EndIf;
	
	XMLReader = New XMLReader;
	XMLReader.OpenFile(SourceFilePath);

	XMLFile = New File(SourceFilePath);
	XMLLocation = XMLFile.Path;
	
	DOMBuilder = Новый DOMBuilder;
	DocumentDOM = DOMBuilder.Read(XMLReader);

	SchemaNamespace = GetNamespace(DocumentDOM.DocumentElement);
	LinkbaseData = GetLinkbaseVariable(SchemaNamespace, XMLLocation, SourceFilePath);

	// iterate each node
	For Each LinkNode In DocumentDOM.DocumentElement.ChildNodes Do
		
		NodeReader = New DOMNodeReader;
		NodeReader.Open(LinkNode);
		
		Try
			If LinkNode.LocalName = "roleRef" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.RoleRefType());	
				LinkbaseData.RoleRefs.Insert(LinkroleStructure.XDTOObject.roleURI, LinkroleStructure);
				RootVar.RoleRefs.Insert(LinkroleStructure.XDTOObject.roleURI, LinkroleStructure);
			ElsIf LinkNode.LocalName = "arcroleRef" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.ArcroleRefType());	
				LinkbaseData.ArcroleRefs.Insert(LinkroleStructure.XDTOObject.arcroleURI, LinkroleStructure);
			ElsIf LinkNode.LocalName = "definitionLink" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.DefinitionLinkType());	
				LinkbaseData.DefinitionLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
			ElsIf LinkNode.LocalName = "presentationLink" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.PresentationLinkType());	
				LinkbaseData.PresentationLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
			ElsIf LinkNode.LocalName = "calculationLink" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.CalculationLinkType());	
				LinkbaseData.CalculationLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
			ElsIf LinkNode.LocalName = "footnoteLink" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.FootnoteLinkType());	
				LinkbaseData.FootnoteLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
			ElsIf LinkNode.LocalName = "referenceLink" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.ReferenceLinkType());	
				LinkbaseData.ReferenceLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
			ElsIf LinkNode.LocalName = "labelLink" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.LabelLinkType());	
				LinkbaseData.LabelLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
			ElsIf LinkNode.LocalName = "link" Then
				LinkroleStructure = GetLinkroleVariable();
				LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.GenLinkType());	
				LinkbaseData.GenLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
			EndIf;
		Except
			LinkroleStructure = GetLinkroleVariable();
			LinkroleStructure.XDTOObject = XDTOFactory.ReadXML(NodeReader);	
			LinkbaseData.GenLinks.Insert(LinkroleStructure.XDTOObject.role, LinkroleStructure);
		EndTry;
		
	EndDo; 
	
	// add to root
	RootVar.Linkbases.Insert(SourceFilePath, LinkbaseData); 
		 	
	Return LinkbaseData;
	
EndFunction // GetSchemaImport()

// Get import component schema
//
Function GetSchemaElement(RootVar, SchemaComponent, SchemaData, SourceFilePath)
	
	NodeReader = New DOMNodeReader;
	NodeReader.Open(SchemaComponent.DOMElement);
		
	XDTOElement = XDTOFactory.ReadXML(NodeReader, velpo_TaxonomyUpdateClientServerCached.GetXSDElementType());
				
	Href = SourceFilePath + "#" + XDTOElement.id;
	
	// check if we've got it
	ElementData = RootVar.Elements[Href];
	If  ElementData <> Undefined Then
		Return ElementData;
	EndIf;
	
	NamespaceURI = SchemaComponent.NamespaceURI;
	QNameFull = SchemaComponent.NamespaceURI + ":" + SchemaComponent.Name;
	QName = GetElementQName(RootVar, SchemaComponent, SchemaData);
	
	ElementData = New Structure("XDTOObject, Typename, NamespaceURI, QName", XDTOElement, "Element", NamespaceURI, QName);
	
	// add to root
	RootVar.Elements.Insert(Href, ElementData); 
	RootVar.QNames.Insert(QNameFull, Href); 
	RootVar.QNames.Insert(QName, Href); 
	
	Return ElementData;
	
EndFunction // GetSchemaImport()

// Set catalogs for rewrite
//
Procedure SetRewriteCatalogs(RootVar)

	// get catalog.xml to rewritePrefix
	RewritePrefixMap = New Map;	
	RootVar.Insert("RewritePrefix", RewritePrefixMap);
	
	CatalogFileArray = FindFiles(RootVar.Path, "catalog.xml", True);
	
	If CatalogFileArray.Count() > 0 Then
		
		CatalogFile = CatalogFileArray[0];
		
		ReaderStream = New XMLReader();
		ReaderStream.OpenFile(CatalogFile.FullName);

		CatalogPackage = XDTOFactory.ReadXML(ReaderStream, velpo_TaxonomyUpdateClientServerCached.GetCatalogType());
		
		For Each rewriteURI In CatalogPackage.rewriteURI Do
			RewritePrefixMap.Insert(rewriteURI.uriStartString,  GetLocalDirectoryPath(RootVar, rewriteURI.rewritePrefix, CatalogFile.Path));
		EndDo; 
		
	EndIf;
		
EndProcedure // SetRewriteCatalogs()

#EndRegion

#Region Save

// Get elementRef by type
//
Function GetElementDataByHref(RootVar, Href)
	
	Return RootVar.Elements[Href];
	
EndFunction

// Get Href by Qname 
//
//
Function GetElementDataByQName(RootVar, QName)
	
	Return GetElementDataByHref(RootVar, RootVar.QNames[QName]);
	
EndFunction // GetHrefByQName()

// Get Hypercube ref
//
Function GetHypercubeRef(RootVar, Href, ElementData)
	
	Ref = Undefined;
	If ElementData.Property("HypercubeRef", Ref) Then
		Return Ref;
	EndIf;
	
	XDTOElement = ElementData.XDTOObject;

	Hyper = ChartsOfCharacteristicTypes.velpo_HypercubeAxes.CreateFolder();
	Hyper.Description = XDTOElement.Name;
	Hyper.Name = XDTOElement.Name;
	Hyper.HypercudeAxisType = Enums.velpo_HypercubeAxisTypes.Hypercube;
	Hyper.Write();
	Ref = Hyper.Ref;
	
	SetLinkByHref(RootVar, Href, "Element", XDTOElement, ElementData, Ref);
	
	ElementData.Insert("HypercubeRef", Ref);
	
	Return Ref;

EndFunction //  GetElementRef(ElementData)()

// Get Axis ref
//
Function  GetAxisRef(RootVar, Href, ElementData)
	
	Ref = Undefined;
	If ElementData.Property("AxisRef", Ref) Then
		Return Ref;
	EndIf;
	
	XDTOElement = ElementData.XDTOObject;
	
	Hyper = ChartsOfCharacteristicTypes.velpo_HypercubeAxes.CreateItem();
	FillPropertyValues(Hyper, ElementData);
	Hyper.Name = XDTOElement.Name;
	
	TestStructure = New Structure("typedDomainRef");
	FillPropertyValues(TestStructure, XDTOElement);
	
	If	TestStructure.typedDomainRef = Undefined Then
		Hyper.HypercudeAxisType = Enums.velpo_HypercubeAxisTypes.ExplicitDimension;
		Hyper.DataType = GetDataTypeRef(RootVar, Href, ElementData, True);
	Else
		Hyper.HypercudeAxisType = Enums.velpo_HypercubeAxisTypes.TypedDimension;
		ValueDataHref = StrSplit(Href, "#", False)[0] + TestStructure.typedDomainRef;
		ValueData = GetElementDataByHref(RootVar, ValueDataHref);
		Hyper.DataType = GetDataTypeRef(RootVar, ValueDataHref, ValueData);
	EndIf;
	
	Hyper.Write();
	Ref = Hyper.Ref;

	SetLinkByHref(RootVar, Href, "Element", XDTOElement, ElementData, Ref);
		
	ElementData.Insert("AxisRef", Ref);
	
	Return Ref;
	
EndFunction //  GetElementRef(ElementData)()

// Get Member ref
//
Function  GetMemberRef(RootVar, Href, ElementData)
	
	Ref = Undefined;
	If ElementData.Property("MemberRef", Ref) Then
		Return Ref;
	EndIf;
	
	XDTOElement = ElementData.XDTOObject;

	Hyper = Catalogs.velpo_MemberValues.CreateItem();
	FillPropertyValues(Hyper, ElementData);
	Hyper.Name = XDTOElement.Name;
	Hyper.Write();
	Ref = Hyper.Ref;
	
	SetLinkByHref(RootVar, Href, "Element",  XDTOElement, ElementData, Ref);
	
	ElementData.Insert("MemberRef", Ref);
	
	Return Ref;

EndFunction //  GetElementRef(ElementData)()

// Get tValueData ref
//
Function  GetDataTypeRef(RootVar, Href, ElementData, IsAxis = False)
	
	Ref = Undefined;
	
	If ElementData.Property("DataTypeRef", Ref) Then
		Return Ref;
	EndIf;	
		
	XDTOElement = ElementData.XDTOObject;

	Hyper = ChartsOfCharacteristicTypes.velpo_ValueDataTypes.CreateItem();
	FillPropertyValues(Hyper, ElementData);
	FillPropertyValues(Hyper, XDTOElement);
	Hyper.Description = XDTOElement.Id;
	Hyper.Name = XDTOElement.Name;
	
	If XDTOElement.Type = Undefined Then
		Type = Undefined;
		If XDTOElement.simpleType <> Undefined Then
			Type = XDTOElement.simpleType.restriction.base.LocalName;
			If XDTOElement.simpleType.restriction.pattern.Count() > 0 Then
				Hyper.Pattern = XDTOElement.simpleType.restriction.pattern[0].value;
			EndIf; 
		EndIf;
		If XDTOElement.complexType <> Undefined Then
			Type = XDTOElement.complexType.simpleContent.restriction.base.LocalName;
			If XDTOElement.complexType.simpleContent.restriction.pattern.Count() > 0 Then
				Hyper.Pattern = XDTOElement.complexType.simpleContent.restriction.pattern[0].value;
			EndIf;
		EndIf;
		If Type = Undefined Then
			Hyper.BaseType = Enums.velpo_BaseDataTypes.anyType;
		Else
			Hyper.BaseType = Enums.velpo_BaseDataTypes[Type];	
		EndIf;
	Else
		Type = XDTOElement.Type.LocalName;	
		Hyper.BaseType = Enums.velpo_BaseDataTypes[XDTOElement.Type.LocalName];	
	EndIf;
	
	If Type = "enumerationItemType" Or IsAxis Then
		СValueType = New TypeDescription("CatalogRef.velpo_MemberValues");
	ElsIf Type = "percentItemType" OR  Type = "perShareItemType" Then
		СValueType = velpo_CommonFunctions.NumberTypeDescription(6, 4);
	ElsIf Type = "decimalItemType" Or Type = "floatItemType" Or Type = "float" Then
		СValueType = velpo_CommonFunctions.NumberTypeDescription(26, 6);
	ElsIf Type = "intItemType" OR Type = "integerItemType" Or Type = "int" OR Type = "integer"  Then
		СValueType = velpo_CommonFunctions.NumberTypeDescription(17, 0);
	ElsIf Type = "monetaryItemType" Then
		СValueType = velpo_CommonFunctions.NumberTypeDescription(17, 2);
	ElsIf Type = "sharesItemType" Then
		СValueType = velpo_CommonFunctions.NumberTypeDescription(17, 4);
	ElsIf Type = "dateItemType" OR Type = "date" Then
		СValueType = velpo_CommonFunctions.DateTypeDescription(DateFractions.Date);
	ElsIf Type = "dateTimeItemType" Or Type = "dateTime" Then
		СValueType = velpo_CommonFunctions.DateTypeDescription(DateFractions.DateTime);
	ElsIf Type = "timeItemType" Or Type = "time" Then
		СValueType = velpo_CommonFunctions.DateTypeDescription(DateFractions.Time);
	Else
		СValueType = New TypeDescription("String");
	EndIf;
	
	Hyper.ValueType = 	СValueType;
	
	Hyper.Write();
	Ref = Hyper.Ref;
	
	If Type ="enumerationItemType" Then
		RoleRef = RootVar.RoleRefs[XDTOElement.linkrole];
		SplitArray = StrSplit(Href, "#", True);
		LocalPath = SplitArray[0];
		SplitArray = StrSplit(RoleRef.XDTOObject.href, "#", True);
		IdPath = SplitArray[1];
		
		Record = InformationRegisters.velpo_EnumLinks.CreateRecordManager();
		Record.Owner = Ref;
		Record.Taxonomy = RootVar.TaxonomyRef;
		Record.RoleType = RootVar.RoleTypes[LocalPath + "#" + IdPath].Ref;
		
		DomainData = GetElementDataByQName(RootVar, XDTOElement.domain);
		Record.Concept = GetConceptRef(RootVar, RootVar.QNames[XDTOElement.domain], DomainData);
		Record.Write(True);
	EndIf;

	ElementData.Insert("DataTypeRef", Ref);
	
	Return Ref;

EndFunction //  GetElementRef(ElementData)()

// Get Concept ref
//
Function GetConceptRef(RootVar, Href, ElementData)
	
	Ref = Undefined;
	If ElementData.Property("ConceptRef", Ref) Then
		Return Ref;
	EndIf;
	
	XDTOElement = ElementData.XDTOObject;
	
	Hyper = ChartsOfAccounts.velpo_Reporting.CreateAccount();
	FillPropertyValues(Hyper, ElementData);
	Hyper.Code = XDTOElement.Name;
	Hyper.Name = XDTOElement.Name;
	Hyper.IsAbstract = (XDTOElement.abstract);
	Hyper.IsNillable = (XDTOElement.Nillable);
	Hyper.DataType = GetDataTypeRef(RootVar, Href, ElementData);
	
	ValueDataType = velpo_CommonFunctions.ObjectAttributeValue(Hyper.DataType, "BaseType");
  	        
	If ValueDataType = Enums.velpo_BaseDataTypes.MonetaryItemType
		Or ValueDataType = Enums.velpo_BaseDataTypes.Integer
		Or ValueDataType = Enums.velpo_BaseDataTypes.IntegerItemType
		Or ValueDataType = Enums.velpo_BaseDataTypes.Int
		Or ValueDataType = Enums.velpo_BaseDataTypes.IntItemType
		Or ValueDataType = Enums.velpo_BaseDataTypes.Decimal
		Or ValueDataType = Enums.velpo_BaseDataTypes.DateTimeItemType
		Or ValueDataType = Enums.velpo_BaseDataTypes.Float
		Or ValueDataType = Enums.velpo_BaseDataTypes.FloatItemType
		Or ValueDataType = Enums.velpo_BaseDataTypes.SharesItemType
		Then
		Hyper.ConceptType = Enums.velpo_ConceptTypes.Measure;
	Else
		Hyper.ConceptType = Enums.velpo_ConceptTypes.Info;
	EndIf;
		
	Hyper.TurnoversOnly  = (XDTOElement.periodType = "duration");
	
	Hyper.Write();
	Ref = Hyper.Ref;
	
	SetLinkByHref(RootVar, Href, "Element", XDTOElement, ElementData, Ref);
		
	ElementData.Insert("ConceptRef", Ref);
	
	Return Ref;      

EndFunction //  GetElementRef(ElementData)()

// Get Element  ref
//
Function  GetElementRef(RootVar, Href, ElementData)
	
	Return GetConceptRef(RootVar, Href, ElementData);

EndFunction //  GetElementRef(ElementData)()

// Translat Loc to map with override
//
Function GetLocatorMap(RootVar, XDTOObject, LocNames, LinkbaseStructure)
	
	LocatorMap = New Map;
	
	LocArray = StrSplit(LocNames, ",", False);
	
	For Each LocName In LocArray Do
		XDTOList =  XDTOObject[LocName];
		If XDTOList = Undefined Then
			Continue;
		EndIf;
		For Each XDTOLoc In XDTOList Do
			LocatorMap.Insert(XDTOLoc.Label, OverrideHref(RootVar, XDTOLoc, LinkbaseStructure));
		EndDo; 
	EndDo;
	
	Return LocatorMap;

EndFunction // GetLocatorMap()

// Make arc tree
//
//
Function GetLinkbaseArcTree(RootVar, XDTOObject, ArcNames, LinkbaseStructure, AddProperties = False)
	
	StringType = New TypeDescription("String");
	DecimalType = velpo_CommonFunctions.NumberTypeDescription(10, 2); 
	IntType = velpo_CommonFunctions.NumberTypeDescription(10, 0); 
	BooleanType = New TypeDescription("Boolean");
	
	ArcTree = New ValueTree;
	ArcTree.Columns.Add("ArcNode");
	ArcTree.Columns.Add("NodeRef");
	ArcTree.Columns.Add("NodeOwnerRef");
	ArcTree.Columns.Add("Label", StringType);
	ArcTree.Columns.Add("Arcrole", StringType);
	ArcTree.Columns.Add("Title", StringType);
	ArcTree.Columns.Add("From", StringType);                                
	ArcTree.Columns.Add("To", StringType);
	ArcTree.Columns.Add("Order", DecimalType);
	ArcTree.Columns.Add("Priority", IntType);
	ArcTree.Columns.Add("ContextElement", StringType);
	ArcTree.Columns.Add("Closed", BooleanType);
	ArcTree.Columns.Add("Name", StringType);
	ArcTree.Columns.Add("Cover", BooleanType);
	ArcTree.Columns.Add("Complement", BooleanType);
	ArcTree.Columns.Add("IsDone", BooleanType);
	
	ArcCache = New Map;
	ArcArray = StrSplit(ArcNames, ",", False);
	
	For Each ArcName In ArcArray Do
		ArcName = TrimAll(ArcName);
		XDTOArc = XDTOObject[ArcName];
		If XDTOArc = Undefined Then
			Continue;
		EndIf;	
		
		For Each Arc In XDTOArc Do
			FromArray = ArcCache[Arc.from];
			If FromArray = Undefined Then
				FromNode = ArcTree.Rows.Add();
				FillPropertyValues(FromNode,Arc,, "Arcrole");
				FromNode.Label = Arc.from;
				FromNode.ArcNode = Arc;
				FromArray = New Array;
				FromArray.Add(FromNode);
				ArcCache.Insert(Arc.from, FromArray);
			EndIf;
			
			ToArray = ArcCache[Arc.to];
			If ToArray = Undefined Then
				ToArray = New Array;
				ArcCache.Insert(Arc.to, ToArray);
			EndIf;
			
			For Each Node In  FromArray Do
				ToNode = Node.Rows.Find(Arc.to, "Label", False);
				If ToNode = Undefined Then
					ToNode = Node.Rows.Add();
					FillPropertyValues(ToNode,Arc);
					ToNode.Label = Arc.to;
					ToNode.ArcNode = Arc;
					ToArray.Add(ToNode);
				EndIf;
			EndDo; 
			
		EndDo; 
	EndDo; 


	Return ArcTree;
	
EndFunction // GettLinkbaseArcTree()

//  Get all childs
//
//
Function GetChildArcsMap(ArcCache, Label)

	LabelsMap = New Map;
	NodeArray = ArcCache[Label];
	If NodeArray = Undefined Then
		Return LabelsMap;
	EndIf;
	For Each Node In NodeArray Do
		If Node.To <> Label Then
			LabelsMap.Insert(Node.To, Node);
		EndIf;
	EndDo; 

	Return LabelsMap;
	
EndFunction // GetArc()

//  Get all parents
//
//
Function GetParentArcsMap(ArcCache, Label)

	LabelsMap = New Map;
	NodeArray = ArcCache[Label];
	If NodeArray = Undefined Then
		Return LabelsMap;
	EndIf;
	For Each Node In NodeArray Do
		If Node.From <> Label Then
			LabelsMap.Insert(Node.From, Node);
		EndIf;
	EndDo; 
	
	Return LabelsMap;
	
EndFunction // GetArc()
 
// Get role type item from rolerefs and create a new default
//
//
Function GetRoleTypeByURi(RootVar, URi, LinkbaseStructure)
	
	RoleRef = LinkbaseStructure.RoleRefs[URi];
	// default
	If RoleRef = Undefined Then
		RoleTypeRef = RootVar.DefaultRoles[URi];
		If RoleTypeRef = Undefined Then
			RoleTypeStructure = Catalogs.velpo_RoleTypes.GetStructure();
			RoleTypeStructure.Name = URi;
			RoleTypeStructure.Description = URi;
			RoleTypeStructure.Owner = RootVar.TaxonomyRef;
			RoleTypeRef = Catalogs.velpo_RoleTypes.GetItem(RoleTypeStructure);
			RootVar.DefaultRoles.Insert(URi, RoleTypeRef); 
		EndIf;
		Return	RoleTypeRef;
	EndIf;
	
	// get by href
	Return  RootVar.RoleTypes[RoleRef.XDTOObject.href].Ref;

EndFunction // GetRoleTypeByUri()
	
// Overrides hrefwith SourcePath
//
Function OverrideHref(RootVar, XDTOObject, LinkbaseStructure)
	
	SplitArray = StrSplit(XDTOObject.Href, "#", True);
	LocalPath = SplitArray[0];
	If ValueIsFilled(LocalPath) Then
		LocalPath = GetLocalDirectoryPath(RootVar, LocalPath, LinkbaseStructure.Path);
		// check xsd                                   
		If  StrEndsWith(LocalPath, ".xsd") Then
			SchemaData = RootVar.Schemas[LocalPath];
			If SchemaData = Undefined Then
				SchemaData = GetSchemaData(RootVar, LocalPath);
				For Each Linkbase In SchemaData.Linkbases Do
					CreatePrimaryLinkbaseData(RootVar, Linkbase.Value);
				EndDo; 
			EndIf;
		Else
			LinkbaseData = RootVar.Linkbases[LocalPath];
			If LinkbaseData = Undefined Then
				CreatePrimaryLinkbaseData(RootVar, GetLinkbaseData(RootVar, LocalPath));
			EndIf;
		EndIf;	
		XDTOObject.Href = LocalPath + "#" + SplitArray[1];
	Else
		XDTOObject.Href = LinkbaseStructure.Href + XDTOObject.Href;
	EndIf;
		
	Return XDTOObject.Href;
	
EndFunction // OverrideHref()

// Set link to hrefs map
//
Procedure SetLinkByHref(RootVar, Href, URI, XDTOObject, TypeStructure, Ref = Undefined, Owner = Undefined, Parent = Undefined)
	
	RefsStructure = RootVar.LinkHrefs[Href];
	
	If RefsStructure = Undefined Then
		Refs = New Array;
		RefsStructure = velpo_CommonFunctionsClientServer.CopyStructure(TypeStructure);
		RefsStructure.Insert("Refs", Refs);
		RefsStructure.Insert("URI", URI);
		RefsStructure.Insert("XDTOObject", XDTOObject);
		RootVar.LinkHrefs.Insert(Href, RefsStructure);
	EndIf;
 	 
	If Ref <> Undefined Then
		RefsStructure.Refs.Add(New Structure("Ref, Owner, Parent", Ref, Owner, Parent));
	EndIf;
	
	RefsStructure.Insert("IsEmpty", (RefsStructure.Refs.Count() = 0));
		
EndProcedure // SetLinkByHref()

// Set refs to hrefs map
//
Procedure AddNewRefByHref(RootVar, Href, Ref, Owner = Undefined, Parent = Undefined)
	
	RefsStructure = RootVar.LinkHrefs[Href];
	RefsStructure.Refs.Add(New Structure("Ref, Owner, Parent", Ref, Owner, Parent));	
	RefsStructure.Insert("IsEmpty", False);
	
EndProcedure // SetLinkByHref()

// Override role map
//
Procedure OverrideLinkBaseRole(RootVar, RoleMap, LinkbaseStructure)
	
	For Each RoleLink In RoleMap Do
		RoleLinkStructure = RoleLink.Value;
		If RoleLinkStructure.IsOverried Then
			Continue;
		EndIf;
		XDTOObject = RoleLinkStructure.XDTOObject;
		OverrideHref(RootVar, XDTOObject, LinkbaseStructure);			
		RoleLinkStructure.IsOverried = True;
	EndDo;
	
EndProcedure // OverrideLinkBaseRole()

//  Makes root element
//
//
Procedure CreateTaxonomyElement(RootVar)

	RootVar.Insert("TaxonomyRef", Catalogs.velpo_Taxonomies.GetItem(RootVar.Taxonomy));
	
EndProcedure // CreateTaxonomyElement()

// Makes all role types and role tables
//
Procedure CreateRoleTypes(RootVar)

	For Each RoleType In RootVar.RoleTypes Do
		
		RoleTypeMap = RoleType.Value;
		
		XDTORoleType = RoleTypeMap.XDTOObject;
		RoleTypeStructure = Catalogs.velpo_RoleTypes.GetStructure();
		RoleTypeStructure.Name = XDTORoleType.roleURI;
		RoleTypeStructure.Description = ?(XDTORoleType.definition = Undefined, XDTORoleType.roleURI, XDTORoleType.definition);
		
		If Not ValueIsFilled(RoleTypeStructure.Description) Then
			RoleTypeStructure.Description = RoleType.Key;
		EndIf;
		
		RoleTypeStructure.Owner = RootVar.TaxonomyRef;
		RoleTypeMap.Insert("Ref", Catalogs.velpo_RoleTypes.GetItem(RoleTypeStructure));
					
	EndDo; 

EndProcedure // CreateRoleTypes()

//  Procedure creates a tree node
//
//
Procedure CreateTreeNode(RootVar, RoleTypeRef, ArcRow, TypeName)

	NodeObject = Catalogs["velpo_" + TypeName].CreateItem();
	FillPropertyValues(NodeObject, ArcRow);
	NodeObject.Owner = RoleTypeRef;
	If ArcRow.Parent <> Undefined Then
		NodeObject.Parent = ArcRow.Parent.Node;
	EndIf;
	NodeObject.Write();
	ArcRow.Node = NodeObject.Ref;
	
EndProcedure // CreateTreeNode()

#Region Definition

//  Makes definition data
//
Procedure AddDefinitionData(RootVar, RoleTypeRef, ArcTreeRow, LocatorMap, LinkbaseStructure)
	
	For Each ArcRow In ArcTreeRow.Rows Do
		Href = LocatorMap[ArcRow.Label];
		ElementData = GetElementDataByHref(RootVar, Href);
		// leaves
		If ArcRow.Parent <> Undefined Then
			FillPropertyValues(ArcRow, ArcRow.Parent, "Concept, Hypercube, Axis, Domain, OCCType, IsClosed, IsExcluded");
		EndIf;
		
		XDTOElement = ElementData.XDTOObject;		
		
		ArcRow.IsAlias = (ArcRow.Arcrole = "http://www.xbrl.org/2003/arcrole/essence-alias");
		ArcRow.IsSpecial = (ArcRow.Arcrole = "http://www.xbrl.org/2003/arcrole/general-special");
		ArcRow.IsSimilar = (ArcRow.Arcrole = "http://www.xbrl.org/2003/arcrole/similar-tuples");
		ArcRow.IsRequired = (ArcRow.Arcrole = "http://www.xbrl.org/2003/arcrole/requires-element");
		
		// check
		If IsHypercube(XDTOElement.SubstitutionGroup) Then
			ArcRow.OCCType = ?(ArcRow.ContextElement = "segment", Enums.velpo_OCCTypes.Segment,  Enums.velpo_OCCTypes.Scenario);
			ArcRow.IsClosed = ArcRow.Closed;
			ArcRow.IsExcluded = (ArcRow.Arcrole = "http://xbrl.org/int/dim/arcrole/notAll");
			ArcRow.Hypercube = GetHypercubeRef(RootVar, Href, ElementData);
			ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Hypercube;
		ElsIf IsAxis(XDTOElement.SubstitutionGroup) Then
			ArcRow.Axis = GetAxisRef(RootVar, Href, ElementData);
			ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Axis;
		ElsIf IsMember(XDTOElement.Type) OR  (ArcRow.Arcrole = "http://xbrl.org/int/dim/arcrole/dimension-domain") Then
			DomainMember = GetMemberRef(RootVar, Href, ElementData);
			ArcRow.IsDefault = (ArcRow.Arcrole = "http://xbrl.org/int/dim/arcrole/dimension-default");
			If ArcRow.IsDefault Then
				IndexStructure = New Structure("Concept, Hypercube, Axis, Domain");
				FillPropertyValues(IndexStructure, ArcRow);
				If ValueIsFilled(IndexStructure.Domain) Then
					IndexStructure.Insert("Member", DomainMember);
					TreeNodeType = Enums.velpo_TreeNodeTypes.Member;
				Else
					IndexStructure.Domain = DomainMember;
					TreeNodeType = Enums.velpo_TreeNodeTypes.Domain;
				EndIf;
				DefaultArray = ArcRow.Parent.Rows.FindRows(IndexStructure, True);
				If DefaultArray.Count() > 0 Then
					For Each NodeDefault In DefaultArray Do
						NodeDefault.IsDefault = True;
						NodeObj = NodeDefault.Node.GetObject();
						NodeObj.IsDefault = True;
						NodeObj.Write();
					EndDo; 
					// without adding
					Continue;
				Else
					ArcRow.TreeNodeType = TreeNodeType;
					FillPropertyValues(ArcRow, IndexStructure);
				EndIf;
			Else
				If (ArcRow.Arcrole = "http://xbrl.org/int/dim/arcrole/dimension-domain") Then
					ArcRow.Domain = DomainMember;
					ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Domain;
				Else
					ArcRow.Member = DomainMember;
					ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Member;
				EndIf;
			EndIf;
		Else // concept
			ArcRow.Concept = GetConceptRef(RootVar, Href, ElementData);
			ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Concept;
		EndIf;			
		// create node
		CreateTreeNode(RootVar, RoleTypeRef, ArcRow, "DefinitionTrees");
		// add child
		AddDefinitionData(RootVar, RoleTypeRef, ArcRow, LocatorMap, LinkbaseStructure);
	EndDo; 

EndProcedure // AddDefinitionData()

// Saves definition base data to db
//
Procedure CreateDefinitionData(RootVar, LinkRole, LinkbaseStructure)

	URi = LinkRole.Key;
	LinkRoleStructure = LinkRole.Value;
	
	If LinkRoleStructure.IsDone Then
		Return;
	EndIf;

	XDTOObject = LinkRoleStructure.XDTOObject;
	
	LocatorMap = GetLocatorMap(RootVar, XDTOObject, "loc", LinkbaseStructure); 
	ArcTree = GetLinkbaseArcTree(RootVar, XDTOObject, "definitionArc", LinkbaseStructure);

	LinkRoleStructure.IsOverried = True;
	
	StringType = New TypeDescription("String");
	BooleanType = New TypeDescription("Boolean");
	NodeType = New TypeDescription("CatalogRef.velpo_DefinitionTrees");
	TreeNodeTypes = New TypeDescription("EnumRef.velpo_TreeNodeTypes");
	ReportingRefType = New TypeDescription("ChartOfAccountsRef.velpo_Reporting");
	HypercubeAxesType = New TypeDescription("ChartOfCharacteristicTypesRef.velpo_HypercubeAxes");
	MembersValuesType = New TypeDescription("CatalogRef.velpo_MemberValues");
	OCCTypesType = New TypeDescription("EnumRef.velpo_OCCTypes");
	
	RoleTypeRef = GetRoleTypeByURi(RootVar, URi, LinkbaseStructure);
	RoleTypeObj = RoleTypeRef.GetObject();
	
	// add addtional columns
	ArcTree.Columns.Add("Node", NodeType);
	ArcTree.Columns.Add("TreeNodeType", TreeNodeTypes);
	ArcTree.Columns.Add("Concept", ReportingRefType);
	ArcTree.Columns.Add("Hypercube", HypercubeAxesType);
	ArcTree.Columns.Add("Axis", HypercubeAxesType);
	ArcTree.Columns.Add("Domain", MembersValuesType);
	ArcTree.Columns.Add("Member", MembersValuesType);
	ArcTree.Columns.Add("OCCType", OCCTypesType);
	ArcTree.Columns.Add("IsClosed", BooleanType);
	ArcTree.Columns.Add("IsDefault", BooleanType);
	ArcTree.Columns.Add("IsExcluded", BooleanType);
	ArcTree.Columns.Add("IsAlias", BooleanType);
	ArcTree.Columns.Add("IsSpecial", BooleanType);
	ArcTree.Columns.Add("IsSimilar", BooleanType);
	ArcTree.Columns.Add("IsRequired", BooleanType);

	AddDefinitionData(RootVar, RoleTypeRef, ArcTree, LocatorMap, LinkbaseStructure);
	
	RoleTypeObj.Write();
	
	 LinkRoleStructure.IsDone = True;
	 
EndProcedure

// Makes definition
//
Procedure CreateDefinitionLinkbase(RootVar, LinkbaseStructure)
	
	LinkRoleMap = LinkbaseStructure.DefinitionLinks;
	For Each LinkRole In LinkRoleMap Do
		CreateDefinitionData(RootVar, LinkRole, LinkbaseStructure);
	EndDo; 
	
EndProcedure // CreateDefinitionLinkbase()

#EndRegion 

#Region Presentation

//  Makes definition data
//
Procedure AddPresentationData(RootVar, RoleTypeRef, ArcTreeRow, LocatorMap, LinkbaseStructure)
	
	For Each ArcRow In ArcTreeRow.Rows Do
		Href = LocatorMap[ArcRow.Label];
		ElementData = GetElementDataByHref(RootVar, Href);
		// leaves
		If ArcRow.Parent <> Undefined Then
			FillPropertyValues(ArcRow, ArcRow.Parent, "Concept, Hypercube, Axis, Domain");
		EndIf;
		XDTOElement = ElementData.XDTOObject;	
		// check
		If IsHypercube(XDTOElement.SubstitutionGroup) Then
			ArcRow.Hypercube = GetHypercubeRef(RootVar, Href, ElementData);
			ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Hypercube;
		ElsIf IsAxis(XDTOElement.SubstitutionGroup) Then
			ArcRow.Axis = GetAxisRef(RootVar, Href, ElementData);
			ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Axis;
		ElsIf IsMember(XDTOElement.Type) Then
			DomainMember = GetMemberRef(RootVar, Href, ElementData);
			If ArcRow.Parent <> Undefined And ValueIsFilled(ArcRow.Parent.Domain) Then
				ArcRow.Member = DomainMember;
				ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Member;
			Else
				ArcRow.Domain = DomainMember;
				ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Domain;
			EndIf;
		Else // concept
			ArcRow.Concept = GetConceptRef(RootVar, Href, ElementData);
			ArcRow.TreeNodeType = Enums.velpo_TreeNodeTypes.Concept;
		EndIf;			
		// create node
		CreateTreeNode(RootVar, RoleTypeRef, ArcRow, "PresentationTrees");
		// add child
		AddPresentationData(RootVar, RoleTypeRef, ArcRow, LocatorMap, LinkbaseStructure);
	EndDo; 

EndProcedure // AddDefinitionData()

// Saves presentation base data to db
//
Procedure CreatePresentationData(RootVar, LinkRole, LinkbaseStructure)
	
	URi = LinkRole.Key;
	LinkRoleStructure = LinkRole.Value;
	
	If LinkRoleStructure.IsDone Then
		Return;
	EndIf;
	
	XDTOObject = LinkRoleStructure.XDTOObject;
	
	LocatorMap = GetLocatorMap(RootVar, XDTOObject, "loc", LinkbaseStructure); 
	ArcTree = GetLinkbaseArcTree(RootVar, XDTOObject, "presentationArc", LinkbaseStructure);

	LinkRoleStructure.IsOverried = True;
	
	NodeType = New TypeDescription("CatalogRef.velpo_PresentationTrees");
	TreeNodeTypes = New TypeDescription("EnumRef.velpo_TreeNodeTypes");
	ReportingRefType = New TypeDescription("ChartOfAccountsRef.velpo_Reporting");
	HypercubeAxesType = New TypeDescription("ChartOfCharacteristicTypesRef.velpo_HypercubeAxes");
	MembersValuesType = New TypeDescription("CatalogRef.velpo_MemberValues");
	
	RoleTypeRef = GetRoleTypeByURi(RootVar, URi, LinkbaseStructure);
	
	// add addtional columns
	ArcTree.Columns.Add("Node", NodeType);
	ArcTree.Columns.Add("TreeNodeType", TreeNodeTypes);
	ArcTree.Columns.Add("Concept", ReportingRefType);
	ArcTree.Columns.Add("Hypercube", HypercubeAxesType);
	ArcTree.Columns.Add("Axis", HypercubeAxesType);
	ArcTree.Columns.Add("Domain", MembersValuesType);
	ArcTree.Columns.Add("Member", MembersValuesType);

	AddPresentationData(RootVar, RoleTypeRef, ArcTree, LocatorMap, LinkbaseStructure);
	
	LinkRoleStructure.IsDone = True;
	
EndProcedure

// Makes presentation
//
Procedure CreatePresentationLinkbase(RootVar, LinkbaseStructure)
	
	LinkRoleMap = LinkbaseStructure.PresentationLinks;
	For Each LinkRole  In LinkRoleMap Do
		CreatePresentationData(RootVar, LinkRole, LinkbaseStructure);
	EndDo; 
	
EndProcedure // CreatePresentationLinkbase()

#EndRegion

#Region Calculation

//  Makes calculation data
//
Procedure AddCalculationData(RootVar, RoleTypeRef, ArcTreeRow, LocatorMap, LinkbaseStructure)
	
	For Each ArcRow In ArcTreeRow.Rows Do
		Href = LocatorMap[ArcRow.Label];
		ElementData = GetElementDataByHref(RootVar, Href);
		// leaves
		If ArcRow.Parent <> Undefined Then
			FillPropertyValues(ArcRow, ArcRow.Parent, "Concept");
		EndIf;
		// element
		XDTOElement = ElementData.XDTOObject;	
		ArcRow.Concept = GetConceptRef(RootVar, Href, ElementData);
		// create node
		CreateTreeNode(RootVar, RoleTypeRef, ArcRow, "CalculationTrees");
		// add child
		AddCalculationData(RootVar, RoleTypeRef, ArcRow, LocatorMap, LinkbaseStructure);
	EndDo; 

EndProcedure // AddDefinitionData()

// Saves calculation base data to db
//
Procedure CreateCalculationData(RootVar, LinkRole, LinkbaseStructure)
	
	URi = LinkRole.Key;
	LinkRoleStructure = LinkRole.Value;
	
	If LinkRoleStructure.IsDone Then
		Return;
	EndIf;
	
	XDTOObject = LinkRoleStructure.XDTOObject;
	
	LocatorMap = GetLocatorMap(RootVar, XDTOObject, "loc", LinkbaseStructure); 
	ArcTree = GetLinkbaseArcTree(RootVar, XDTOObject, "calculationArc", LinkbaseStructure);

	LinkRoleStructure.IsOverried = True;
	
	NodeType = New TypeDescription("CatalogRef.velpo_CalculationTrees");
	TreeNodeTypes = New TypeDescription("EnumRef.velpo_TreeNodeTypes");
	ReportingRefType = New TypeDescription("ChartOfAccountsRef.velpo_Reporting");

	RoleTypeRef = GetRoleTypeByURi(RootVar, URi, LinkbaseStructure);
	
	// add addtional columns
	ArcTree.Columns.Add("Node", NodeType);
	ArcTree.Columns.Add("TreeNodeType", TreeNodeTypes);
	ArcTree.Columns.Add("Concept", ReportingRefType);
		
	AddCalculationData(RootVar, RoleTypeRef, ArcTree, LocatorMap, LinkbaseStructure);
	
	LinkRoleStructure.IsDone = True;
	
EndProcedure

// Makes calculation
//
Procedure CreateCalculationLinkbase(RootVar, LinkbaseStructure)
	
	LinkRoleMap = LinkbaseStructure.CalculationLinks;
	For Each LinkRole  In LinkRoleMap Do
		CreateCalculationData(RootVar, LinkRole, LinkbaseStructure);
	EndDo; 
	
EndProcedure // CreateCalculationLinkbase()

#EndRegion

#Region GenLinks

//  Add additional asertion formula definitions
//
Procedure AddAspectNodeDefintions(RootVar, GenObject, ExtAttribs, XDTOObject)
	
	AspectArrays = New Array;
	AspectArrays.Add("conceptAspect");
	AspectArrays.Add("dimensionAspect");
	AspectArrays.Add("entityIdentifierAspect");
	AspectArrays.Add("periodAspect");
	AspectArrays.Add("unitAspect");
	
	For Each AspectName In AspectArrays Do
		XDTOList = XDTOObject[AspectName];
		IsSet = False;
		For Each XDTOAspect In  XDTOList Do
			IsSet = True;
			If  AspectName = "dimensionAspect" Then
				ExtAttribs.AttributeType = Enums.velpo_AttributeTypes.QName;
				ExtAttribs.NamespaceURI = XDTOAspect.__content.NamespaceURI;
				ExtAttribs.LocalName = XDTOAspect.__content.LocalName;
				Href = RootVar.QNames[ExtAttribs.NamespaceURI + ":" + ExtAttribs.LocalName];
				ElementData = GetElementDataByHref(RootVar, Href);
				ExtAttribs.Axis = GetAxisRef(RootVar, Href, ElementData);
			EndIf;
		EndDo; 
		If IsSet Then
			GenObject.NodeType = Enums.velpo_DefinitionNodeTypes[AspectName];
			Break;	
		EndIf;
	EndDo; 
			
EndProcedure // Add()

//  Add additional ruleNode definitions
//
Procedure AddRuleNodeDefintions(RootVar, GenObject, ExtAttribs, XDTOObject)

	ExtAttribs.IsAbstract = (XDTOObject.abstract);
	ExtAttribs.IsMerge = (XDTOObject.merge);
	
EndProcedure // AddRuleNode()


//  Add additional ruleNode definitions
//
Procedure AddRuleNodeRulSetDefintions(RootVar, GenObject, ExtAttribs, XDTOObject)

	IsRuleSet = False;
	If  XDTOObject.ruleSet = Undefined Or XDTOObject.ruleSet.Count() = 0 Then
		RuleSetObject = Catalogs.velpo_RuleSets.CreateItem();
		RuleSetObject.Owner = GenObject.Ref;
		RuleSetObject.Write();
		AspectsOwner = RuleSetObject.Ref;
		RuleSetList = New Array;
		RuleSetList.Add(XDTOObject);
		IsRuleSet = True;
	Else
		RuleSetList = XDTOObject.ruleSet;
	EndIf;
	
	AspectArrays = New Array;
//	AspectArrays.Add("abstract_aspect");
	AspectArrays.Add("concept");
	AspectArrays.Add("entityIdentifier");
	AspectArrays.Add("period");
	AspectArrays.Add("explicitDimension");
	AspectArrays.Add("typedDimension");
//	AspectArrays.Add("abstract_dimension_aspect");
	AspectArrays.Add("abstract_occ_aspect");
	AspectArrays.Add("unit");
	
	For Each RuleSet In  RuleSetList Do
		If  Not IsRuleSet Then
			RuleSetObject = Catalogs.velpo_RuleSets.CreateItem();
			RuleSetObject.Owner = GenObject.Ref;
			RuleSetObject.Tag = RuleSet.Tag;
			RuleSetObject.Write();
			AspectsOwner = RuleSetObject.Ref;
		EndIf;
		For Each AspectName In AspectArrays Do
			XDTOList = RuleSet[AspectName];
			For Each XDTOAspect In XDTOList Do
				AspectRule = Catalogs.velpo_AspectRules.CreateItem();
				AspectRule.Owner = AspectsOwner; 
				AspectRule.AspectRuleType = Enums.velpo_AspectRuleType[AspectName];
				AspectRuleExtAttribs = AspectRule[AspectName].Add();
				If AspectName = "concept" Then
					AspectRuleExtAttribs.AttributeType = Enums.velpo_AttributeTypes.QName;
					AspectRuleExtAttribs.Qname = XDTOAspect.qname.NamespaceURI + ":" + XDTOAspect.qname.LocalName;
					Href = RootVar.QNames[AspectRuleExtAttribs.Qname];
					ElementData = GetElementDataByHref(RootVar, Href);
					AspectRuleExtAttribs.Concept = GetConceptRef(RootVar, Href, ElementData);
				ElsIf  AspectName = "explicitDimension" Then
					AspectRuleExtAttribs.AttributeType = Enums.velpo_AttributeTypes.QName;
					AspectRuleExtAttribs.Qname = XDTOAspect.dimension.NamespaceURI + ":" + XDTOAspect.dimension.LocalName;
					Href = RootVar.QNames[AspectRuleExtAttribs.Qname];
					ElementData = GetElementDataByHref(RootVar, Href);
					AspectRuleExtAttribs.Axis = GetAxisRef(RootVar, Href, ElementData);
					If XDTOAspect.member <> Undefined Then
						Href = RootVar.QNames[XDTOAspect.member.qname.NamespaceURI + ":" + XDTOAspect.member.qname.LocalName];
						ElementData = GetElementDataByHref(RootVar, Href);
						AspectRuleExtAttribs.Member = GetMemberRef(RootVar, Href, ElementData);
					EndIf;
				ElsIf AspectName = "period" Then
						If Not (XDTOAspect.forever = Undefined) Then
							AspectRuleExtAttribs.AttributeType = Enums.velpo_AttributeTypes.Forever;
						ElsIf Not (XDTOAspect.instant = Undefined) Then
							AspectRuleExtAttribs.AttributeType = Enums.velpo_AttributeTypes.Instant;
							AspectRuleExtAttribs.Instant = XDTOAspect.instant.Value;
						ElsIf Not (XDTOAspect.duration = Undefined) Then
							AspectRuleExtAttribs.AttributeType = Enums.velpo_AttributeTypes.Duration;
							AspectRuleExtAttribs.Start = XDTOAspect.duration.Start;
							AspectRuleExtAttribs.End = XDTOAspect.duration.End;
						EndIf;
				EndIf;
				AspectRule.Write();	
			EndDo; 
		EndDo;
	EndDo;
	
EndProcedure // AddRuleNode()


//  Add additional asertion formula definitions
//
Procedure AddAssertionFormulaDefinitions(RootVar, GenObject, ExtAttribs, XDTOObject, ArcRow, LocatorMap)

	// severity
	For Each LocChild In ArcRow.Rows Do
		SevRef =  RootVar.SeverityHrefs[LocatorMap[LocChild.Label]];;
			If SevRef <> Undefined Then
			GenObject.Severity = SevRef;					
		EndIf;
	EndDo; 
	
	// assertation, formula
	GenObject.IsDimensional = (XDTOObject.aspectModel="dimensional");
	If GenObject.AssertionFormulaType = Enums.velpo_AssertionFormulaTypes.ConsistencyAssertion Then
		ExtAttribs.IsStrict = XDTOObject.strict;
	ElsIf GenObject.AssertionFormulaType = Enums.velpo_AssertionFormulaTypes.Formula Then
		If XDTOObject.Precision <> Undefined Then
			ExtAttribs.AttributeType = Enums.velpo_AttributeTypes.Precision;
		ElsIf XDTOObject.Decimals <> Undefined Then
			ExtAttribs.AttributeType = Enums.velpo_AttributeTypes.Decimals;
		EndIf;
	EndIf;
	
EndProcedure // Add()

// Saves formula base data to db
//
Procedure AddGenLinkData(RootVar, LinkRole, LinkbaseStructure, LabelLinkOnly = False)
	
	URi = LinkRole.Key;
	LinkRoleStructure = LinkRole.Value;
	XDTOObject = LinkRoleStructure.XDTOObject;
	
	If LinkRoleStructure.IsOverried Then
		Return;
	EndIf;
		
	LocatorMap = Undefined;
	ArcTree = Undefined;
	SevertyMap = Undefined;
	RoleTypeRef = Undefined;
	
	If LinkRoleStructure.Property("LocatorMap", LocatorMap) Then
		LinkRoleStructure.Property("ArcTree", ArcTree);
		LinkRoleStructure.Property("SevertyMap", SevertyMap);
		LinkRoleStructure.Property("RoleTypeRef", RoleTypeRef);
	Else
		LocatorMap = GetLocatorMap(RootVar, XDTOObject, "loc", LinkbaseStructure);
		If LabelLinkOnly Then
			ArcTree = GetLinkbaseArcTree(RootVar, XDTOObject, "labelArc", LinkbaseStructure);
		Else
			// get arcs
			ArcNames =  "tableBreakdownArc,breakdownTreeArc,definitionNodeSubtreeArc,tableParameterArc,variableArc,variableFilterArc,variableSetFilterArc,arc";
			ArcTree = GetLinkbaseArcTree(RootVar,  XDTOObject, ArcNames, LinkbaseStructure, True);	
		EndIf;
		RoleTypeRef = GetRoleTypeByURi(RootVar, URi, LinkbaseStructure);
		
		LinkRoleStructure.Insert("LocatorMap", LocatorMap);	
		LinkRoleStructure.Insert("ArcTree", ArcTree);
		LinkRoleStructure.Insert("SevertyMap", Undefined);
		LinkRoleStructure.Insert("RoleTypeRef", RoleTypeRef);
		
		LinkRoleStructure.IsOverried = True;
	EndIf;
	 		
	GenLinkArray = velpo_TaxonomyUpdateClientServerCached.GetGenLinkArray(); 
		
	For Each GenLinkStructure In GenLinkArray Do
		
		If LabelLinkOnly And GenLinkStructure.TypeName <> "LabelLinks" Then
			Continue;
		EndIf;
	
		LocatorData = XDTOObject[GenLinkStructure.Loc];
		If LocatorData = Undefined Then
			Continue;
		EndIf;
		
		If GenLinkStructure.TypeName = "SeverityTypes" Then
			SeverityTypesMap = velpo_TaxonomyUpdateClientServerCached.GetSeverityTypesMap();
			Href = LinkbaseStructure.Href + "#" + LocatorData.id;
			SetLinkByHref(RootVar, Href, URi, LocatorData, GenLinkStructure, SeverityTypesMap[GenLinkStructure.Loc]);
			RootVar.SeverityHrefs.Insert(Href, SeverityTypesMap[GenLinkStructure.Loc]);
			Continue;
		EndIf;
			
		For Each XDTOLoc In LocatorData Do
			
			If XDTOLoc.id = Undefined Then
				Href = LinkbaseStructure.Href + "#" + String(New UUID);
			Else
				Href = LinkbaseStructure.Href + "#" + XDTOLoc.id;
			EndIf;
			LocatorMap.Insert(XDTOLoc.Label, Href); 
			
			SetLinkByHref(RootVar, Href,  URi, XDTOLoc, GenLinkStructure);
			
		EndDo;
		
	EndDo;
		
EndProcedure

// Makes gen link
//
Procedure AddLinkbaseGenData(RootVar, LinkbaseStructure)
	
	LinkRoleMap = LinkbaseStructure.GenLinks;
	For Each LinkRole  In LinkRoleMap Do
		AddGenLinkData(RootVar, LinkRole, LinkbaseStructure);
	EndDo; 

EndProcedure // CreateGenLlinkbase()

// Makes gen link
//
Procedure AddLinkbaseLabelData(RootVar, LinkbaseStructure)
	
	LinkRoleMap = LinkbaseStructure.LabelLinks;
	For Each LinkRole  In LinkRoleMap Do
		AddGenLinkData(RootVar, LinkRole, LinkbaseStructure, True);
	EndDo; 

EndProcedure // CreateGenLlinkbase()

// Saves formula base data to db
//
Procedure CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure, ArcTreeRow = Undefined, LabelLinkOnly = False)
	
	URI = LinkRole.Key;
	LinkRoleStructure = LinkRole.Value;
	
	LocatorMap = LinkRoleStructure.LocatorMap;
	RoleTypeRef = LinkRoleStructure.RoleTypeRef;
	
	If ArcTreeRow = Undefined Then
		ArcTreeRow = LinkRoleStructure.ArcTree;
	EndIf;
	
	For Each ArcRow In ArcTreeRow.Rows Do
		
		If ArcRow.IsDone Then
			CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure, ArcRow, LabelLinkOnly);
			Continue;
		EndIf;
		
		ArcRow.IsDone = True;
		
		Href = LocatorMap[ArcRow.Label];
		LinkRefData = RootVar.LinkHrefs[Href];
		
		If LinkRefData = Undefined Then
			Continue;
		ElsIf LinkRefData.TypeName = "SeverityTypes" Then
			Continue;
		ElsIf  LabelLinkOnly And LinkRefData.TypeName <> "LabelLinks" Then
			ArcRow.NodeRef = LinkRefData.Refs;
			CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure, ArcRow, LabelLinkOnly);
			Continue;
		ElsIf LinkRefData.TypeName = "Element" Then
			ArcRow.NodeRef = LinkRefData.Refs;
			CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure, ArcRow, LabelLinkOnly);
			Continue;
		EndIf;
		
		LinkOnly = StrEndsWith(LinkRefData.TypeName, "Links");
		// ref to another and empty
		IsThisLinkbase = StrStartsWith(Href, LinkbaseStructure.Href);
		If (IsThisLinkbase And URI <> LinkRefData.URI) OR (Not IsThisLinkbase) Then
			If LinkRefData.IsEmpty Then
				CreateGenLinkByHref(RootVar, Href, LinkRefData.URI);
				LinkRefData = RootVar.LinkHrefs[Href];
			EndIf;
			ArcRow.NodeRef = LinkRefData.Refs;
			CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure, ArcRow, LabelLinkOnly);
			Continue;
		EndIf;
		
		XDTOObject = LinkRefData.XDTOObject;	
		GenLinkType =  ?(LinkOnly, Undefined, Type("CatalogRef.velpo_" + LinkRefData.TypeName)); 
			
		OwnerParentArray = New Array;
		
		If ArcRow.Parent = Undefined Then
			ParentOwnerRef = RootVar.TaxonomyRef;
			ParentRef = RootVar.TaxonomyRef;
		Else
			ParentOwnerRef = ArcRow.Parent.NodeOwnerRef;
			ParentRef = ArcRow.Parent.NodeRef;
		EndIf;
		
		IsParentRefArray = (TypeOf(ParentRef) = Type("Array"));
		
		If LinkOnly Then
			If IsParentRefArray Then
				For Each RefParentStructure In ParentRef  Do
					OwnerParentArray.Add(New Structure("Owner", RefParentStructure.Ref));
				EndDo; 
			Else
				OwnerParentArray.Add(New Structure("Owner", ParentRef));				
			EndIf;
		Else
			If IsParentRefArray Then
				For Each RefParentStructure In ParentRef  Do
					Message(1);
					// TODO
				EndDo;
			Else
				TypesAreEqual = (TypeOf(ParentRef) = GenLinkType);
				For Each RefStructure In LinkRefData.Refs Do
					If (TypesAreEqual And RefStructure.Parent = ParentRef)
						Or (Not TypesAreEqual And RefStructure.Owner = ParentOwnerRef) Then
						ArcRow.NodeRef = RefStructure.Ref;
						ArcRow.NodeOwnerRef = ParentOwnerRef;
						Break;
					EndIf;
				EndDo;
			EndIf;
			If Not ValueIsFilled(ArcRow.NodeRef) Then
				If TypesAreEqual Then
					OwnerParentArray.Add(New Structure("Owner, Parent", ParentOwnerRef, ParentRef));
				Else
					OwnerParentArray.Add(New Structure("Owner", ParentRef));				
				EndIf;
			EndIf;
		EndIf;
		
		// set
		For Each OwnerParentStructure In OwnerParentArray  Do
			
			// set new object
			If LinkOnly Then
				GenObject = InformationRegisters["velpo_" + LinkRefData.TypeName].CreateRecordManager();
				GenObject.Taxonomy = RootVar.TaxonomyRef;
			Else
				GenObject = Catalogs["velpo_" + LinkRefData.TypeName].CreateItem();				
			EndIf;
						
			TestSt = New Structure("URI", LinkRole.Key);
			
			FillPropertyValues(GenObject, ArcRow.ArcNode);
			FillPropertyValues(GenObject, XDTOObject);
			FillPropertyValues(GenObject, LinkRefData);
			FillPropertyValues(GenObject, OwnerParentStructure);
			FillPropertyValues(GenObject, TestSt);
			
			If LinkRefData.SetExtAttribs Then
				ExtAttribs = GenObject[LinkRefData.Loc].Add();
				FillPropertyValues(ExtAttribs, XDTOObject);
			Else
				ExtAttribs = Undefined;
			EndIf;
			
			SetParentChildOrder = False;
			SetLanguage = False;
			SetRole = False;
			
			// additional pararmeters by types
			If LinkRefData.TypeName = "AssertionFormulaDefinitions" Then
				AddAssertionFormulaDefinitions(RootVar, GenObject, ExtAttribs, XDTOObject, ArcRow, LocatorMap);
			ElsIf LinkRefData.TypeName = "MessageLinks" Then
				GenObject.MessageType = Enums.velpo_MessageTypes[?(ArcRow.arcrole = "http://xbrl.org/arcrole/2010/assertion-satisfied-message", "Satisfied", "Unsatisfied")];
				GenObject.Message = XDTOObject.__content;
				SetRole = True;
				SetLanguage = True;
			ElsIf LinkRefData.TypeName = "RoleTables" Then
				GenObject.Name = LinkRole.Key + "/" + XDTOObject.id;
			ElsIf LinkRefData.TypeName = "Breakdowns" Then
				GenObject.AxisBreakdown = Enums.velpo_AxisBreakdowns[ArcRow.ArcNode.axis];
				SetParentChildOrder = True;
			ElsIf LinkRefData.TypeName = "DefinitionNodes" Then
				If LinkRefData.Loc = "aspectNode" Then
					AddAspectNodeDefintions(RootVar, GenObject, ExtAttribs, XDTOObject);
				ElsIf LinkRefData.Loc = "ruleNode" Then
					AddRuleNodeDefintions(RootVar, GenObject, ExtAttribs, XDTOObject);
					SetParentChildOrder = True;
				Else
					SetParentChildOrder = True;
				EndIf;
			ElsIf LinkRefData.TypeName = "ParameterDefinitions" Then
				GenObject._Select = XDTOObject.Select;
				GenObject._As = XDTOObject.As;
				GenObject.IsRequired = XDTOObject.Required;
			ElsIf LinkRefData.TypeName = "LabelLinks" Then
				GenObject.Label = XDTOObject.__content;
				SetLanguage = True;
			EndIf;
			// role
			LocRole = Undefined;
			If LinkOnly Then
				TestStructure = New Structure("role");
				FillPropertyValues(TestStructure, XDTOObject);
				If TestStructure.role = Undefined Then
					GenObject.RoleType = RoleTypeRef;		
				Else
					GenObject.RoleType = GetRoleTypeByURi(RootVar, XDTOObject.role, LinkbaseStructure);
					LocRole = XDTOObject.role;
				EndIf;
			Else
				GenObject.RoleType = RoleTypeRef;	
			EndIf;
			// set parent-child
			If  SetParentChildOrder Then
				GenObject.ParentChildOrder = Enums.velpo_ParentChildOrders[?(XDTOObject.parentChildOrder = "children-first", "ChildrenFirst", "ParentFirst")];
			EndIf;
			// language
			If SetLanguage Then
				LangRef =  RootVar.LanguageRefs[XDTOObject.Lang];
				If LangRef = Undefined Then
					LangStructure = Catalogs.velpo_Languages.GetStructure();
					LangStructure.Code = XDTOObject.Lang;
					LangRef = Catalogs.velpo_Languages.GetItem(LangStructure);
					RootVar.LanguageRefs.Insert(XDTOObject.Lang, LangRef);
				EndIf;
				GenObject.Language = LangRef;
			EndIf;
			GenObject.Write();				
			// set description
			If LinkRefData.TypeName = "LabelLinks" Then
				// main label
				If  LocRole = "http://www.xbrl.org/2003/role/label" OR  LocRole = "http://www.xbrl.org/2008/role/label" Then
					OwnerObj = OwnerParentStructure.Owner.GetObject();
					OwnerObj.Description = GenObject.Label;
					OwnerObj.Write();
				EndIf;
			ElsIf LinkRefData.Loc = "ruleNode" Then
				AddRuleNodeRulSetDefintions(RootVar, GenObject, ExtAttribs, XDTOObject);
			EndIf;
			
			If Not LinkOnly Then
				ArcRow.NodeRef = GenObject.Ref;
				ArcRow.NodeOwnerRef = GenObject.Owner;
				If OwnerParentStructure.Property("Parent") Then
					AddNewRefByHref(RootVar, Href, GenObject.Ref, OwnerParentStructure.Owner, OwnerParentStructure.Parent);
				Else
					AddNewRefByHref(RootVar, Href, GenObject.Ref,OwnerParentStructure.Owner);
				EndIf;
			EndIf;
			
		EndDo;
		// leaves
		If Not LinkOnly Then
			CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure, ArcRow, LabelLinkOnly);
		EndIf;
		
	EndDo; 
EndProcedure

// Get data to Gen link by href and URI
//
//
Procedure CreateGenLinkByHref(RootVar, Href, URI)

    SplitArray = StrSplit(Href, "#", True);
	LocalPath = SplitArray[0];
	CreateGenLinkbase(RootVar, RootVar.Linkbases[LocalPath], URI);
	
EndProcedure // GreateGenLinkByHref()

// Makes gen link
//
Procedure CreateGenLinkbase(RootVar, LinkbaseStructure,URI = Undefined)
	
	LinkRoleMap = LinkbaseStructure.GenLinks;
	For Each LinkRole  In LinkRoleMap Do
		If URI <> Undefined And URI <> LinkRole.Key Then
			Continue;
		EndIf;
		LinkRoleStructure = LinkRole.Value;
		If LinkRoleStructure.IsDone Then
			Continue;
		EndIf;
		CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure);
		LinkRoleStructure.IsDone = True;
	EndDo; 

EndProcedure // CreateGenLlinkbase()

// Makes gen link
//
Procedure CreateLabelLinkbase(RootVar, LinkbaseStructure)
	
	LinkRoleMap = LinkbaseStructure.LabelLinks;
	For Each LinkRole  In LinkRoleMap Do
		LinkRoleStructure = LinkRole.Value;
		If LinkRoleStructure.IsDone Then
			Continue;
		EndIf;
		CreateGenLinkTree(RootVar, LinkRole, LinkbaseStructure,, True);
		LinkRoleStructure.IsDone = True;
	EndDo; 

EndProcedure // CreateLinkbaseLabelData()

#EndRegion

#Region Linkbases

// Create single link base
//
Procedure CreatePrimaryLinkbaseData(RootVar, LinkbaseStructure)
	
	If LinkbaseStructure.IsDone Then
		Return;
	EndIf;
	
	// override role refs
	OverrideLinkBaseRole(RootVar, LinkbaseStructure.RoleRefs, LinkbaseStructure);
	
	// override acrrole
	OverrideLinkBaseRole(RootVar, LinkbaseStructure.ArcroleRefs, LinkbaseStructure);
	
	// link bases
	CreateDefinitionLinkbase(RootVar, LinkbaseStructure);
	CreatePresentationLinkbase(RootVar, LinkbaseStructure);
	CreateCalculationLinkbase(RootVar, LinkbaseStructure);

	AddLinkbaseGenData(RootVar, LinkbaseStructure);
	AddLinkbaseLabelData(RootVar, LinkbaseStructure);
	
	// TODO
	//AddFootnoteLinkbaseData(RootVar, LinkbaseStructure);
	//AddReferenceLinkbaseData(RootVar, LinkbaseStructure);
	 LinkbaseStructure.IsDone = True;
		
EndProcedure // CreateLinkbase()

// Create linkbases
//
Procedure CreateLinkbases(RootVar)
	
	// set primary data and arc gor gens
	For Each Linkbase In RootVar.Linkbases Do
		LinkbaseStructure = Linkbase.Value;
		CreatePrimaryLinkbaseData(RootVar, LinkbaseStructure);
	EndDo; 
	
	// set gen data, 
	For Each Linkbase In RootVar.Linkbases Do
		LinkbaseStructure = Linkbase.Value;
		CreateGenLinkbase(RootVar, LinkbaseStructure);	
	EndDo; 
	
	//labels, footnotes, etc
	For Each Linkbase In RootVar.Linkbases Do
		LinkbaseStructure = Linkbase.Value;
		CreateLabelLinkbase(RootVar, LinkbaseStructure);
	EndDo;
	
EndProcedure // CreateLinkbases()

#EndRegion 

#Region EntryPoints

// Get entry point
//
Function GetTextEntryPoint()

	

EndFunction // GetTextEntryPoint()

// Add role types to map
//
Procedure AddRoleTypesRefs(Schemas, RolesMap)

 	For Each Schema In Schemas Do
		SchemaData = Schema.Value;
		RoleTypeMap = SchemaData.RoleTypes;
		For Each RoleType In RoleTypeMap Do
			RoleTypeStructure = RoleType.Value;
			RolesMap.Insert(RoleTypeStructure.Ref, RoleType.Value);
		EndDo; 
		AddRoleTypesRefs(SchemaData.Schemas, RolesMap);
	EndDo; 

EndProcedure // AddRoleTypesRefs()

// Create entry points
//
Procedure CreateEntryPoints(RootVar)
	
	For Each EntryPointData In RootVar.EntryPoints Do
		
		RolesMap = New Map;
		AddRoleTypesRefs(EntryPointData.Schemas, RolesMap);
	
		RoleTypesArray = New Array;
		For Each Role In RolesMap Do
			RoleTypesArray.Add(Role.Key);
		EndDo; 
		
		EntryPointStructure = Catalogs.velpo_EntryPoints.GetStructure();
		FillPropertyValues(EntryPointStructure, EntryPointData); 
		EntryPointStructure.Owner = RootVar.TaxonomyRef; 
		EntryPointStructure.RoleTypes = RoleTypesArray;
		
		Query = New Query;
		Query.SetParameter("RoleTypes", RoleTypesArray);
		Query.Text = "SELECT DISTINCT Ref As Ref From Catalog.velpo_RoleTables WHERE RoleType IN (&RoleTypes)";
		
		EntryPointStructure.RoleTables = Query.Execute().Unload().UnloadColumn("Ref");
		
		Catalogs.velpo_EntryPoints.GetItem(EntryPointStructure);
		
	EndDo; 

EndProcedure // CreateEnums()

#EndRegion 

//  Saves data to DB
//
//
Procedure SaveTaxonomyData(RootVar)

	BeginTransaction();
	
	//  stage 1.  create taxonomy
	CreateTaxonomyElement(RootVar);
	
	// stage 2. Role types
	CreateRoleTypes(RootVar);
	
	// stage 3. Linkbases
	CreateLinkbases(RootVar);
	
	// stage 4. Entry points
	CreateEntryPoints(RootVar);
	
	CommitTransaction();

EndProcedure // SaveTaxonomyData()

#EndRegion 

#Region Interface

// Imports taxonomy from server temp storage.
//
// Parameters:
//  EntryPointsArray - Array - array of  entryPointDocument
//  ResultAddress      - String    - a temporary storage address to store import results.
//
Procedure ImportTaxonomy(TaxonomyStructure, EntryPointsArray, ResultAddress) Export
	
	//CommonUse.ScheduledJobOnStart();
	
	EventName = NStr("en = 'XBRL.Taxonomy import'; ru = 'XBRL.Импорт таксономии'",
		velpo_CommonFunctionsClientServer.DefaultLanguageCode());
	
	WriteLogEvent(EventName, EventLogLevel.Information, , ,
		NStr("en = 'The scheduled taxonomy import is started'; ru = 'Начата регламентная загрузка таксономии'"));
	
	CurrentDate = CurrentSessionDate();
	
	ImportState = Undefined;
	ErrorsOccurredOnImport = False;
	
	If EntryPointsArray.Count() = 0 Then
		ErrorsOccurredOnImport = True;
	Else
		
		ZipFileName = GetTempFileName("zip");
		BinaryData = GetFromTempStorage(ResultAddress);
		BinaryData.Write(ZipFileName);

		// unpack zip archive
		PathForSaving = GetTempFileName();
		ZipReader = New ZipFileReader(ZipFileName);
		ZipReader.ExtractAll(PathForSaving, ZIPRestoreFilePathsMode.Restore);
		ZipReader.Close();
		
		// set variables
		RootVar = GetTaxonomyVariable(TaxonomyStructure, EntryPointsArray, PathForSaving);
		
		// set catalogs rewrite
		SetRewriteCatalogs(RootVar);

		// import entry points
		ImportEntryPoints(RootVar, ErrorsOccurredOnImport);
		
		// save data from root var
		SaveTaxonomyData(RootVar);
		
	EndIf;
				
	If ErrorsOccurredOnImport Then
		WriteLogEvent(
			EventName,
			EventLogLevel.Error,
			, 
			,
			NStr("en = 'Errors occured during the scheduled taxonomy import'; ry = 'Во время регламентного задания загрузки таксономии возникли ошибки'"));
	Else
		WriteLogEvent(
			EventName,
			EventLogLevel.Information,
			,
			,
			NStr("en = 'The scheduled  taxonomy import is completed.'; ru = 'Завершена регламентная загрузка таксономии.'"));
	EndIf;
	
EndProcedure

#EndRegion