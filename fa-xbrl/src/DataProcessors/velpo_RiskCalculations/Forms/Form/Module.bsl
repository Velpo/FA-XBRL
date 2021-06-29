///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region Public

&AtClient
Procedure ChooseDynamicListColumnValueCompletionNotify(Value, AdditionalParameters) Export

	If Value = Undefined Then
		Return;
	EndIf;
	
	// import
	Client = velpo_Client;
	ServerCall = velpo_ServerCall; 
	NumberType = Type("Number");
	
	Client.SetFieldValue(Value, AdditionalParameters);
																	
	SetNewKey = False;														
	If AdditionalParameters.FieldName = "ObjectID"
		Or AdditionalParameters.FieldName = "ScheduleDate"
		Or AdditionalParameters.FieldName = "Resource"
		Or AdditionalParameters.FieldName = "Indicator" Then
		AdditionalParameters.RowStructure[AdditionalParameters.FieldName] = Value; 
		SetNewKey = True;
	EndIf;
	
	If SetNewKey Then
		AdditionalParameters.Item.CurrentRow = ServerCall.GetRowKey(AdditionalParameters.RegisterName, 
																																				AdditionalParameters.RowStructure, 
																																				AdditionalParameters.Period);
	EndIf;
	
	NotifyChanged(AdditionalParameters.Item.CurrentRow);
	
	If AdditionalParameters.FieldName = "ObjectID"
		And AdditionalParameters.Item.Name = "OwnFundData" Then
		ActivateOwnFundDataRow();
	EndIf;
	
	If AdditionalParameters.Item.Name = "OwnFundData" Then
		If TypeOf(Value) = NumberType Then
			AccountStructure = ServerCall.GetAccountData(ThisForm.CurrentAccount);
			FooterPath = AdditionalParameters.FieldName + "_Footer";
			If AccountStructure[AdditionalParameters.FieldName].IsCalculation Then
				CurrentTotals = Number(StrReplace(ThisForm[FooterPath], " ", "")) - AdditionalParameters.CurrentValue + Value;
				ThisForm[FooterPath] = GetFooterFormatedNumber(AccountStructure, AdditionalParameters.FieldName, CurrentTotals);
			EndIf;
		EndIf;
	EndIf;
		
EndProcedure // ChooseDynamicListColumnValueCompletionNotify()

&AtClient
Procedure FillDynamicListCompletionNotify(QueryResult, AdditionalParameters) Export

	If QueryResult = DialogReturnCode.Yes Then 
		
		FillDataAtServer(AdditionalParameters.ItemName);
		RefreshCurrentItem(AdditionalParameters.ItemName);
		
	EndIf;

EndProcedure // FillDynamicListCompletionNotify() 

&AtClient
Procedure CalculateDataCompletionNotify(QueryResult, AdditionalParameters) Export

	If QueryResult = DialogReturnCode.Yes Then 
		
		CalculateDataAtServer(AdditionalParameters);
		RefreshCurrentItem(AdditionalParameters.ItemName);
				
	EndIf;

EndProcedure // FillDynamicListCompletionNotify() 
	
#EndRegion 

#Region ServiceProceduresAndFunctions

&AtClientAtServerNoContext
Function GetFooterFormatedNumber(AccountStructure, Name, Value)
	
	NumberQualifiers = AccountStructure[Name].ValueType.NumberQualifiers;
	Return Format(Value, "NZ=0,00; ND=" + String(NumberQualifiers.Digits) +  "; NFD=" + String(NumberQualifiers.FractionDigits)); 

EndFunction // GetFooterFormatedNumber()

