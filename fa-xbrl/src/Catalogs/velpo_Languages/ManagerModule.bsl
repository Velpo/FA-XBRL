Function GetStructure() Export

	Return New Structure("Code"); 	

EndFunction // GetItemStructure()

Function GetItem(Attribs, Create = True) Export
	
	LanguageRef = Catalogs.velpo_Languages.FindByCode(Attribs.Code);
		
	If  LanguageRef = Catalogs.velpo_Languages.EmptyRef() Then
		LanguageObject = Catalogs.velpo_Languages.CreateItem();
		FillPropertyValues(LanguageObject, Attribs);
		LanguageObject.Write();
		LanguageRef = LanguageObject.Ref;
	EndIf;
	
	Return LanguageRef;

EndFunction // Create()
