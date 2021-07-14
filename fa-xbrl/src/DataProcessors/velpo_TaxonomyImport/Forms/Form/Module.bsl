///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

&AtServerNoContext
Function CheckJobCompleted(BackgroundJobID)
	Return velpo_LongActions.JobCompleted(BackgroundJobID);
EndFunction

&AtServer
Procedure ImportTaxonomyAtServer(Address)
	
	SetPrivilegedMode(True);
	//
	//ScheduledJob = ScheduledJobs.FindPredefined(Metadata.ScheduledJobs.TaxonomyImport);
	//
	//Filter = New Structure;
	//Filter.Insert("ScheduledJob", ScheduledJob);
	//Filter.Insert("State", BackgroundJobState.Active);
	//BackgroundCleanupJobs = BackgroundJobs.GetBackgroundJobs(Filter);
	//If BackgroundCleanupJobs.Count() > 0 Then
	//	BackgroundJobID = BackgroundCleanupJobs[0].UUID;
	//Else
	//	ResultAddress = PutToTempStorage(Undefined, UUID);
	//	BackgroundJobDescription = StringFunctionsClientServer.SubstituteParametersInString(NStr("en = '%1 started manually'; ru = '%1 запущен вручную'"), ScheduledJob.Metadata.Synonym);
	//	
	//	JobParameters = New Array;
	//	JobParameters.Add(FileNameList);
	//	JobParameters.Add(Location);
	//	JobParameters.Add(ResultAddress);
	//	
	//	BackgroundJob = BackgroundJobs.Execute(
	//		ScheduledJob.Metadata.MethodName,
	//		JobParameters,
	//		String(ScheduledJob.UUID),
	//		BackgroundJobDescription);
	//		
	//	BackgroundJobID = BackgroundJob.UUID;
	//EndIf;
	
	EntryPointsArray = velpo_CommonFunctionsClientServer.GetCheckedListValues(ThisForm.EntryPoints);
	TaxonomyStructure = New Structure(velpo_TaxonomyUpdateClientServerCached.GetTaxonomyPackageAttribs());
	FillPropertyValues(TaxonomyStructure, Object);
	
	// import
	velpo_TaxonomyUpdate.ImportTaxonomy(TaxonomyStructure, EntryPointsArray, Address);
	
EndProcedure

&AtClient
Procedure ImportTaxonomy()
	
	// change page
	Items.LabelBeingExecuted.Title = NStr("en='Taxonomy import is being executed...'; ru='Выполняется импорт таксономии...'");
	Items.Pages.CurrentPage = Items.PageTaxonomyBeingExecuted;

	AttachIdleHandler("Attachable_TaxonomyImport", 0.5, True);
EndProcedure

&AtClient
Procedure AnalyzeTaxonomy()
	
	// change page
	Items.LabelBeingExecuted.Title = NStr("en='Taxonomy is being analyzed...'; ru='Анализирую таксономию...'");
	Items.Pages.CurrentPage = Items.PageTaxonomyBeingExecuted;
	
	AttachIdleHandler("Attachable_AnalyzeTaxonomy", 0.5, True);

EndProcedure // AnalyzeTaxonomy() 

&AtClient
Procedure TaxonomyFileSelectionCompletion(Val FileNameArray, Val AdditionalParameters) Export
	
	ClearMessages();
	
	If FileNameArray <> Undefined And FileNameArray.Count() > 0 Then 
		Object.TaxonomyFile = FileNameArray[0];
	EndIf;
	
	RefreshDataRepresentation();
	
EndProcedure

&AtClient
Procedure Attachable_TaxonomyImport()
	
	CompletionNotifyDescription = New NotifyDescription("SendTaxonomyImportFileCompletionNotify", ThisForm);
	BeginPutFileToServer(CompletionNotifyDescription,,,, Object.TaxonomyFile, ThisForm.UUID);
	
EndProcedure

&AtClient
Procedure Attachable_AnalyzeTaxonomy()
	
	// start files analysis
	SetEntryPointsValueList(Object.TaxonomyFile);	
	Items.Pages.CurrentPage = Items.PageTaxonomyFile;
	
EndProcedure

