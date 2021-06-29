///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Function GetStructure() Export

	// import
	ClientServer = velpo_ClientServer; 
	                       
	Return ClientServer.GetDimensionDataStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText = 
	"SELECT
	|	DimensionData.Period AS Period,
	|	DimensionData.BusinessUnit AS BusinessUnit,
	|	DimensionData.Account AS Account,
	|	DimensionData.RowNumber AS RowNumber,
	|	DimensionData.Dimension AS Dimension,
	|	DimensionData.Value AS Value,
	|	DimensionData.ObjectID AS ObjectID
	|	//{FIELDS}
	|FROM
	|	InformationRegister.velpo_DimensionData.SliceLast(//{PERIOD}
	|																										,
	|																										//{FILTER}
	|																										) AS DimensionData
	|	//{JOIN}
	|";

	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	DimensionData = InformationRegisters.velpo_DimensionData;
	Server = velpo_Server;
	
	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
	Attribute = Undefined;
	
	If Not AccountStructure.Property(Name, Attribute) Then
		Return Value;
	EndIf;

	CurrentStructure = Server.GetRegisterDimensions(DimensionData);
	FillPropertyValues(CurrentStructure, RowStructure);
	CurrentStructure.Dimension = Attribute.Ref;
	
	Return DimensionData.Get(Period, CurrentStructure).Value;		
		
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	DimensionData = InformationRegisters.velpo_DimensionData;
	Server = velpo_Server;
		
	// vars
	Record = Server.CreateListRow(DimensionData, RowStructure, Period, Clone);
	If Clone Then
		Record.Dimension = Undefined;
	EndIf;
	Record.Write(False);
	
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	Economic = ChartsOfAccounts.velpo_Economic;
	DimensionData = InformationRegisters.velpo_DimensionData;
	Server = velpo_Server; 
	
	// vars
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
	Attribute = Undefined;
	
	If Not AccountStructure.Property(Name, Attribute) Then
		Return;
	EndIf;
	
	RowStructure.Insert("Dimension", Attribute.Ref);
	Server.ChangeListRow(DimensionData, RowStructure, "Value", Period, Value);
	
EndProcedure

Procedure DeleteRows(RowStructure, Period) Export
	
	// import
	Server = velpo_Server;
	DimensionData = InformationRegisters.velpo_DimensionData;
	
	Server.DeleteRows(DimensionData, RowStructure, Period);

EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Common = velpo_CommonFunctions;
	
	// vars
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_DimensionData";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText();
	
	Common.SetDynamicListProperties(List, ListProperties);
	
EndProcedure

#EndIf