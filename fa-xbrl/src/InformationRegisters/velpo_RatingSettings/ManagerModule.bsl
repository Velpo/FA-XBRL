#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
 
Function GetStructure() Export

	// import
	ClientServer = velpo_ClientServer; 
	                       
	Return ClientServer.GetCashFlowsStructure(); 	

EndFunction // GetItemStructure()

Function GetQueryText() Export
	
	QueryText = 
	"SELECT
	|	RatingSetting.RowNumber,
	|	RatingSetting.CreditQualityGroup,
	|	RatingSetting.ConsolidatedRating,
	|	RatingSetting.StandardAndPoors,
	|	RatingSetting.MoodysInvestorsService,
	|	RatingSetting.FitchRatings,
	|	RatingSetting.ExpertRA,
	|	RatingSetting.ACRA,
	|	RatingSetting.AM_Best
	|FROM
	|	InformationRegister.velpo_RatingSettings.SliceLast(//{PERIOD}
	|																												,
	|																												//{FILTER}
	|																												) AS RatingSetting
	|	//{JOIN}
	|ORDER BY
	|	RatingSetting.RowNumber ASC
	|";
	
	Return QueryText;
	
EndFunction // GetCounterpartyDataQueryText()

#EndIf