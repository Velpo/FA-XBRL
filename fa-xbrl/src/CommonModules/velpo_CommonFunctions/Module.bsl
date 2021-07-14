
////////////////////////////////////////////////////////////////////////////////
// Common procedures and functions for working with infobase data.

#Region ObjectsAttribute
	
// Returns a structure that contains attribute values read from the infobase by
// object reference.
// 
// If access to any of the attributes is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights, 
// turn privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
//
// Parameters:
//  Ref        - AnyRef - reference to the object whose attribute values are retrieved.
//  Attributes - String - attribute names separated with commas, formatted according to
//               structure requirements 
//               Example: "Code, Description, Parent".
//             - Structure, FixedStructure -  keys are field aliases used for resulting
//               structure keys, values (optional) are field names. If a value is empty, it
//               is considered equal to the key.
//             - Array, FixedArray - attribute names formatted according to structure
//               property requirements.
//
// Returns:
//  Structure - contains names (keys) and values of the requested attributes.
//              If the string of the requested attributes is empty, an empty structure is returned.
//              If an empty reference is passed as the object reference, all return attribute
//              will be Undefined.
//
Function ObjectAttributeValues(Ref, Val Attributes) Export
	
	If TypeOf(Attributes) = Type("String") Then
		If IsBlankString(Attributes) Then
			Return New Structure;
		EndIf;
		Attributes = velpo_StringFunctionsClientServer.SplitStringIntoSubstringArray(Attributes, ",", True);
	EndIf;
	
	AttributeStructure = New Structure;
	If TypeOf(Attributes) = Type("Structure") Or TypeOf(Attributes) = Type("FixedStructure") Then
		AttributeStructure = Attributes;
	ElsIf TypeOf(Attributes) = Type("Array") Or TypeOf(Attributes) = Type("FixedArray") Then
		For Each Attribute In Attributes Do
			AttributeStructure.Insert(StrReplace(Attribute, ".", ""), Attribute);
		EndDo;
	Else
		Raise velpo_StringFunctionsClientServer.SubstituteParametersInString(
			NStr("en = 'Invalid Attributes parameter type: %1'"),
			String(TypeOf(Attributes)));
	EndIf;
	
	FieldTexts = "";
	For Each KeyAndValue In AttributeStructure Do
		FieldName   = ?(ValueIsFilled(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Value),
		              TrimAll(KeyAndValue.Key));
		
		Alias = TrimAll(KeyAndValue.Key);
		
		FieldTexts  = FieldTexts + ?(IsBlankString(FieldTexts), "", ",") + "" + FieldName + " AS " + Alias;
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text =
	"SELECT
	|" + FieldTexts + " FROM " + Ref.Metadata().FullName() + " AS SpecifiedTableAlias
	| WHERE
	| SpecifiedTableAlias.Ref = &Ref
	|";
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Result = New Structure;
	For Each KeyAndValue In AttributeStructure Do
		Result.Insert(KeyAndValue.Key);
	EndDo;
	FillPropertyValues(Result, Selection);
	
	Return Result;
	
EndFunction

// Returns an attribute value read from the infobase by object reference.
// 
// If access to the attribute is denied, an exception is raised.
// To be able to read the attribute value irrespective of current user rights, 
// turn the privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
// 
// Parameters:
//  Ref           - AnyRef - reference to a catalog, a document, or any other infobase object.
//  AttributeName - String - for example, "Code".
// 
// Returns:
//  Arbitrary. It depends on the type of the read attribute.
// 
Function ObjectAttributeValue(Ref, AttributeName) Export
	
	Result = ObjectAttributeValues(Ref, AttributeName);
	Return Result[StrReplace(AttributeName, ".", "")];
	
EndFunction
 
