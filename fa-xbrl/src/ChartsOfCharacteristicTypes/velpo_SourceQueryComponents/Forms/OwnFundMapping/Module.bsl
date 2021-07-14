///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region ServiceProceduresAndFunctions

&AtClientAtServerNoContext
Procedure SetMainFormFilters(Form)

	// import
	CommonClientServer = velpo_CommonFunctionsClientServer;
	ServerCall = velpo_ServerCall;
	
	//vars
	DimensionList = New ValueList;
	PropertyList = New ValueList;
	AccountStructure = ServerCall.GetAccountData(Form.Account);
	
	If AccountStructure.ObjectID <> Undefined Then
		DimensionList.Add(AccountStructure.ObjectID.Ref);
	EndIf;
	
	If Form.TableType = Form.MainTableType Then
		For Each DimensionName In AccountStructure.Dimensions Do
			DimensionList.Add(AccountStructure[DimensionName].Ref);
		EndDo; 
	EndIf;
	
	For Each PropertyName In AccountStructure.Properties Do
		If Form.TableType = Form.CashFlowType 
			And Form.CashFlowAttributes.FindByValue(PropertyName) = Undefined Then
			Continue;
		EndIf;
		PropertyList.Add(AccountStructure[PropertyName].Ref);
	EndDo; 
	
	CommonClientServer.SetDynamicListFilterItem(Form.ItemLinks, "Account",  Form.Account,  DataCompositionComparisonType.Equal, False, True);
	CommonClientServer.SetDynamicListFilterItem(Form.ItemLinks, "TableType",  Form.TableType,  DataCompositionComparisonType.Equal, False, True);
	
	CommonClientServer.SetDynamicListFilterItem(Form.DimensionIDTypes, "Ref",  DimensionList,  DataCompositionComparisonType.InList, False, True);
	CommonClientServer.SetDynamicListFilterItem(Form.ObjectAttributes, "Ref",  PropertyList,  DataCompositionComparisonType.InList, False, True);
	
	CommonClientServer.SetDynamicListParameter(Form.SourceQueryComponents, "Account",  Form.Account,  True);
	CommonClientServer.SetDynamicListParameter(Form.DimensionIDTypes, "Account",  Form.Account,  True);
	CommonClientServer.SetDynamicListParameter(Form.ObjectAttributes, "Account",  Form.Account,  True);
	
	CommonClientServer.SetDynamicListParameter(Form.SourceQueryComponents, "ItemTableType",  Form.TableType,  True);
	CommonClientServer.SetDynamicListParameter(Form.DimensionIDTypes, "ItemTableType",  Form.TableType,  True);
	CommonClientServer.SetDynamicListParameter(Form.ObjectAttributes, "ItemTableType",  Form.TableType,  True);

EndProcedure // SetMainFormFilters()

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// import
	ServerCache  = velpo_ServerCache;
	ItemTableTypes = Enums.velpo_ItemTableTypes;
	
	//vars
	CashFlowMap = ServerCache.GetAllCashFlowMap();
	For Each KeyValue In CashFlowMap Do
		ThisForm.CashFlowAttributes.Add(KeyValue.Key);
	EndDo;  
	ThisForm.MainTableType = ItemTableTypes.MainTable;
	ThisForm.CashFlowType = ItemTableTypes.CashFlow;
	ThisForm.TableType = ThisForm.MainTableType;
	
	// set main
	SetMainFormFilters(ThisForm);
	
EndProcedure

#EndRegion

#Region FormCommands

&AtClient
Procedure AddToFields(Command)

	FormParameters = New Structure("Account,Property,TableType");
	FillPropertyValues(FormParameters, ThisForm);
	FormParameters.Insert("Owner", ThisForm.CurrentField);
	FormParameters.Insert("Property", ThisForm.CurrentProperty);
	
	OpenForm("Catalog.velpo_ItemLinks.ObjectForm",
		FormParameters, 
		ThisForm); 
	
EndProcedure

#EndRegion

#Region FormFieldEvents

&AtClient
Procedure AccountOnChange(Item)
	
	SetMainFormFilters(ThisForm);
	
EndProcedure

&AtClient
Procedure ItemTableTypeOnChange(Item)
	
	SetMainFormFilters(ThisForm);
	
EndProcedure

#EndRegion

#Region FormTableEvents

&AtClient
Procedure ListOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ThisForm.CurrentProperty = CurrentData.Ref;
	ThisForm.Items[?(Item.Name = "DimensionIDTypes", "ObjectAttributes", "DimensionIDTypes")].SelectedRows.Clear();
	
EndProcedure

&AtClient
Procedure SourceQueryComponentsOnActivateRow(Item)
	
	CurrentData = Item.CurrentData;
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	ThisForm.CurrentField = CurrentData.Ref;
	
EndProcedure

#EndRegion