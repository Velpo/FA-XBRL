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
Procedure GenerateCompletionNotify(QueryResult, AdditionalParameters) Export

	If QueryResult = DialogReturnCode.Yes Then 
		GenerateAtServer();
	EndIf;
		
EndProcedure // ChooseDynamicListColumnValueCompletionNotify()

&AtClient
Procedure SaveCompletionNotify(QueryResult, AdditionalParameters) Export

	If QueryResult = DialogReturnCode.Yes Then 
		SaveAtServer();
		Notify("ChangeCashFlow",, ThisForm.FormOwner);
		ThisForm.Close();
	EndIf;
		
EndProcedure // ChooseDynamicListColumnValueCompletionNotify()

#EndRegion

#Region ServiceProceduresAndFunctions

&AtServer
Function GetPropertiesQueryText()
	
	// import
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;

	// vars
	QueryText = ObjectProperties.GetQueryText();
	QueryText = StrReplace(QueryText, "//{FIELDS}", ",Attribute.PredefinedDataName AS Name");
	QueryText = StrReplace(QueryText, "//{PERIOD}", "&PeriodFilter");
	QueryText = StrReplace(QueryText, "//{FILTER}", "ObjectID = &ObjectID AND Attribute IN (&Attributes)");

	Return QueryText ;
	
EndFunction // GetPropertiesQueryText()

&AtServer
Function GetCashFlowQueryText()

	// import
	CashFlows = InformationRegisters.velpo_CashFlows;

	// vars
	QueryText = CashFlows.GetQueryText();
	QueryText = StrReplace(QueryText, "//{PERIOD}", "&PeriodFilter");
	QueryText = StrReplace(QueryText, "//{FILTER}", "ObjectID = &ObjectID");

	Return QueryText ;

EndFunction // GetCashFlowQueryText()

&AtServer
Function GetPropertyList()

	// import
	ObjectAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;

	// vars 
	PropertyList = New ValueList;
	PropertyList.Add(ObjectAttributes.OpenDate, "OpenDate");
	PropertyList.Add(ObjectAttributes.CloseDate, "CloseDate");
	PropertyList.Add(ObjectAttributes.FrequencyType, "FrequencyType");
	PropertyList.Add(ObjectAttributes.PaymentType, "PaymentType");
	PropertyList.Add(ObjectAttributes.NominalValue, "NominalValue");
	PropertyList.Add(ObjectAttributes.InterestRate, "InterestRate");
	
	Return PropertyList;

EndFunction // GetPropertyArray()

&AtServer
Procedure GenerateAtServer()

	// import
	PaymentTypes = Enums.velpo_PaymentTypes;

	CashFlowSet.Clear();
	
	If PaymentType = PaymentTypes.Annuity Then
		GenerateAnnuityPayments();
	ElsIf PaymentType = PaymentTypes.Differentiated Then
		GenerateDifferentiatedPayments();
	ElsIf PaymentType = PaymentTypes.Capitalization Then
		GenerateCapitalizationPayments();
	ElsIf PaymentType = PaymentTypes.Installment Then
		GenerateInstallmentPayments();
	EndIf;

EndProcedure //GenerateAtServer

&AtServer
Procedure AddCashFlowRecord(RecordStructure)
	Record = CashFlowSet.Add();
	FillPropertyValues(Record, RecordStructure);
	If Record.ScheduleDate > CloseDate Then
		Record.ScheduleDate = CloseDate;
	EndIf;
EndProcedure

&AtServer
Procedure AddNegativeNominalValue()
	
	// import
	CashFlows = InformationRegisters.velpo_CashFlows;

	// vars
	RecordStructure = CashFlows.GetStructure();
	FillPropertyValues(RecordStructure, Parameters);

	RecordStructure.Insert("ScheduleDate", OpenDate); 
	RecordStructure.Insert("CashFlow", -NominalValue);
	AddCashFlowRecord(RecordStructure);
	
EndProcedure // AddNominalValue()