&AtClient
Procedure SetEntryPointsValueList(Val TaxonomyFullFileName) 

	TaxonomyFile = New File(TaxonomyFullFileName);
	LowerExtensionName = Right(Lower(TaxonomyFile.Extension), 3);
	
	// Zip-file
	If LowerExtensionName = "zip" Then
		
		ZipReader = New ZipFileReader(TaxonomyFullFileName);
		ZipEntry = ZipReader.Items.Find("taxonomyPackage.xml");
		If ZipEntry = Undefined Then
			velpo_CommonFunctionsClientServer.MessageToUser(
			NStr("en = 'Taxonomy package file is not found.'; ru = 'Файл  пакета таксономии не найден.'"),
			,
			"Object.TaxonomyFile");
			Return;
		EndIf;
		
		XMLFilePath = GetTempFileName();
		ZipReader.Extract(ZipEntry, XMLFilePath, ZIPRestoreFilePathsMode.DontRestore);
		ZipReader.Close();
		
		XMLFileName = XMLFilePath + "\taxonomyPackage.xml";
		
	Else
		Return;
	EndIf;
	
	CompletionNotifyDescription = New NotifyDescription("SendTaxonomyPackageCompletionNotify", ThisForm);
	BeginPutFileToServer(CompletionNotifyDescription,,,, XMLFileName, ThisForm.UUID);
	
EndProcedure

&AtClient
Procedure SendTaxonomyPackageCompletionNotify(PlacedFileDescription, AdditionalParameters) Export
	
	If PlacedFileDescription <> Undefined Then
		EntryPoints.Clear();
		TaxonomyStructure = velpo_TaxonomyUpdateServerCall.GetTaxonomyPackage(PlacedFileDescription.Address);
		FillPropertyValues(Object, TaxonomyStructure, velpo_TaxonomyUpdateClientServerCached.GetTaxonomyPackageAttribs());
		velpo_CommonFunctionsClientServer.FillValueList(TaxonomyStructure.EntryPoints, EntryPoints);
		EntryPoints.SortByPresentation(SortDirection.Asc);
		ManageFormVisibility();
	EndIf;

EndProcedure

&AtClient
Procedure ManageFormVisibility()

	NameAttributeArray = velpo_StringFunctionsClientServer.SplitStringIntoSubstringArray(velpo_TaxonomyUpdateClientServerCached.GetTaxonomyPackageAttribs());
	For Each NameAttrib In NameAttributeArray Do
		Items[NameAttrib].Visible = ValueIsFilled(Object[NameAttrib]);
	EndDo; 
	
	Items.EntryPoints.Visible = (EntryPoints.Count() > 0);

EndProcedure // ManageFormVisibility()

&AtClient
Procedure SendTaxonomyImportFileCompletionNotify(PlacedFileDescription, AdditionalParameters) Export
	
	If PlacedFileDescription <> Undefined Then
		ImportTaxonomyAtServer(PlacedFileDescription.Address);
		Items.Pages.CurrentPage = Items.PageTaxonomyFile;
		ShowMessageBox(,  NStr("en='Taxonomy is imported!.'; ru='Таксономия успешно загружена!'")) 
	EndIf;

EndProcedure

#EndRegion

#Region FormEventHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// Skipping the initialization to guarantee that the form
	// will be received if the Autotest parameter is passed.
	If Parameters.Property("Autotest") Then
		Return;
	EndIf;

EndProcedure

#EndRegion

#Region FormCommandHandlers

////////////////////////////////////////////////////////////////////////////////
// Supplied part.

&AtClient
Procedure ImportCommand(Command)
	
	ClearMessages();
	ImportTaxonomy();
	
EndProcedure

&AtClient
Procedure AnalysisCommand(Command)
	
	ClearMessages();
	
	If Not ValueIsFilled(Object.TaxonomyFile) Then
		velpo_CommonFunctionsClientServer.MessageToUser(
			NStr("en = 'Taxonomy file is not set.'; ru = 'Файл таксономии не указан.'"),
			,
			"Object.TaxonomyFile");
		Return;
	EndIf;
	
	AnalyzeTaxonomy();
	
EndProcedure

#EndRegion

#Region FormHeaderItemEventHandlers

// TaxonomyFile

&AtClient
Procedure TaxonomyFileStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter",  velpo_StringFunctionsClientServer.SubstituteParametersInString(
			"%1|*.zip",
			NStr("en = 'Archive (*.zip)'; ru = 'Архив (*.zip)'")));
		
	Notification = New NotifyDescription("TaxonomyFileSelectionCompletion", ThisForm);
	velpo_BusinessReportingClient.SelectTaxonomyFile(Notification, DialogSettings);

EndProcedure


#EndRegion


