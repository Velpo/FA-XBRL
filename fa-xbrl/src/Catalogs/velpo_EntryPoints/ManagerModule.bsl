///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetStructure() Export

	Return New Structure(velpo_TaxonomyUpdateClientServerCached.GetEntryPointAttribs()); 	

EndFunction // GetItemStructure()

Function GetItem(Attribs, Create = True) Export
	
	EntryPointRef = Catalogs.velpo_EntryPoints.FindByDescription(Attribs.Description);
		
	If  Create And EntryPointRef = Catalogs.velpo_EntryPoints.EmptyRef() Then
		TableNames = "RoleTypes,RoleTables";
		EntryPointObject = Catalogs.velpo_EntryPoints.CreateItem();
		FillPropertyValues(EntryPointObject, Attribs,, TableNames);
		EntryPointObject.LongDescription = Attribs.Description; 
		TableNamesArray = StrSplit(TableNames, ",");
		For Each TableName In TableNamesArray Do
			If Attribs[TableName] <> Undefined Then
				ColumnName = Left(TableName, StrLen(TableName) - 1);
				For Each RoleRef In Attribs[TableName] Do
					RoleRow = EntryPointObject[TableName].Add();
					RoleRow[ColumnName] = RoleRef;
				EndDo; 
			EndIf;		
		EndDo; 
		EntryPointObject.Write();
		EntryPointRef = EntryPointObject.Ref;
	EndIf;
	
	Return EntryPointRef;

EndFunction // Create()
