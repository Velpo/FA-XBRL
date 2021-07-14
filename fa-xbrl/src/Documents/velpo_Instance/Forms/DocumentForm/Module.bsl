///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

// get our main text query
&AtServer
Function GetTableTextQuery()

	Text = 
	"SELECT
	|	// 0 
	|	Breakdowns.Ref AS Breakdown,
	|	Breakdowns.AxisBreakdown AS AxisBreakdown,
	|	Breakdowns.ParentChildOrder AS ParentChildOrder,
	|	Breakdowns.Priority AS Priority,
	|	Breakdowns.Order AS Order,
	|	Breakdowns.ID AS BreakdownID
	|INTO
	|	VT_DistinctBreakdowns
	|FROM
	|	Catalog.Breakdowns AS Breakdowns
	|WHERE
	|	Breakdowns.Owner = &RoleTable
	|INDEX BY
	|	Breakdown	
	|;
	|SELECT DISTINCT
	|	// 1
	|	DefinitionNodes.Ref AS NodeRef
	|INTO
	|	VT_DistinctNodes
	|FROM
	|	Catalog.DefinitionNodes AS DefinitionNodes
	|
	|	INNER JOIN  VT_DistinctBreakdowns AS DistinctBreakdowns
	|	ON DefinitionNodes.Owner = DistinctBreakdowns.Breakdown
	|INDEX BY
	|	NodeRef	
	|;
	|SELECT
	|	// 2 
	|	Breakdowns.Breakdown,
	|	Breakdowns.AxisBreakdown,
	|	Breakdowns.ParentChildOrder,
	|	Breakdowns.Priority,
	|	Breakdowns.Order,
	|	Breakdowns.BreakdownID
	|FROM
	|	VT_DistinctBreakdowns AS Breakdowns
	|ORDER BY
	|	AxisBreakdown,
	|	Order
	|;
	|SELECT
	|	// 3 Nodes
	|	DefinitionNodes.Ref AS NodeRef,
	|	DefinitionNodes.NodeType AS NodeType,
	|	DefinitionNodes.Owner AS Breakdown,
	|	DefinitionNodes.Owner.AxisBreakdown AS AxisBreakdown,
	|	DefinitionNodes.Owner.ParentChildOrder AS ParentChildOrderBreakdown,
	|	DefinitionNodes.ParentChildOrder AS ParentChildOrder,
	|	DefinitionNodes.Priority AS Priority,
	|	DefinitionNodes.Order AS Order,
	|	DefinitionNodes.ID AS NodeID,
	|	DefinitionNodes.AspectNode.(
	|		TagSelector AS TagSelector,
	|		Axis AS Axis,
	|		Axis.Description AS AxisLabel,
	|		Axis.DataType AS DataType,
	|		Axis.DataType.ValueType AS ValueType,
	|		Axis.DataType.Pattern AS Pattern
	|	) AS AspectNode,
	|	DefinitionNodes.RuleNode.(
	|		TagSelector AS TagSelector,
	|		IsAbstract AS IsAbstract,
	|		IsMerge AS IsMerge
	|	) AS RuleNode
	|FROM
	|	Catalog.DefinitionNodes AS DefinitionNodes
	|
	|	INNER JOIN  VT_DistinctNodes AS DistinctNodes
	|	ON DefinitionNodes.Ref  = DistinctNodes.NodeRef
	|
	|ORDER BY
	|	DefinitionNodes.Owner,
    |	DefinitionNodes.Ref HIERARCHY
	|AUTOORDER
	|;
	|SELECT
	|	// 4 Aspect rules
	|	AspectRules.Owner.Owner AS NodeRef,
	|	AspectRules.Owner.Tag AS Tag,
	|	AspectRules.AspectRuleType AS AspectRuleType,
	|	AspectRules.Concept.(
	|		Concept AS Concept,
	|		Concept.IsAbstract AS IsAbstract,
	|		Concept.Description AS Article,
	|		Concept.DataType AS DataType,
	|		Concept.DataType.ValueType AS ValueType,
	|		Concept.DataType.Pattern AS Pattern
	|	) AS Concept,
	|	AspectRules.EntityIdentifier.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		Scheme AS Scheme,
	|		Value AS Value
	|	) AS EntityIdentifier,
	|	AspectRules.Period.(
	|		AttributeType AS AttributeType,
	|		Instant AS Instant,
	|		Start AS Start,
	|		Period.End AS End,
	|		Forever AS Forever
	|	) AS Period,
	|	AspectRules.ExplicitDimension.(
	|		Axis AS Axis,
	|		Axis.Description + "", "" +  Member.Description AS Article,
	|		Member AS Member
	|	) AS ExplicitDimension,
	|	AspectRules.Abstract_occ_aspect.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		AttributeType AS AttributeType,
	|		OCCType AS OCCType,
	|		Fragments AS Fragments,
	|		XPath AS XPath
	|	) AS Abstract_occ_aspect,
	|	AspectRules.Unit.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		AttributeType AS AttributeType,
	|		Multiplacation AS Multiplacation,
	|		Division AS Division
	|	) AS Unit,
	|	AspectRules.TypedDimension.(
	|		Ref AS Ref,
	|		LineNumber AS LineNumber,
	|		AttributeType AS AttributeType,
	|		Value AS Value,
	|		XPath AS XPath
	|	) AS TypedDimension
	|FROM
	|	Catalog.AspectRules AS AspectRules
	|
	|	INNER JOIN  VT_DistinctNodes AS DistinctNodes
	|	ON AspectRules.Owner.Owner = DistinctNodes.NodeRef
	|;
	|SELECT
	|	// 5 labels
	|	LabelLinks.Owner AS NodeRef,
	|	LabelLinks.Label,
	|	LabelLinks.RoleType.Name AS Role,
	|	LabelLinks.Order
	|FROM
	|	InformationRegister.LabelLinks AS LabelLinks
	|	
	|	INNER JOIN  VT_DistinctNodes AS DistinctNodes
	|	ON LabelLinks.Owner = DistinctNodes.NodeRef
	|WHERE
	|	LabelLinks.Language.Code = ""ru""
	|ORDER BY
	|	NodeRef,
	|	Order
	|;
	|SELECT DISTINCT
	|	// 6 enums
	|	ValueDataTypes.Ref AS DataType,	
	|	DefinitionTrees.Member AS Member,
	|	Member.Description AS MemberLabel
	|FROM
	|	ChartOfCharacteristicTypes.ValueDataTypes AS  ValueDataTypes
	|
	|	INNER JOIN InformationRegister.EnumLinks AS EnumLinks
	|	ON EnumLinks.Owner = ValueDataTypes.Ref
	|	AND EnumLinks.Taxonomy = &Taxonomy
	|
	|	INNER JOIN Catalog.DefinitionTrees AS DefinitionTrees
	|	ON DefinitionTrees.Owner = EnumLinks.RoleType
	|	AND DefinitionTrees.Concept =  EnumLinks.Concept
	|ORDER BY
	|	DataType,
	|	Member.Description
	|;
	|";
	
	Return Text;
	
