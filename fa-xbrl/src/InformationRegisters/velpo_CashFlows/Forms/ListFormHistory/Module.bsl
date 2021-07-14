///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// vars
	ObjectID = Undefined;
	Parameters.Filter.Property("ObjectID", ObjectID);
	Items.ObjectID.Visible = Not ValueIsFilled(ObjectID);

EndProcedure

#EndRegion
