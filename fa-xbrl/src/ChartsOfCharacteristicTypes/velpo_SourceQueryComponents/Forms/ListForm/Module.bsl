///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServerNoContext
Function GetComponentRefs(Source)
	
	Query = New Query;
	Query.SetParameter("Source", Source);
	Query.Text =
	"SELECT DISTINCT
	|	CASE
	|		WHEN UseDefaults THEN Defaults
	|		ELSE Ref
	|	END AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents
	|WHERE
	|	Ref IN HIERARCHY (&Source)
	|";
	Return Query.Execute().Unload().UnloadColumn("Ref");
		
EndFunction // GetComponentRefs()

&AtServer
Function GetAxisTypeConceptsTextQuery()

	Text = 
	"SELECT
	|	// 0
	|	RoleTypes.RoleType AS RoleType
	|INTO TMP_RoleTypes
	|FROM
	|	Catalog.velpo_RoleTables.RoleTypes AS RoleTypes
	|WHERE
	|	RoleTypes.Ref = &RoleTable
	|
	|INDEX BY
	|	RoleType
	|;
	|
	|SELECT
	|	// 1
	|	RoleTypesConcepts.Concept AS Concept,
	|	RoleTypesConcepts.Concept.ConceptVariant AS Variant
	|INTO TMP_Concepts
	|FROM
	|	Catalog.RoleTypes.Concepts AS RoleTypesConcepts
	|WHERE
	|	RoleTypesConcepts.Ref IN
	|			(SELECT
	|				TMP_RoleTypes.RoleType
	|			FROM
	|				TMP_RoleTypes)
	|
	|INDEX BY
	|	Concept,
	|	Variant
	|;
	|
	|SELECT
	|	// 2
	|	RoleTypesAxisTypes.AxisType AS AxisType
	|FROM
	|	Catalog.RoleTypes.AxisTypes AS RoleTypesAxisTypes
	|WHERE
	|	RoleTypesAxisTypes.Ref IN
	|			(SELECT
	|				TMP_RoleTypes.RoleType
	|			FROM
	|				TMP_RoleTypes)
	|";
	
	Если НЕ ThisForm.ShowAxleByTable Тогда
		Text = Text +
		"
		|UNION
		|
		|SELECT
		|	ReportingExtDimensionTypes.ExtDimensionType
		|FROM
		|	ChartOfAccounts.Reporting.ExtDimensionTypes AS ReportingExtDimensionTypes
		|WHERE
		|	ReportingExtDimensionTypes.Ref IN " + ?(ThisForm.ShowSubConcepts, "HIERARCHY", "") + "
		|			(SELECT
		|				TMP_Concepts.Concept
		|			FROM
		|				TMP_Concepts
		|			WHERE
		|				TMP_Concepts.Variant = VALUE(Enum.ConceptVariants.Measure))
		|";
	КонецЕсли;
		
	Text = Text +
	"
	|;
	|
	|SELECT
	|	// 3
	|	Ref AS Concept
	|FROM
	|	ChartOfAccounts.velpo_Reporting
	|WHERE
	|	Ref IN " + ?(ThisForm.ShowSubConcepts, "HIERARCHY", "") + "
	|			(SELECT
	|				TMP_Concepts.Concept
	|			FROM
	|				TMP_Concepts
	|			)
	|";
	
	Return Text; 

EndFunction // GetAxisTypeConceptsTextQuery() 

