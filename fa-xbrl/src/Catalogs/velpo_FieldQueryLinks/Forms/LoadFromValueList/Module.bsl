
&НаКлиенте
Процедура LoadList(Команда)

	vFilterType = ПредопределенноеЗначение("Перечисление.FilterQueryTypes.Or");
	ReturnArray = New Array;
	ValueArray = velpo_StringFunctionsClientServer.SplitStringIntoSubstringArray(ThisForm.ValueList, ",");
	For Each Value In ValueArray Do
		ReturnStructure = New Structure;
		ReturnStructure.Insert("FilterType", vFilterType); 
		ReturnStructure.Insert("Field", ThisForm.Field);
		ReturnStructure.Insert("ComparisonType", ThisForm.ComparisonType);
		ReturnStructure.Insert("Value", Value);
		ReturnArray.Add(ReturnStructure);
	EndDo;
	
	Notify("LoadFromValueList", ReturnArray);
	
КонецПроцедуры