// Returns a map that contains attribute values of several objects read from the infobase.
// 
// If access to any of the attributes is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights, 
// turn privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
// 
// Parameters:
//  RefArray       - array of references to objects of the same type (it is important that all
//                   referenced objects have the same type);
//  AttributeNames - String - it must contains attribute names separated with commas.
// 			             These attributes will be used for keys in the resulting structures.
// 			             Example: "Code, Description, Parent".
// 
// Returns:
//  Map where keys are object references, and values are structures that
//  contains AttributeNames as keys and attribute values as values.
// 
Function ObjectsAttributeValues(RefArray, AttributeNames) Export
	
	AttributeValues = New Map;
	If RefArray.Count() = 0 Then
		Return AttributeValues;
	EndIf;
	
	Query = New Query;
	Query.Text =
		"SELECT
		|	Ref AS Ref, " + AttributeNames + " FROM " + RefArray[0].Metadata().FullName() + " AS Table
		| WHERE Table.Ref IN (&RefArray)";
	Query.SetParameter("RefArray", RefArray);
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Result = New Structure(AttributeNames);
		FillPropertyValues(Result, Selection);
		AttributeValues[Selection.Ref] = Result;
	EndDo;
	
	Return AttributeValues;
	
EndFunction

// Returns values of a specific attribute for several objects read from the infobase.
// 
// If access to the attribute is denied, an exception is raised.
// To be able to read attribute values irrespective of current user rights, 
// turn privileged mode on.
// 
// Is not intended for retrieving empty reference attribute values.
// 
// Parameters:
//  RefArray     - array of references to objects of the same type (it is important that all
//                 referenced objects have the same type);
// AttributeName - String - for example, "Code".
// 
// Returns:
//  Map where keys are object references, and values are attribute values.
// 
Function ObjectsAttributeValue(RefArray, AttributeName) Export
	
	AttributeValues = ObjectsAttributeValues(RefArray, AttributeName);
	For Each Item In AttributeValues Do
		AttributeValues[Item.Key] = Item.Value[AttributeName];
	EndDo;
		
	Return AttributeValues;
	
EndFunction

#EndRegion

#Region Storages

////////////////////////////////////////////////////////////////////////////////
// Saving, reading, and deleting settings from storages.


// Loads settings from the common settings storage.
//
// Parameters:
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - optional. A key of the settings to be saved.
//   DefaultValue        - Arbitrary - optional. The value to be substituted if the settings
//                         cannot be loaded.
//   SettingsDescription - SettingsDescription - optional. When reading the settings value,
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - optional. A name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//
Function CommonSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		DefaultValue,
		SettingsDescription,
		UserName);
	
EndFunction

// Loads settings item from the system settings storage.
//
// Parameters:
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - Optional. key of the settings to be saved.
//   DefaultValue        - Arbitrary - Optional.
//                         The value to be substituted if the settings cannot be loaded.
//   SettingsDescription - SettingsDescription - Optional. When reading the settings value,
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - Optional. The name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//
Function SystemSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		SystemSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName);
	
EndFunction

// Loads settings item from the settings storage through its manager.
//
// Parameters:
//   StorageManager      - StandardSettingsStorageManager - storage from which the settings
//                         item is loaded.
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - Optional. The key of the settings to be saved.
//   DefaultValue        - Arbitrary - Optional. The value to be substituted if the settings
//                         cannot be loaded.
//   SettingsDescription - SettingsDescription - Optional. When reading the settings value, 
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - Optional. name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//   "Settings that are automatically saved to the system storage" in Syntax Assistant.
//
Function StorageLoad(StorageManager, ObjectKey, SettingsKey, DefaultValue,
	SettingsDescription, UserName)
	
	Result = Undefined;
	
	If AccessRight("SaveUserData", Metadata) Then
		Result = StorageManager.Load(ObjectKey, SettingsKey(SettingsKey), SettingsDescription, UserName);
	EndIf;
	
	If Result = Undefined Then
		Result = DefaultValue;
	Else
		SetPrivilegedMode(True);
		If DeleteDeadReferences(Result) Then
			Result = DefaultValue;
		EndIf;
	EndIf;
	
	Return Result;
EndFunction