&AtClientAtServerNoContext
Procedure SetMainFormFilters(Form)

	// import
	CommonClientServer = velpo_CommonFunctionsClientServer;
	ServerCall = velpo_ServerCall;
	
	// set dynamic filter
	ListArray = New Array;
	ListArray.Add(Form.CounterpartyData);
	ListArray.Add(Form.OwnFundData);
	ListArray.Add(Form.NonLifeSolvencyMarginData);
	ListArray.Add(Form.ConcentrationData);
	ListArray.Add(Form.NormativeRatioData);
	ListArray.Add(Form.CalculationData);
	
	For Each List In ListArray Do
		CommonClientServer.SetDynamicListFilterItem(List, "Period",  Form.Object.Period,  DataCompositionComparisonType.Equal, False, True);	
		CommonClientServer.SetDynamicListFilterItem(List, "BusinessUnit",  Form.Object.BusinessUnit,  DataCompositionComparisonType.Equal, False, True);	
	EndDo; 
	
	// balance
	CommonClientServer.SetDynamicListParameter(Form.BalanceData, "PeriodFilter",  Form.Object.Period);
	CommonClientServer.SetDynamicListParameter(Form.BalanceData, "BusinessUnit",  Form.Object.BusinessUnit);
	CommonClientServer.SetDynamicListParameter(Form.BalanceData, "Account",  ServerCall.GetAccountListByRef(Form.CurrentAccount));
	
	// cash flow
	CommonClientServer.SetDynamicListParameter(Form.CashFlows, "PeriodFilter",  Form.Object.Period);
	CommonClientServer.SetDynamicListParameter(Form.CashFlows, "ObjectID",  Undefined);
	
	// set main header
	Form.Items.MainGroup.CollapsedRepresentationTitle = String(Form.Object.BusinessUnit) + "; " + Format(Form.Object.Period, "DF=dd.MM.yyyy");

EndProcedure // SetMainFormFilters() 

&AtClientAtServerNoContext
Procedure SetShowCalculation(Form)

	Form.Items.GroupCalcultation.Visible = Form.Items.OwnFundDataCommandShowCalculation.Check;
		
EndProcedure // SetShowCalculation() 

&AtServer
Function GetAccountColumns(AccountStructure)
	
	// vars
	ReturnMap = New Map;
	
	If AccountStructure.ObjectID <> Undefined Then
		ReturnMap.Insert("ObjectID", AccountStructure.ObjectID);
	EndIf;
	
	For Each PropertyName In AccountStructure.Properties Do
		ReturnMap.Insert(PropertyName, AccountStructure[PropertyName]);
	EndDo; 
	
	For Each DimensionName In AccountStructure.Dimensions Do
		ReturnMap.Insert(DimensionName, AccountStructure[DimensionName]);
	EndDo; 
	
	Return ReturnMap;
	
EndFunction // GetAccountColumns()

&AtServer
Function GetQueryTextTotals(AccountStructure, ByAccount = True)
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	
	// vars
	IsOwnFunds = (AccountStructure.Ref = Economic.OwnFunds);
	NumberType = Type("Number");
	
	If IsOwnFunds Then
		SignText = "CASE WHEN Account.Parent = VALUE(ChartOfAccounts.velpo_Economic.Assets) THEN 1 ELSE -1 END";
	Else
		SignText = "1";	
	EndIf;
	
	FieldText = "";
	For Each PropertyName In AccountStructure.Properties Do
		AttributeData = AccountStructure[PropertyName];
		If AttributeData.IsCalculation And AttributeData.ValueType.ContainsType(NumberType) Then
			FieldText = FieldText + ?(FieldText = "", "", ",") + "ISNULL(SUM(" + SignText + " * " + PropertyName + "), 0) AS  " + PropertyName;
		EndIf;
	EndDo; 
	
	QueryText = 
	"SELECT
	|	//{ACCOUNT}Account AS Account,
	|	//{ACCOUNT} Account.Parent AS Parent,
	|" + FieldText + "
	|FROM
	|	InformationRegister.velpo_OwnFundData
	|WHERE
	|	Period = &PeriodFilter
	|	AND BusinessUnit = &BusinessUnit
	|	AND Account IN (&Account)
	|//{ACCOUNT} GROUP BY //{ACCOUNT}Account
	|";
	
	If ByAccount Then
		If  IsOwnFunds Then
			QueryText =StrReplace(QueryText, "//{ACCOUNT}Account", "Account.Parent") + Chars.CR + "UNION ALL" + Chars.CR + QueryText; 
		EndIf;
		QueryText = StrReplace(QueryText, "//{ACCOUNT}", "");
	EndIf;
	
	Return QueryText;
	
EndFunction // GetQueryTextTotals()

