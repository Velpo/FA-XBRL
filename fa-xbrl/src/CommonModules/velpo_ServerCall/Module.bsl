///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetAccountData(AccountRef) Export
	
	// import
	Chart = ChartsOfAccounts.velpo_Economic;
	
	Return Chart.GetAccountData(AccountRef);
	
EndFunction // GetAccountListByRef()

Function GetAccountListByRef(AccountRef) Export

	// import
	Chart = ChartsOfAccounts.velpo_Economic;
	
	Return Chart.GetAccountListByRef(AccountRef);

EndFunction // GetAccountListByRef()

Function GetRegisterDimensions(RegisterName) Export

	// import
	Server = velpo_Server;
	
	Return Server.GetRegisterDimensions(InformationRegisters[RegisterName]);
	
EndFunction // GetRegisterDimensions()

Function GetFieldValue(RegisterName,RowStructure, Name, Period) Export
	
	Register = InformationRegisters[RegisterName];
	
	Return Register.GetFieldValue(RowStructure, Name, Period);
	
EndFunction // GetFieldValue()

Function GetRowKey(RegisterName, RowStructure, Period) Export
	
	KeyStructure = GetRegisterDimensions(RegisterName);
	KeyStructure.Insert("Period",  Period);
	FillPropertyValues(KeyStructure, RowStructure);
	
	RowKey = InformationRegisters[RegisterName].CreateRecordKey(KeyStructure);
	
	Return RowKey;
	
EndFunction // GetRowKey()
 
Function AddListRowKey(RegisterName, RowStructure, Period, Clone) Export 

	// import
	Register = InformationRegisters[RegisterName];
	
	Row = Register.AddListRow(RowStructure, Period, Clone);
	
	If Row = Undefined Then
		Return Undefined;
	Else
		Return GetRowKey(RegisterName, Row, Period);
	EndIf;
	
EndFunction // AddListRow()

Function DeleteListRowKey(RegisterName, RowStructure, Period) Export 

	// import
	Register = InformationRegisters[RegisterName];
	
	Row = Register.DeleteListRow(RowStructure, Period);
	
	If Row = Undefined Then
		Return Undefined;
	Else
		Return GetRowKey(RegisterName, Row, Period);
	EndIf;
	
EndFunction // AddListRow()

Function GetAttributeData(AttributeRef) Export

	// import
	Common = velpo_CommonFunctions;
	
	Return Common.ObjectAttributeValues(AttributeRef, "Ref,Description,ValueType");
	
EndFunction // GetAttributeData()

Function GetResourceData(AttributeRef) Export

	//vars
	Description = Metadata.ChartsOfCharacteristicTypes.velpo_ObjectAttributes.Synonym;
	ValueType = New TypeDescription("ChartOfCharacteristicTypesRef.velpo_ObjectAttributes");
	
	Return New Structure("Ref,Description,ValueType", AttributeRef, Description, ValueType);
	
EndFunction // GetAttributeData()

Function GetIndicatorData(AttributeRef) Export

	//vars
	Description = Metadata.ChartsOfCharacteristicTypes.velpo_ResourceIndicators.Synonym;
	ValueType = New TypeDescription("ChartOfCharacteristicTypesRef.velpo_ResourceIndicators");
	
	Return New Structure("Ref,Description,ValueType", AttributeRef, Description, ValueType);
	
EndFunction // GetAttributeData()

Function GetAttributeDataByName(AttributeName) Export

	// import
	EconomicItemAttributes = ChartsOfCharacteristicTypes.velpo_ObjectAttributes;
	Common = velpo_CommonFunctions;
	
	Try
	 	AttributeRef = EconomicItemAttributes[AttributeName];
	Except
		Return Undefined;
	EndTry;
	
	Return GetAttributeData(AttributeRef);
	
EndFunction // GetAttributeDataByName()

Procedure SetFieldValue(RegisterName, RowStructure, Name, Period, Value) Export
	
	// import
	Register = InformationRegisters[RegisterName];
	
	Register.SetFieldValue(RowStructure, Name, Period, Value);
	
EndProcedure