// Loads settings item from the form data settings storage.
//
// Parameters:
//   ObjectKey           - String - settings object key.
//   SettingsKey         - String - Optional. key of the settings to be saved.
//   DefaultValue        - Arbitrary - Optional.
//                         The value to be substituted if the settings cannot be loaded.
//   SettingsDescription - SettingsDescription - Optional. When reading the settings value,
//                         auxiliary settings data is written to this parameter.
//   UserName            - String - Optional. The name of a user whose settings are loaded.
//                         If it is not specified, current user settings are loaded.
//
// Returns: 
//   Arbitrary - settings loaded from the storage.
//   Undefined - if settings are not found and the DefaultValue parameter is not specified.
//
// See also:
//   "StandardSettingsStorageManager.Load" in Syntax Assistant.
//
Function FormDataSettingsStorageLoad(ObjectKey, SettingsKey = "", DefaultValue = Undefined, 
	SettingsDescription = Undefined, UserName = Undefined) Export
	
	Return StorageLoad(
		FormDataSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		DefaultValue, 
		SettingsDescription, 
		UserName);
	
EndFunction

// Deletes dead references from a variable.
//
// Parameters:
//   RefOrCollection - AnyRef, Arbitrary - object to be checked or collection to be cleared.
//
// Returns: 
//   Boolean - 
//    * True  - if the RefOrCollection of a reference type and the object are not found in the infobase.
//    * False - when the RefOrCollection of a reference type or the object are found in the infobase.
//
Function DeleteDeadReferences(RefOrCollection)
	
	Type = TypeOf(RefOrCollection);
	
	If Type = Type("Undefined")
		Or Type = Type("Boolean")
		Or Type = Type("String")
		Or Type = Type("Number")
		Or Type = Type("Date") Then // Optimization - often used primitive types.
		
		Return False; // Not a reference.
		
	ElsIf Type = Type("Array") Then
		
		Count = RefOrCollection.Count();
		For Number = 1 To Count Do
			ReverseIndex = Count - Number;
			Value = RefOrCollection[ReverseIndex];
			If DeleteDeadReferences(Value) Then
				RefOrCollection.Delete(ReverseIndex);
			EndIf;
		EndDo;
		
		Return False; // Not a reference.
		
	ElsIf Type = Type("Structure")
		Or Type = Type("Map") Then
		
		For Each KeyAndValue In RefOrCollection Do
			Value = KeyAndValue.Value;
			If DeleteDeadReferences(Value) Then
				RefOrCollection.Insert(KeyAndValue.Key, Undefined);
			EndIf;
		EndDo;
		
		Return False; // Not a reference.
		
	ElsIf IsReference(Type) Then
		
		If ObjectAttributeValue(RefOrCollection, "Ref") = Undefined Then
			RefOrCollection = Undefined;
			Return True; // Dead reference.
		Else
			Return False; // Object found.
		EndIf;
		
	Else
		
		Return False; // Not a reference.
		
	EndIf;
	
EndFunction

// Deletes settings item from the form data settings storage.
//
// Parameters:
//   ObjectKey   - String - settings object key. 
//               - Undefined - Settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - Settings and all keys are deleted.
//   UserName    - String - Name of a user whose settings are deleted.
//               - Undefined - Settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//
Procedure FormDataSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		FormDataSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves the settings item to the common settings storage and updates 
// cached values.
// 
// Parameters:
//  Corresponds to the CommonSettingsStorage.Save method. 
//  See StorageSave() procedure parameters for details. 
//
Procedure CommonSettingsStorageSaveAndRefreshCachedValues(ObjectKey, SettingsKey, Value) Export
	
	CommonSettingsStorageSave(ObjectKey, SettingsKey, Value,,,True);
	
EndProcedure

// Deletes the settings item from the common settings storage.
//
// Parameters:
//   ObjectKey   - String - settings object key. 
//               - Undefined - settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - settings and all keys are deleted.
//   UserName    - String - name of a user whose settings are deleted.
//               - Undefined - settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//
Procedure CommonSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves the StructureArray user settings array and updates 
// cached values. Can be called on client.
// 
// Parameters:
//  StructureArray - Array - Array of Structure with the following fields:
//                    Object, SettingsItem, Value.
//
Procedure CommonSettingsStorageSaveArrayAndRefreshCachedValues(StructureArray) Export
	
	CommonSettingsStorageSaveArray(StructureArray, True);
	