&AtServer
Procedure SetFooterAttributes()

	// import
	RegisterOwnFundData = InformationRegisters.velpo_OwnFundData;
	Common = velpo_CommonFunctions;
	Economic = ChartsOfAccounts.velpo_Economic;
	Server = velpo_Server;
	
	// vars
	AttribsArray = New Array;
	ResourceStructure = Server.GetRegisteResources(RegisterOwnFundData);
	StringType = Common.StringTypeDescription("100");
	
	// set resuces
	For Each Resource In ResourceStructure Do
		PropertyName = Resource.Key;
		Attrib = New FormAttribute(PropertyName + "_Footer", StringType);
		AttribsArray.Add(Attrib);
	EndDo; 
	    		
	ThisForm.ChangeAttributes(AttribsArray); 

EndProcedure

&AtServer
Procedure InitializeData()
	
	// import
	RiskCalculations = DataProcessors.velpo_RiskCalculations;
	Economic = ChartsOfAccounts.velpo_Economic;
	
	// set footer attributes
	SetFooterAttributes();

	// create lists
	InformationRegisters.velpo_CounterpartyData.SetDynamicList(Items.CounterpartyData);
	InformationRegisters.velpo_OwnFundData.SetDynamicList(Items.OwnFundData);
	InformationRegisters.velpo_NonLifeSolvencyMarginData.SetDynamicList(Items.NonLifeSolvencyMarginData);
	InformationRegisters.velpo_NormativeRatioData.SetDynamicList(Items.NormativeRatioData);
	InformationRegisters.velpo_ConcentrationData.SetDynamicList(Items.ConcentrationData);

	// set current account
	AccountStructure = Economic.GetAccountData(Economic.OwnFunds);
	ColumnArray = New Array;
	NumberType = Type("Number");
	For Each PropertyName In AccountStructure.Properties Do
		AttributeData = AccountStructure[PropertyName];
		If AttributeData.IsCalculation And AttributeData.ValueType.ContainsType(NumberType)  And PropertyName <> "MarketRate" Then 
			ColumnArray.Add(PropertyName);
		EndIf;	
	EndDo; 
	RiskCalculations.AddDynamicListColumns(Items.BalanceData, AccountStructure, ColumnArray);
	
	// filters
	SetMainFormFilters(ThisForm);
	SetShowCalculation(ThisForm);
	
EndProcedure

&AtServer
Procedure SetFooterTotals(AccountRef, ItemName)
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
		
	//vars
	AccountStructure = Economic.GetAccountData(AccountRef);

	Query = New 	Query;
	Query.SetParameter("PeriodFilter", Object.Period);
	Query.SetParameter("BusinessUnit", Object.BusinessUnit);
	Query.SetParameter("Account", Economic.GetAccountListByRef(AccountRef));
	Query.Text = GetQueryTextTotals(AccountStructure, False);
	
	Result = Query.Execute();
	Columns = Result .Columns;
	Selection = Query.Execute().Select();
	Selection.Next();
	For Each Column In Columns Do
		ColumnName = Column.Name;
		ThisForm[ColumnName + "_Footer"] = GetFooterFormatedNumber(AccountStructure, ColumnName, Selection[ColumnName]);
	EndDo; 
	
EndProcedure

&AtServer
Procedure SetColumnVisibility(AccountRef, ItemName)
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	ServerCache = velpo_ServerCache;
	
	//vars
	AccountStructure = Economic.GetAccountData(AccountRef);
	ColumnMap = ServerCache.GetAccountColumns(AccountRef);
	IsGroupAccount = ServerCache.CheckGroupAccount(AccountRef);
	OwnFundDataItem = ThisForm.Items[ItemName];

	// set column visibility
	Items[ItemName + "Account"].Visible = IsGroupAccount;
	
	ColumnCollection = OwnFundDataItem.ChildItems;
	For Each Column In ColumnCollection Do
		Name = Mid(Column.Name, 12);
		If  Name = "Account" Or Name = "RowNumber" Or Name = "ObjectID" Then
			Continue;
		EndIf;
		ColumnStructure = ColumnMap[Name];
		If ColumnStructure = Undefined Then
			Column.Visible = False;
		ElsIf IsGroupAccount Then
			Column.Visible = ColumnStructure.IsCalculation;
		Else
			Column.Visible = True;
		EndIf;
	EndDo;
	
	// set cashflow visible
	Items.GroupCashFlows.Visible = AccountStructure.Flags.CashFlow;

EndProcedure // SetColumnVisibility()

