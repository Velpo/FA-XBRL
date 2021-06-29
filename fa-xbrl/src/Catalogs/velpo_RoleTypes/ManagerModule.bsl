///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetStructure() Export

	Return New Structure("Name, Description, Owner"); 	

EndFunction // GetStructure()

Function GetItem(Atrribs, Create = True) Export
	
	RoleTypeRef = Catalogs.velpo_RoleTypes.FindByAttribute("Name", Atrribs.Name,, Atrribs.Owner);
	
	If RoleTypeRef = Catalogs.velpo_RoleTypes.EmptyRef() And Create Then 
		RoleTypeObject = Catalogs.velpo_RoleTypes.CreateItem();
		FillPropertyValues(RoleTypeObject, Atrribs);
		RoleTypeObject.LongDescription = Atrribs.Description;
		RoleTypeObject.Write();
		RoleTypeRef = RoleTypeObject.Ref;
	EndIf;
	
	Return RoleTypeRef;

EndFunction // Create()
