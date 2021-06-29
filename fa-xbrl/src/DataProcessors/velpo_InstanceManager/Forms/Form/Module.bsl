///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServer
Function UnloadInstanceAtServer(InstanceFile)
	
	Obj = DataProcessors.velpo_InstanceFileUnload.Create();
	FillPropertyValues(Obj, Object, "BusinessUnit,Taxonomy,EntryPoint,Period");
	Obj.InstanceFile = InstanceFile; 
	
	Return Obj.UnloadInstance();
	                      
EndFunction // UnloadInstanceAtServer()

&AtClient
Procedure ChangePeriodByMonth(Item, Direction)
	
	Object.Period = EndOfMonth(AddMonth(Object.Period, Direction));
	ItemOnChange(Item);
	
EndProcedure // ChangePeriodByMonth()

&AtClient
Procedure Attached_HandlerEventOnHeaderChange()

	velpo_CommonFunctionsClientServer.SetDynamicListParameter(RoleTables, "Period",  Object.Period, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(RoleTables, "Taxonomy",  Object.Taxonomy, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(RoleTables, "BusinessUnit",  Object.BusinessUnit, True);
	velpo_CommonFunctionsClientServer.SetDynamicListParameter(RoleTables, "EntryPoint",  Object.EntryPoint, True);
	
EndProcedure // Attached_HandlerEventOnActivateListRow()

&AtClient
Procedure ItemOnChange(Item)
	
	AttachIdleHandler("Attached_HandlerEventOnHeaderChange", 0.1, True);
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)

	If Not ValueIsFilled(Object.Period) Then
		Object.Period = EndOfMonth(CurrentDate());
	EndIf;
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	Attached_HandlerEventOnHeaderChange();
	AttachIdleHandler("Attached_HandlerEventOnHeaderChange", 0.1, True);
	
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
Procedure RoleTablesSelection(Item, SelectedRow, Field, StandardProcessing)
	
	StandardProcessing = False;
	FormParameters = New Structure("BusinessUnit, Taxonomy, EntryPoint, Period, RoleTable");
	FillPropertyValues(FormParameters, Object);
	FormParameters.RoleTable = SelectedRow.RoleTable;
		
	If ValueIsFilled(SelectedRow.Instance) Then
		FormParameters.Insert("Key", SelectedRow.Instance);
	EndIf;
	
	OpenForm("Document.Instance.ObjectForm", FormParameters, ThisForm);

EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "NotifyWritingInstance" Then
		Items.RoleTables.Refresh();
	EndIf;
	
EndProcedure

&AtClient
Procedure InstanceFileSelectionCompletion(Val FileNameArray, Val AdditionalParameters) Export
	
	ClearMessages();
	
	If FileNameArray <> Undefined And FileNameArray.Count() > 0 Then 
		InstanceFile = FileNameArray[0];
		DataAddress = UnloadInstanceAtServer(InstanceFile);
		velpo_BusinessReportingClient.SaveInstanceFile(DataAddress, InstanceFile);
	EndIf;
		
EndProcedure

&AtClient
Procedure CommandValidation(Command)
	
	FormParameters = New Structure("BusinessUnit,Taxonomy,EntryPoint,Period");
	FillPropertyValues(FormParameters,Object);
	
	OpenForm("DataProcessor.InstanceManager.Form.ФормаПроверки", 
		FormParameters, 
		ThisForm);
	
EndProcedure

&AtClient
Procedure CommandUnload(Command)
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter",  velpo_StringFunctionsClientServer.SubstituteParametersInString(
			"%1|*.xbrl",
			NStr("en = 'Xbrl instance (*.xbrl)'; ru = 'Файл отчета (*.xbrl)'")));
		
	Notification = New NotifyDescription("InstanceFileSelectionCompletion", ThisForm);
	velpo_BusinessReportingClient.SelectTaxonomyFile(Notification, DialogSettings, FileDialogMode.Save);
	
EndProcedure

&AtClient
Procedure CommandZipPackage(Command)

	FormParameters = New Structure("BusinessUnit,Taxonomy,EntryPoint,Period");
	FillPropertyValues(FormParameters,Object);
	
	OpenForm("DataProcessor.InstanceManager.Form.FormZipPackage", 
		FormParameters, 
		ThisForm);
	
EndProcedure