&AtServer
Procedure ActivateAccountRowAtServer(AccountRef)
	
	// import
	Common = velpo_CommonFunctions;
	CommonClientServer = velpo_CommonFunctionsClientServer;
	RegisterOwnFundData = InformationRegisters.velpo_OwnFundData;
	Economic = ChartsOfAccounts.velpo_Economic;
	ServerCache = velpo_ServerCache;
	
	// vars
	AccountStructure = Economic.GetAccountData(AccountRef);
	OwnFundDataItem = Items.OwnFundData;
	IsGroupAccount = ServerCache.CheckGroupAccount(AccountRef);
	DataName = ?(IsGroupAccount, "Balance", "OwnFund") + "Data";
	
	SetColumnVisibility(AccountRef, DataName);
	SetFooterTotals(AccountRef, DataName);

	
	// set text
	ListProperties = Common.DynamicListPropertiesStructure();
	
	If IsGroupAccount Then
		CommonClientServer.SetDynamicListParameter(BalanceData, "Account", Economic.GetAccountListByRef(AccountRef));
		ListProperties.QueryText = GetQueryTextTotals(AccountStructure);
	Else
		// delete sorting
		UserCollection = OwnFundData.SettingsComposer.UserSettings.Items;
		For Each ItemCollection In UserCollection Do
			If  TypeOf(ItemCollection) = Type("DataCompositionOrder") Then
				ItemCollection.Items.Clear();
			EndIf;
		EndDo; 
		// set dynamic filter
		CommonClientServer.SetDynamicListFilterItem(OwnFundData, "Account",  AccountRef,  DataCompositionComparisonType.Equal, False, True);
		ListProperties.QueryText = RegisterOwnFundData.GetQueryText(AccountStructure, IsGroupAccount);
	EndIf;
	
	Common.SetDynamicListProperties(Items[DataName], ListProperties);
	Items.OwnFundsPages.CurrentPage = Items["Page" + DataName];
	
	// set account
	ThisForm.CurrentAccount = AccountRef;

EndProcedure // ActivateAccountRow()

&AtServer
Procedure FillDataAtServer(ItemName)

	Obj = ThisForm.FormAttributeToValue("Object");
	
	FillParameters = New Structure;
	If ItemName = "CounterpartyData" Then
		Obj.FillCounterpartyData();
	ElsIf  ItemName = "OwnFundData" Then
		Obj.FillOwnFundData(ThisForm.CurrentAccount);
	ElsIf  ItemName = "NonLifeSolvencyMarginData" Then
		Obj.FillNonLifeSolvencyMarginData();
	EndIf;

EndProcedure // FillDataAtServer()

&AtServer
Procedure CalculateDataAtServer(AdditionalParameters)
	
	TextCommand = "Obj." + AdditionalParameters.CommandName;
	If AdditionalParameters.UseAccount Then
		TextCommand = TextCommand + "(ThisForm.CurrentAccount";
		If AdditionalParameters.UseRows Then
			TextCommand = TextCommand + ", AdditionalParameters.RowArray";
		EndIf;
		TextCommand = TextCommand + ");"
	ElsIf AdditionalParameters.UseRows Then
		TextCommand = TextCommand + "(AdditionalParameters.RowArray)";
	Else
		TextCommand = TextCommand + "();"
	EndIf;
	
	Obj = ThisForm.FormAttributeToValue("Object");
	Execute(TextCommand);
			
EndProcedure // FillDataAtServer()

&AtClient
Procedure ChangePeriodByMonth(Item, Direction)
	
	Object.Period = EndOfMonth(AddMonth(Object.Period, Direction));
	SetMainFormFilters(ThisForm);
	
EndProcedure // ChangePeriodByMonth()

&AtClient
Function GetRowStructureByItem(ItemName)
	
	// import
	ClientServer = velpo_ClientServer; 	
	
	// vars
	If ItemName = "CounterpartyData" Then
		RowStructure = ClientServer.GetCounterpartyDataStructure();
	ElsIf ItemName = "OwnFundData" Then
		RowStructure = ClientServer.GetOwnFundDataStructure();
	ElsIf ItemName = "ConcentrationData" Then
		RowStructure = ClientServer.GetConcentrationDataStructure();
	ElsIf ItemName = "NonLifeSolvencyMarginData" Then
		RowStructure = ClientServer.GetNonLifeSolvencyMarginDataStructure();
	ElsIf ItemName = "NormativeRatioData" Then
		RowStructure = ClientServer.GetNormativeRatioStructure();
	ElsIf ItemName = "CashFlows" Then
		RowStructure = ClientServer.GetCashFlowsStructure();
	ElsIf ItemName = "CalculationData" Then
		RowStructure = ClientServer.GetCalculationDataStructure();
	EndIf;
	
	Return RowStructure;
	
