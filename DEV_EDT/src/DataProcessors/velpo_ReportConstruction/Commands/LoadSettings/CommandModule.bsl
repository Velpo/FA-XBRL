
#Region ProceduresAndFunctions

&AtServer
Function PutSettings(Location)

	Status = True;
	
	Try
		DataProcessors.velpo_ReportConstruction.PutSettingData(Location);	
	Except
		velpo_CommonFunctionsClientServer.MessageToUser(DetailErrorDescription(ErrorInfo()));
		Status = False;
	EndTry;
	
	Return Status;

EndFunction // PutSettings() 

&AtClient
Procedure SettingsFileSelectionCompletion(FileName, AdditionalParameters) Export
	
	ClearMessages();
	
	// set location
	Location = PutToTempStorage(New BinaryData(FileName));
	If Location = Undefined Then
		Return;
	EndIf;
	If PutSettings(Location) Then
		ShowMessageBox(, NStr("ru = 'Загрузка настроек выполнена!'; en = 'Source settings loading is completed!'"));
		Notify("SourceSettingsIsLoaded");
	EndIf;
		
EndProcedure

#EndRegion

#Region CommandHandlers

&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	Notification = New NotifyDescription("SettingsFileSelectionCompletion", ThisObject);
	velpo_BusinessReportingClient.SelectTaxonomyFile(Notification);

EndProcedure

#EndRegion

