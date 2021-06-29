
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)
	
	OpenForm("DataProcessor.velpo_InstanceManager.Form", 
		, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
		
EndProcedure