EndFunction

&AtClient
Procedure Attached_HandlerEventOnActivateAccountsRow()
	
	ActivateAccountRowAtServer(ThisForm.CurrentAccount);
	
EndProcedure // Attached_HandlerEventOnActivateListRow()

&AtClient
Procedure RefreshCurrentItem(ItemName)
	
	CurrentItemName = ItemName;
	If Items.Pages.CurrentPage = Items.PageOwnFunds
		And Items.OwnFundsPages.CurrentPage = Items.PageBalanceData Then
		CurrentItemName = "BalanceData";
	EndIf;
	
	Items[CurrentItemName].Refresh();	
	If ItemName = "OwnFundData" Then
		SetFooterTotals(ThisForm.CurrentAccount, CurrentItemName);
	EndIf;
	
	If CurrentItemName <> "BalanceData" 
		And Items.OwnFundDataCommandShowCalculation.Check Then
		Items.CalculationData.Refresh();
	EndIf;
	
EndProcedure // RefreshCurrentItem()

&AtClient
Procedure ActivateOwnFundDataRow()

	// import
	CommonClientServer = velpo_CommonFunctionsClientServer;
	
	// vars
	HasCashFlow = ThisForm.Items.Accounts.CurrentData.CashFlow;
	HasCheck = Items.OwnFundDataCommandShowCalculation.Check;
	
	If HasCashFlow Or HasCheck Then
		OwnFundDataItem = ThisForm.Items.OwnFundData;
		ObjectList = New ValueList;
		RowNumberList = New ValueList;
		AccountList = New ValueList;
		For Each Row In OwnFundDataItem.SelectedRows Do
			RowData = OwnFundDataItem.RowData(Row);
			ObjectList.Add(RowData.ObjectID);
			RowNumberList.Add(RowData.RowNumber);
			AccountList.Add(RowData.Account);
		EndDo; 
	Else
		Return;
	EndIf;
		
	// set dynamic filter
	If  HasCashFlow Then
		CanChangeRow = (ObjectList.Count() <= 1);
		Items.CashFlows.ChangeRowSet = CanChangeRow;
		Items.CashFlowsCashFlowFill.Visible = CanChangeRow;
		Items.CashFlowsObjectID.Visible = Not CanChangeRow;
		CommonClientServer.SetDynamicListParameter(CashFlows, "ObjectID",  ObjectList);
	EndIf;
	
	// calcultion
	If HasCheck Then
		CanChangeRow = (RowNumberList.Count() <= 1);
		Items.CalculationData.ChangeRowSet = CanChangeRow;
		Items.CalculationDataObjectID.Visible = Not CanChangeRow;
		CommonClientServer.SetDynamicListParameter(CalculationData, "Account",  AccountList);
		CommonClientServer.SetDynamicListParameter(CalculationData, "RowNumber",  RowNumberList);
	EndIf;
	
	If ObjectList.Count() > 0 Then
		ThisForm.CurrentObject = ObjectList[0].Value;
	EndIf;
	
EndProcedure // Attached_HandlerEventOnActivateListRow()

&AtClient
Procedure Attached_HandlerEventOnActivateOwnFundDataRow()
	
	ActivateOwnFundDataRow();
	
EndProcedure

&AtClient
Procedure FillDynamicListByName(ItemName)
	
	AdditionalParameters = New Structure("ItemName", ItemName);
	
	CompletionNotifyDescription = New NotifyDescription("FillDynamicListCompletionNotify", ThisForm, AdditionalParameters);

	ShowQueryBox(CompletionNotifyDescription, NStr("en='Fill data?';ru='Заполнить данные?'"), QuestionDialogMode.YesNo);

EndProcedure // FillDynamicListByName()