EndFunction // GetTableTextQuery() 

// get all settings
&AtServer
Function GetTableSettings()

	Query = New Query;
	Query.SetParameter("Taxonomy", Object.Taxonomy);
	Query.SetParameter("RoleTable", Object.RoleTable);
	Query.Text = GetTableTextQuery();
	
	ResultArray = Query.ExecuteBatch();
	
	SettingsVar = New Structure;
	
	BreakdownsTable = ResultArray[2].Unload(QueryResultIteration.Linear);
	BreakdownsTable.Indexes.Add("Breakdown");
	
	NodsTree = ResultArray[3].Unload(QueryResultIteration.ByGroupsWithHierarchy);
	NodsTree.Rows.Sort("Order");
	
	AspectRulesTable = ResultArray[4].Unload(QueryResultIteration.Linear);
	AspectRulesTable.Indexes.Add("NodeRef");
	
	LabelsTable = ResultArray[5].Unload(QueryResultIteration.Linear);
	LabelsTable.Indexes.Add("NodeRef");
	
	EnumsDataTable = ResultArray[6].Unload(QueryResultIteration.Linear);
	EnumsDataTable.Indexes.Add("DataType");
	
	AspectTablesMap = New Map;
	TablesColumnsMap = New Map;
	For i = 0 To 2 Do
		
		AxisBreakdown = Enums.velpo_AxisBreakdowns.Get(i);
		
		ColumnsTree = New ValueTree;
		ColumnsTree.Columns.Add("NodeId", velpo_CommonFunctions.StringTypeDescription("500"));
		ColumnsTree.Columns.Add("Name", New TypeDescription("String"));
		ColumnsTree.Columns.Add("Title", New TypeDescription("String"));
		ColumnsTree.Columns.Add("Code", velpo_CommonFunctions.StringTypeDescription("10"));
		ColumnsTree.Columns.Add("Path", New TypeDescription("String"));
		ColumnsTree.Columns.Add("DataType", New TypeDescription("ChartOfCharacteristicTypesRef.ValueDataTypes"));
		ColumnsTree.Columns.Add("IsAbstract", New TypeDescription("Boolean"));
		ColumnsTree.Columns.Add("IsMerge", New TypeDescription("Boolean"));
		ColumnsTree.Columns.Add("HasCode", New TypeDescription("Boolean"));
		ColumnsTree.Columns.Add("NotEmpty", New TypeDescription("Boolean"));
		ColumnsTree.Columns.Add("TypeLink", New TypeDescription("String"));
		ColumnsTree.Columns.Add("NodeData", New TypeDescription("Structure"));
		TablesColumnsMap.Insert(AxisBreakdown, ColumnsTree);
		
		AspectTable = New ValueTable;
		If AxisBreakdown <> Enums.velpo_AxisBreakdowns.Y Then 
			AspectTable.Columns.Add("Arcticle", velpo_CommonFunctions.StringTypeDescription("500"));
			AspectTable.Columns.Add("Code", velpo_CommonFunctions.StringTypeDescription("5"));
			AspectTable.Columns.Add("NodeId", velpo_CommonFunctions.StringTypeDescription("500"));
			AspectTable.Columns.Add("NodeRef", New TypeDescription("CatalogRef.DefinitionNodes"));
			AspectTable.Columns.Add("IsAbstract", New TypeDescription("Boolean"));
			AspectTable.Columns.Add("DataType", New TypeDescription("ChartOfCharacteristicTypesRef.ValueDataTypes"));
			If AxisBreakdown = Enums.velpo_AxisBreakdowns.X Then 
				AspectTable.Columns.Add("IsFilled", New TypeDescription("Boolean"));
			EndIf;
		EndIf;
		
		AspectTablesMap.Insert(AxisBreakdown,  AspectTable);
		
	EndDo;
	
	SettingsVar.Insert("Breakdowns", BreakdownsTable);
	SettingsVar.Insert("NodsTree", NodsTree);
	SettingsVar.Insert("AspectRules", AspectRulesTable);
	SettingsVar.Insert("Labels", LabelsTable);
	SettingsVar.Insert("AspectTables", AspectTablesMap);
	SettingsVar.Insert("ColumnTrees", TablesColumnsMap);
	SettingsVar.Insert("InstanceDate", BegOfDay(Object.Date));
	SettingsVar.Insert("FormAttributes", New Map);
	SettingsVar.Insert("EnumsTable", EnumsDataTable);
	SettingsVar.Insert("EnumsMap", New Map);
	SettingsVar.Insert("ModelMap", New Map);
			
	Return SettingsVar;
	
EndFunction // GetTableSettings() 

// get labels
&AtServer
Function GetNodeLabelData(SettingsVar, NodeRef)

	LabelsArray = SettingsVar.Labels.FindRows(New Structure("NodeRef", NodeRef)); 
	LabelStructure = New Structure("Article, Code", "", "");	
	For Each LabelData In LabelsArray Do
		If LabelData.Role = "http://www.eurofiling.info/xbrl/role/rc-code" Then
			LabelStructure.Code = LabelData.Label;
		Else
			LabelStructure.Article = LabelData.Label;
		EndIf;
	EndDo; 
	
	Return LabelStructure;

EndFunction // GetNodeLabel() 

