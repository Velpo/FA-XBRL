
&AtClient
Procedure CommandProcessing(CommandParameter, CommandExecuteParameters)

	OpenForm("ChartOfCharacteristicTypes.velpo_SourceQueryComponents.Form.OwnFundMapping", 
		, 
		CommandExecuteParameters.Source, 
		CommandExecuteParameters.Uniqueness, 
		CommandExecuteParameters.Window, 
		CommandExecuteParameters.URL);
	
EndProcedure