&AtClient
Procedure CalculateDataByName(ItemName, CommandName, UseAccount = False, UseRows = False)
	
	// vars
	AdditionalParameters = New Structure("ItemName, CommandName, UseAccount, UseRows", ItemName, CommandName, UseAccount, UseRows);
		
	If UseRows Then
		Item = Items[ItemName];
		SelectedRows = Item.SelectedRows;
		RowArray = New Array;
		For Each Row In SelectedRows Do
			CurrentData = Item.RowData(Row);
			RowArray.Add(CurrentData.RowNumber);
		EndDo; 
		AdditionalParameters.Insert("RowArray", RowArray);
		
		CalculateDataCompletionNotify(DialogReturnCode.Yes, AdditionalParameters);
	Else
		CompletionNotifyDescription = New NotifyDescription("CalculateDataCompletionNotify", ThisForm, AdditionalParameters);
		ShowQueryBox(CompletionNotifyDescription, NStr("en='Calculate data?';ru='Выполнить расчет?'"), QuestionDialogMode.YesNo);
	EndIf;

EndProcedure // FillDynamicListByName()

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// import                                     
	DimensionIDTypes = ChartsOfCharacteristicTypes.velpo_DimensionIDTypes;
	Common = velpo_CommonFunctions;
	
	// vars
	CounterpartyTypes = Common.ObjectAttributeValue(DimensionIDTypes.CounterpartyID, "ValueType");
	
	If Not ValueIsFilled(Object.Period) Then
		Object.Period = EndOfMonth(CurrentDate());
	EndIf;
	
	InitializeData();
		
EndProcedure

&AtServer
Procedure OnLoadDataFromSettingsAtServer(Settings)
	
	If Settings["Object.Period"] <> Undefined Then
		SetMainFormFilters(ThisForm);	
	EndIf;
	
EndProcedure

&AtClient
Procedure NotificationProcessing(EventName, Parameter, Source)
	
	If EventName = "ChangeCashFlow" And Source = ThisForm Then
		NotifyChanged(Items.OwnFundData.CurrentRow);
		Items.CashFlows.Refresh();
	EndIf;
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure PreviousMonth(Command)

	ChangePeriodByMonth(Command, -1);
	
EndProcedure

&AtClient
Procedure NextMonth(Command)
	
	ChangePeriodByMonth(Command, 1);

EndProcedure

&AtClient
Procedure ChangeAFew(Command)
	
	Item = ThisForm.CurrentItem;
	If Item.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	ListDataBeforeRowChange(Item, True);
	
EndProcedure

&AtClient
Procedure ClearValue(Command)
	
	Item = ThisForm.CurrentItem;
	If Item.CurrentRow = Undefined Then
		Return;
	EndIf;
	
	//import
	Client = velpo_Client;
	
	// vars
	ItemName = Item.Name;
	Field = Item.CurrentItem;
	FiledName = StrReplace(Field.Name, ItemName, "");
	
	If FiledName = "ObjectID" Then
		Return;
	EndIf;
		
	RowStructure = GetRowStructureByItem(ItemName);
	FillPropertyValues(RowStructure, Item.CurrentData);
			
	// open
	Client.ClearDynamicListColumnValue(ThisForm, "velpo_" + ItemName, RowStructure, FiledName, Object.Period, Item, True);

EndProcedure

&AtClient
Procedure CounterpartyFill(Command)

	FillDynamicListByName("CounterpartyData");
	
EndProcedure

&AtClient
Procedure OwnFundFill(Command)
	
	FillDynamicListByName("OwnFundData");
	
EndProcedure

&AtClient
Procedure NonLifeSolvencyMarginFill(Command)
	
	FillDynamicListByName("NonLifeSolvencyMarginData");
	
EndProcedure

&AtClient
Procedure ShowCalculation(Command)
	
	Check = Not Items.OwnFundDataCommandShowCalculation.Check;
	Items.OwnFundDataCommandShowCalculation.Check = Check;
	
	If Check Then
		ActivateOwnFundDataRow();
	EndIf;

	SetShowCalculation(ThisForm);
	
EndProcedure

&AtClient
Procedure CashFlowFill(Command)

	If Not ValueIsFilled(ThisForm.CurrentObject) Then
		Return;
	EndIf;
	
	FormParameters = New Structure;
	FormParameters.Insert("ObjectID", ThisForm.CurrentObject);
	FormParameters.Insert("Period", Object.Period);
	
	OpenForm("InformationRegister.velpo_CashFlows.Form.FormAutoFill",
		FormParameters,
		ThisForm);
	