// Get description
//
&AtServer
Function GetRuleNodeDefinition(SettingsVar, NodeRef)
	
	RuleNodeStructure = New Structure("Article, IsAbstract, DataType, ValueType, Pattern, Concept, Axis, Member, PeriodInstant, PeriodStart, PeriodEnd", 
																					"",
																					False,
																					ChartsOfCharacteristicTypes.velpo_ValueDataTypes.EmptyRef(),
																					Undefined,
																					"",
																					ChartsOfAccounts.velpo_Reporting.EmptyRef(),
																					ChartsOfCharacteristicTypes.velpo_HypercubeAxes.EmptyRef(),
																					Catalogs.velpo_MemberValues.EmptyRef(),
																					'0001-01-01', '0001-01-01', '0001-01-01');
																					
	AspecrtRulesArray = SettingsVar.AspectRules.FindRows(New Structure("NodeRef", NodeRef));
	For Each AspectRule In  AspecrtRulesArray Do
		If  AspectRule.AspectRuleType = Enums.velpo_AspectRuleType.Concept Then
			ConceptLine = AspectRule.Concept[0];
			FillPropertyValues(RuleNodeStructure, ConceptLine);
		ElsIf AspectRule.AspectRuleType = Enums.velpo_AspectRuleType.ExplicitDimension Then
			ExplicitDimensionLine = AspectRule.ExplicitDimension[0];
			FillPropertyValues(RuleNodeStructure, ExplicitDimensionLine);
		ElsIf AspectRule.AspectRuleType = Enums.velpo_AspectRuleType.Period Then
			PeriodLine = AspectRule.Period[0];
			FillPropertyValues(RuleNodeStructure, PeriodLine);
			RuleNodeStructure.PeriodInstant = SettingsVar.InstanceDate;
			If PeriodLine.AttributeType = Enums.velpo_AttributeTypes.Instant Then 
				If  PeriodLine.Instant = "$par:refPeriodEnd" Then
					RuleNodeStructure.PeriodInstant = SettingsVar.InstanceDate;
				ElsIf PeriodLine.Instant = "$par:startMonth"Then
					RuleNodeStructure.PeriodInstant = BegOfDay(BegOfMonth(SettingsVar.InstanceDate) - 1);
				ElsIf PeriodLine.Instant = "$par:startRepYear" Then
					RuleNodeStructure.PeriodInstant = BegOfDay(BegOFYear(SettingsVar.InstanceDate) - 1);
				Else
					RuleNodeStructure.PeriodInstant = SettingsVar.InstanceDate;
				EndIf;
				RuleNodeStructure.Article = ?(RuleNodeStructure.Article = "", Format(RuleNodeStructure.PeriodInstant, "DF=dd.MM.yyyy"), "");
			Else // duration
				If	PeriodLine.Start = "$par:startRepYear + xsd:dayTimeDuration('P1D')" Then
					RuleNodeStructure.PeriodStart = BegOFYear(SettingsVar.InstanceDate);
				EndIf;
				If	PeriodLine.Start = "$par:refPeriodEnd" Then
					RuleNodeStructure.PeriodEnd = SettingsVar.InstanceDate;
				EndIf;
				RuleNodeStructure.Article = ?(RuleNodeStructure.Article = "", Format(RuleNodeStructure.PeriodStart, "DF=dd.MM.yyyy") + "-" + Format(RuleNodeStructure.PeriodEnd, "DF=dd.MM.yyyy"), "");
			EndIf;
	
		EndIf;
	EndDo;
	
	Return RuleNodeStructure;

EndFunction // GetNodeArticle()

//  Add attribute to collection
//
&AtServer
Function AddFormAttribute(SettingsVar, AxisBreakdown, Val Name, Val Title, Val ValueType)

	AspectTable = SettingsVar.AspectTables[AxisBreakdown];
	
	If AxisBreakdown = Enums.velpo_AxisBreakdowns.Z Then
		Path = "AspectsTableZ";
	ElsIf AxisBreakdown = Enums.velpo_AxisBreakdowns.Y Then
		Path = "AspectsTableZ.AspectsTableY";
	ElsIf AxisBreakdown = Enums.velpo_AxisBreakdowns.X Then
		Path = "AspectsTableZ.AspectsTableY.AspectsTableX";
	EndIf;
	AttribPath = Path + "." + Name;
	
	Attrib =  SettingsVar.FormAttributes[AttribPath];
	If Attrib <> Undefined Then
		Return AttribPath;
	EndIf;
	
	If AxisBreakdown = Enums.velpo_AxisBreakdowns.X Then
		ThisForm.ColumnsX.Add(Name);
	ElsIf AxisBreakdown = Enums.velpo_AxisBreakdowns.Y Then
		ThisForm.ColumnsY.Add(Name);
	ElsIf AxisBreakdown = Enums.velpo_AxisBreakdowns.Z Then
		ThisForm.ColumnsZ.Add(Name);
	EndIf;
	
	If ValueType = Undefined Then
		ValueType  = velpo_TaxonomyUpdateServerCashed.GetAllTypes();
	EndIf;
	
	AspectTable.Columns.Add(Name, ValueType, Title);
	Attrib = New  FormAttribute(Name, ValueType, Path, Title);
	SettingsVar.FormAttributes.Insert(AttribPath,  Attrib);
	
	Return AttribPath;
	
EndFunction // AddFormAttribute()

// Get main label
&AtServer
Function GetMainArticleLabel(Label, NodeLabelStructure, UseCode = True)

	If  NodeLabelStructure.Code = "" Or  Not UseCode Then
		Return ?(NodeLabelStructure.Article = "", Label, NodeLabelStructure.Article);
	Else
		Return NodeLabelStructure.Code;
	EndIf;

EndFunction // GetMainArticleLabel() 


//  Set a new node description in column tree
//
//
&AtServer
Function AddColumnNode(SettingsVar, ColumnTree, NodeId, Title, Code, Path, DataType, ValueType,  NodeDataStructure, IsAbstract = False, IsMerge = False, NotEmpty = False)
	
	// add enum
	AddEnumValues(SettingsVar, DataType);
	
	ColumnNode = ColumnTree.Rows.Add();
	ColumnNode.Name = StrReplace(Path, ".", "_");
	ColumnNode.NodeId = NodeId;
	ColumnNode.Title = Title;
	ColumnNode.Code = Code;
	ColumnNode.Path = Path;
	ColumnNode.DataType = DataType;
	ColumnNode.IsAbstract = IsAbstract;
	ColumnNode.HasCode = ValueIsFilled(Code);
	ColumnNode.NodeData = NodeDataStructure;
	ColumnNode.NotEmpty = NotEmpty;
	
	If ValueType = Undefined And Not StrStartsWith(Path, "Group_") Then
		PathArray = StrSplit(Path, ".", False);
		PathIndex = PathArray.UBound() - 1;
		If ThisForm.IsEnglish Then
			ColumnNode.TypeLink = "Items." + PathArray[PathIndex] + ".CurrentData.DataType";
		Else
			ColumnNode.TypeLink = "Элементы." + PathArray[PathIndex] + ".ТекущиеДанные.DataType";
		EndIf;
	EndIf;
	
	// is data
	If  Not IsAbstract Then
		// add model data
		AddModelData(SettingsVar, NodeId, NodeDataStructure, ColumnNode);
	EndIf;
			
	Return ColumnNode;
	
EndFunction // AddColumnNode()

// add model data
//
&AtServer
Procedure AddModelData(SettingsVar, NodeId, NodeDataStructure, ColumnNode = Undefined)

	ModelArray = SettingsVar.ModelMap[NodeId];
	If ModelArray = Undefined Then
		ModelArray = New Array;
		SettingsVar.ModelMap.Insert(NodeId, ModelArray);
	EndIf;
	
	ModelArray.Add(NodeDataStructure);
	
	// parent data
	If  ColumnNode <> Undefined Then
		CurParent = ColumnNode.Parent;
		While CurParent <> Undefined Do
			ModelArray.Add(CurParent.NodeData);
			CurParent = CurParent.Parent;
		EndDo;
	EndIf;
	
EndProcedure // AddModelData()

// add pattern to list
//
Procedure AddPatternValue(Name, Pattern)

	If Not ValueIsFilled(Pattern) Then
		Return
	EndIf;
	
	If ThisForm.PatternsList.FindByValue(Name) = Undefined Then
		ThisForm.PatternsList.Add(Name, Pattern)
	EndIf;

