  
  #Region XDTOPackage
  
  
// Returns an XML presentation of the XDTO object.
//
// Parameters:
//  XDTODataObject - XDTODataObject - object, whose XML presentation will be generated.
//  Factory        - XDTOFactory - factory used for generating the XML presentation.
//                   If the parameter is not specified, the global XDTO factory is used.
//
// Returns: 
//   String - XML presentation of the XDTO object.
//
Function XDTODataObjectIntoXMLString(Val XDTODataObject, Val Factory = Undefined) Export
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Write = New XMLWriter();
	Write.SetString();
	Factory.WriteXML(Write, XDTODataObject, , , , XMLTypeAssignment.Explicit);
	
	Return Write.Close();
	
EndFunction

// Generates an XDTO object by the XML presentation.
//
// Parameters:
//  XMLLine - String      - XML presentation of the XDTO object.
//  Factory - XDTOFactory - factory used to generate the XDTO object.
//            If the parameter is not, the global XDTO factory is used.
//
// Returns: 
//   XDTODataObject.
//
Function XDTODataObjectFromXMLString(Val XMLLine, Val Factory = Undefined) Export
	
	If Factory = Undefined Then
		Factory = XDTOFactory;
	EndIf;
	
	Reader = New XMLReader;
	Reader.SetString(XMLLine);
	
	Return Factory.ReadXML(Reader);
	
EndFunction

// Check if is list
//
Function IsXDTOList(Val XDTOData) Export

	Return (TypeOf(XDTOData) = Type("XDTOList"));

EndFunction // XDTOIsList()

// Check if is object
//
Function IsXDTODataObject(Val XDTOData) Export

	Return (TypeOf(XDTOData) = Type("XDTODataObject"));

EndFunction // IsXDTODataObject()

//  Get first object
//
Function GetFirstXDTOObject(XDTOData) Export

	If IsXDTOList(XDTOData) Then
		Return XDTOData[0];
	Else
		Return XDTOData;
	EndIf;
	
EndFunction // XDTOGetFirstObject()
 
// Get content for object
//
Function GetXDTOObjectValueContent(XDTOData, Name) Export

	Return ?(XDTOData[Name] = Undefined, "", XDTOData[Name].__content);	

EndFunction // GetXDTOObjectContent()
 

  #EndRegion 

#Region Interface

// Parses the URI string into parts and returns them as a structure.
// The following normalizations are described based on RFC 3986.
//
// Parameters:
// URLString - String - link to the resource in the following format:
//             <schema>://<username>:<password>@<domain>:<port>/<path>?<query_string>#<fragment_id>
//
// Returns:
// Structure      - composite part of the URI according to the format:
// * Schema       - String.
// * Username     - String.
// * Password     - String.
// * ServerName   - String - <domain>:<port> part of the input parameter.
// * Domain       - String
// * Port         - String
// * PathAtServer - String - <path>?<query_string>#<fragment_id> part of the input parameter
//
Function URIStructure(Val URLString) Export
	
	URLString = TrimAll(URLString);
	
	// Schema
	Schema = "";
	Position = Find(URLString, "://");
	If Position > 0 Then
		Schema = Lower(Left(URLString, Position - 1));
		URLString = Mid(URLString, Position + 3);
	EndIf;

	// Connection string and path on server
	ConnectionString = URLString;
	PathAtServer = "";
	Position = Find(ConnectionString, "/");
	If Position > 0 Then
		PathAtServer = Mid(ConnectionString, Position + 1);
		ConnectionString = Left(ConnectionString, Position - 1);
	EndIf;
		
	// User details and server name
	AuthorizationString = "";
	ServerName = ConnectionString;
	Position = Find(ConnectionString, "@");
	If Position > 0 Then
		AuthorizationString = Left(ConnectionString, Position - 1);
		ServerName = Mid(ConnectionString, Position + 1);
	EndIf;
	
	// Username and password
	Login = AuthorizationString;
	Password = "";
	Position = Find(AuthorizationString, ":");
	If Position > 0 Then
		Login = Left(AuthorizationString, Position - 1);
		Password = Mid(AuthorizationString, Position + 1);
	EndIf;
	
	// Domain and port
	Domain = ServerName;
	Port = "";
	Position = Find(ServerName, ":");
	If Position > 0 Then
		Domain = Left(ServerName, Position - 1);
		Port   = Mid(ServerName, Position + 1);
	EndIf;
	
	Result = New Structure;
	Result.Insert("Schema", Schema);
	Result.Insert("Login", Login);
	Result.Insert("Password", Password);
	Result.Insert("ServerName", ServerName);
	Result.Insert("Domain", Domain);
	Result.Insert("Port", ?(IsBlankString(Port), Undefined, Number(Port)));
	Result.Insert("PathAtServer", PathAtServer);
	
	Return Result;
	
