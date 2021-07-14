///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Function Create(BeginOfPeriod = Undefined, EndOfPeriod, BusinessUnit, Component = Undefined, SourceDocument = Undefined) Export

	DocObject = Documents.velpo_Fact.CreateDocument();
	DocObject.BeginOfPeriod = BegOfDay(BeginOfPeriod);
	DocObject.Date = EndOfDay(EndOfPeriod);
	DocObject.BusinessUnit = BusinessUnit;
	DocObject.Component = Component;
	DocObject.SourceDocument = SourceDocument;
	DocObject.PointOfChange = CurrentUniversalDateInMilliseconds();
	DocObject.Write(DocumentWriteMode.Posting);
	
	Return DocObject;
	
EndFunction // Create()