EndProcedure // AddPatternValue()

// add pattern to list
//
Procedure AddEnumValues(SettingsVar, DataType)
	
	FilterStructure = New Structure("DataType", DataType);
	EnumsArray = SettingsVar.EnumsTable.FindRows(FilterStructure);
	If EnumsArray.Count() = 0 Then
		Return
	EndIf;
	
	// check if have set it
	If SettingsVar.EnumsMap[DataType] = Undefined Then
		EnumsList = New ValueList;
		For Each EnumMemberLine In EnumsArray Do
			EnumsList.Add(EnumMemberLine.Member, EnumMemberLine.MemberLabel);
		EndDo; 
		 SettingsVar.EnumsMap.Insert(DataType, EnumsList);
	EndIf;

EndProcedure // AddPatternValue()

// make new attrib 
&AtServer
Procedure SetTableAttributes(SettingsVar, BreakdownData, ColumnTree, Nodes = Undefined)

	If  TypeOf(Nodes) <> Type("Structure") Then
		Nodes.Rows.Sort("Order");
	EndIf;
	
	For Each Node In Nodes.Rows Do
		
		LabelStructure = GetNodeLabelData(SettingsVar, Node.NodeRef);

		NodeDataStructure = New Structure("IsAspect, Concept, Axis, Member, PeriodInstant, PeriodStart, PeriodEnd", False);
		
		// set rule as new line in Z and X and column in Y
		If Node.NodeType = Enums.velpo_DefinitionNodeTypes.Rule Then
			
			RuleNode = Node.RuleNode[0]; 
			RuleNodeStructure = GetRuleNodeDefinition(SettingsVar, Node.NodeRef);
			
			FillPropertyValues(NodeDataStructure, RuleNodeStructure);
			
			
			AddPatternValue(Node.NodeID, RuleNodeStructure.Pattern);
					
			// check if concept is abstract
			IsAbstract = ?(RuleNode.IsAbstract, True, RuleNodeStructure.IsAbstract);
	
			
			If  BreakdownData.AxisBreakdown = Enums.velpo_AxisBreakdowns.X Then
				If IsAbstract Then
					Path = "Group_" + Node.NodeID;
				Else
					Path = AddFormAttribute(SettingsVar, 
														BreakdownData.AxisBreakdown, 
														Node.NodeID, 
														GetMainArticleLabel(RuleNodeStructure.Article, LabelStructure), 
														RuleNodeStructure.ValueType);
				EndIf;									
				
				ColumnNode = AddColumnNode(SettingsVar, 
													ColumnTree, 
													Node.NodeID,
													GetMainArticleLabel(RuleNodeStructure.Article, LabelStructure, False),
													LabelStructure.Code, 
													Path, 
													RuleNodeStructure.DataType,
													RuleNodeStructure.ValueType,
													NodeDataStructure,
													IsAbstract,
													RuleNode.IsMerge);
														
				
			Else
				
				If BreakdownData.AxisBreakdown = Enums.velpo_AxisBreakdowns.Y Then
					LocAxis = Enums.velpo_AxisBreakdowns.X;
				Else
					LocAxis = BreakdownData.AxisBreakdown;
				EndIf;
				LineAspects = SettingsVar.AspectTables[LocAxis].Add();
				LineAspects.NodeId = Node.NodeID;
				TabStr = "";
				NodeLevel = Node.Level();
				For i = 1  To NodeLevel Do
					TabStr = TabStr + "	";
				EndDo; 
				LineAspects.Arcticle = TabStr + GetMainArticleLabel(RuleNodeStructure.Article, LabelStructure, False);
				LineAspects.Code = LabelStructure.Code;
				LineAspects.NodeRef = Node.NodeRef;
				LineAspects.IsAbstract = IsAbstract;
				
				LineAspects.DataType = RuleNodeStructure.DataType;
				// set code
				If ValueIsFilled(LineAspects.Code) Then
					If BreakdownData.AxisBreakdown = Enums.velpo_AxisBreakdowns.Z Then
						ThisForm.ShowCodeZ = True;
					Else
						ThisForm.ShowCodeX = True;
					EndIf;
				EndIf;
				// add enum
				AddEnumValues(SettingsVar, RuleNodeStructure.DataType);
				// add model data
				If Not IsAbstract Then
					// TODO я не отрабатываю строку строк - а нужно.
					AddModelData(SettingsVar, Node.NodeID, NodeDataStructure);
				EndIf;
			EndIf;
			
		ElsIf Node.NodeType = Enums.velpo_DefinitionNodeTypes.DimensionAspect Then 
			
			If BreakdownData.AxisBreakdown = Enums.velpo_AxisBreakdowns.Y Then
				LocalAxis = Enums.velpo_AxisBreakdowns.X;
				LocColumnTree = SettingsVar.ColumnTrees[LocalAxis];
			ElsIf BreakdownData.AxisBreakdown = Enums.velpo_AxisBreakdowns.X Then
				LocalAxis = Enums.velpo_AxisBreakdowns.Y;
				LocColumnTree = SettingsVar.ColumnTrees[LocalAxis];
			Else
				LocalAxis = BreakdownData.AxisBreakdown;
				LocColumnTree = ColumnTree;
			EndIf;
			
			// aspects to column
			AspectNode = Node.AspectNode[0]; 
			
			FillPropertyValues(NodeDataStructure, AspectNode);
			NodeDataStructure.IsAspect = True;
			
			Path = AddFormAttribute(SettingsVar, 
													LocalAxis, 
													Node.NodeID,
													GetMainArticleLabel(AspectNode.AxisLabel, LabelStructure), 
													AspectNode.ValueType);
			LocColumnNode = AddColumnNode(SettingsVar, 
													LocColumnTree, 
													Node.NodeID,
													GetMainArticleLabel(AspectNode.AxisLabel, LabelStructure, False),
													LabelStructure.Code, 
													Path,
													AspectNode.DataType,
													AspectNode.ValueType,
													NodeDataStructure,,,True);
													
			AddPatternValue(Node.NodeID, AspectNode.Pattern);
			// return to main												
			If BreakdownData.AxisBreakdown = Enums.velpo_AxisBreakdowns.X Then 
				ColumnNode = ColumnTree;
			Else
				ColumnNode = LocColumnNode;
			EndIf;
		Else
			Continue;
		EndIf;
		
		// childs
		SetTableAttributes(SettingsVar, BreakdownData, ColumnNode, Node);
		
	EndDo; 
	
EndProcedure

// set data by breakdown
&AtServer
Procedure InitializeTableBreakdown(SettingsVar, AxisBreakdowns)
	
	BreakdownsArray = SettingsVar.Breakdowns.FindRows( New Structure("AxisBreakdown", AxisBreakdowns));
	For Each BreakdownData In BreakdownsArray Do
		NodesArray = SettingsVar.NodsTree.Rows.FindRows(New Structure("Breakdown", BreakdownData.Breakdown));
		NodeTreeStructure = New Structure("Rows", NodesArray);
		SetTableAttributes(SettingsVar, BreakdownData, SettingsVar.ColumnTrees[AxisBreakdowns], NodeTreeStructure);
	EndDo;