EndProcedure

// Deletes settings item from the system settings storage.
//
// Parameters:
//   ObjectKey   - String - settings object key. 
//               - Undefined - Settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - Settings and all keys are deleted.
//   UserName    - String - name of a user whose settings are deleted.
//               - Undefined - Settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//
Procedure SystemSettingsStorageDelete(ObjectKey, SettingsKey, UserName) Export
	
	StorageDelete(
		SystemSettingsStorage,
		ObjectKey,
		SettingsKey,
		UserName);
	
EndProcedure

// Saves settings to the common settings storage.
//
// Parameters:
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules
//                               must be reset.
//
// See also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//
Procedure CommonSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshCachedValues = False) Export
	
	StorageSave(
		CommonSettingsStorage,
		ObjectKey,
		SettingsKey,
		Value,
		SettingsDescription,
		UserName,
		NeedToRefreshCachedValues);
	
EndProcedure

// Saves the array of user settings to StructureArray. 
// Can be called on client.
// 
// Parameters:
//  StructureArray            - Array - Array of Structure with the following fields:
//                              Object, SettingsItem, Value;
//  NeedToRefreshCachedValues - Boolean - flag that shows whether cached values will be updated.
//
Procedure CommonSettingsStorageSaveArray(StructureArray,
	NeedToRefreshCachedValues = False) Export
	
	If Not AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	For Each Item In StructureArray Do
		CommonSettingsStorage.Save(Item.Object, SettingsKey(Item.Settings), Item.Value);
	EndDo;
	
	If NeedToRefreshCachedValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Saves settings item to the system settings storage.
//
// Parameters:
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules
//                               must be reset.
//
// See also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//
Procedure SystemSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshCachedValues = False) Export
	
	StorageSave(
		SystemSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshCachedValues);
	
EndProcedure

// Saves settings item to the form data settings storage.
//
// Parameters:
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules
//                               must be reset.
//
// See also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//
Procedure FormDataSettingsStorageSave(ObjectKey, SettingsKey = "", Value,
	SettingsDescription = Undefined, UserName = Undefined, 
	NeedToRefreshCachedValues = False) Export
	
	StorageSave(
		FormDataSettingsStorage, 
		ObjectKey, 
		SettingsKey, 
		Value,
		SettingsDescription, 
		UserName, 
		NeedToRefreshCachedValues);
	
EndProcedure

// Saves settings item to the settings storage through its manager.
//
// Parameters:
//   StorageManager            - StandardSettingsStorageManager - Storage where the settings saved.
//   ObjectKey                 - String - settings object key.
//   SettingsKey               - String - key of the settings to be saved.
//   Value                     - Arbitrary - settings to be saved in a storage. 
//   SettingsDescription       - SettingsDescription - auxiliary settings data.
//   UserName                  - String - name of a user whose settings are saved.
//                               If it is not specified, current user settings are saved.
//   NeedToRefreshCachedValues - Boolean - flag that shows whether cashes of Cashed modules must be reset.
//
// See. also:
//   "StandardSettingsStorageManager.Save" in Syntax Assistant.
//   "Settings that are automatically saved to the system storage" in Syntax Assistant.
//
Procedure StorageSave(StorageManager, ObjectKey, SettingsKey, Value,
	SettingsDescription, UserName, NeedToRefreshCachedValues)
	
	If NOT AccessRight("SaveUserData", Metadata) Then
		Return;
	EndIf;
	
	StorageManager.Save(ObjectKey, SettingsKey(SettingsKey), Value, SettingsDescription, UserName);
	
	If NeedToRefreshCachedValues Then
		RefreshReusableValues();
	EndIf;
	
EndProcedure