EndFunction

// Returns the code of the default configuration language, for example, "en".
Function DefaultLanguageCode() Export
	#If Not ThinClient  And Not WebClient Then
		Return Metadata.DefaultLanguage.LanguageCode;
	#Else
	//TODO
	//	Return StandardSubsystemsClientCached.ClientParameters().DefaultLanguageCode;
	#EndIf
EndFunction  

// Searches for the item in the value list or in the array.
//
Function FindInList(List, Item)
	
	Var ItemInList;
	
	If TypeOf(List) = Type("ValueList") Then
		If TypeOf(Item) = Type("ValueListItem") Then
			ItemInList = List.FindByValue(Item.Value);
		Else
			ItemInList = List.FindByValue(Item);
		EndIf;
	EndIf;
	
	If TypeOf(List) = Type("Array") Then
		ItemInList = List.Find(Item);
	EndIf;
	
	Return ItemInList;
	
EndFunction

// Creates a copy of the passed object.
//
// Parameters:
//  Source - Arbitrary - object to be copied.
//
// Returns:
//  Arbitrary - copy of the object that is passed to the Source parameter.
//
// Note:
//  The function cannot be used for object types (CatalogObject, DocumentObject, and others).
//
Function CopyRecursive(Source) Export
	
	Var Destination;
	
	SourceType = TypeOf(Source);
	If SourceType = Type("Structure") Then
		Destination = CopyStructure(Source);
	ElsIf SourceType = Type("Map") Then
		Destination = CopyMap(Source);
	ElsIf SourceType = Type("Array") Then
		Destination = CopyArray(Source);
	ElsIf SourceType = Type("ValueList") Then
		Destination = CopyValueList(Source);
	#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then
	ElsIf SourceType = Type("ValueTable") Then
		Destination = Source.Copy();
	#EndIf
	Else
		Destination = Source;
	EndIf;
	
	Return Destination;
	
EndFunction

// Creates a copy of the value of the Structure type.
// 
// Parameters:
//  SourceStructure – Structure – structure to be copied.
// 
// Returns:
//  Structure - copy of the source structure.
//
Function CopyStructure(SourceStructure) Export
	
	ResultStructure = New Structure;
	
	For Each KeyAndValue In SourceStructure Do
		ResultStructure.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultStructure;
	
EndFunction

// Creates a copy of the value of the Map type.
// 
// Parameters:
// SourceMap – Map - map to be copied.
// 
// Returns:
// Map - copy of the source map.
//
Function CopyMap(SourceMap) Export
	
	ResultMap= New Map;
	
	For Each KeyAndValue In SourceMap Do
		ResultMap.Insert(KeyAndValue.Key, CopyRecursive(KeyAndValue.Value));
	EndDo;
	
	Return ResultMap;

EndFunction

// Creates a copy of the value of the Array type.
// 
// Parameters:
// SourceArray – Array - array to be copied.
// 
// Returns:
// Array - copy of the source array.
//
Function CopyArray(SourceArray) Export
	
	ResultArray = New Array;
	
	For Each Item In SourceArray Do
		ResultArray.Add(CopyRecursive(Item));
	EndDo;
	
	Return ResultArray;
	
EndFunction

// Creates a copy of the value of the ValueList type.
// 
// Parameters:
// SourceList – ValueList - value list to be copied.
// 
// Returns:
// ValueList - copy of the source value list.
//
Function CopyValueList(SourceList) Export
	
	ResultList = New ValueList;
	
	For Each ListItem In SourceList Do
		ResultList.Add(
			CopyRecursive(ListItem.Value), 
			ListItem.Presentation, 
			ListItem.Check, 
			ListItem.Picture);
	EndDo;
	
	Return ResultList;
	
