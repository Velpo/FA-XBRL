
&AtServer
Procedure AutofilAtServer(ItemName)
	
	// import
	Common = velpo_CommonFunctions;
	
	ItemValueType = Common.ObjectAttributeValue(Object[ItemName], "ValueType");
	FieldValueType = velpo_CommonFunctions.ObjectAttributeValue(Object.Owner, "ValueType");
	TabularSection = Object[ItemName + "Links"];
	
	TypesArray = ItemValueType.Types();
	For Each Type In TypesArray  Do
		If Enums.AllRefsType().ContainsType(Type) Then
			Value = Undefined;
			Value = ItemValueType.AdjustValue(Value);
			MetadataValue = Value.Metadata();
			For Each EnumValue  In MetadataValue.EnumValues Do
			 	LinksLine = TabularSection.Add();
				Value = Enums[MetadataValue.Name][EnumValue.Name];
				LinksLine.FieldValue  = FieldValueType.AdjustValue(Value);
				LinksLine.Value  = Value;
			EndDo; 
		EndIf;
	EndDo; 
	
	Object.UseSourceValue = False;
				
EndProcedure


&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	// import
	Common = velpo_CommonFunctions;
	ItemLinkTypes = Enums.velpo_ItemLinkTypes;
	
	If Object.Ref.IsEmpty() Then
		
		FillPropertyValues(Object, Parameters, "Owner,Account,TableType");
		Object.Result = Common.ObjectAttributeValue(Object.Owner, "Parent");
	
		If TypeOf(Parameters.Property) = Type("ChartOfCharacteristicTypesRef.velpo_DimensionIDTypes") Then
			Object.Dimension = Parameters.Property;
			Object.LinkType = ItemLinkTypes.Dimension;
		Else
			Object.Attribute = Parameters.Property;
			Object.LinkType = ItemLinkTypes.Attribute;
		EndIf;
		
	EndIf;	
	
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	NotifyChanged(Object.Ref);
	
EndProcedure

&AtClient
Procedure ListOnEditEnd(Item, NewRow, CancelEdit)

	Object.UseSourceValue = False;
	
EndProcedure

&AtClient
Procedure AttributeLinksAutofill(Command)
	
	AutofilAtServer("Attribute");
	
EndProcedure

&AtClient
Procedure DimensionLinksAutofill(Command)
	
	AutofilAtServer("Dimension");
	
EndProcedure
