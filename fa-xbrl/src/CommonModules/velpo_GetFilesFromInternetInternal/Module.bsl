////////////////////////////////////////////////////////////////////////////////
// Get files from the Internet subsystem
// 
////////////////////////////////////////////////////////////////////////////////

#Region InternalInterface

////////////////////////////////////////////////////////////////////////////////
// Adds handlers of internal events (subscriptions).

// See the description of this procedure in the StandardSubsystemsServer module.
Procedure InternalEventHandlersOnAdd(ClientHandlers, ServerHandlers) Export
	
	// SERVER HANDLERS
	
	ServerHandlers["StandardSubsystems.InfobaseVersionUpdate\OnAddUpdateHandlers"].Add(
		"GetFilesFromInternetInternal");
	
	ServerHandlers
["StandardSubsystems.BaseFunctionality\StandardSubsystemClientLogicParametersOnAdd"].Add(
		"GetFilesFromInternetInternal");
	
	ServerHandlers["StandardSubsystems.BaseFunctionality\SecurityProfilesOnEnable"].Add(
		"GetFilesFromInternetInternal");
		
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Internal event handlers

// Adds update handlers that are required by the subsystem.
//
// Parameters:
//  Handlers - ValueTable - see the description of NewUpdateHandlerTable function in the InfobaseUpdate common module.
// 
Procedure OnAddUpdateHandlers(Handlers) Export
	
	Handler = Handlers.Add();
	Handler.Version    = "1.2.1.4";
	Handler.Procedure = "GetFilesFromInternetInternal.UpdateSavedProxySettings";
	
EndProcedure

// Fills the parameter structures required by the client configuration code.
//
// Parameters:
//   Parameters   - Structure - parameter structure.
//
Procedure StandardSubsystemClientLogicParametersOnAdd(Parameters) Export
	
	Parameters.Insert("velpo_ProxyServerSettings", velpo_GetFilesFromInternet.GetProxyServerSetting());
	
EndProcedure

// Is summoned when infobase security profiles are enabled.
//
Procedure SecurityProfilesOnEnable() Export
	
	// Reset proxy settings to default condition.
	SaveServerProxySettings(Undefined);
	
	WriteLogEvent(velpo_GetFilesFromInternetClientServer.EventLogMessageText(),
		EventLogLevel.Warning, Metadata.Constants.velpo_ProxyServerSettingsttings,,
		NStr("en = 'When security profile is enabled, the proxy server settings are restored to default condition.'; ru = 'When security profile is enabled, the proxy server settings are restored to default condition.'"));
	
EndProcedure

#EndRegion

#Region InternalProceduresAndFunctions

// Saves proxy server settings parameters on the 1C:Enterprise server side
//
Procedure SaveServerProxySettings(Val Settings) Export
	
	SetPrivilegedMode(True);
	Constants.velpo_ProxyServerSettingsttings.Set(New ValueStorage(Settings));
	
EndProcedure

////////////////////////////////////////////////////////////////////////////////
// Infobase update

// Initializes new proxy server settings UseProxy
// and UseSystemSettings.
//
Procedure RefreshStoredProxySettings() Export
	
	InfobaseUserArray = InfobaseUsers.GetUsers();
	
	For Each IBUser In InfobaseUserArray Do
		
		ProxyServerSettings = velpo_CommonFunctions.CommonSettingsStorageLoad(
			"velpo_ProxyServerSettings", ,	, ,	IBUser.Name);
		
		If TypeOf(ProxyServerSettings) = Type("Map") Then
			
			SaveUserSettings = False;
			If ProxyServerSettings.Get("UseProxy") = Undefined Then
				ProxyServerSettings.Insert("UseProxy", False);
				SaveUserSettings = True;
			EndIf;
			If ProxyServerSettings.Get("UseSystemSettings") = Undefined Then
				ProxyServerSettings.Insert("UseSystemSettings", False);
				SaveUserSettings = True;
			EndIf;
			If SaveUserSettings Then
				velpo_CommonFunctions.CommonSettingsStorageSave(
					"velpo_ProxyServerSettings", , ProxyServerSettings, , IBUser.Name);
			EndIf;
			
		EndIf;
		
	EndDo;
	
	ProxyServerSettings = velpo_GetFilesFromInternet.ProxySettingsAtServer();
	
	If TypeOf(ProxyServerSettings) = Type("Map") Then
		
		SaveServerSettings = False;
		If ProxyServerSettings.Get("UseProxy") = Undefined Then
			ProxyServerSettings.Insert("UseProxy", False);
			SaveServerSettings = True;
		EndIf;
		If ProxyServerSettings.Get("UseSystemSettings") = Undefined Then
			ProxyServerSettings.Insert("UseSystemSettings", False);
			SaveServerSettings = True;
		EndIf;
		If SaveServerSettings Then
			SaveServerProxySettings(ProxyServerSettings);
		EndIf;
		
	EndIf;
	
EndProcedure

#EndRegion
