///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServer
Function GetFullFileName(prefix)

	Return
		prefix + "_" 
		+ velpo_CommonFunctions.ObjectAttributeValue(Parameters.BusinessUnit, "Identifier") + "_"
		+ velpo_CommonFunctions.ObjectAttributeValue(Parameters.EntryPoint, "Name") + "_"
		+ Format(Parameters.Period, "DF=yyyyMMdd")
		+ ?(prefix = "arch", ".zip", ".xml");
		
EndFunction // GetFullFileName()

&AtServer
Function UnloadInstanceAtServer()
	
	Obj = DataProcessors.velpo_InstanceFileUnload.Create();
	FillPropertyValues(Obj, Parameters, "BusinessUnit,Taxonomy,EntryPoint,Period");
		
	Return Obj.UnloadInstance();
	                      
EndFunction // UnloadInstanceAtServer()

&AtClient
Function GetXBRLFile(FilePath)
	
	PathToTempFile = FilePath + GetFullFileName("XBRL");
	BinaryData = GetFromTempStorage(UnloadInstanceAtServer());
	BinaryData.Write(PathToTempFile);
	Return PathToTempFile;
	
EndFunction // GetXBRLFile()

&AtClient
Function GetServiceFile(FilePath)
	
	PathToTempFile =  FilePath + GetFullFileName("Service");
	TextWriter = New TextWriter(PathToTempFile, TextEncoding.UTF8);
	
	TextWriter.WriteLine("<?xml version=""1.0"" encoding=""utf-8""?>");
	TextWriter.WriteLine("<serviceInfo xmlns:xsd=""http://www.w3.org/2001/XMLSchema"" xmlns:xsi=""http://www.w3.org/2001/XMLSchema-instance"">");
	TextWriter.WriteLine("	<Name>Служебный файл пакета отчетности</Name>");
	TextWriter.WriteLine("	<Type_Message>XBRL</Type_Message>");
	TextWriter.WriteLine("	<ReportDate>" + Format(Parameters.Period, "DF=yyyy-MM-dd") + "</ReportDate>");
	TextWriter.WriteLine("	<files>");
	TextWriter.WriteLine("		<fileItem>");
	TextWriter.WriteLine("			<Name>" + GetFullFileName("XBRL") + "</Name>");
	TextWriter.WriteLine("			<Description>XBRL файл пакета отчётности</Description>");
	TextWriter.WriteLine("		</fileItem>");
	TextWriter.WriteLine("	</files>");
	TextWriter.WriteLine("</serviceInfo>");

	TextWriter.Close();
	TextWriter = Undefined;
	FileStream = Undefined;
	
	Return PathToTempFile;

EndFunction // GetServiceFile()

&AtClient
Procedure GenerateXBRL()
	
	FilesToDelete = New Array;
			
	File = New File(ThisForm.ZipFilePath);
	FilePath = File.Path;
	
	XBRLFilePath = GetXBRLFile(FilePath);
	FilesToDelete.Add(XBRLFilePath);
	
	ZipFile = New ZipFileWriter(ThisForm.ZipFilePath); 
	
	ZipFile.Add(XBRLFilePath, ZIPStorePathMode.DontStorePath); 
	If ThisForm.IncludeServiceFile Then
		ServiceFile = GetServiceFile(FilePath);
		FilesToDelete.Add(ServiceFile);
		ZipFile.Add(ServiceFile, ZIPStorePathMode.DontStorePath); 
	EndIf;
	
	For Each AddFileLine In ThisForm.AdditionalFiles  Do
		ZipFile.Add(AddFileLine.FilePath, ZIPStorePathMode.DontStorePath); 
	EndDo; 
	ZipFile.Write();
	
	For Each FileName In FilesToDelete  Do
		BeginDeletingFiles(New NotifyDescription, FileName);
	EndDo; 
	
EndProcedure // GenerateXBRL()

&AtClient
Procedure ZipFilePathStartSelectionCompletion(Val FileNameArray, Val AdditionalParameters) Export
	
	ClearMessages();
	
	If FileNameArray <> Undefined And FileNameArray.Count() > 0 Then 
		ThisForm.ZipFilePath = FileNameArray[0];
	EndIf;
	
	RefreshDataRepresentation();
	
EndProcedure

&AtClient
Procedure AdditionalFilesFilePathSelectionCompletion(Val FileNameArray, Val AdditionalParameters) Export
	
	ClearMessages();
	
	If FileNameArray <> Undefined And FileNameArray.Count() > 0 Then 
		Items.AdditionalFiles.CurrentData.FilePath = FileNameArray[0];
	EndIf;
	
	RefreshDataRepresentation();
	
EndProcedure

&AtClient
Procedure ZipFilePathStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter",  velpo_StringFunctionsClientServer.SubstituteParametersInString(
			"%1|*.xbrl",
			NStr("en = 'Zip-file (*.zip)'; ru = 'Файл zip (*.zip)'")));
	DialogSettings.Insert("FullFileName", GetFullFileName("arch"));
			
	Notification = New NotifyDescription("ZipFilePathStartSelectionCompletion", ThisForm);
	velpo_BusinessReportingClient.SelectTaxonomyFile(Notification, DialogSettings, FileDialogMode.Save);

EndProcedure

&AtClient
Procedure AdditionalFilesFilePathStartChoice(Item, ChoiceData, StandardProcessing)
	
	StandardProcessing = False;
	
	DialogSettings = New Structure;
	DialogSettings.Insert("Filter",  velpo_StringFunctionsClientServer.SubstituteParametersInString(
			"%1|*.*",
			NStr("en = 'Any file'; ru = 'Любой файл'")));
	DialogSettings.Insert("CheckFileExistence", True);
				
	Notification = New NotifyDescription("AdditionalFilesFilePathSelectionCompletion", ThisForm);
	velpo_BusinessReportingClient.SelectTaxonomyFile(Notification, DialogSettings, FileDialogMode.Open);

EndProcedure

&AtClient
Procedure CommandGenerate(Command)
	
	GenerateXBRL();
	File = New File(ThisForm.ZipFilePath);
	If ValueIsFilled(File.Path) Then
		ShowMessageBox(, Nstr("en='Zip package is generated!';ru='Пакет для отправки создан!'"));		
		#If Not WebClient Then
	 		BeginRunningApplication(New NotifyDescription, File.Path);
		#EndIf 
	EndIf;
	
EndProcedure

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	ThisForm.IncludeServiceFile = True;
	
EndProcedure