// Deletes settings item from the settings storage through its manager.
//
// Parameters:
//   StorageManager - StandardSettingsStorageManager - storage where the settings item is deleted.
//   ObjectKey   - String - settings object key. 
//               - Undefined - Settings for all objects are deleted.
//   SettingsKey - String - key of the settings to be saved.
//               - Undefined - Settings and all keys are deleted.
//   UserName    - String - Name of a user whose settings are deleted.
//               - Undefined - Settings of all users are deleted.
//
// See also:
//   "StandardSettingsStorageManager.Delete" in Syntax Assistant.
//   "Settings that are automatically saved to the system storage" in Syntax Assistant.
//
Procedure StorageDelete(StorageManager, ObjectKey, SettingsKey, UserName)
	
	If AccessRight("SaveUserData", Metadata) Then
		StorageManager.Delete(ObjectKey, SettingsKey(SettingsKey), UserName);
	EndIf;
	
EndProcedure
	
#EndRegion 

#Region DataTypes

// Checking whether the passed type is a reference data type.
// "Undefined" returned False.
//
// Returns:
//  Boolean.
//
Function IsReference(Type) Export
	
	Return Type <> Type("Undefined") 
		AND (Catalogs.AllRefsType().ContainsType(Type)
		Or Documents.AllRefsType().ContainsType(Type)
		Or Enums.AllRefsType().ContainsType(Type)
		Or ChartsOfCharacteristicTypes.AllRefsType().ContainsType(Type)
		Or ChartsOfAccounts.AllRefsType().ContainsType(Type)
		Or ChartsOfCalculationTypes.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.AllRefsType().ContainsType(Type)
		Or BusinessProcesses.RoutePointsAllRefsType().ContainsType(Type)
		Or Tasks.AllRefsType().ContainsType(Type)
		Or ExchangePlans.AllRefsType().ContainsType(Type));
	
EndFunction

// Constructor of the TypeDescription object that contains the String type.
//
// Parameters:
//  StringLength - Number.
//
// ReturnValue:
//  TypeDescription.
//
Function StringTypeDescription(StringLength) Export

	Array = New Array;
	Array.Add(Type("String"));

	StringQualifier = New StringQualifiers(StringLength, AllowedLength.Variable);

	Return New TypeDescription(Array, , StringQualifier);

EndFunction

// Constructor of the TypeDescription object that contains the Number type.
//
// Parameters:
//  DigitCapacity - Number - total number of number digits (the number of digits in the integer
//                  part plus the number of digits in the fractional part).
//  FractionDigits - Number - number of fractional part digits.
//  NumberSign    - AllowedSign - allowed number sign.
//
// ReturnValue:
//  TypeDescription.
//
Function NumberTypeDescription(DigitCapacity, FractionDigits = 0, NumberSign = Undefined) Export

	If NumberSign = Undefined Then
		NumberQualifier = New NumberQualifiers(DigitCapacity, FractionDigits);
	Else
		NumberQualifier = New NumberQualifiers(DigitCapacity, FractionDigits, NumberSign);
	EndIf;

	Return New TypeDescription("Number", NumberQualifier);

EndFunction

// Constructor of the TypeDescription object that contains the Date type.
//
// Parameters:
//  DateFractions - DateFractions - set of Date type value usage options.
//
// ReturnValue:
//  TypeDescription.
//
Function DateTypeDescription(DateFractions) Export

	Array = New Array;
	Array.Add(Type("Date"));

	DateQualifier = New DateQualifiers(DateFractions);

	Return New TypeDescription(Array, , , DateQualifier);

EndFunction
	
#EndRegion

#Region Interface