EndProcedure

// add attribs to form
&AtServer
Procedure SetFormTablesColumns(SettingsVar)
	AttribsArray = New Array;
	For Each Attrib In SettingsVar.FormAttributes Do
	    	AttribsArray.Add(Attrib.Value);
	EndDo; 
	ThisForm.ChangeAttributes(AttribsArray); 
EndProcedure

// add our main data
&AtServer
Procedure AddFormTablesData(SettingsVar, CurrentTable, Val AxisBreakdown = Undefined)
	
	// data to add
	If AxisBreakdown = Undefined Then
		LocalAxis = Enums.velpo_AxisBreakdowns.Z;
		ChildTable = "AspectsTableY";
	ElsIf AxisBreakdown = Enums.velpo_AxisBreakdowns.Z Then
		LocalAxis = Enums.velpo_AxisBreakdowns.Y;
		ChildTable = "AspectsTableX";
	ElsIf AxisBreakdown = Enums.velpo_AxisBreakdowns.Y Then
		LocalAxis = Enums.velpo_AxisBreakdowns.X;
		ChildTable = Undefined;
	ElsIf AxisBreakdown = Enums.velpo_AxisBreakdowns.X Then
		Return
	EndIf;
	
	AspectTable = SettingsVar.AspectTables[LocalAxis];
	AspectRowCount = AspectTable.Count();
	ColumnTreeCount = SettingsVar.ColumnTrees[LocalAxis].Rows.Count();
	If  LocalAxis <>  Enums.velpo_AxisBreakdowns.X And AspectRowCount = 0 And ColumnTreeCount = 0 Then
		AxisStr = velpo_CommonFunctions.EnumValueName(LocalAxis);
		ThisForm["Hide" + AxisStr] = True;
		AspectTable.Add();
	EndIf;
	   
	For Each ApectLine In AspectTable Do
		CurrentLine = CurrentTable.Add(); 	    	
	    FillPropertyValues(CurrentLine, ApectLine);
		If ChildTable <> Undefined Then
			AddFormTablesData(SettingsVar, CurrentLine[ChildTable], LocalAxis);	
		EndIf;
	EndDo; 
	
EndProcedure

// add form elements
&AtServer
Procedure AddFormTableElement(SettingsVar, Val ColumnNodeTree, Val ParentItem)
	
	// get 
	For Each ColumnNode In ColumnNodeTree.Rows Do
		
		LocParentItem = ParentItem;
		
		If ColumnNode.IsAbstract Or ColumnNode.HasCode Then
			
			ColumnGroup = Items.Add(?(ColumnNode.HasCode, "Group_", "") + ColumnNode.Name,  Type("FormGroup"), ParentItem);
			ColumnGroup.Type = FormGroupType.ColumnGroup;
			If ColumnNode.IsMerge Or ColumnNode.HasCode Then
				ColumnGroup.Group = ColumnsGroup.Vertical;
			Else
				ColumnGroup.Group = ColumnsGroup.Horizontal;
			EndIf;
			
			ColumnGroup.Title  = ColumnNode.Title;
			ColumnGroup.ShowTitle = True;
			ColumnGroup.ShowInHeader = True;	
			ColumnGroup.ToolTip = ColumnNode.Title;
			ColumnGroup.HeaderHorizontalAlign = ItemHorizontalLocation.Center; 
			LocParentItem = ColumnGroup;
			
		EndIf;
		
		// input field
		If Not ColumnNode.IsAbstract Then
		
			ColumnField =  Items.Add(ColumnNode.Name,  Type("FormField"), LocParentItem);
			ColumnField.Type = FormFieldType.InputField;
			ColumnField.DataPath = ColumnNode.Path;	
						
			If ColumnNode.HasCode Then
				ColumnField.Title = ColumnNode.Code;
			Else
				ColumnField.Title = ColumnNode.Title;
			EndIf;
			
			If ValueIsFilled(ColumnNode.TypeLink) Then
				ColumnField.TypeLink = New TypeLink(ColumnNode.TypeLink);
			EndIf;
			
			ColumnField.ShowInHeader = True;				
			ColumnField.HeaderHorizontalAlign = ItemHorizontalLocation.Center;
			ColumnField.BackColor = StyleColors.ReportGroup2BackColor;
			ColumnField.MarkNegatives = True;
			ColumnField.ToolTip = ColumnNode.Title;
			
			EnumsList = SettingsVar.EnumsMap[ColumnNode.DataType];
			If EnumsList <> Undefined Then
				ColumnField.ListChoiceMode = True;
				ColumnField.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
				velpo_CommonFunctionsClientServer.LinkValueList(EnumsList, ColumnField.ChoiceList);
			EndIf;
			
			If ColumnNode.NotEmpty Then
				ColumnField.AutoMarkIncomplete = True;
				ColumnField.AutoChoiceIncomplete = True;
			EndIf;
						
			IsGroup = (ColumnNode.Rows.Count() > 0);
			If  IsGroup Then
				ColumnGroup = Items.Add("Group_Sub_" + ColumnNode.Name,  Type("FormGroup"), LocParentItem);
				ColumnGroup.Type = FormGroupType.ColumnGroup;
				ColumnGroup.Group = ColumnsGroup.Vertical;
				ColumnField.ShowInHeader = False;				
				LocParentItem = ColumnGroup;
			EndIf;
			
		EndIf;
		
		AddFormTableElement(SettingsVar, ColumnNode, LocParentItem);
		
	EndDo;  

EndProcedure // AddFormTableElements() 

// add all elements
&AtServer
Procedure AddFormTablesElements(SettingsVar, AxisBreakdown)
	
	ColumnTree = SettingsVar.ColumnTrees[AxisBreakdown];
	AxisStr = velpo_CommonFunctions.EnumValueName(AxisBreakdown);
	
	// add elements
	AddFormTableElement(SettingsVar, ColumnTree, Items["AspectsTable" + AxisStr]);
	
	// neither columns nor rows
	AspectTableCount = SettingsVar.AspectTables[AxisBreakdown].Count();
	ColumnsCount = ColumnTree.Rows.Count();
	
	// can't insert
	If AspectTableCount > 0 Then
		TableItem = Items["AspectsTable" + AxisStr];
		TableItem.ChangeRowSet = False;
		TableItem.ChangeRowOrder = False;
		If AxisStr = "Z" Then
			Items.AspectsTableZ_Code.Visible = ThisForm.ShowCodeZ;
		ElsIf AxisStr = "X" Then
			Items.AspectsTableX_Code.Visible = ThisForm.ShowCodeX;
		EndIf;
	Else
		Items["AspectsTable" + AxisStr + "_Arcticle"].Visible = False;
		Items["AspectsTable" + AxisStr + "_Code"].Visible = False;
	EndIf;
	
