///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

&AtClient
Procedure ChooseDynamicListColumnValueCompletionNotify(Value, AdditionalParameters) Export

	If Value = Undefined Then
		Return;
	EndIf;
	
	// import
	ServerCall = velpo_ServerCall; 
	ServerCall.SetFieldValue(AdditionalParameters.RegisterName, 
															AdditionalParameters.RowStructure, 
															AdditionalParameters.FieldName, 
															AdditionalParameters.Period,
															Value);
															
	If AdditionalParameters.FieldName = "ScheduleDate" Then
		AdditionalParameters.RowStructure.ScheduleDate = Value; 
		AdditionalParameters.Item.CurrentRow = ServerCall.GetRowKey(AdditionalParameters.RegisterName, 
																																				AdditionalParameters.RowStructure, 
																																				AdditionalParameters.Period);
	EndIf;
	
	NotifyChanged(AdditionalParameters.Item.CurrentRow);
	                    
EndProcedure // ChooseDynamicListColumnValueCompletionNotify()

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// import
	CommonClientServer = velpo_CommonFunctionsClientServer;

	// vars
	Parameters.Filter.Property("ObjectID", ThisForm.ObjectID);
	HasObjectID = ValueIsFilled(ThisForm.ObjectID);
	Items.ObjectID.Visible = Not HasObjectID;
	Items.ShowHistory.Visible = HasObjectID; 
	
	If HasObjectID Then
		CommonClientServer.SetDynamicListParameter(List, "ObjectID",  ThisForm.ObjectID);
	Else
		StandardProcessing = False;
	EndIf;
		
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not HasObjectID Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CloseOnOwnerClose", True);
		OpenForm("InformationRegister.velpo_CashFlows.Form.ListFormHistory", 
									FormParameters, 
									FormOwner, 
									UUID,
									Window,
									,
									OnCloseNotifyDescription,
									WindowOpeningMode);
		Cancel = True;
		
	EndIf;

EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure ShowHistory(Command)
	
	FormParameters = New Structure;
	FormParameters.Insert("CloseOnOwnerClose", True);
	FormParameters.Insert("Filter", New Structure("ObjectID", ThisForm.ObjectID)); 
	
	OpenForm("InformationRegister.velpo_CashFlows.Form.ListFormHistory", 
		FormParameters, 
		ThisForm);
	
EndProcedure

#EndRegion

#Region List

&AtClient
Procedure ListSelection(Item, SelectedRow, Field, StandardProcessing)
	
	//import
	ClientServer = velpo_ClientServer; 
	Client = velpo_Client;
	
	// vars
	ListData = Item.CurrentData;
	RowStructure = ClientServer.GetCashFlowsStructure();
	FillPropertyValues(RowStructure, ListData);
	
	// open
	Client.ChooseDynamicListColumnValue(ThisForm, "velpo_CashFlows", RowStructure, Field.Name,  ListData.Period, Item, StandardProcessing);

EndProcedure

&AtClient
Procedure ListBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	//import
	ClientServer = velpo_ClientServer; 
	Client = velpo_Client;
	
	// vars
	RowStructure = ClientServer.GetCashFlowsStructure();
	RowStructure.ObjectID = ThisForm.ObjectID;
		
	If Clone Then
		ListData = Item.CurrentData;
		FillPropertyValues(RowStructure, ListData);
		Period = ListData.Period;
	Else
		Period = Undefined;
	EndIf;
		
	Client.AddDynamicListRow(ThisForm, "velpo_CashFlows", RowStructure, Period, Item, Cancel, Clone);
	
EndProcedure

&AtClient
Procedure ListBeforeDeleteRow(Item, Cancel)
	
	//import
	ClientServer = velpo_ClientServer; 
	Client = velpo_Client;
	
	// vars
	ListData = Item.CurrentData;
	RowStructure = ClientServer.GetCashFlowsStructure();
	FillPropertyValues(RowStructure, ListData);
	
	Client.DeleteDynamicListRow(ThisForm, "velpo_CashFlows", RowStructure, ListData.Period, Item, Cancel);

EndProcedure

#EndRegion
