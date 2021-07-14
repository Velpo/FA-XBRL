///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	
Function GetZeroAttributeMap() Export

	// import
	ResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;
	
	ZeroMap = New Map;
	ZeroMap.Insert("CompulsoryHealthInsuranceClause_1_2_1", ResourceIndicators.Clause_1_2_1);
	ZeroMap.Insert("RiskClause_1_2_2", ResourceIndicators.Clause_1_2_2);
	ZeroMap.Insert("ClaimRightClause_1_2_3", ResourceIndicators.Clause_1_2_3);
	ZeroMap.Insert("CompulsoryHealthInsuranceClause_1_3_1", ResourceIndicators.Clause_1_3_1);
	ZeroMap.Insert("AssetValueChangeClause_1_3_2", ResourceIndicators.Clause_1_3_2); 
	ZeroMap.Insert("OtherOffBalanceLiabilitiesClause_1_3_3", ResourceIndicators.Clause_1_3_3); 
	ZeroMap.Insert("LiabilitiesClause_1_3_4", ResourceIndicators.Clause_1_3_4); 
	ZeroMap.Insert("MutualFundClause_3_1_7", ResourceIndicators.Clause_3_1_7); 
	ZeroMap.Insert("CashDepositClause_3_1_15", ResourceIndicators.Clause_3_1_15); 
	ZeroMap.Insert("ArrestClause_3_1_23", ResourceIndicators.Clause_3_1_23); 
	
	Return ZeroMap;

EndFunction // GetZeroAttributeCache()

Function GetMainCalculationAttributeMap() Export

	// import
	ResourceIndicators = ChartsOfCharacteristicTypes.velpo_ResourceIndicators;
	
	MainMap = New Map;
	MainMap.Insert("BookValue", ResourceIndicators.TotalValue);
	MainMap.Insert("ImpairmentAllowance", ResourceIndicators.ImpairmentAllowance);
	MainMap.Insert("OverdueDebt",  ResourceIndicators.Clause_3_1_13);
	
	Return MainMap;

EndFunction // GetMainCalculationAttributeArray()

#EndIf