EndProcedure // AddFormTableElements() 

&AtServer
Procedure InitializeTables()

	// 1 get settings
	SettingsVar = GetTableSettings();
	
	// 2 set table breakdowns in this order (!)
	InitializeTableBreakdown(SettingsVar, Enums.velpo_AxisBreakdowns.Z);
	InitializeTableBreakdown(SettingsVar, Enums.velpo_AxisBreakdowns.Y);
	InitializeTableBreakdown(SettingsVar, Enums.velpo_AxisBreakdowns.X);
	
	// 3 change attributes
	SetFormTablesColumns(SettingsVar);
	
	// 4 fill our data
	AddFormTablesData(SettingsVar, ThisForm.AspectsTableZ);
	
	
		// TODO поправить
	TypeAc = ChartsOfCharacteristicTypes.velpo_ValueDataTypes.FindByAttribute("Name", "Tip_Akczionerov_Axis");
	Role = Catalogs.velpo_RoleTypes.FindByAttribute("Name", "http://www.cbr.ru/xbrl/nso/ins/rep/2021-04-01/tab/sr_0420152/Tip_Akczionerov_Axis");
	Query = New Query;
	Query.SetParameter("Role", Role);
	Query.Text = "Select Distinct Member, Member.Description AS Present From Catalog.DefinitionTrees Where Owner = &Role And TreeNodeType = Value(Enum.TreeNodeTypes.Member) And Member.Description <> ""Итого""";
	List = New ValueList;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		List.Add(Selection.Member, Selection.Present);
	EndDo;
	SettingsVar.EnumsMap.Insert(TypeAc,  List);
	
	TypeAc = ChartsOfCharacteristicTypes.velpo_ValueDataTypes.FindByAttribute("Name", "KodVidaDeyatelnostiAxis");
	Role = Catalogs.velpo_RoleTypes.FindByAttribute("Name", "http://www.cbr.ru/xbrl/nso/ins/rep/2021-04-01/tab/sr_0420152/KodVidaDeyatelnostiAxis");
	Query = New Query;
	Query.SetParameter("Role", Role);
	Query.Text = "Select Distinct Member, Member.Description AS Present From Catalog.DefinitionTrees Where Owner = &Role And TreeNodeType = Value(Enum.TreeNodeTypes.Member) And Member.Description <> ""Итого""";
	List = New ValueList;
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		List.Add(Selection.Member, Selection.Present);
	EndDo;
	SettingsVar.EnumsMap.Insert(TypeAc,  List);

	
	// 5 set form elements
	AddFormTablesElements(SettingsVar, Enums.velpo_AxisBreakdowns.Z);
	AddFormTablesElements(SettingsVar, Enums.velpo_AxisBreakdowns.Y);
	AddFormTablesElements(SettingsVar, Enums.velpo_AxisBreakdowns.X);
	
	// 6 set enums
	For Each EnumData In  SettingsVar.EnumsMap Do
		EnumLine = ThisForm.EnumsTable.Add();
		EnumLine.DataType = EnumData.Key;
		EnumLine.Members = velpo_CommonFunctionsClientServer.CopyValueList(EnumData.Value);
	EndDo;
	
	// 7 set model data
	For Each ModelData In SettingsVar.ModelMap Do
		ModelLine = ThisForm.ModelDataTable.Add();
		ModelLine.NodeId = ModelData.Key;
		For Each ModelStructure In ModelData.Value Do
			If Not ModelLine.IsAspect Then
				ModelLine.IsAspect = ModelStructure.IsAspect;
			EndIf;
			ModelLine.Data.Add(ModelStructure);
		EndDo; 
	
	EndDo; 

EndProcedure

&AtServer
Procedure FillTableData()

	CurrentObject = ThisForm.FormAttributeToValue("Object");
	AspectsTable = CurrentObject.TableStorage.Get();
	ThisForm.ValueToFormAttribute(AspectsTable, "AspectsTableZ");

EndProcedure

&AtClient
Procedure ManageVisible()

	If ThisForm.OnlyFilled Then
		Items.CommandOnlyFilled.Title = NStr("en = 'Show hide rows'; ru = 'Показатель скрытые строки'")
	Else
		Items.CommandOnlyFilled.Title = NStr("en = 'Hide unfilled rows'; ru = 'Скрыть незаполненные строки'")
	EndIf;
	
	Items.GroupAspectsTableZ.Visible = Not ThisForm.HideZ;
	Items.GroupAspectsTableY.Visible = Not ThisForm.HideY;

EndProcedure // ManageVisible()

&AtClient
Procedure Attached_HandlerEventOnOpen()

	Items.Pages.CurrentPage = Items.MainPage;
	
	ThisForm.CurrentItem = Items.AspectsTableZ;
	ThisForm.CurrentItem = Items.AspectsTableY;
	
	Items.AspectsTableZ.Refresh();
	Items.AspectsTableY.Refresh();
	
	Items.AspectsTableZ.CurrentRow = 0;
	Items.AspectsTableY.CurrentRow = 0;
	
	ManageVisible();
	ThisForm.IsOpened = True;
	
EndProcedure // Attached_HandlerEventOnActivateListRow()

&AtClient
Procedure Attached_HandlerEventChangeZ()

	Items.Pages.CurrentPage = Items.MainPage;
	ThisForm.CurrentItem = Items.AspectsTableY;
	//Items.AspectsTableY.Refresh();
	Items.AspectsTableY.CurrentRow = 0;	
	ManageVisible();
	
EndProcedure // Attached_HandlerEventOnActivateListRow()

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThisForm.IsEnglish = (Metadata.ScriptVariant = Metadata.ObjectProperties.ScriptVariant.English);
	
	If Object.Ref.IsEmpty() Then
		FillPropertyValues(Object, ThisForm.Parameters);
		Object.Date = ThisForm.Parameters.Period;
	EndIf;
	
	ThisForm.Title = String(Object.RoleTable);

	InitializeTables();

	If Not Object.Ref.IsEmpty() Then
		FillTableData();
	EndIf;

	Items.Pages.CurrentPage = Items.PageInstanceBeingExecuted;
	Items.AspectsTableZ.CurrentRow = 0;
	Items.AspectsTableY.CurrentRow = 0;

EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	AttachIdleHandler("Attached_HandlerEventOnOpen", 0.1, True);
	
EndProcedure

&AtClient
Procedure CommandOnlyFilled(Command)

	ThisForm.OnlyFilled = Not ThisForm.OnlyFilled;
	
	If Not ThisForm.OnlyFilled Then
		FillStructure = New FixedStructure();
	Else
		FillStructure = New FixedStructure(New Structure("IsFilled", ThisForm.OnlyFilled));
	EndIf;
	
	Items.AspectsTableX.RowFilter = 	FillStructure;
	
	ManageVisible();
		
EndProcedure

