
#Region FormEventsHandlers

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// vars
	ObjectID = Undefined;
	Parameters.Filter.Property("ObjectID", ObjectID);
	Items.ObjectID.Visible = Not ValueIsFilled(ObjectID);

EndProcedure

#EndRegion