EndFunction


// Creates a copy of the passed object.
//
// Parameters:
//  Source - Arbitrary - object to be copied.
//
// Returns:
//  Arbitrary - copy of the object that is passed to the Source parameter.
//
// Note:
//  The function cannot be used for object types (CatalogObject, DocumentObject, and others).
//
Procedure LinkRecursive(Source, Destination) Export
	
	SourceType = TypeOf(Source);
	If SourceType = Type("Structure") Then
		LinkStructure(Source, Destination);
	ElsIf SourceType = Type("Map") Then
		LinkMap(Source, Destination);
	ElsIf SourceType = Type("Array") Then
		LinkArray(Source, Destination);
	ElsIf SourceType = Type("ValueList") Then
		LinkValueList(Source, Destination);
	Elsif Destination <> Source Then
		Destination = Source;
	EndIf;
		
EndProcedure

// Creates a copy of the value of the Structure type.
// 
// Parameters:
//  SourceStructure – Structure – structure to be copied.
// 
// Returns:
//  Structure - copy of the source structure.
//
Procedure LinkStructure(SourceStructure, DestinationStructure) Export
	
	For Each KeyAndValue In SourceStructure Do
		DistinationValue = Undefined;
		If DestinationStructure.Property(KeyAndValue.Key, DistinationValue) Then
			LinkRecursive(KeyAndValue.Value, DistinationValue);
		Else
			DestinationStructure.Insert(KeyAndValue.Key, KeyAndValue.Value);
		EndIf;
	EndDo;
	
EndProcedure

// Creates a copy of the value of the Map type.
// 
// Parameters:
// SourceMap – Map - map to be copied.
// 
// Returns:
// Map - copy of the source map.
//
Procedure LinkMap(SourceMap, DestinationMap) Export
	
	For Each KeyAndValue In SourceMap Do
		ResultMap = DestinationMap[KeyAndValue.Key];
		If ResultMap = Undefined Then
			DestinationMap.Insert(KeyAndValue.Key, KeyAndValue.Value);
		Else
			LinkRecursive(KeyAndValue.Value, ResultMap);	
		EndIf;
	EndDo;
	
EndProcedure

// Creates a copy of the value of the Array type.
// 
// Parameters:
// SourceArray – Array - array to be copied.
// 
// Returns:
// Array - copy of the source array.
//
Procedure LinkArray(SourceArray, DestinationArray) Export
	
	ResultArray = New Array;
	
	For Each Item In SourceArray Do
		DestinationItemIndex = DestinationArray.Find(Item) ;
		If DestinationItemIndex = Undefined Then
			DestinationArray.Add(Item);
		Else
			LinkRecursive(Item, DestinationArray.Get(DestinationItemIndex));
		EndIf;
	EndDo;
	
EndProcedure

// Creates a copy of the value of the ValueList type.
// 
// Parameters:
// SourceList – ValueList - value list to be copied.
// 
// Returns:
// ValueList - copy of the source value list.
//
Procedure LinkValueList(SourceList, DestinationList) Export
	
	For Each ListItem In SourceList Do
		ValueListItem = DestinationList.FindByValue(ListItem.Value);
		If ValueListItem = Undefined Then
			DestinationList.Add(
				ListItem.Value, 
				ListItem.Presentation, 
				ListItem.Check, 
				ListItem.Picture);
		Else
			LinkRecursive(ListItem, ValueListItem);	
		EndIf;
	EndDo;
	
EndProcedure


// Compares value list items or array elements by values.
Function ValueListsEqual(List1, List2) Export
	
	EqualLists = True;
	
	For Each ListItem1 In List1 Do
		If FindInList(List2, ListItem1) = Undefined Then
			EqualLists = False;
			Break;
		EndIf;
	EndDo;
	
	If EqualLists Then
		For Each ListItem2 In List2 Do
			If FindInList(List1, ListItem2) = Undefined Then
				EqualLists = False;
				Break;
			EndIf;
		EndDo;
	EndIf;
	
	Return EqualLists;
	
EndFunction 

//  Get array of list values, which are checked
//
Function GetCheckedListValues(List) Export
	
	ResultArray = New Array;
	For Each Item In List Do
		If Item.Check Then
			ResultArray.Add(Item.Value);
		EndIf;
	EndDo; 

	Return ResultArray;
	