// Compares data of a complex structure taking nesting into account.
//
// Parameters:
//  Data1 - Structure ,   FixedStructure -
//        - Map,          FixedMap -
//        - Array,        FixedArray - 
//        - ValueStorage, ValueTable -
//        - Simple types - that can be compared for equality, for example, String, Number, Boolean.
//
//  Data2 - Arbitrary - same types that the Data1 parameter has.
//
// Returns:
//  Boolean.
//
Function IsEqualData(Data1, Data2) Export
	
	If TypeOf(Data1) <> TypeOf(Data2) Then
		Return False;
	EndIf;
	
	If TypeOf(Data1) = Type("Structure")
	 Or TypeOf(Data1) = Type("FixedStructure") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		For Each KeyAndValue In Data1 Do
			OldValue = Undefined;
			
			If NOT Data2.Property(KeyAndValue.Key, OldValue)
			 Or NOT IsEqualData(KeyAndValue.Value, OldValue) Then
			
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Map")
	      Or TypeOf(Data1) = Type("FixedMap") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		NewMapKeys = New Map;
		
		For Each KeyAndValue In Data1 Do
			NewMapKeys.Insert(KeyAndValue.Key, True);
			OldValue = Data2.Get(KeyAndValue.Key);
			
			If NOT IsEqualData(KeyAndValue.Value, OldValue) Then
				Return False;
			EndIf;
		EndDo;
		
		For Each KeyAndValue In Data2 Do
			If NewMapKeys[KeyAndValue.Key] = Undefined Then
				Return False;
			EndIf;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("Array")
	      Or TypeOf(Data1) = Type("FixedArray") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		Index = Data1.Count()-1;
		While Index >= 0 Do
			If NOT IsEqualData(Data1.Get(Index), Data2.Get(Index)) Then
				Return False;
			EndIf;
			Index = Index - 1;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueTable") Then
		
		If Data1.Count() <> Data2.Count() Then
			Return False;
		EndIf;
		
		If Data1.Columns.Count() <> Data2.Columns.Count() Then
			Return False;
		EndIf;
		
		For Each Column In Data1.Columns Do
			If Data2.Columns.Find(Column.Name) = Undefined Then
				Return False;
			EndIf;
			
			Index = Data1.Count()-1;
			While Index >= 0 Do
				If NOT IsEqualData(Data1[Index][Column.Name], Data2[Index][Column.Name]) Then
					Return False;
				EndIf;
				Index = Index - 1;
			EndDo;
		EndDo;
		
		Return True;
		
	ElsIf TypeOf(Data1) = Type("ValueStorage") Then
	
		If NOT IsEqualData(Data1.Get(), Data2.Get()) Then
			Return False;
		EndIf;
		
		Return True;
	EndIf;
	
	Return Data1 = Data2;
	
EndFunction

// Retrieves the name of the enumeration value as a metadata object.
//
// Parameters:
//  Value - value of the enumeration whose name is retrieved.
//
// Returns:
//  String - enumeration value name as a metadata object.
//
Function EnumValueName(Value) Export
	
	MetadataObject = Value.Metadata();
	
	ValueIndex = Enums[MetadataObject.Name].IndexOf(Value);
	
	Return MetadataObject.EnumValues[ValueIndex].Name;
	
EndFunction 

// Returns the name of the predefined item by the specified reference.
// To be used instead of the obsolete GetPredefinedItemName method in configurations made for
// the platform 8.2.
//
// Parameters:
//  Ref - AnyRef - reference to the predefined item.
//
// Returns:
//  String - predefined item name.
//
Function PredefinedName(Val Ref) Export
	
	Return ObjectAttributeValue(Ref, "PredefinedDataName");
	
EndFunction

// Checks whether the attribute with the passed name exists among the object attributes.
//
// Parameters:
//  AttributeName  - String - Attribute name;
//  ObjectMetadata - MetadataObject - object, where the attribute is searched.
//
// Returns:
//  Boolean.
//
Function HasObjectAttribute(AttributeName, ObjectMetadata) Export

	Return NOT (ObjectMetadata.Attributes.Find(AttributeName) = Undefined);

EndFunction

// Returns a settings key string within a valid length.
// Checks the length of the passed string. If it exceeds 128, converts its end according to the
// MD5 algorithm into a short alternative. As the result, the string becomes 128 character
// length.
// If the original string is less then 128 characters, it is returned as is.
//
// Parameters:
//  String - String - string of an arbitrary length.
//
Function SettingsKey(Val String)
	Result = String;
	If StrLen(String) > 128 Then // A key longer than 128 characters raises an exception when accessing the settings storage
		Result = Left(String, 96);
		DataHashing = New DataHashing(HashFunction.MD5);
		DataHashing.Append(Mid(String, 97));
		Result = Result + StrReplace(DataHashing.HashSum, " ", "");
	EndIf;
	Return Result;
EndFunction

