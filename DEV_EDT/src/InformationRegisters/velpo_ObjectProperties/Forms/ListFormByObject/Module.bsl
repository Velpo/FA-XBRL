
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
															
	NotifyChanged(AdditionalParameters.Item.CurrentRow);
	                    
EndProcedure // ChooseDynamicListColumnValueCompletionNotify()

&AtServer
Procedure ActualizeProperties()

	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	DimensionIDTypes = ChartsOfCharacteristicTypes.velpo_DimensionIDTypes;
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;
	
	// vars
	IDArray = New Array;
	ObjectType = TypeOf(ThisForm.ObjectID);
	SelectionID = DimensionIDTypes.Select();
	While SelectionID.Next() Do
		If 	SelectionID.ValueType.ContainsType(ObjectType) Then
			IDArray.Add(SelectionID.Ref);
		EndIf;
	EndDo;
	
	// get properties
	PropertyMap = Economic.GetAccountPropertiesByDimensionID(IDArray);
	RowStructure = ObjectProperties.GetStructure(); 
	RowStructure.ObjectID = ThisForm.ObjectID;
	
	// get current data
	Query = New Query;
	Query.SetParameter("ObjectID", ThisForm.ObjectID);
	Query.Text = StrReplace(ObjectProperties.GetQueryText(), "//{FILTER}", "ObjectID = &ObjectID");
	TableProperties = Query.Execute().Unload();
	TableProperties.Indexes.Add("Attribute");
	For Each Property In PropertyMap Do
		If TableProperties.Find(Property.Value) = Undefined Then
			RowStructure.Attribute = Property.Value;
			ObjectProperties.AddListRow(RowStructure,, False);
		EndIf;
	EndDo; 

EndProcedure // ActualizeProperties() 

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
		ActualizeProperties();	
	Else
		StandardProcessing = False;
	EndIf;
	
	CommonClientServer.SetDynamicListParameter(List, "ObjectID",  ThisForm.ObjectID);
	
EndProcedure

&AtClient
Procedure OnOpen(Cancel)
	
	If Not HasObjectID Then
		
		FormParameters = New Structure;
		FormParameters.Insert("CloseOnOwnerClose", True);
		OpenForm("InformationRegister.velpo_ObjectProperties.Form.ListFormHistory", 
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
	
	OpenForm("InformationRegister.velpo_ObjectProperties.Form.ListFormHistory", 
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
	RowStructure = ClientServer.GetObjectPropertiesStructure();
	FillPropertyValues(RowStructure, ListData);
	
	// open
	Client.ChooseDynamicListColumnValue(ThisForm, "velpo_ObjectProperties", RowStructure, "Value",  ListData.Period, Item, StandardProcessing);

EndProcedure

#EndRegion