EndFunction // GetCheckedListValues()
 

// Generates and displays the message that can relate to a form item.
//
// Parameters
// MessageToUserText - String - message text;
// DataKey           - Any infobase object reference - infobase object reference, to which this
//                     message relates, or a record key;
// Field             - String - form item description;
// DataPath          - String - data path (path to a form attribute);
// Cancel            - Boolean - Output parameter. It is always set to True.
//
// Examples:
//
// 1. Showing the message associated with the object attribute near the managed form field:
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ,
// 	"FieldInFormObject",
// 	"Object");
//
// An alternative variant of using in the object form module:
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ,
// 	"Object.FieldInFormObject");
//
// 2. Showing the message associated with the form attribute near the managed form field:
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ,
// 	"FormAttributeName");
//
// 3. Showing the message associated with infobase object attribute.
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), ObjectInfobase, "Responsible");
//
// 4. Showing messages associated with an infobase object attribute by reference.
// CommonUseClientServer.MessageToUser(
// 	NStr("en = 'Error message.'"), Ref, , , Cancel);
//
// Incorrect using:
// 1. Passing DataKey and DataPath parameters at the same time.
// 2. Passing a value of an illegal type to the DataKey parameter.
// 3. Specifying a reference without specifying a field (and/or a data path).
//
Procedure MessageToUser(
		Val MessageToUserText,
		Val DataKey = Undefined,
		Val Field = "",
		Val DataPath = "",
		Cancel = False) Export
	
	Message = New UserMessage;
	Message.Text = MessageToUserText;
	Message.Field = Field;
	
	IsObject = False;
	
#If Not ThinClient And Not WebClient Then
	If DataKey <> Undefined
	 And XMLTypeOf(DataKey) <> Undefined Then
		ValueTypeString = XMLTypeOf(DataKey).TypeName;
		IsObject = Find(ValueTypeString, "Object.") > 0;
	EndIf;
#EndIf
	
	If IsObject Then
		Message.SetData(DataKey);
	Else
		Message.DataKey = DataKey;
	EndIf;
	
	If Not IsBlankString(DataPath) Then
		Message.DataPath = DataPath;
	EndIf;
		
	Message.Message();
	
	Cancel = True;
	
EndProcedure

// Fills the destination collection with values from the source collection.
// Objects of the following types can be a destination collection and a source collection:
// ValueTable, ValueTree, ValueList, and other collection types.
//
// Parameters:
//  SourceCollection - ArbitraryCollection - value collection that is a source of filling data;
//  TargetCollection - ArbitraryCollection - value collection that is a target of filling data.
//
Procedure FillPropertyCollection(SourceCollection, TargetCollection) Export
	
	For Each Item In SourceCollection Do
		
		FillPropertyValues(TargetCollection.Add(), Item);
		
	EndDo;
	
EndProcedure

// Find item in collection
//
Procedure FindRecursively(ItemCollection, ItemArray, SearchMethod, SearchValue)
	
	For Each FilterItem In ItemCollection Do
		
		If TypeOf(FilterItem) = Type("DataCompositionFilterItem") Then
			
			If SearchMethod = 1 Then
				If FilterItem.LeftValue = SearchValue Then
					ItemArray.Add(FilterItem);
				EndIf;
			ElsIf SearchMethod = 2 Then
				If FilterItem.Presentation = SearchValue Then
					ItemArray.Add(FilterItem);
				EndIf;
			EndIf;
		Else
			
			FindRecursively(FilterItem.Items, ItemArray, SearchMethod, SearchValue);
			
			If SearchMethod = 2 And FilterItem.Presentation = SearchValue Then
				ItemArray.Add(FilterItem);
			EndIf;
			
		EndIf;
		
	EndDo;
	
EndProcedure

// Fills the destination collection with values from the source value list.
//
Procedure FillValueList(SourceList, TargetList) Export
	
	For Each ListItem In SourceList Do
		TargetList.Add(
			CopyRecursive(ListItem.Value), 
				ListItem.Presentation, 
				ListItem.Check, 
				ListItem.Picture);
	EndDo; 

EndProcedure


#EndRegion 

#Region DynamicList