#EndRegion 

#Region Reference

// Checks whether the metadata object belongs to the Document type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsDocument(MetadataObject) Export
	
	Return Metadata.Documents.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Catalog type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsCatalog(MetadataObject) Export
	
	Return Metadata.Catalogs.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Enumeration type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsEnum(MetadataObject) Export
	
	Return Metadata.Enums.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Exchange plan type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsExchangePlan(MetadataObject) Export
	
	Return Metadata.ExchangePlans.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of characteristic types type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsChartOfCharacteristicTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCharacteristicTypes.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Business process type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsBusinessProcess(MetadataObject) Export
	
	Return Metadata.BusinessProcesses.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Task type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsTask(MetadataObject) Export
	
	Return Metadata.Tasks.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of accounts type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsChartOfAccounts(MetadataObject) Export
	
	Return Metadata.ChartsOfAccounts.Contains(MetadataObject);
	
EndFunction

// Checks whether the metadata object belongs to the Chart of calculation types type.
// 
// Parameters:
//  MetadataObject – metadata object to be checked.
// 
// Returns:
//  Boolean.
//
Function IsChartOfCalculationTypes(MetadataObject) Export
	
	Return Metadata.ChartsOfCalculationTypes.Contains(MetadataObject);
	
EndFunction

#EndRegion

#Region TypeName

////////////////////////////////////////////////////////////////////////////////
// Type names.

// Returns a value for identification of the Information registers type. 
//
// Returns:
//  String.
//
Function TypeNameInformationRegisters() Export
	
	Return "InformationRegisters";
	
EndFunction

// Returns a value for identification of the Accumulation registers type. 
//
// Returns:
//  String.
//
Function TypeNameAccumulationRegisters() Export
	
	Return "AccumulationRegisters";
	
EndFunction

// Returns a value for identification of the Accounting registers type. 
//
// Returns:
//  String.
//
Function TypeNameAccountingRegisters() Export
	
	Return "AccountingRegisters";
	
EndFunction

// Returns a value for identification of the Calculation registers type. 
//
// Returns:
//  String.
//
Function TypeNameCalculationRegisters() Export
	
	Return "CalculationRegisters";
	
EndFunction

// Returns a value for identification of the Documents type. 
//
// Returns:
// String.
//
Function TypeNameDocuments() Export
	
	Return "Documents";
	
EndFunction

// Returns a value for identification of the Catalogs type. 
//
// Returns:
//  String.
//
Function TypeNameCatalogs() Export
	
	Return "Catalogs";
	
EndFunction

// Returns a value for identification of the Enumerations type. 
//
// Returns:
// String.
//
Function TypeNameEnums() Export
	
	Return "Enums";
	
EndFunction

// Returns a value for identification of the Reports type. 
//
// Returns:
//  String.
//
Function TypeNameReports() Export
	
	Return "Reports";
	
EndFunction

// Returns a value for identification of the Data processors type. 
//
// Returns:
//  String.
//
Function TypeNameDataProcessors() Export
	
	Return "DataProcessors";
	
EndFunction

// Returns a value for identification of the Exchange plans type. 
//
// Returns:
//  String.
//
Function TypeNameExchangePlans() Export
	
	Return "ExchangePlans";
	
EndFunction

// Returns a value for identification of the Charts of characteristic types type. 
//
// Returns:
//  String.
//
Function TypeNameChartsOfCharacteristicTypes() Export
	
	Return "ChartsOfCharacteristicTypes";
	
EndFunction

// Returns a value for identification of the Business processes type. 
//
// Returns:
//  String.
//
Function TypeNameBusinessProcesses() Export
	
	Return "BusinessProcesses";
	
EndFunction

// Returns a value for identification of the Tasks type. 
//
// Returns:
//  String.
//
Function TypeNameTasks() Export
	
	Return "Tasks";
	
EndFunction

// Returns a value for identification of the Charts of accounts type. 
//
// Returns:
//  String.
//
Function TypeNameChartsOfAccounts() Export
	
	Return "ChartsOfAccounts";
	
EndFunction