&AtServer
Procedure GenerateAnnuityPayments()
	
	// import
	CashFlows = InformationRegisters.velpo_CashFlows;
	FrequencyTypes = Enums.velpo_FrequencyTypes;
	PaymentTypes = Enums.velpo_PaymentTypes;
	
	// vars
	Division = FrequencyTypes.GetTermByItem(FrequencyType);
	Duration  = FrequencyTypes.GetDurationByItem(FrequencyType, OpenDate, CloseDate);
	RatePercent = (InterestRate / 100) / (12 / Division);
	PeriodicPayment = NominalValue * PaymentTypes.GetAnnuityCoefficient(RatePercent, Duration);
	RecordStructure = CashFlows.GetStructure();
	FillPropertyValues(RecordStructure, Parameters);
	
	AddNegativeNominalValue();
	
	For i = 1 To Duration Do
		RecordStructure.Insert("ScheduleDate", AddMonth(OpenDate, i *Division)); 
		RecordStructure.Insert("CashFlow", PeriodicPayment); 
		AddCashFlowRecord(RecordStructure);
	EndDo; 

EndProcedure

&AtServer
Procedure GenerateDifferentiatedPayments()
	
	// import
	CashFlows = InformationRegisters.velpo_CashFlows;
	FrequencyTypes = Enums.velpo_FrequencyTypes;
	PaymentTypes = Enums.velpo_PaymentTypes;
	
	// vars
	Division = FrequencyTypes.GetTermByItem(FrequencyType);
	Duration  = FrequencyTypes.GetDurationByItem(FrequencyType, OpenDate, CloseDate);
	RatePercent = (InterestRate / 100);
	MainPart = Round(NominalValue / Duration, 2);
	Rest = NominalValue; 
	RecordStructure = CashFlows.GetStructure();
	FillPropertyValues(RecordStructure, Parameters);
	
	AddNegativeNominalValue();
	
	For i = 1 To Duration Do
		ScheduleDate = AddMonth(OpenDate, i *Division);
		Coefficient = PaymentTypes.GetDifferentiatedCoefficient(RatePercent, AddMonth(ScheduleDate, -1 * Division), ScheduleDate);
		RecordStructure.Insert("ScheduleDate", ScheduleDate); 
		RecordStructure.Insert("CashFlow", ?(i = Duration, Rest, MainPart) + Rest * Coefficient);
		Rest = Rest - MainPart;
		AddCashFlowRecord(RecordStructure);
	EndDo; 
		
EndProcedure

&AtServer
Procedure GenerateCapitalizationPayments()
	
	// import
	CashFlows = InformationRegisters.velpo_CashFlows;
	FrequencyTypes = Enums.velpo_FrequencyTypes;
	PaymentTypes = Enums.velpo_PaymentTypes;
	
	// vars
	Division = FrequencyTypes.GetTermByItem(FrequencyType);
	Duration  = FrequencyTypes.GetDurationByItem(FrequencyType, OpenDate, CloseDate);
	RatePercent = (InterestRate / 100);
	Rest = NominalValue; 
	RecordStructure = CashFlows.GetStructure();
	FillPropertyValues(RecordStructure, Parameters);
	
	AddNegativeNominalValue();	
	
	For i = 1 To Duration Do
		ScheduleDate = AddMonth(OpenDate, i *Division);
		Coefficient = PaymentTypes.GetDifferentiatedCoefficient(RatePercent, AddMonth(ScheduleDate, -1 * Division), ScheduleDate);
		CurrentPercents = Rest * Coefficient;
		RecordStructure.Insert("ScheduleDate", ScheduleDate); 
		RecordStructure.Insert("CashFlow", ?(i = Duration,  NominalValue, 0) + CurrentPercents);
		Rest = Rest + CurrentPercents;
		AddCashFlowRecord(RecordStructure);
	EndDo; 

EndProcedure

&AtServer
Procedure GenerateInstallmentPayments()
	
	// import
	CashFlows = InformationRegisters.velpo_CashFlows;
	FrequencyTypes = Enums.velpo_FrequencyTypes;
	
	// vars
	Division = FrequencyTypes.GetTermByItem(FrequencyType);
	Duration  = FrequencyTypes.GetDurationByItem(FrequencyType, OpenDate, CloseDate);
	MainPart = Round(NominalValue / Duration, 2);
	Rest = NominalValue; 
	RecordStructure = CashFlows.GetStructure();
	FillPropertyValues(RecordStructure, Parameters);
	
	AddNegativeNominalValue();
	
	For i = 1 To Duration Do
		ScheduleDate = AddMonth(OpenDate, i *Division);
		RecordStructure.Insert("ScheduleDate", ScheduleDate); 
		RecordStructure.Insert("CashFlow", ?(i = Duration, Rest, MainPart));
		Rest = Rest - MainPart;
		AddCashFlowRecord(RecordStructure);
	EndDo; 
		
