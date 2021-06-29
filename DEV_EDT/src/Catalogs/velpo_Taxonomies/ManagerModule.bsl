///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function GetStructure() Export

	Return New Structure(velpo_TaxonomyUpdateClientServerCached.GetTaxonomyPackageAttribs()); 	

EndFunction // GetItemStructure()

Function GetItem(Attribs, Create = True) Export
	
	TaxonomyRef = Catalogs.velpo_Taxonomies.FindByAttribute("Identifier", Attribs.Identifier);
		
	If  Create And TaxonomyRef = Catalogs.velpo_Taxonomies.EmptyRef() Then
		TaxonomyObject = Catalogs.velpo_Taxonomies.CreateItem();
		FillPropertyValues(TaxonomyObject, Attribs);
		If ValueIsFilled(TaxonomyObject.Description) Then
			TaxonomyObject.LongDescription = Attribs.Description; 
		Else
			TaxonomyObject.LongDescription = ?(ValueIsFilled(TaxonomyObject.Name), TaxonomyObject.Name, TaxonomyObject.Identifier);
			TaxonomyObject.Description = TaxonomyObject.LongDescription;
		EndIf;
		TaxonomyObject.Write();
		TaxonomyRef = TaxonomyObject.Ref;
	EndIf;
	
	Return TaxonomyRef;

EndFunction // Create()