////////////////////////////////////////////////////////////////////////////////
// Functions for working with dynamic list filters and parameters.

// Searches for the item and the group of the dynamic list filter by the passed field name or
// presentation.
// Parameters:
//  SearchArea   - container with items and groups of the filter, for example
//                 List.Filter or a group in the filter;
//  FieldName    - String - data composition field name (is not used for groups);
//  Presentation - String - data composition field presentation;
//
Function FindFilterItemsAndGroups(Val SearchArea,
									Val FieldName = Undefined,
									Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	Return ItemArray;
	
EndFunction

// Searches for a filter item in the collection by the specified presentation. 
//
// Parameters:
//  WhereToAdd   - container with items and groups of the filter, for example, List.Filter or a
//                 group in the filter;
//  Presentation - String - group presentation.
//
Function FindFilterItemByPresentation(ItemCollection, Presentation) Export
	
	ReturnValue = Undefined;
	
	For Each FilterItem In ItemCollection Do
		If FilterItem.Presentation = Presentation Then
			ReturnValue = FilterItem;
			Break;
		EndIf;
	EndDo;
	
	Return ReturnValue
	
EndFunction

// Adds filter groups to ItemCollection.
// Parameters:
//  ItemCollection - container with items and groups of the filter, for example
//                   List.Filter or a group in the filter;
//  GroupType      - DataCompositionFilterItemsGroupType - group type; 
//  Presentation   - String - group presentation.
//
Function CreateFilterItemGroup(Val ItemCollection, Presentation, GroupType) Export
	

	If TypeOf(ItemCollection) = Type("DataCompositionFilterItemGroup") Then

		ItemCollection = ItemCollection.Items;
	EndIf;
	
	FilterItemGroup = FindFilterItemByPresentation(ItemCollection, Presentation);
	If FilterItemGroup = Undefined Then
		FilterItemGroup = ItemCollection.Add(Type("DataCompositionFilterItemGroup"));
	Else
		FilterItemGroup.Items.Clear();
	EndIf;
	
	FilterItemGroup.Presentation = Presentation;
	FilterItemGroup.Application = DataCompositionFilterApplicationType.Items;
	FilterItemGroup.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	FilterItemGroup.GroupType = GroupType;
	FilterItemGroup.Use = True;
	
	Return FilterItemGroup;
	
EndFunction

// Adds the composition item into the composition item container.
//
// Parameters:
// ItemCollection - container with items and groups of the filter, for example
//                  List.Filter or a group in the filter;
// FieldName      - String - data composition field name. Must be filled.
// ComparisonType - DataCompositionComparisonType - comparison type; 
// RightValue     - Arbitrary - value to be compared; 
// Presentation   - String - data composition item presentation;
// Use            - Boolean - item usage;
// ViewMode       - DataCompositionSettingsItemViewMode - view mode.
// UserSettingID  - String - see DataCompositionFilter.UserSettingID in the Syntax Assistant.
//
Function AddCompositionItem(AreaToAdd,
									Val FieldName,
									Val ComparisonType,
									Val RightValue = Undefined,
									Val Presentation = Undefined,
									Val Use = Undefined,
									Val ViewMode = Undefined,
									Val UserSettingID = Undefined) Export
	
	Item = AreaToAdd.Items.Add(Type("DataCompositionFilterItem"));
	Item.LeftValue = New DataCompositionField(FieldName);
	Item.ComparisonType = ComparisonType;
	
	If ViewMode = Undefined Then
		Item.ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	Else
		Item.ViewMode = ViewMode;
	EndIf;
	
	If RightValue <> Undefined Then
		Item.RightValue = RightValue;
	EndIf;
	
	If Presentation <> Undefined Then
		Item.Presentation = Presentation;
	EndIf;
	
	If Use <> Undefined Then
		Item.Use = Use;
	EndIf;
 
	// Important: The ID must be set up in the final stage of the item customization or it will
	// be copied to the user settings in a half-filled condition.
	If UserSettingID  <> Undefined Then
		Item.UserSettingID  = UserSettingID;
	ElsIf Item.ViewMode <>  DataCompositionSettingsItemViewMode.Inaccessible Then
		Item.UserSettingID  = FieldName;
	EndIf;	
	Return Item;
	
EndFunction

// Changes the filter item with the specified field name or presentation.
//
// Parameters:
//  FieldName      - String - data composition field name. Must be filled;
//  ComparisonType - DataCompositionComparisonType - comparison type;
//  RightValue     - Arbitrary - value to be compared;
//  Presentation   - String - data composition item presentation;
//  Use            - Boolean - item usage;
//  ViewMode       - DataCompositionSettingsItemViewMode - view mode.
//
Function ChangeFilterItems(SearchArea,
								Val FieldName = Undefined,
								Val Presentation = Undefined,
								Val RightValue = Undefined,
								Val ComparisonType = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(SearchArea.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If FieldName <> Undefined Then
			Item.LeftValue = New DataCompositionField(FieldName);
		EndIf;
		If Presentation <> Undefined Then
			Item.Presentation = Presentation;
		EndIf;
		If Use <> Undefined Then
			Item.Use = Use;
		EndIf;
		If ComparisonType <> Undefined Then
			Item.ComparisonType = ComparisonType;
		EndIf;
		If RightValue <> Undefined Then
			Item.RightValue = RightValue;
		EndIf;
		If ViewMode <> Undefined Then
			Item.ViewMode = ViewMode;
		EndIf;
	EndDo;
	
	Return ItemArray.Count();
	
EndFunction

// Deletes the filter item with the specified field name or presentation.
// 
// Parameters:
//  AreaToDelete - container with items and groups of the filter, for example
//                 List.Filter or a group in the filter;
//  FieldName    - String - data composition field name (is not used for groups);
//  Presentation - String - data composition field presentation.
// 
Procedure DeleteFilterItems(Val AreaToDelete,
										Val FieldName = Undefined,
										Val Presentation = Undefined) Export
	
	If ValueIsFilled(FieldName) Then
		SearchValue = New DataCompositionField(FieldName);
		SearchMethod = 1;
	Else
		SearchMethod = 2;
		SearchValue = Presentation;
	EndIf;
	
	ItemArray = New Array;
	
	FindRecursively(AreaToDelete.Items, ItemArray, SearchMethod, SearchValue);
	
	For Each Item In ItemArray Do
		If Item.Parent = Undefined Then
			AreaToDelete.Items.Delete(Item);
		Else
			Item.Parent.Items.Delete(Item);
		EndIf;
	EndDo;
	
EndProcedure

// Adds or replaces the existing filter item.   
// 
// Parameters:
//  WhereToAdd     - container with items and groups of the filter, for example
//                   List.Filter or a group in the filter;
//  FieldName      - String - data composition field name (must always be filled);
//  ComparisonType - DataCompositionComparisonType - comparison type;
//  RightValue     - Arbitrary - value to be compared;
//  Presentation   - String - data composition field presentation;
//  Use            - Boolean - item usage;
//  ViewMode       - DataCompositionSettingsItemViewMode - view mode.
//  UserSettingID  - String - see DataCompositionFilter.UserSettingID in the Syntax Assistant.
//
Procedure SetFilterItem(WhereToAdd,
								Val FieldName,
								Val RightValue = Undefined,
								Val ComparisonType = Undefined,
								Val Presentation = Undefined,
								Val Use = Undefined,
								Val ViewMode = Undefined,
								Val UserSettingID = Undefined) Export
	
	ModifiedCount = ChangeFilterItems(WhereToAdd, FieldName, Presentation,
							RightValue, ComparisonType, Use, ViewMode);
	
	If ModifiedCount = 0 Then
		If ComparisonType = Undefined Then
			ComparisonType = DataCompositionComparisonType.Equal;
		EndIf;
		If ViewMode = Undefined Then
			ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
		EndIf;
		AddCompositionItem(WhereToAdd, FieldName, ComparisonType,
								RightValue, Presentation, Use, ViewMode, UserSettingID);
	EndIf;
	
EndProcedure
 
// Adds or replaces the filter item of the dynamic list.
//
// Parameters:
//  DynamicList    - DynamicList - form attribute that requires the filter to be set.
//  FieldName      - String - data composition field name. Must be filled.
//  RightValue     - Arbitrary - value to be compared.
//  ComparisonType - DataCompositionComparisonType - comparison type.
//  Presentation   - String - data composition field presentation.
//  Use - Boolean  - item usage.
//  ViewMode       - DataCompositionSettingsItemViewMode - view mode.
//  UserSettingID  - String - see  DataCompositionFilter.UserSettingID in the Syntax Assistant.
//
Procedure  SetDynamicListFilterItem(DynamicList, FieldName,
	RightValue = Undefined,
	ComparisonType = Undefined,
	Presentation = Undefined,
	Use = Undefined,
	ViewMode = Undefined,
	UserSettingID = Undefined) Export
	
	If ViewMode =  Undefined Then
		ViewMode =  DataCompositionSettingsItemViewMode.Inaccessible;
	EndIf;
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.FixedSettings.Filter,
		FieldName);
	
	SetFilterItem(
		DynamicList.SettingsComposer.Settings.Filter,
		FieldName,
		RightValue,
		ComparisonType,
		Presentation,
		Use,
		ViewMode,
		UserSettingID);
	
EndProcedure 
 
// Copies filters from the form parameters to the dynamic list.
//
// Parameters:
// Form        - ManagedForm - form to be a source of the filters.
// DynamicList - DynamicList - Optional. The list where the filter will be set.
//               If the value is not passed the form attribute named List of the corresponding
//               type is expected.
//
// Important: Once the procedure execution finishes, the Form.Paramerets.Filters collection is 
//            cleared. That is why if the Form.Parameres.Filter collection is used in the form
//            script, the procedure must be executed after the execution of such script. For
//            example, in the end of the OnCreateAtServer handler. 
//
Procedure MoveFiltersToDynamicList(Form, DynamicList = Undefined) Export
	Var ComparisonType;
	
	If Not Form.Parameters.Property("Filter")  Then
		Return;
	EndIf;
	If DynamicList = Undefined Then
		DynamicList = Form.List;
	EndIf;
	
	FiltersFromParameters = Form.Parameters.Filter;
	DynamicListFilters = DynamicList.SettingsComposer.Settings.Filter;
	
	Use = True;
	ViewMode = DataCompositionSettingsItemViewMode.Inaccessible;
	
	For Each KeyAndValue In FiltersFromParameters Do
		FieldName = KeyAndValue.Key;
		RightValue = KeyAndValue.Value;
		
		If TypeOf(RightValue) = Type("Array") Then
			ComparisonType =  DataCompositionComparisonType.InList;
		ElsIf TypeOf(RightValue) = Type("ValueList") Then
			ComparisonType = DataCompositionComparisonType.InList;
		Else
			ComparisonType = Undefined;
		EndIf;
		
		SetFilterItem(
			DynamicListFilters,
			FieldName,
			RightValue,
			ComparisonType,
			,
			Use,
			ViewMode);
	EndDo;
	
	FiltersFromParameters.Clear();
EndProcedure 
 
// Deletes the filter group item of the dynamic list.
//
// Parameters:
//  DynamicList  - DynamicList - form attribute that requires the filter to be set.
//  FieldName    - String - composition field name. Does not used for groups.
//  Presentation - String - composition field presentation.
//
Procedure DeleteDynamicListFilterCroupItems(DynamicList, FieldName = Undefined, Presentation = Undefined) Export
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.FixedSettings.Filter,
		FieldName,
		Presentation);
	
	DeleteFilterItems(
		DynamicList.SettingsComposer.Settings.Filter,
		FieldName,
		Presentation);
 
EndProcedure 
 
// Sets of updates the ParameterName parameter of the List dynamic list.
//
// Parameters:
// List          - DynamicList - form attribute, for which the parameter must be set.
// ParameterName - String - name of the parameter dynamic list.
// Value         - Arbitrary - new parameter value.
// Use           - Boolean - flag that shows whether the parameter is used.
//
Procedure SetDynamicListParameter(List, ParameterName, Value, Use = True) Export
	
	DataCompositionParameterValue = List.Parameters.FindParameterValue(New DataCompositionParameter(ParameterName));
	If DataCompositionParameterValue <> Undefined Then
		If Use And DataCompositionParameterValue.Value <> Value Then
			DataCompositionParameterValue.Value  = Value;
		EndIf;
		If DataCompositionParameterValue.Use <> Use Then
			DataCompositionParameterValue.Use = Use;
		EndIf;
	EndIf;
	
EndProcedure 

#EndRegion 