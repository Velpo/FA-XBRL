///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Procedure SetFieldValue(Value, AdditionalParameters) Export

	// import
	ServerCall = velpo_ServerCall;
	
	// vars
	SelectedRows = AdditionalParameters.Item.SelectedRows;
	RowCount = SelectedRows.Count();
	
	For Each Row In SelectedRows Do
		If RowCount > 1 Then
			CurrentData = AdditionalParameters.Item.RowData(Row);
			FillPropertyValues(	AdditionalParameters.RowStructure, CurrentData);
		EndIf;
			
		ServerCall.SetFieldValue(AdditionalParameters.RegisterName, 
															AdditionalParameters.RowStructure, 
															AdditionalParameters.FieldName, 
															AdditionalParameters.Period,
															Value);
	EndDo; 

EndProcedure

Procedure ChooseDynamicListColumnValue(Form, RegisterName, RowStructure, FieldName, Period, Item, StandardProcessing) Export

	// import
	ServerCall = velpo_ServerCall;
	CommonClientServer = velpo_CommonFunctionsClientServer;
	
	// vars
	StandardProcessing = False;
	
	Attribute = Undefined;
	AttributeRef = Undefined;
	AccountRef = Undefined;
	
	If FieldName = "Resource" And RowStructure.Property(FieldName, AttributeRef) Then
		If Not ValueIsFilled(RowStructure.Account) Then
			Return;
		EndIf;
		Attribute = ServerCall.GetResourceData(AttributeRef);	
	ElsIf RowStructure.Property("Indicator", AttributeRef) Then
		If FieldName = "Indicator" Then
			Attribute = ServerCall.GetIndicatorData(AttributeRef);
		Else
			Attribute = ServerCall.GetAttributeData(AttributeRef);	
		EndIf;
	ElsIf RowStructure.Property("Attribute", AttributeRef) Then
		Attribute = ServerCall.GetAttributeData(AttributeRef);	
	ElsIf RowStructure.Property("Account", AccountRef) Then
		AccountStructure = ServerCall.GetAccountData(AccountRef);
		AccountStructure.Property(FieldName, Attribute);
	Else
		Attribute = ServerCall.GetAttributeDataByName(FieldName);
	EndIf;
	
	If Attribute = Undefined Then
		Return;
	EndIf;
	
	CurrentValue = ServerCall.GetFieldValue(RegisterName, RowStructure, FieldName, Period);
	
	ValueType = Attribute.ValueType;
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentValue", CurrentValue);
	AdditionalParameters.Insert("RegisterName", RegisterName);
	AdditionalParameters.Insert("RowStructure", RowStructure);
	AdditionalParameters.Insert("FieldName", FieldName);
	AdditionalParameters.Insert("Period", Period);
	AdditionalParameters.Insert("Item", Item);
		
	CompletionNotifyDescription = New NotifyDescription("ChooseDynamicListColumnValueCompletionNotify", Form, AdditionalParameters);
	UseAnyType = False;	
	
	// different types
	If ValueType.Types().Count() = 1 Then
		If ValueType.ContainsType(Type("Boolean")) Then
			SetFieldValue(?(CurrentValue = Null Or CurrentValue = Undefined, True, Not CurrentValue), AdditionalParameters);
			NotifyChanged(Item.CurrentRow);
		ElsIf ValueType.ContainsType(Type("Date")) Then
			ShowInputDate(CompletionNotifyDescription, CurrentValue, Attribute.Description, ValueType.DateQualifiers.DateFractions);
		ElsIf ValueType.ContainsType(Type("String")) Then
			ShowInputString(CompletionNotifyDescription, CurrentValue, Attribute.Description, ValueType.StringQualifiers.Length, False);
		ElsIf ValueType.ContainsType(Type("Number")) Then
			ShowInputNumber(	CompletionNotifyDescription, CurrentValue, Attribute.Description, ValueType.NumberQualifiers.Digits, ValueType.NumberQualifiers.FractionDigits);
		ElsIf ValueType.ContainsType(Type("CatalogRef.velpo_CategoryIDs")) Then
			FormParameters = New Structure;
			FormParameters.Insert("AllowRootChoice", False);
			FormParameters.Insert("ChoiceFoldersAndItems",  FoldersAndItems.Items);
			FormParameters.Insert("ChoiceMode", True);
			FormParameters.Insert("CloseOnOwnerClose", True);
			FormParameters.Insert("CurrentRow", CurrentValue);
			FormParameters.Insert("Filter", New Structure("Owner", Attribute.Ref)); 
			OpenForm("Catalog.velpo_CategoryIDs.ChoiceForm", FormParameters, Form,,,,CompletionNotifyDescription,);
		Else
			UseAnyType = True;
		EndIf;
	Else
		UseAnyType = True;
	EndIf;
	
	If UseAnyType Then
		ShowInputValue(CompletionNotifyDescription, CurrentValue, Attribute.Description, ValueType);
	EndIf;
	
EndProcedure // ChooseDynamicListColumnValue()

Procedure ClearDynamicListColumnValue(Form, RegisterName, RowStructure, FieldName, Period, Item, StandardProcessing) Export

	// import
	ServerCall = velpo_ServerCall;
	CommonClientServer = velpo_CommonFunctionsClientServer;
	
	// vars
	StandardProcessing = False;
	
	AdditionalParameters = New Structure;
	AdditionalParameters.Insert("CurrentValue", Undefined);
	AdditionalParameters.Insert("RegisterName", RegisterName);
	AdditionalParameters.Insert("RowStructure", RowStructure);
	AdditionalParameters.Insert("FieldName", FieldName);
	AdditionalParameters.Insert("Period", Period);
	AdditionalParameters.Insert("Item", Item);
	
	SetFieldValue(Undefined, AdditionalParameters);
	NotifyChanged(Item.CurrentRow);
		
EndProcedure // ChooseDynamicListColumnValue()

Procedure AddDynamicListRow(Form, RegisterName, RowStructure, Period, Item, Cancel, Clone) Export

	// import
	ServerCall = velpo_ServerCall;
	CommonClientServer = velpo_CommonFunctionsClientServer;
	
	// vars
	Cancel = True;
	
	RowKey = ServerCall.AddListRowKey(RegisterName, RowStructure, Period, Clone);
	
	If RowKey <> Undefined Then
		NotifyChanged(RowKey);
		Item.CurrentRow = RowKey;
	EndIf;
	
EndProcedure

Procedure DeleteDynamicListRow(Form, RegisterName, RowStructure, Period, Item, Cancel) Export

	// import
	ServerCall = velpo_ServerCall;
	CommonClientServer = velpo_CommonFunctionsClientServer;
	
	// vars
	Cancel = True;
	
	RowKey = ServerCall.DeleteListRowKey(RegisterName, RowStructure, Period);
	
	If RowKey <> Undefined Then
		NotifyChanged(RowKey);
		Item.CurrentRow = RowKey;
	EndIf;
	
EndProcedure


 