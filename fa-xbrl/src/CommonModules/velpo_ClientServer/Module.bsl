///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetCounterpartyDataStructure() Export

	Return New Structure("Period,BusinessUnit,Account,ObjectID"); 	

EndFunction // GetCounterpartyDataStructure()

Function GetOwnFundDataStructure() Export

	Return New Structure("Period,BusinessUnit,Account,RowNumber,ObjectID"); 	

EndFunction // GetOwnFundDataStructure()

Function GetConcentrationDataStructure() Export

	Return New Structure("Period,BusinessUnit,Account,RowNumber,ObjectID"); 	

EndFunction // GetOwnFundDataStructure()

Function GetNonLifeSolvencyMarginDataStructure() Export

	Return New Structure("Period,BusinessUnit,Account,ObjectID"); 	

EndFunction // GetNonLifeSolvencyMarginDataStructure()

Function GetNormativeRatioStructure() Export

	Return New Structure("Period,BusinessUnit,Account,ObjectID"); 	

EndFunction // GetNormativeRatioStructure()

Function GetCashFlowsStructure() Export

	Return New Structure("Period,ObjectID,ScheduleDate,Void"); 	

EndFunction // GetCashFlowsStructure()

Function GetCalculationDataStructure() Export

	Return New Structure("Period,BusinessUnit,Account,RowNumber,Resource,Indicator"); 	

EndFunction // GetCashFlowsStructure()

Function GetDimensionDataStructure() Export

	Return New Structure("Period,BusinessUnit,Account,RowNumber,Dimension,ObjectID"); 	

EndFunction // GetDimensionDataStructure()

Function GetObjectPropertiesStructure() Export

	Return New Structure("Period,ObjectID,Attribute"); 	

EndFunction // GetObjectPropertiesStructure()

Function GetUnloadIdentificatorsStructure() Export

	Return New Structure("Period,ObjectID"); 	

EndFunction // GetUnloadIdentificatorsStructure()





