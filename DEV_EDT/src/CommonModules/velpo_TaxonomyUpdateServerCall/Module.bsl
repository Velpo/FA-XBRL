///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
// Copyright (c) 2018, Velpo (Paul Tarasov)
//
// Subsystem:  Taxonomy Update
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region InternalProceduresAndFunctions

// Function returns whole entry points value list 
//
// Parameters:
//  TaxonomyFullFileName  - String - path to Taxonomy packege or Schema
//
// Returns:
//   ValueList   -  list of taxonomy file pathes
//
Function GetTaxonomyPackage(Val XMLAddress) Export

	XMLFileName = GetTempFileName("xml");
	BinaryData = GetFromTempStorage(XMLAddress);
	BinaryData.Write(XMLFileName);

	EntryPointsList = New ValueList;
	
	ReaderStream = New XMLReader();
	ReaderStream.OpenFile(XMLFileName);
	
	TaxonomyStructure = New Structure(velpo_TaxonomyUpdateClientServerCached.GetTaxonomyPackageAttribs());
	
	TaxonomyPackage = XDTOFactory.ReadXML(ReaderStream, velpo_TaxonomyUpdateClientServerCached.GetTaxonomyPackageType());
	
	TaxonomyStructure.Insert("Identifier", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "identifier"));
	TaxonomyStructure.Insert("Name", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "name"));
	TaxonomyStructure.Insert("Description", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "description"));
	TaxonomyStructure.Insert("Version", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "version"));
	TaxonomyStructure.Insert("Publisher", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "publisher"));
	TaxonomyStructure.Insert("PublisherURL", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "publisherURL"));
	TaxonomyStructure.Insert("PublisherCountry", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "publisherCountry"));
	TaxonomyStructure.Insert("PublicationDate", velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(TaxonomyPackage, "publicationDate"));
	
	If TaxonomyPackage.license <> Undefined Then
		TaxonomyStructure.Insert("LicenseHref", TaxonomyPackage.license.href);
		TaxonomyStructure.Insert("LicenseName", TaxonomyPackage.license.Name);
	EndIf;
		
	EntryPoints = TaxonomyPackage.EntryPoints;
	
	For Each EntryPoint  In EntryPoints.entryPoint Do
		
		 HRefArray = New Array;
		 For Each entryPointDocument In EntryPoint.entryPointDocument Do
		 	HRefArray.Add(entryPointDocument.href);
		EndDo; 
		
		EntryPointStructure  = New Structure(velpo_TaxonomyUpdateClientServerCached.GetEntryPointAttribs());  
		EntryPointStructure.Name = velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(EntryPoint, "Name");
		EntryPointStructure.Description = velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(EntryPoint, "Description");
		EntryPointStructure.Hrefs = HRefArray;
		EntryPointStructure.Version = velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(EntryPoint, "Version");
		EntryPointStructure.Language = velpo_CommonFunctionsClientServer.GetXDTOObjectValueContent(EntryPoint, "languages");
		
		DescrPattern = ?(IsBlankString(EntryPointStructure.Description), 
											"%1",
											"%2 - (%1)");
		
		EntryPointsList.Add(
			EntryPointStructure, 
			velpo_StringFunctionsClientServer.SubstituteParametersInString(
				DescrPattern,
				EntryPointStructure.Name,
				EntryPointStructure.Description));
			
	EndDo; 
	
	TaxonomyStructure.Insert("EntryPoints", EntryPointsList);
	Return TaxonomyStructure;
	
EndFunction

#EndRegion