&AtServer
Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	AspectTables = ThisForm.FormAttributeToValue("AspectsTableZ");
	CurrentObject.TableStorage =  New ValueStorage(AspectTables);
	
EndProcedure

&AtServer
Procedure AddNodeModelData(AxisLine, AxisString, NodeId, ModelTable, PeriodMap, ConceptMap, AxisMap, AspectsOnly = Undefined, IsColumn = False, ColumnName = "")
	
	If IsColumn And AxisString = "X" Then
		AddNodeModelData(AxisLine, AxisString, AxisLine.NodeId, ModelTable, PeriodMap, ConceptMap, AxisMap, AspectsOnly, False, NodeId);
	EndIf;
	
	ModelArray = ModelTable.FindRows(New Structure("NodeId", NodeId));
	If ModelArray.Count() = 0 Then
		Return;
	EndIf;
	
	ModelLine = ModelArray[0];
	
	If AspectsOnly <> Undefined Then
		If AspectsOnly And Not ModelLine.IsAspect Then
			Return;
		ElsIf Not AspectsOnly And ModelLine.IsAspect Then
			Return;
		EndIf;
	EndIf;
	
	ModelList = ModelLine.Data;
	For Each ModelElement In ModelList Do
		
		ModelStructure = ModelElement.Value;
		
		If ValueIsFilled(ModelStructure.Concept) Then
			ValueArray = ConceptMap[ModelStructure.Concept];
			If ValueArray = Undefined Then
				ValueArray = New Array;
				ConceptMap.Insert(ModelStructure.Concept, ValueArray);	
			EndIf;
			If IsColumn Then
				ValueArray.Add(AxisLine[NodeId]);
			Else
				ValueArray.Add(AxisLine[ColumnName]);
			EndIf;
		EndIf;
		
		If ValueIsFilled(ModelStructure.Axis) Then
			If ModelStructure.IsAspect Then
				Member = AxisLine[NodeId];
			Else
				Member = ModelStructure.Member;
			EndIf;
			MemberArray = AxisMap[ModelStructure.Axis];
			If MemberArray = Undefined Then
				MemberArray = New Array;
				AxisMap.Insert(ModelStructure.Axis, MemberArray);
			EndIf;
			MemberArray.Add(Member);
		EndIf;
		
		If ValueIsFilled(ModelStructure.PeriodInstant) Then
			PeriodMap.Insert("Instant", ModelStructure.PeriodInstant);
		EndIf;
		
		If ValueIsFilled(ModelStructure.PeriodStart) Then
			PeriodMap.Insert("StartDate", ModelStructure.PeriodStart);
		EndIf;
		
		If ValueIsFilled(ModelStructure.PeriodEnd) Then
			PeriodMap.Insert("EndDate", ModelStructure.PeriodEnd);
		EndIf;
	
	EndDo; 
	
EndProcedure // AddAxisModelData()

&AtServer
Procedure AddAxisModelData(AxisLine, AxisString, ModelTable, PeriodMap,ConceptMap, AxisMap, AspectsOnly = False)
	
	AxisColumns = ThisForm["Columns" + AxisString];
	For Each AxisColumn In AxisColumns Do
		AddNodeModelData(AxisLine, AxisString, AxisColumn.Value, ModelTable, PeriodMap, ConceptMap, AxisMap, AspectsOnly, True);
	EndDo; 
	
EndProcedure // AddAxisModelData()
  
&AtServer
Procedure OverrrideMap(SourceMap, DestinationMap)

	For Each KeyAndValue In SourceMap Do
		DestinationMap.Insert(KeyAndValue.Key, KeyAndValue.Value);
	EndDo;

EndProcedure // OverrrideMap()

&AtServer
Procedure OnWriteAtServer(Cancel, CurrentObject, WriteParameters)
	
	 ModelTable = ThisForm.FormAttributeToValue("ModelDataTable");
	 ModelTable.Indexes.Add("NodeId");
	 	 
	 // sets
	InstanceRecordsSet = InformationRegisters.velpo_InstanceRecords.CreateRecordSet();
	InstanceRecordsSet.Filter.Instance.Set(CurrentObject.Ref);
	InstanceRecordsSet.Write(True);
	InstanceRecordsTable = InstanceRecordsSet.Unload();
	
	InstanceScenariosSet = InformationRegisters.velpo_InstanceScenarios.CreateRecordSet();
	InstanceScenariosSet.Filter.Instance.Set(CurrentObject.Ref);
	InstanceScenariosSet.Write(True);
	InstanceScenariosTable = InstanceScenariosSet.Unload();
	
	InstancePeriodsSet = InformationRegisters.velpo_InstancePeriods.CreateRecordSet();
	InstancePeriodsSet.Filter.Instance.Set(CurrentObject.Ref);
	InstancePeriodsSet.Write(True);
	InstancePeriodsTable = InstancePeriodsSet.Unload();
	
	// iteration
	For Each LineZ In ThisForm.AspectsTableZ  Do
		
		AxisZMap = New Map;
		ConceptZMap = New Map;
		PeriodZMap = New Map;
		
		AddAxisModelData(LineZ, "Z", ModelTable, PeriodZMap, ConceptZMap, AxisZMap);
		
		For Each LineY In LineZ.AspectsTableY  Do
			
			AxisYMap = New Map;
			ConceptYMap = New Map;
			PeriodYMap = New Map;
			
			AddAxisModelData(LineY, "Y", ModelTable, PeriodYMap, ConceptYMap, AxisYMap);
			
			For Each LineX In LineY.AspectsTableX Do
				
				AxisXMap = New Map;
				ConceptXMap = New Map;
				PeriodXMap = New Map;
				
				OverrrideMap(AxisZMap, AxisXMap); 
				OverrrideMap(AxisYMap, AxisXMap);
				
				OverrrideMap(ConceptZMap, ConceptXMap); 
				OverrrideMap(ConceptYMap, ConceptXMap);
				
				OverrrideMap(PeriodZMap, PeriodXMap); 
				OverrrideMap(PeriodYMap, PeriodXMap);
				
				AddAxisModelData(LineX, "X", ModelTable, PeriodXMap, ConceptXMap, AxisXMap, True);

				For Each AxisColumn In ThisForm.ColumnsX Do
					
					AxisСellMap = New Map;
					ConceptCellMap = New Map;
					PeriodCellMap = New Map;
					
					OverrrideMap(AxisXMap, AxisСellMap); 
					OverrrideMap(ConceptXMap, ConceptCellMap); 
					OverrrideMap(PeriodXMap, PeriodCellMap);
					
					
					AddNodeModelData(LineX, "X", AxisColumn.Value, ModelTable, PeriodCellMap, ConceptCellMap, AxisСellMap, False, True);
					
					// concept
					For Each ConceptData In ConceptCellMap Do
						
						// eache value
						For Each ConceptValue In ConceptData.Value Do
							
							If Not ValueIsFilled(ConceptValue) Then
								Continue;
							EndIf;
							
							// TODO 
							// нужно оптимизировать 
							RecordID = New UUID;
							InstanceRecord = InstanceRecordsTable.Add();	
							InstanceRecord.Instance = CurrentObject.Ref;
							InstanceRecord.RecordID = RecordID;
							InstanceRecord.Concept = ConceptData.Key;
							InstanceRecord.Value = ConceptValue;
							If TypeOf(InstanceRecord.Value) = Type("String") Then
								If InstanceRecord.Value <> String(ConceptValue) Then
									InstanceRecord.Text = String(ConceptValue);
								EndIf;
							EndIf;
							InstanceRecord.ScenarioID = RecordID;
							InstanceRecord.PeriodID = RecordID;
							
							InstancePeriod = InstancePeriodsTable.Add();	
							InstancePeriod.Instance = CurrentObject.Ref;
							InstancePeriod.PeriodID = RecordID;
							InstancePeriod.StartDate = PeriodCellMap["StartDate"];
							InstancePeriod.EndDate = PeriodCellMap["EndDate"];
							InstancePeriod.Instant = PeriodCellMap["Instant"];
							
							If Not ValueIsFilled(InstancePeriod.Instant)
								And Not ValueIsFilled(InstancePeriod.StartDate)
								And Not ValueIsFilled(InstancePeriod.Instant) Then
								InstancePeriod.Instant = CurrentObject.Date;
							EndIf;
							
							// set scenarions
							i = 0;
							For Each AxisData In AxisСellMap  Do
								For Each AxisValue In AxisData.Value Do
									i = i + 1;	
									InstanceScenario = InstanceScenariosTable.Add();	
									InstanceScenario.Instance = CurrentObject.Ref;
									InstanceScenario.ScenarioID = RecordID;
									InstanceScenario.Number = i;	
									InstanceScenario.Axis = AxisData.Key;
									InstanceScenario.Value = AxisValue;
								EndDo; 
							EndDo; 
						EndDo; 
					EndDo; 
				EndDo; 
			EndDo;
		EndDo;
	EndDo; 
	
	InstanceRecordsSet.Load(InstanceRecordsTable);
	InstanceRecordsSet.Write(False);
		
	InstanceScenariosSet.Load(InstanceScenariosTable);
	InstanceScenariosSet.Write(False);
	
	InstancePeriodsSet.Load(InstancePeriodsTable);
	InstancePeriodsSet.Write(False);
		
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	  Notify("NotifyWritingInstance");
	