// Returns a value for identification of the Charts of calculation types type. 
//
// Returns:
//  String.
//
Function TypeNameChartsOfCalculationTypes() Export
	
	Return "ChartsOfCalculationTypes";
	
EndFunction

// Returns a value for identification of the Constants type. 
//
// Returns:
// String.
//
Function TypeNameConstants() Export
	
	Return "Constants";
	
EndFunction

// Returns a value for identification of the Document journals type. 
//
// Returns:
//  String.
//
Function TypeNameDocumentJournals() Export
	
	Return "DocumentJournals";
	
EndFunction

// Returns a value for identification of the Sequences type. 
//
// Returns:
//  String.
//
Function SequenceTypeName() Export
	
	Return "Sequences";
	
EndFunction

// Returns a value for identification of the Sequences type. 
//
// Returns:
//  String.
//
Function ScheduledJobTypeName() Export
	
	Return "ScheduledJobs";
	
EndFunction
	
#EndRegion 

#Region XML

// Returns the value in the XML string format.
// The following value types can be serialized into an XML string with this function: 
// Undefined, Null, Boolean, Number, String, Date, Type, UUID, BinaryData,
// ValueStorage, TypeDescription, data object references and the data 
// objects themselves, sets of register records, and the constant value manager.
//
// Parameters:
//  Value – Arbitrary - value to be serialized into an XML string.
//
// Returns:
//  String - resulting string.
//
Function ValueToXMLString(Value) Export
	
	XMLWriter = New XMLWriter;
	XMLWriter.SetString();
	XDTOSerializer.WriteXML(XMLWriter, Value, XMLTypeAssignment.Explicit);
	
	Return XMLWriter.Close();
EndFunction

// Returns a value restored from the XML string. 
// The following value types can be restored from the XML string with this function: 
// Undefined, Null, Boolean, Number, String, Date, Type, UUID, BinaryData,
// ValueStorage, TypeDescription, data object references and the data 
// objects themselves, sets of register records, and the constant value manager.
//
// Parameters:
//  XMLString – serialized string.
//
// Returns:
//  String - resulting string.
//
Function ValueFromXMLString(XMLString) Export
	
	XMLReader = New XMLReader;
	XMLReader.SetString(XMLString);
	
	Return XDTOSerializer.ReadXML(XMLReader);
EndFunction
	
#EndRegion 

#Region DynamicList

// Sets the query text, primary table, or dynamic reading from a dynamic list.
// To avoid low performance, set these properties within the same call of this procedure.
//
// Parameters:
//  List - FormTable - a form item of the dynamic list whose properties are to be set.
//  ParametersStructure - Structure - see DynamicListPropertiesStructure(). 
//
Procedure SetDynamicListProperties(List, ParametersStructure) Export
	
	Form = List.Parent;
	ManagedFormType = Type("ManagedForm");
	
	While TypeOf(Form) <> ManagedFormType Do
		Form = Form.Parent;
	EndDo;
	
	DynamicList = Form[List.DataPath];
	QueryText = ParametersStructure.QueryText;
	
	If Not IsBlankString(QueryText) Then
		DynamicList.QueryText = QueryText;
		DynamicList.CustomQuery = 	True;
	EndIf;
	
	MainTable = ParametersStructure.MainTable;
	
	If Not IsBlankString(MainTable) Then
		DynamicList.MainTable = MainTable;
	EndIf;
	
	DynamicDataRead = ParametersStructure.DynamicDataRead;
	
	If TypeOf(DynamicDataRead) = Type("Boolean") Then
		DynamicList.DynamicDataRead = DynamicDataRead;
	EndIf;
	
EndProcedure

// Creates a dynamic list property structure to call SetDynamicListProperties().
//
// Returns:
//  Structure - any field can be Undefined if it is not set:
//     * QueryText - String - the new query text.
//     * MainTable - String - the name of the main table.
//     * DynamicDataRead - Boolean - a flag indicating whether dynamic reading is used.
//
Function DynamicListPropertiesStructure() Export
	
	Return New Structure("QueryText, MainTable, DynamicDataRead");
	
EndFunction
     
#EndRegion 

