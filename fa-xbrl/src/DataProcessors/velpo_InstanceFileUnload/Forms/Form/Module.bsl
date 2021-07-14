///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServer
Function GetRoleTableTaxtQuery()

	Text = 
	"SELECT DISTINCT
	|	Catalog_RoleTables.Ref AS Value,
	|	Catalog_RoleTables.RoleType.LongDescription AS Presentation
	|FROM
	|	Catalog.RoleTables AS Catalog_RoleTables
	|
	|	INNER JOIN Catalog.EntryPoints.RoleTables AS Catalog_EntryPoints_RoleTables
	|	ON Catalog_RoleTables.Ref = Catalog_EntryPoints_RoleTables.RoleTable
	|	AND Catalog_EntryPoints_RoleTables.Ref = &EntryPoint
	|WHERE
	|	Catalog_RoleTables.Owner = &Taxonomy
	|ORDER BY
	|	Catalog_RoleTables.Description
	|";
	
	Return Text;
	
EndFunction // GetRoleTableTaxtQuery()

&AtServer
Procedure FillRoleTablesList()

	Object.RoleTablesList.Clear();
	
	If ValueIsFilled(Object.EntryPoint) Then
		Query = New Query;
		Query.SetParameter("Taxonomy", Object.Taxonomy);
		Query.SetParameter("EntryPoint", Object.EntryPoint);
		Query.Text = GetRoleTableTaxtQuery(); 
		RoleTables = Query.Execute().Unload();
		For Each RoleTable In RoleTables Do
			Object.RoleTablesList.Add(	RoleTable.Value, RoleTable.Presentation, True);
		EndDo;
	EndIf;
	
	CurrFilter = (Object.RoleTablesList.Count() > 0);
	If ThisForm.HasTableFilter <> CurrFilter Then 
		ThisForm.HasTableFilter = CurrFilter;
		ManageFormVisibility(); 
	EndIf;
	
EndProcedure // FillRoleTablesList()

&AtServer
Function UnloadInstanceAtServer()

	Obj = ThisForm.FormAttributeToValue("Object");
	
	Return Obj.UnloadInstance();
	                      
EndFunction // UnloadInstanceAtServer()

&AtServer
Procedure ManageFormVisibility()

	Items.RoleTablesList.Visible = ThisForm.HasTableFilter;

EndProcedure // ManageVisibility()

&AtClient
Procedure ChangePeriodByMonth(Item, Direction)
	
	Object.Period = EndOfMonth(AddMonth(Object.Period, Direction));

EndProcedure // ChangePeriodByMonth()

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not ValueIsFilled(Object.Period) Then
		Object.Period = EndOfMonth(CurrentDate());
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If ValueIsFilled(Parameters.BusinessUnit) Then
		FillPropertyValues(Object, Parameters, "BusinessUnit,Taxonomy,EntryPoint,Period");
		Object.RoleTablesList.Clear();
	EndIf;

	ThisForm.HasTableFilter = (Object.RoleTablesList.Count() > 0);
	ManageFormVisibility();
	
	If Not ThisForm.HasTableFilter Then
		FillRoleTablesList();	
	EndIf;

EndProcedure

&AtClient
Procedure CommandPreviousMonth(Command)

	ChangePeriodByMonth(Command, -1);
	
EndProcedure

&AtClient
Procedure CommandNextMonth(Command)
	
	ChangePeriodByMonth(Command, 1);

EndProcedure

&AtClient
Procedure CommandUnload(Command)
	
	If Not ThisForm.CheckFilling() Then
		Return;
	EndIf;

	DataAddress = UnloadInstanceAtServer();
	
	velpo_BusinessReportingClient.SaveInstanceFile(DataAddress, Object.InstanceFile);
	
EndProcedure

&AtClient
Procedure InstanceFileSelectionCompletion(Val FileNameArray, Val AdditionalParameters) Export
	
	ClearMessages();
	
	If FileNameArray <> Undefined And FileNameArray.Count() > 0 Then 
		Object.InstanceFile = FileNameArray[0];
	EndIf;
	
	RefreshDataRepresentation();
	
EndProcedure

&AtClient
Procedure TaxonomyOnChange(Item)
	
	FillRoleTablesList();
	
EndProcedure

&AtClient
Procedure EntryPointOnChange(Item)
	
	FillRoleTablesList();
	
EndProcedure

&AtClient
Procedure InstanceFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter",  velpo_StringFunctionsClientServer.SubstituteParametersInString(
			"%1|*.xbrl",
			NStr("en = 'Xbrl instance (*.xbrl)'; ru = 'Файл отчета (*.xbrl)'")));
		
	Notification = New NotifyDescription("InstanceFileSelectionCompletion", ThisForm);
	velpo_BusinessReportingClient.SelectTaxonomyFile(Notification, DialogSettings, FileDialogMode.Save);
	
EndProcedure