EndProcedure

&AtServer
Procedure InitializeData()

	// vars 
	Query = New Query;
	Query.SetParameter("ObjectID", Parameters.ObjectID);
	Query.SetParameter("PeriodFilter", Parameters.Period);
	Query.SetParameter("Attributes", GetPropertyList());
	
	// get properties	
	Query.Text = GetPropertiesQueryText();
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		ThisForm[Selection.Name] = Selection.Value;
	EndDo;
	
	// get cash flow
	Query.Text = StrReplace(GetCashFlowQueryText(), "//{JOIN}", "WHERE Void = FALSE ORDER BY ScheduleDate ASC");
	CashFlowSet.Load(Query.Execute().Unload());
		
EndProcedure // InitializeData()

&AtServer
Procedure SaveAtServer()
	
	// import
	ObjectProperties = InformationRegisters.velpo_ObjectProperties;

	// vars 
	ObjectPropertyStructure = ObjectProperties.GetStructure();
	PropertyList = GetPropertyList();
	
	FillPropertyValues(ObjectPropertyStructure, ThisForm.Parameters);
	RecordCashFlowSet = ThisForm.FormAttributeToValue("CashFlowSet");
	
	Query = New Query;
	Query.SetParameter("ObjectID", Parameters.ObjectID);
	Query.SetParameter("PeriodFilter", Parameters.Period);
	Query.SetParameter("Attributes", PropertyList);
	Query.SetParameter("ScheduleDates", RecordCashFlowSet.UnloadColumn("ScheduleDate"));
	
	// get properties	and cash flows
	Query.Text = GetPropertiesQueryText() + Chars.CR + ";" + Chars.CR + StrReplace(GetCashFlowQueryText(), "//{JOIN}", "WHERE ScheduleDate NOT IN (&ScheduleDates)");
	QueryResults = Query.ExecuteBatch();
	PropertyTable = QueryResults[0].Unload();
	CashFlowTable = QueryResults[1].Unload();
	PropertyTable.Indexes.Add("Attribute");
	
	BeginTransaction();
	
	// set property
	For Each PropertyElement In PropertyList Do
		PropertyArray = PropertyTable.FindRows(New Structure("Attribute", PropertyElement.Value));
		CurrentValue = ThisForm[PropertyElement.Presentation];
		If PropertyArray.Count() = 0 Or PropertyArray[0].Value <> CurrentValue Then
			ObjectPropertyStructure.Insert("Attribute", PropertyElement.Value);
			ObjectProperties.SetFieldValue(ObjectPropertyStructure, "Value", ObjectPropertyStructure.Period, CurrentValue);
		EndIf;
	EndDo;
		
	// set cash flow
	RecordCashFlowSet.Filter.Period.Set(Parameters.Period);
	RecordCashFlowSet.Filter.ObjectID.Set(Parameters.ObjectID);
	For Each Row In CashFlowTable Do
		Record = RecordCashFlowSet.Add();
		FillPropertyValues(Record, Row,, "Period");
		Record.Period = Parameters.Period;
		Record.Void = True;
	EndDo; 
	RecordCashFlowSet.Write(True);
	
	CommitTransaction();
	
EndProcedure // SaveAtServer()

#EndRegion

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	InitializeData();
	
EndProcedure

#EndRegion

#Region FormCommandsHandlers

&AtClient
Procedure SaveAndClose(Command)

	CompletionNotifyDescription = New NotifyDescription("SaveCompletionNotify", ThisForm);

	ShowQueryBox(CompletionNotifyDescription, NStr("en='Save cash flow?';ru='Сохранить денежный поток?'"), QuestionDialogMode.YesNo);
	
EndProcedure

&AtClient
Procedure Generate(Command)
	
	CompletionNotifyDescription = New NotifyDescription("GenerateCompletionNotify", ThisForm);

	ShowQueryBox(CompletionNotifyDescription, NStr("en='Generate cash flow?';ru='Сформировать денежный поток?'"), QuestionDialogMode.YesNo);
	
EndProcedure

#EndRegion
