///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
// Copyright (c) 2018, Velpo (Paul Tarasov)
//
// Subsystem:  Taxonomy Update
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region InterfaceInteractive

// Interactive 

//  Interective select taxomy packege or schema file.
//
// Parameters:
//     CompletionNotification - NotifyDescription - export procedure that is called with the following parameters:
//                                Result               - structure that contains the following fields: 
//                                                       Name, Location, and ErrorDetails. 
//                                AdditionalParameters - Undefined.
//
//     DialogParameters       - Structure - optional additional parameters of the file selection dialog.
//     FormID                 - String, UUID - this value is used for saving data to a temporary storage.
//
Procedure SelectTaxonomyFile(CompletionNotification, Val DialogParameters = Undefined, Val DialogMode = Undefined) Export
	
	// If the extension is available, using the custom file dialog to select a file
	DialogDefaultOptions = New Structure;
	DialogDefaultOptions.Insert("CheckFileExist", True);
	DialogDefaultOptions.Insert("Title",          NStr("en = 'Select file'; ru = 'Выберите файл'"));
	DialogDefaultOptions.Insert("Multiselect",    False);
	DialogDefaultOptions.Insert("Preview",        False);
	
	SetDefaultStructureValues(DialogParameters, DialogDefaultOptions);
	
	ChoiceDialog = New FileDialog(?(DialogMode = Undefined, FileDialogMode.Open, DialogMode));
	FillPropertyValues(ChoiceDialog, DialogParameters);
	
	ChoiceDialog.Show(CompletionNotification);
 
EndProcedure

// Save data to file
//
Procedure SaveInstanceFile(DataAddress, PathToFile) Export

	If DataAddress <> Undefined Then
		
		BinaryData = GetFromTempStorage(DataAddress);
		BinaryData.Write(PathToFile);
		ShowMessageBox(, Nstr("en='XBRL unload is comleted!';ru='Выгрузка XBRL завершена!'"));
		
		#If Not WebClient Then
			File = New File(PathToFile);
		 	BeginRunningApplication(New NotifyDescription, File.Path);
		#EndIf 
		
	EndIf;


EndProcedure // SaveInstanceFile()


#EndRegion

#Region InternalInteractive

// Adds fields to the target structure if the structure does not contain these fields.
//
// Parameters:
//     Result        - Structure - target structure. 
//     DefaultValues - Structure - default values.
//
Procedure SetDefaultStructureValues(Result, Val DefaultValues)
	
	If Result = Undefined Then
		Result = New Structure;
	EndIf;
	
	For Each KeyValue In DefaultValues Do
		PropertyName = KeyValue.Key;
		If Not Result.Property(PropertyName) Then
			Result.Insert(PropertyName, KeyValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

#EndRegion