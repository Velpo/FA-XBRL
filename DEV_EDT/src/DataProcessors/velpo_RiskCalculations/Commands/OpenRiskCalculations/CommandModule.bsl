
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("DataProcessor.velpo_RiskCalculations.Form",,
		CommandExecuteParameters.Source,
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure
