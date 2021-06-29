
Function GetAccountingRecordType(RecordType) Export

	Return ?(RecordType = Enums.velpo_BalanceTypes.Debit, AccountingRecordType.Debit, AccountingRecordType.Credit);

КонецФункции // GetAccountingRecordType()

Function GetAxisTypeArray(Concept) Export

	Query = New Query;
	Query.SetParameter("Concept", Concept);
	Query.Text = 
	"SELECT
	|	ReportingExtDimension.ExtDimensionType AS AxisType
	|FROM
	|	ChartOfAccounts.Reporting.ExtDimensionTypes AS ReportingExtDimension
	|WHERE
	|	ReportingExtDimension.Ref = &Concept
	|";
	Return Query.Execute().Unload().UnloadColumn("AxisType");	

EndFunction // GetAxisTypeArray()

Function GetAxisValue(Ref) Export

	AxisStructure = velpo_CommonFunctions.ObjectAttributeValues(Ref, "AxisValueType, Description, ValueBoolean, ValueDate, ValueRef, ValueNumber");
	AttributeName = Catalogs.AxisMembers.GetAttributeTypeName(AxisStructure.AxisValueType);
	Return AxisStructure[AttributeName];	
	
EndFunction // GetAxisValue()

Function GetAxisValueType(Ref) Export

	Return velpo_CommonFunctions.ObjectAttributeValue(Ref, "AxisValueType");
		
EndFunction // GetAxisValue()

Function CheckElementIsBlock(Element) Export

	Return (velpo_CommonFunctions.ObjectAttributeValue(Element, "ConceptType") = Enums.velpo_BaseDataTypes.Block);

EndFunction // CheckElementIsBlock()

Function GetAxisTypeByName(Name) Export

	Return ChartsOfCharacteristicTypes.velpo_HypercubeAxes.FindByAttribute("Name", Name);
	
EndFunction // GetAxisTypeByName()

Function GetMemberValueByName(Name) Export

	Return Catalogs.velpo_MemberValues.FindByAttribute("Name", Name);
	
EndFunction // GetMemberValueByName()

Function GetConceptByName(Name) Export

	Query = New Query;
	Query.SetParameter("Name", Name);
	Query.Text =
	"SELECT TOP 1
	|	Reporting.Ref AS Ref
	|FROM
	|	ChartOfAccounts.Reporting AS Reporting
	|WHERE
	|	Reporting.Name = &Name
	|
	|ORDER BY
	|	Reporting.IsGroup DESC
	|";
	Selection = Query.Execute().Select();
	If Selection.Next() Then
		Return Selection.Ref;
	Else
		Return ChartsOfAccounts.velpo_Reporting.EmptyRef();
	EndIf;
	
EndFunction // GetConceptByName()

Function GetConceptValueType(Ref) Export

	ConceptValueTypeAttrib = velpo_CommonFunctions.ObjectAttributeValue(Ref, "DataType");
	Return velpo_CommonFunctions.ObjectAttributeValue(ConceptValueTypeAttrib, "ValueType");
	
EndFunction // GetConceptValueType()

Function GetConceptVariantType(Ref) Export

	Return velpo_CommonFunctions.ObjectAttributeValue(Ref, "ConceptVariant");
	
EndFunction // GetConceptVariantType()

Function GetConceptType(Ref) Export

	Return velpo_CommonFunctions.ObjectAttributeValue(Ref, "ConceptType");
	
EndFunction // GetConceptValueType()

Function GetAxisValueName(Ref) Export

	Return velpo_CommonFunctions.ObjectAttributeValue(Ref, "Name");

EndFunction // GetAxisValueName()

Function GetConceptValueName(Ref) Export

	Return velpo_CommonFunctions.ObjectAttributeValue(Ref, "Name");	

EndFunction // GetConceptValueName()

Function CheckComparisonQueryType(Ref, Name) Export
	
	Return (Ref = Enums.velpo_ComparisonQueryTypes[Name]);
	
EndFunction

Function CheckFilterQueryType(Ref, Name) Export
	
	Return (Ref = Enums.velpo_FilterQueryTypes[Name]);
	
EndFunction

Function GetXDTOSerializer() Export

	 Return New XDTOSerializer(XDTOFactory);
	
EndFunction // GetXDTOSeriliser()

Function CheckConceptIsMeasure(Element) Export
	Return (velpo_CommonFunctions.ObjectAttributeValue(Element, "ConceptVariant") = Enums.velpo_ConceptTypes.Measure);
EndFunction

Function CheckInHierarchy(Ref, Parent) Export
	
    Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.SetParameter("Parent", Parent);
	Query.Text =
	"SELECT TOP 1 
	|	&Ref IN HIERARCHY(&Parent) As Check
	|";
	Selection = Query.Execute().Select();
	Selection.Next();
	
	Return Selection.Check;
		
EndFunction

// TODO
Функция ПолучитьТаблицуРасчетныхПоказателей(Показатель, ВидДвижения) Экспорт
	
	//Запрос = Новый Запрос;
	//Запрос.УстановитьПараметр("Показатель", Показатель);
	//Запрос.Текст = 
	//"ВЫБРАТЬ
	//|	Ссылка КАК Показатель,
	//|	Ссылка.Вид КАК ВидСчета,
	//|	Ссылка.Дебетовый КАК Дебетовый,
	//|	Ссылка.Кредитовый КАК Кредитовый
	//|ИЗ
	//|	ПланСчетов.Отчетный.Расчет
	//|ГДЕ
	//|	Показатель = &Показатель
	//|	И Ссылка.ПометкаУдаления = ЛОЖЬ
	//|	И Ссылка." + ?(ВидДвижения = "Дебет", "Дебетовый = ИСТИНА", "Кредитовый = ИСТИНА") + "
	//|	
	//|ОБЪЕДИНИТЬ ВСЕ
	//|
	//|ВЫБРАТЬ
	//|	Ссылка КАК Показатель,
	//|	Ссылка.Вид КАК ВидСчета,
	//|	Ссылка.Дебетовый КАК Дебетовый,
	//|	Ссылка.Кредитовый КАК Кредитовый
	//|ИЗ
	//|	ПланСчетов.Отчетный.Расчет
	//|ГДЕ
	//|	Показатель = &Показатель
	//|	И Ссылка.ПометкаУдаления = ЛОЖЬ
	//|	И Ссылка.Дебетовый = ЛОЖЬ
	//|	И Ссылка.Кредитовый = ЛОЖЬ
	//|";
	//ТаблицаПоказателей = Запрос.Выполнить().Выгрузить();
	//	
	//Возврат ТаблицаПоказателей;

КонецФункции

 