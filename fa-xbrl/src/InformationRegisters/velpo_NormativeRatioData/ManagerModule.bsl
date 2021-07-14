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
	                       
	Return ClientServer.GetNormativeRatioStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText =
	"SELECT
	|	NormativeRatio.Period AS Period,
	|	NormativeRatio.BusinessUnit AS BusinessUnit,
	|	NormativeRatio.ObjectID AS ObjectID,
	|	NormativeRatio.ItemValue AS ItemValue,
	|	NormativeRatio.Account AS Account,
	|	NormativeRatio.Account AS ObjectType,
	|	CAST(NormativeRatio.ObjectID AS Catalog.velpo_NormativeRatioItems).Code AS Code
	|FROM
	|	InformationRegister.velpo_NormativeRatioData AS NormativeRatio
	|";

	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

Function GetFieldValue(RowStructure, Name, Period) Export
	
	 // import
	NormativeRatio = InformationRegisters.velpo_NormativeRatioData;
	Server = velpo_Server; 

	Value = Undefined;
	
	If RowStructure.Property(Name, Value) Then
		Return Value;
	EndIf;
	
	// vars
	CurrentStructure = Server.GetRegisterDimensions(NormativeRatio);
	FillPropertyValues(CurrentStructure, RowStructure);
	
	Return NormativeRatio.Get(Period, CurrentStructure)[Name];		
	
EndFunction // GetFieldValue()

Function AddListRow(RowStructure, Period, Clone) Export
	
	// import
	Economic = ChartsOfAccounts.velpo_Economic;
	NormativeRatio = InformationRegisters.velpo_NormativeRatioData;
	Server = velpo_Server;
		
	// vars
	RowStructure.Account = Economic.NormativeRatio;
	AccountStructure = Economic.GetAccountData(RowStructure.Account);
		
	BeginTransaction();
	
	Record = Server.CreateListRow(NormativeRatio, RowStructure, Period, Clone);
	Record.ObjectID = AccountStructure.ObjectID.ValueType.AdjustValue(Undefined);
	Record.ObjectType = AccountStructure.ObjectID.Ref;
	Record.Write(False);
		
	CommitTransaction();
	
	Return Record;
	
EndFunction // AddListRow(RowStructure, Period, Clone)

Procedure SetFieldValue(RowStructure, Name, Period, Value) Export
	
	 // import
	NormativeRatio = InformationRegisters.velpo_NormativeRatioData;
	Server = velpo_Server; 
	
	// vars
	Server.ChangeListRow(NormativeRatio, RowStructure, Name, Period, Value);
	
EndProcedure

Procedure SetDynamicList(List) Export
	
	// import
	Cache = velpo_ServerCache;
	Economic = ChartsOfAccounts.velpo_Economic;
	Common = velpo_CommonFunctions;
	RiskCalculations = DataProcessors.velpo_RiskCalculations;

	// vars
	AccountStructure = Economic.GetAccountData(Economic.NormativeRatio);
	
	ListProperties = Common.DynamicListPropertiesStructure();
	ListProperties.MainTable = "InformationRegister.velpo_NormativeRatioData";
	ListProperties.DynamicDataRead = True;
	ListProperties.QueryText = GetQueryText();
	
	Common.SetDynamicListProperties(List, ListProperties);
	
	RiskCalculations.AddDynamicListColumns(List, AccountStructure, AccountStructure.Properties);

EndProcedure

#EndIf