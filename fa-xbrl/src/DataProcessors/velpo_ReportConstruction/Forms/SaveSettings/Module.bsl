///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ProceduresAndFunctions

&AtClient
Procedure SettingsFileSelectionCompletion(FileName, AdditionalParameters) Export
	
	ClearMessages();
	
	// change page
	Items.Pages.CurrentPage = Items.PageSourceSettingsSavingBeingExecuted;

	Location = SaveSettingsToStorage();
	
	If Location <> Undefined Тогда
		BinaryData = GetFromTempStorage(Location);
		BinaryData.Write(FileName);
	КонецЕсли;
	
	Items.Pages.CurrentPage = Items.PageSourceList;
	
	Notification = New NotifyDescription("MessageBoxCompletion", ThisForm);
	ShowMessageBox(Notification, NStr("ru = 'Сохранение настроек выполнено!'; en = 'Source settings saving is completed!'"));
	
EndProcedure

&AtClient
Procedure MessageBoxCompletion(AdditionalParameters) Export

	ThisForm.Close();
	
EndProcedure // MessageBoxCompletion()

&AtClient
Procedure RefreshCompletion(Answer, AdditionalParameters) Export
	
	If Answer = DialogReturnCode.No Then
		Return;
	EndIf;
	
	RefreshSourceList();
		
EndProcedure	

#EndRegion

#Region InternalProceduresAndFunctions

&AtServer
Function SaveSettingsToStorage()

	SourceArray = New Array;
	For Each SourceItem In SourceList  Do
		If 	SourceItem.Check Then
			SourceArray.Add(SourceItem.Value);
		EndIf;
	EndDo; 
	
	If SourceArray.Count() > 0 Then
		Return DataProcessors.velpo_ReportConstruction.GetSettingsData(SourceArray);
	Else
		Return Undefined;
	EndIf;
	
EndFunction // SaveSettings()

&AtServer
Procedure RefreshSourceList()

	ThisForm.SourceList = DataProcessors.velpo_ReportConstruction.GetSourceValueList();
	
EndProcedure // RefreshSourceList()

&AtClient
Procedure OpenSourceItem(Row)
	
	If Row = Undefined Then
		Return;
	EndIf;
	
	OpenForm("ChartOfCharacteristicTypes.SourceQueryComponents.FolderForm", New Structure("Key",  SourceList.Get(Row).Value), Items.SourceList);
		
EndProcedure // OpenSourceItem() 

#EndRegion

#Region FormCommandHandlers

&AtClient
Procedure Refresh(Command)
	
	Notification = New NotifyDescription("RefreshCompletion", ThisObject);
	MessageText = NStr("ru = 'Обновить список?'; en = 'Refresh list?'");
	Title = NStr("ru = 'Настройки'; en = 'Settings'");
	ShowQueryBox(Notification, MessageText, QuestionDialogMode.YesNo, 60, DialogReturnCode.Yes, Title, DialogReturnCode.Yes);
	
EndProcedure

&AtClient
Procedure OpenSettingsItem(Command)
	
	OpenSourceItem(Items.SourceList.CurrentRow);
	
EndProcedure

&AtClient
Procedure Save(Command)
	
	Notification = New NotifyDescription("SettingsFileSelectionCompletion", ThisForm);
	velpo_BusinessReportingClient.SelectTaxonomyFile(Notification,,  FileDialogMode.Save);
		
EndProcedure

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// set value list
	RefreshSourceList();
		
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

// SourceList

&AtClient
Procedure SourceListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Field.Name = "SourceListPresentation" Then
		StandardProcessing = False;
		OpenSourceItem(SelectedRow);
	EndIf;
		
EndProcedure

#EndRegion