EndProcedure

&AtClient
Procedure AspectsTableXBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	If Not Cancel Then
		CurrentData = Items.AspectsTableX.CurrentData;
		If CurrentData = Undefined Then
			Return
		EndIf;
		IsFilled = False;
		IsCleared = False;
		For Each ColumnItem In ThisForm.ColumnsX Do
			ColumnName = ColumnItem.Value;
			LocValue = CurrentData[ColumnName];
			
			// check pattern
			If ValueIsFilled(LocValue) And TypeOf(LocValue) = Type("String") Then
				IsRowNode = ValueIsFilled(CurrentData.NodeId);
				If IsRowNode Then
					PatternPath = CurrentData.NodeId;
				Else
					PatternPath = ColumnName; 
				EndIf;
				
				LocPattern =  ThisForm.PatternsList.FindByValue(PatternPath);
				If LocPattern <> Undefined Then
					Pattern = LocPattern.Presentation;
					test = velpo_TaxonomyUpdateClientServerCached.TestFacetString(Pattern, LocValue);
					If Not test Then
						
						ItemPath = "AspectsTableZ_AspectsTableY_AspectsTableX_" + ColumnName;
						
						If Not IsCleared Then
							ClearMessages();
							IsCleared = True;
						EndIf;
						
						TextMessage = 
						velpo_StringFunctionsClientServer.SubstituteParametersInString(
							NStr("en = '%1 = %2 is not valid for %3.'; ru = '%1 = %2 не прошло проверку шаблоном %3.'"),
							?(IsRowNode, CurrentData.Arcticle, Items[ItemPath].ToolTip),
							String(LocValue),
							Pattern);
						
						LocDataPath = "AspectsTableZ[" + Items.AspectsTableZ.CurrentRow + "].AspectsTableY[" + Items.AspectsTableY.CurrentRow + "].AspectsTableX[" + Items.AspectsTableX.CurrentRow + "]." + ColumnName;
						
						velpo_CommonFunctionsClientServer.MessageToUser(
							TextMessage,, ItemPath, LocDataPath);
							
					EndIf;
				EndIf;
			EndIf;
						
			// check is filled
			If ValueIsFilled(LocValue) Then
				IsFilled = True;
			EndIf;
		EndDo; 
		CurrentData.IsFilled = IsFilled;
	EndIf;
	
EndProcedure

&AtClient
Procedure AspectsTableZOnActivateRow(Item)
	
	If ThisForm.HideY And ThisForm.IsOpened Then
		Items.Pages.CurrentPage = Items.PageInstanceBeingExecuted;
		Items.GroupAspectsTableY.Visible = True;
		AttachIdleHandler("Attached_HandlerEventChangeZ", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure AspectsTableBeforeRowChange(Item, Cancel)
	
	If Cancel Then
		Return;
	EndIf;
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	If ValueIsFilled(CurrentData.DataType) Then
		
		EnumArray = ThisForm.EnumsTable.FindRows(New Structure("DataType", CurrentData.DataType));
		IsEnum = (EnumArray.Count() > 0);
		ItemName = Item.Name;
		AxisStr = Right(ItemName, 1);
		
		If AxisStr = "Z" Then
			Path = "AspectsTableZ";
		ElsIf AxisStr = "Y" Then
			Path = "AspectsTableZ_AspectsTableY";
		Else
			Path = "AspectsTableZ_AspectsTableY_AspectsTableX";
		EndIf;
			
		ColumnsList = ThisForm["Columns" + AxisStr];
		For Each ColumnItem In ColumnsList Do
			LocName = ColumnItem.Value;
			FormItem = Items[Path + "_" + LocName];
			If Not IsEnum And Not FormItem.ListChoiceMode Then
				Continue;
			EndIf;
			FormItem.ListChoiceMode = False;
			FormItem.ChoiceList.Clear();
			If IsEnum Then
				FormItem.ListChoiceMode = IsEnum;
				FormItem.ChoiceHistoryOnInput = ChoiceHistoryOnInput.DontUse;
				velpo_CommonFunctionsClientServer.LinkValueList(EnumArray[0].Members, FormItem.ChoiceList);
			EndIf;
		EndDo; 
	EndIf;
	
EndProcedure

&AtClient
Procedure AspectsTableOnEditEnd(Item, NewRow, CancelEdit)
	
	ThisForm.Modified = True;
	
EndProcedure

&AtClient
Procedure AspectsTableAfterDeleteRow(Item)
	
	ThisForm.Modified = True;
	
EndProcedure