EndProcedure

&AtClient
Procedure CreateCounterpartyIdentificators(Command)
	
	CalculateDataByName("CounterpartyData", "CreateCounterpartyIdentificators");
	
EndProcedure

&AtClient
Procedure CreateCounterpartyIdentificatorsByRows(Command)
	
	CalculateDataByName("CounterpartyData", "CreateCounterpartyIdentificators",, True);
	
EndProcedure

&AtClient
Procedure CounterpartyCreditQuility(Command)
	
	CalculateDataByName("CounterpartyData", "CalculateCounterpartyCreditQuility");
	
EndProcedure

&AtClient
Procedure CounterpartyCreditQuilityByRows(Command)
	
	CalculateDataByName("CounterpartyData", "CalculateCounterpartyCreditQuility",, True)
	
EndProcedure

&AtClient
Procedure Concentration(Command)
	
	CalculateDataByName("ConcentrationData", "CalculateConcentration");
	
EndProcedure

&AtClient
Procedure OwnFundCreditQuility(Command)
	
	CalculateDataByName("OwnFundData", "CalculateOwnFundCreditQuility", True);

EndProcedure

&AtClient
Procedure OwnFundCreditQuilityByRows(Command)
	
	CalculateDataByName("OwnFundData", "CalculateOwnFundCreditQuility", True, True);
	
EndProcedure

&AtClient
Procedure MarketRate(Command)
	
	CalculateDataByName("OwnFundData", "CalculateMarketRate", True);
	
EndProcedure

&AtClient
Procedure ItemValue(Command)
	
	CalculateDataByName("OwnFundData", "CalculateItemValue", True);
	
EndProcedure

&AtClient
Procedure ItemValueByRows(Command)
	
	CalculateDataByName("OwnFundData", "CalculateItemValue", True, True);
	
EndProcedure

&AtClient
Procedure MarketRateByRows(Command)
	
	CalculateDataByName("OwnFundData", "CalculateMarketRate", True, True);
	
EndProcedure

&AtClient
Procedure SolvencyIndicators(Command)
	
	CalculateDataByName("NonLifeSolvencyMarginData", "CalculateSolvencyIndicators");
	
EndProcedure

&AtClient
Procedure SolvencyMargin(Command)
	
	CalculateDataByName("NormativeRatioData", "CalculateSolvencyMargin");
	
EndProcedure

&AtClient
Procedure GotoCounterparty(Command)
	
	// import
	ClientServer = velpo_ClientServer; 
	ServerCall = velpo_ServerCall;
	
	CurrentData = Items.OwnFundData.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
	
	CurrentColumn = Items.OwnFundData.CurrentItem;
	CurrentValue = CurrentData[Mid(CurrentColumn.Name, 12)];
	
	If Not ValueIsFilled(CurrentValue) Then
		Return;
	EndIf;
			
	If CounterpartyTypes.ContainsType(TypeOf(CurrentValue)) Then
		
		KeyStructure =	ClientServer.GetCounterpartyDataStructure();
		FillPropertyValues(KeyStructure, CurrentData);
		KeyStructure.ObjectID = CurrentValue; 
		
		Items.CounterpartyData.CurrentRow = ServerCall.GetRowKey("velpo_CounterpartyData", KeyStructure, CurrentData.Period);
		ThisForm.CurrentItem = Items.CounterpartyData;
		
	EndIf;
	
EndProcedure

&AtClient
Procedure GotoAccount(Command)
	
	// vars
	Item = Items.BalanceData;
	
	BalanceDataSelection(Item, Item.CurrentRow, Item.CurrentItem, True);
	
EndProcedure


#EndRegion

#Region FormFieldsEventsHandlers

&AtClient
Procedure ItemOnChange(Item)
	
	Object.Period = EndOfMonth(Object.Period);
	
	SetMainFormFilters(ThisForm);
	
EndProcedure

#EndRegion

#Region TablesEventsHandlers

&AtClient
Procedure BalanceDataSelection(Item, SelectedRow, Field, StandardProcessing)

	// vars
	StandardProcessing = False;
	CurrentData = Item.CurrentData;
	
	If CurrentData = Undefined Then
		Return;
	EndIf;
		
	Items.Accounts.CurrentRow = CurrentData.Account;

EndProcedure

