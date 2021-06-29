///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetRegisterDimensions(Register) Export

	ReturnStructure = New Structure;
	RegisterMetadata = Register.EmptyKey().Metadata();
	For Each Dimension In RegisterMetadata.Dimensions Do
		ReturnStructure.Insert(Dimension.Name, Undefined);
	EndDo; 
	
	Return ReturnStructure;

EndFunction // GetRegisterDimensions()

Function GetRegisteResources(Register) Export

	ReturnStructure = New Structure;
	RegisterMetadata = Register.EmptyKey().Metadata();
	For Each Resource In RegisterMetadata.Resources Do
		ReturnStructure.Insert(Resource.Name, Undefined);
	EndDo; 
	
	Return ReturnStructure;

EndFunction // GetRegisterDimensions()

Function GetMaxRowNumber(Register, RowStructure, Period) Export
	
	// import
	Common = velpo_CommonFunctions;
	
	// vars
	RegisterName = Register.EmptyKey().Metadata().Name; 
	
	TableBlock = New ValueTable;
	TableBlock.Columns.Add("Period", Common.DateTypeDescription(DateFractions.Date));
	Query = New Query;
	Query.SetParameter("Period", Period);
	Filter = "Period = &Period";
	CurrentStructure = GetRegisterDimensions(Register);
	FillPropertyValues(CurrentStructure, RowStructure);
	
	Block = New DataLock;
	BlockElement = Block.Add("InformationRegister." + RegisterName);
	BlockElement.Mode = DataLockMode.Exclusive;
	BlockElement.DataSource = TableBlock;
	
	NeedBlock = True;
		
	For Each KeyValue In CurrentStructure Do
		If KeyValue.Value = Undefined Then
			NeedBlock = False;
		EndIf;
		TableBlock.Columns.Add(KeyValue.Key);
		BlockElement.UseFromDataSource(KeyValue.Key, KeyValue.Key);
		If KeyValue.Key = "RowNumber" Then
			Continue;
		EndIf;
		Filter = Filter + " AND " + KeyValue.Key + " = &" + KeyValue.Key;
		Query.SetParameter(KeyValue.Key, KeyValue.Value);
	EndDo; 
	LIneBlock = TableBlock.Add();
	FillPropertyValues(LIneBlock, RowStructure);
	
	If NeedBlock Then
		If TransactionActive() Then
			Block.Lock();	
		EndIf;
	EndIf;
		
	Query.Text = 
	"SELECT 
	|	ISNULL(MAX(RowNumber),0) + 1 AS RowNumber
	|FROM
	|	InformationRegister." + RegisterName + "
	|WHERE
	|	" + Filter + "
	|";
	Selection = Query.Execute().Select();
	Selection.Next();
	Return Selection.RowNumber;

EndFunction // GetMaxRowNumber

Function CreateListRow(Register, RowStructure, Period, Clone) Export

	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	Server = velpo_Server;
	
	// vars
	AccountStructure = Undefined;
	If RowStructure.Property("Account") Then
		AccountStructure = Economic.GetAccountData(RowStructure.Account);
	EndIf;

	Record = Register.CreateRecordManager();
	
	FillPropertyValues(Record, RowStructure);
	
	If ValueIsFilled(Period) Then
		Record.Period = Period;
	Else
		Record.Period = '2000-01-01';
	EndIf;
		
	If Clone Then
		Record.Read();
		NewRecord = Register.CreateRecordManager();
		FillPropertyValues(NewRecord, Record);
		Record = Undefined;
		Record = NewRecord;
	EndIf; 

	If AccountStructure <> Undefined Then
		Record.Account = RowStructure.Account; 
	EndIf;
	
	Return Record; 

EndFunction // CreateListRow()

Procedure ChangeListRow(Register, RowStructure, Name,  Period, Value) Export

	// vars
	CurrentStructure = GetRegisterDimensions(Register);
	FillPropertyValues(CurrentStructure, RowStructure);
	
	RecordSet = Register.CreateRecordSet();
	RecordSet.Filter.Period.Set(Period, True);
	For Each Element In CurrentStructure Do
		RecordSet.Filter[Element.Key].Set(Element.Value, True);
	EndDo; 
	RecordSet.Read();
	
	If  CurrentStructure.Property(Name) Then
		SetData = RecordSet.Unload();
		RecordSet.Clear();
		RecordSet.Write(True);
		RecordSet.Filter[Name].Set(Value, True);
		RecordSet.Load(SetData);
	EndIf;
	
	If RecordSet.Count() > 0 Then
		For Each Record In RecordSet Do
	 		Record[Name] = Value;
		EndDo; 
	Else
		Record = RecordSet.Add();
		Record.Period = Period;
		FillPropertyValues(Record, RowStructure);
		Record[Name] = Value;
	EndIf;
	
	If RowStructure.Property(Name) Then
		RowStructure[Name] = Value;
	EndIf;
	
	RecordSet.Write(True);
	 	
EndProcedure // ChangeListRow()

Procedure DeleteRows(Register, RowStructure, Period) Export

	// vars
	RecordSet = Register.CreateRecordSet();
	CurrentStructure = Register.GetStructure();
	FillPropertyValues(CurrentStructure, RowStructure);
	If Period <> Undefined Then
		RecordSet.Filter.Period.Set(Period, True);
	EndIf;
	
	For  Each KeyValue In CurrentStructure Do
		If KeyValue.Value = Undefined Then
			Continue;
		EndIf;
		RecordSet.Filter[KeyValue.Key].Set(KeyValue.Value, True);
	EndDo;
	
	RecordSet.Write(True);

EndProcedure

 
