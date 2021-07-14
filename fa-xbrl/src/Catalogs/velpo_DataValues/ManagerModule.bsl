
//Function GetAttributeTypeName(AxisValueType) Export

//	If AxisValueType = Enums._DEL_AxisValueTypes.Number Then
//		AttributeName = "ValueNumber";
//	ElsIf AxisValueType = Enums._DEL_AxisValueTypes.Date Then
//		AttributeName = "ValueDate";
//	ElsIf AxisValueType = Enums._DEL_AxisValueTypes.Boolen Then
//		AttributeName = "ValueBoolean";
//	ElsIf AxisValueType = Enums._DEL_AxisValueTypes.Ref Then
//		AttributeName = "ValueRef";
//	Else
//		AttributeName = "Description";
//	EndIf;
//	
//	Return AttributeName;
//	
//EndFunction // GetAttributeTypeName()

//Function GetAxis(AxisType, Value, Create = True) Export

//	If Value = Undefined Or Value = Null Then
//		Return Undefined;
//	EndIf;
//	
//	If TypeOf(Value) = Type("CatalogRef.DomainMembers") Then
//		Return Value;
//	Endif;
//	
//	AxisValueType = BusinessReportingCashed.GetAxisValueType(AxisType);
//	AttributeName = GetAttributeTypeName(AxisValueType);
//	If AttributeName = "Description" Then 
//		AxisRef = Catalogs.AxisMembers.FindByDescription(Value, True, , AxisType);
//	Else
//		AxisRef = Catalogs.AxisMembers.FindByAttribute(AttributeName, Value,, AxisType);
//	EndIf;
//	// if found
//	If  ValueIsFilled(AxisRef) Then
//		Return AxisRef;
//	ElsIf НЕ Create Then 
//		Return Undefined;
//	EndIf;
//	
//	// create new
//	AxisObj = Catalogs.AxisMembers.CreateItem();
//	AxisObj.Owner = AxisType; 
//	AxisObj._DEL_DataType = AxisValueType;
//	AxisObj.Description = String(Value);
//	AxisObj[AttributeName] = Value;
//	AxisObj.Write();
//	
//	Return AxisObj.Ref;

//EndFunction // GetAxis()

//Function GetAxisValue(AxisRef) Export

//	Return BusinessReportingCashed.GetAxisValue(AxisRef);

//EndFunction // GetAxisValue()