&AtServer
Procedure SetParametersAxisTypeConceptsAtServer()

	//TempTablesManager = New TempTablesManager;
	//Query = New Query;
	//Query.TempTablesManager = TempTablesManager;
	//Query.SetParameter("RoleTable", ThisForm.RoleTable);
	//Query.Text = GetAxisTypeConceptsTextQuery();
	//
	//ParResults = Query.ExecuteBatch();
	//AxisTypesArray = ParResults[2].Unload().UnloadColumn("AxisType");
	//ConceptsArray = ParResults[3].Unload().UnloadColumn("Concept");
	
	AxisTypesArray = New Array;
	ConceptsArray = New Array;
	
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(Axes, "RoleTable",  ThisForm.RoleTable, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(AxisTypes, "AxisTypesArray",  AxisTypesArray, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(AxisTypes, "Result",  ThisForm.CurrentResult, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "ConceptsArray",  ConceptsArray, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "ShowAllMapping",  ThisForm.ShowAllMapping, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "ShowConceptByAxisType",  ThisForm.ShowConceptByAxisType, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "AxisType",  Undefined, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "Result",  ThisForm.CurrentResult, True);
	
	//TempTablesManager.Close();
	
EndProcedure // SetParametersAxisTypeConceptsAtServer()

&AtClient
Procedure Attached_HandlerEventOnActivateListRow()

	ListDataAxisTypes = ThisForm.Items.AxisTypes.CurrentData;
	If ListDataAxisTypes = Undefined Then
		velpo_CommonFunctionsClientServer.SetDynamicListParameter(Axes, "AxisType",  Undefined, True);
		velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "AxisType",  Undefined, True);
	Else
		velpo_CommonFunctionsClientServer.SetDynamicListParameter(Axes, "AxisType",  ListDataAxisTypes.Ref, True);
		velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "AxisType",  ListDataAxisTypes.Ref, True);
	EndIf;
	
	If ThisForm.SetFieldBy = 0 Then
		SetNewResult = False;
		
		ListData = ThisForm.Items.List.CurrentData;
		
		If ListData = Undefined Then
			velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "Owner");
			ThisForm.CurrentResult = Undefined;
			SetNewResult = True;
		ElsIf ListData.IsFolder Then
			velpo_CommonFunctionsClientServer.SetDynamicListFilterItem(FieldQueryLinks, "Owner",  GetComponentRefs(ListData.Ref),  DataCompositionComparisonType.InList, False, True);
			If  ThisForm.CurrentResult <> ListData.Ref Then
				ThisForm.CurrentResult = ListData.Ref;
				SetNewResult = True;
			EndIf;
		Else
			velpo_CommonFunctionsClientServer.SetDynamicListFilterItem(FieldQueryLinks, "Owner",  ?(ListData.UseDefaults, ListData.Defaults, ListData.Ref),  DataCompositionComparisonType.Equal, False, True);
			If  ThisForm.CurrentResult <> ListData.Parent Then
				ThisForm.CurrentResult = ListData.Parent;
				SetNewResult = True;
			EndIf;
		EndIf;
		
		If SetNewResult Then
			velpo_CommonFunctionsClientServer.SetDynamicListParameter(AxisTypes, "Result",  ThisForm.CurrentResult, True);
			velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "Result",  ThisForm.CurrentResult, True);
			velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "ShowAllMapping",  ThisForm.ShowAllMapping, True);
			velpo_CommonFunctionsClientServer.SetDynamicListParameter(Concepts, "ShowConceptByAxisType",  ThisForm.ShowConceptByAxisType, True);
		EndIf;
		
		velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "AxisType");
		velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "Concept");	
				
		Items.FieldQueryLinksSource.Visible = False;
		Items.FieldQueryLinksResult.Visible = False;
		
	ElsIf ThisForm.SetFieldBy = 1 Then
		
		ListData = ThisForm.Items.AxisTypes.CurrentData;
		
		If ListData = Undefined Then
			velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "AxisType");
		Else
			velpo_CommonFunctionsClientServer.SetDynamicListFilterItem(FieldQueryLinks, "AxisType",  ListData.Ref,  DataCompositionComparisonType.Equal, False, True);
		EndIf;
		
		velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "Owner");
		velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "Concept");
		
		Items.FieldQueryLinksSource.Visible = True;
		Items.FieldQueryLinksResult.Visible = True;

	ElsIf ThisForm.SetFieldBy = 2 Then
		
		ListData = ThisForm.Items.Concepts.CurrentData;
		
		If ListData = Undefined Then
			velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "Concept");
		Else
			velpo_CommonFunctionsClientServer.SetDynamicListFilterItem(FieldQueryLinks, "Concept",  ListData.Ref,  DataCompositionComparisonType.Equal, False, True);
		EndIf;
		
		velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "Owner");
		velpo_CommonFunctionsClientServer.DeleteDynamicListFilterCroupItems(FieldQueryLinks, "AxisType");
		
		Items.FieldQueryLinksSource.Visible = True;
		Items.FieldQueryLinksResult.Visible = True;
		
	EndIf;