&AtClient
Procedure ListDataSelection(Item, SelectedRow, Field, StandardProcessing)
	
	If Item.CurrentRow = Undefined Then
		StandardProcessing = False;
		Return;
	EndIf;
	
	//import
	Client = velpo_Client;
	
	// vars
	ItemName = Item.Name;
	FiledName = StrReplace(Field.Name, ItemName, "");
	
	RowStructure = GetRowStructureByItem(ItemName);
	FillPropertyValues(RowStructure, Item.CurrentData);

	// don't change
	If ItemName = "ConcentrationData" 
		And FiledName = "CounterpartyID"
		And RowStructure.ObjectID = PredefinedValue("Enum.velpo_ConcentrationTypes.RealEstate") Then
		StandardProcessing = False;
		Return;				
	EndIf;
			
	// open
	Client.ChooseDynamicListColumnValue(ThisForm, "velpo_" + ItemName, RowStructure, FiledName,  Object.Period, Item, StandardProcessing);
	
EndProcedure

&AtClient
Procedure ListDataBeforeAddRow(Item, Cancel, Clone, Parent, Folder, Parameter)
	
	//import
	Client = velpo_Client;
	
	// vars
	ItemName = Item.Name;
	RowStructure = GetRowStructureByItem(ItemName);
	
	// fill structure
	If RowStructure.Property("BusinessUnit") Then
		RowStructure.BusinessUnit = Object.BusinessUnit;
	EndIf;
	
	If RowStructure.Property("Period") Then
		RowStructure.Period = Object.Period;
	EndIf;
	
	If ItemName = "OwnFundData"
		Or ItemName = "CalculationData" Then
		RowStructure.Account = ThisForm.CurrentAccount;
	ElsIf ItemName = "ConcentrationData" Then
		RowStructure.Account = PredefinedValue("ChartOfAccounts.velpo_Economic.Concentration");
	EndIf;
	
	If ItemName = "CashFlows"
		Or ItemName = "CalculationData" Then
		CurrentOwnFundData = ThisForm.Items.OwnFundData.CurrentData;
		If CurrentOwnFundData <> Undefined Then
			If ItemName = "CashFlows" Then
				RowStructure.ObjectID = CurrentOwnFundData.ObjectID;
			Else
				RowStructure.RowNumber = CurrentOwnFundData.RowNumber;
			EndIf;
		EndIf;
	EndIf;
	
	If Clone Then
		CurrentData = Item.CurrentData;
		FillPropertyValues(RowStructure, CurrentData);
	EndIf;
		
	Client.AddDynamicListRow(ThisForm, "velpo_" + ItemName, RowStructure, Object.Period, Item, Cancel, Clone);
	
EndProcedure

&AtClient
Procedure ListDataBeforeRowChange(Item, Cancel)
	
	Cancel = True;
	
	ListDataSelection(Item, Item.CurrentRow, Item.CurrentItem, False);
	
EndProcedure

&AtClient
Procedure AccountsOnActivateRow(Item)
	
	ListData = ThisForm.Items.Accounts.CurrentData;
	If ListData.Account <> ThisForm.CurrentAccount And ValueIsFilled(ListData.Account) Then
		ThisForm.CurrentAccount = ListData.Account;
		AttachIdleHandler("Attached_HandlerEventOnActivateAccountsRow", 0.1, True);
	EndIf;
	
EndProcedure

&AtClient
Procedure OwnFundDataOnActivateRow(Item)
	
	AttachIdleHandler("Attached_HandlerEventOnActivateOwnFundDataRow", 0.1, True);
	
EndProcedure

&AtClient
Procedure CashFlowsBeforeDeleteRow(Item, Cancel)
	
	//import
	Client = velpo_Client;
	
	// vars
	ItemName = Item.Name;
	CurrentData = Item.CurrentData;
	RowStructure = GetRowStructureByItem(ItemName);
	FillPropertyValues(RowStructure, CurrentData);
	
	Client.DeleteDynamicListRow(ThisForm, "velpo_" + ItemName, RowStructure, Object.Period, Item, Cancel);
	
EndProcedure

#EndRegion




&AtClient
Procedure CoverValue(Command)
	// Вставить содержимое обработчика.
EndProcedure


&AtClient
Procedure ConcentrationDataOnActivateRow(Item)
	// Вставить содержимое обработчика.
EndProcedure

