EndProcedure // Attached_HandlerEventOnActivateListRow()

&AtClient
Procedure AddToAxisTypes(Command)

	ListData = ThisForm.Items.List.CurrentData;
	AxisTypesData = ThisForm.Items.AxisTypes.CurrentData;
	
	OpenForm("Catalog.velpo_FieldQueryLinks.ObjectForm", New Structure("Field, Result, AxisType", ListData.Ref, ListData.Parent, AxisTypesData.Ref), ThisForm); 
	
EndProcedure

&AtClient
Procedure AddToConcepts(Command)
	
	ListData = ThisForm.Items.List.CurrentData;
	ConceptsData = ThisForm.Items.Concepts.CurrentData;
	
	OpenForm("Catalog.velpo_FieldQueryLinks.ObjectForm", New Structure("Field, Result, Concept", ListData.Ref, ListData.Parent, ConceptsData.Ref), ThisForm); 
	
EndProcedure

&AtClient
Procedure ListOnActivateRow(Item)
	
	AttachIdleHandler("Attached_HandlerEventOnActivateListRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure FieldQueryLinksBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	If Clone Then
		Return;
	EndIf;
	
	Cancel = True;
	ListData = ThisForm.Items.List.CurrentData;
	If ListData = Undefined Or ListData.IsFolder Then
		Cancel = True;
		Return;
	EndIf;

	OpenForm("Catalog.velpo_FieldQueryLinks.ObjectForm", New Structure("Field, Result", ListData.Ref, ListData.Parent), Item); 
	
EndProcedure

&AtClient
Procedure TaxonomyOnChange(Item)
	SetParametersAxisTypeConceptsAtServer();
EndProcedure

&AtClient
Procedure RoleTableOnChange(Item)
	SetParametersAxisTypeConceptsAtServer();
EndProcedure

&AtClient
Procedure ShowSubConceptsOnChange(Item)
	SetParametersAxisTypeConceptsAtServer();
EndProcedure

&AtClient
Procedure ShowAxleByTableOnChange(Item)
	SetParametersAxisTypeConceptsAtServer();
EndProcedure

&AtClient
Procedure SetFieldByOnChange(Item)
	AttachIdleHandler("Attached_HandlerEventOnActivateListRow", 0.1, True);
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Attached_HandlerEventOnActivateListRow();
	AttachIdleHandler("Attached_HandlerEventOnActivateListRow", 0.1, True);
		
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	SetParametersAxisTypeConceptsAtServer();
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "NewLink" Then
		Items.AxisTypes.Refresh();
		Items.Concepts.Refresh();
	ElsIf EventName = "SourceSettingsIsLoaded" Then
		Items.List.Refresh();
	EndIf;
	
EndProcedure

&НаКлиенте
Процедура ConceptsПриАктивизацииСтроки(Элемент)
	AttachIdleHandler("Attached_HandlerEventOnActivateListRow", 0.1, True);
КонецПроцедуры

&НаКлиенте
Процедура AxisTypesПриАктивизацииСтроки(Элемент)
	AttachIdleHandler("Attached_HandlerEventOnActivateListRow", 0.1, True);
КонецПроцедуры

&AtClient
Procedure ShowConceptByAxisTypeOnChange(Item)
	SetParametersAxisTypeConceptsAtServer();
	AttachIdleHandler("Attached_HandlerEventOnActivateListRow", 0.1, True);
EndProcedure

&НаКлиенте
Процедура AxesВыбор(Элемент, ВыбраннаяСтрока, Поле, СтандартнаяОбработка)
	
	ОткрытьФорму("Справочник.DomainMembers.ФормаОбъекта", Новый Структура("Ключ", ВыбраннаяСтрока.Axis), Элемент);
	
КонецПроцедуры



