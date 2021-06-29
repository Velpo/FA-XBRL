
Function GetQueryTextConcepts()

	Text =
	"SELECT
	|	// 0
	|	OperationalConceptValues.Recorder AS Fact,
	|	OperationalConceptValues.LineNumber AS LineNumber,
	|	OperationalConceptValues.RecordID AS RecordID,
	|	OperationalConceptValues.Concept AS Concept,
	|	OperationalConceptValues.Concept.Type AS Balance,
	|	OperationalConceptValues.Concept.DataType AS DataType,
	|	OperationalConceptValues.Concept.ConceptVariant AS ConceptVariant,
	|	OperationalConceptValues.Concept.ConceptType AS ConceptType,
	|	OperationalConceptValues.Concept.Name AS Name,
	|	OperationalConceptValues.Concept.IsGroup AS IsGroup,
	|	OperationalConceptValues.RecordType AS RecordType,
	|	OperationalConceptValues.Value AS Value,
	|	OperationalConceptValues.Text AS Text
	|FROM
	|	InformationRegister.OperationalConceptValues AS OperationalConceptValues
	|WHERE
	|	OperationalConceptValues.Recorder = &Fact
	|;
	|
	|SELECT
	|	// 1
	|	OperationalAxes.Recorder AS Fact,
	|	OperationalAxes.LineNumber AS LineNumber,
	|	OperationalAxes.RecordID AS RecordID,
	|	OperationalAxes.AxisType AS AxisType,
	|	OperationalAxes.AxisType.AxisValueType AS AxisValueType,
	|	OperationalAxes.AxisType.TypedDimensionName AS TypedDimensionName,
	|	OperationalAxes.Axis AS Axis
	|FROM
	|	InformationRegister.OperationalAxes AS OperationalAxes
	|WHERE
	|	OperationalAxes.Recorder = &Fact
	|";
	
	Return Text;
	
EndFunction // GetQueryTextConcepts()

Function GetQueryTextFacts()

	Text =
	"SELECT
	|	Fact.Ref AS Ref,
	|	Fact.Date AS Date,
	|	Fact.BusinessUnit AS BusinessUnit,
	|	Fact.Error AS Error,
	|	Fact.DeletionMark AS DeletionMark,
	|	Fact.PointOfChange AS PointOfChange,
	|	Fact.IsLoaded AS IsLoaded
	|FROM
	|	Document.Fact AS Fact
	|WHERE
	|	Fact.PointOfChange > 0
	|ORDER BY
	|	Fact.PointOfChange
	|";

	Return Text;	

EndFunction // GetFactTextQuery()

Функция ПолучитьПоказателиДляЗаполнения(Объект, Данные, Оси, ВидДвижения = Неопределено)
	
	Запрос = Новый Запрос;
	Запрос.УстановитьПараметр("Concept", Данные.Concept);
		
	ТаблицаПоказателейОсей = Новый ТаблицаЗначений;
	ТаблицаПоказателейОсей.Колонки.Добавить("Concept", Новый ОписаниеТипов("ПланСчетовСсылка.Reporting"));
	ТаблицаПоказателейОсей.Колонки.Добавить("ВидДвижения");
	ТаблицаПоказателейОсей.Колонки.Добавить("AxisTypes");
	
	CheckSubConcepts  = True;
	
	// это мера, это группа и это не не загрузка
	If Данные.ConceptVariant = Enums.velpo_ConceptTypes.Measure And Данные.IsGroup And Not Объект.IsLoaded Then
		// check if concept has the same axis array
		ConceptAxisTypes = velpo_BusinessReportingCashed.GetAxisTypeArray(Данные.Concept);
		Успех = True;
		Для каждого ВидОси Из ConceptAxisTypes Цикл
			РезультатПоиска = Оси[ВидОси];
			Если РезультатПоиска = Неопределено Тогда
				Успех = Ложь;
				Прервать;
			КонецЕсли
		EndDo;
		If Успех Then
			ДобавитьПоказательОсей(Данные.Concept, ВидДвижения, ТаблицаПоказателейОсей);
			CheckSubConcepts = False;
		EndIf;
	ElsIf Not Данные.IsGroup Then
		ДобавитьПоказательОсей(Данные.Concept, ВидДвижения, ТаблицаПоказателейОсей);
	EndIf;
	
	If CheckSubConcepts Then
		Запрос.Текст = 
		"ВЫБРАТЬ
		|	Ссылка КАК Concept
		|ИЗ
		|	ПланСчетов.Reporting
		|ГДЕ
		|	Родитель = &Concept
		|	И ПометкаУдаления = ЛОЖЬ
		|";
		ВыборкаПоказателей = Запрос.Выполнить().Выбрать();
		Пока ВыборкаПоказателей.Следующий() Цикл
			ДобавитьПоказательОсей(ВыборкаПоказателей.Concept, ВидДвижения, ТаблицаПоказателейОсей)
		КонецЦикла;
	КонецЕсли;
	
	//Если Данные.MeasureGen = Перечисления.MeasureGen.Мера Тогда
	//	УстановитьРасчетныйПоказатель(Данные.Concept, ВидДвижения, ТаблицаПоказателейОсей);					
	//КонецЕсли;
		
	МассивУдаления = Новый Массив;
	Для каждого СтрокаПоказателейОсей Из ТаблицаПоказателейОсей Цикл
		МассивОсей = СтрокаПоказателейОсей.AxisTypes;
		Успех = Истина;
		Для каждого ВидОси Из МассивОсей Цикл
			РезультатПоиска = Оси[ВидОси];
			Если РезультатПоиска = Неопределено Тогда
				Успех = Ложь;
				Прервать;
			КонецЕсли;
		КонецЦикла; 
		Если НЕ Успех Тогда
			МассивУдаления.Добавить(СтрокаПоказателейОсей);
		КонецЕсли;
	КонецЦикла; 
	
	Для каждого СтрокаПоказателейОсей Из МассивУдаления Цикл
		ТаблицаПоказателейОсей.Удалить(СтрокаПоказателейОсей);
	КонецЦикла; 
	
	Возврат ТаблицаПоказателейОсей;

КонецФункции // ПолучитьПоказателиДляЗаполнения()

Функция ВычислитьХешСтрокиПоАлгоритмуCRC32(Знач Строка)
	ХешированиеДанных = Новый ХешированиеДанных(ХешФункция.CRC32);
	ХешированиеДанных.Добавить(Строка);
	Возврат ХешированиеДанных.ХешСумма;
КонецФункции

Функция ПолучитьНормализованнуюСтрокуОсей(КэшОсей)

	// формируем хеш
	НормализованнаяСтрока = "";
	Для каждого КлючОсь Из КэшОсей Цикл
		
		НормализованнаяСтрока = НормализованнаяСтрока 
																								+ ?(ПустаяСтрока(НормализованнаяСтрока), "", "_") 
																								+  ВРег(Строка(КлючОсь.Value.УникальныйИдентификатор())); 
	КонецЦикла; 
	
	Возврат НормализованнаяСтрока;

КонецФункции // ПолучитьНормализованнуюСтрокуИзмерений()

Функция ПолучитьХешОсей(КэшОсей)
	
	НормализованнаяСтрока = ПолучитьНормализованнуюСтрокуОсей(КэшОсей); 	
	Если НормализованнаяСтрока = Неопределено Тогда
		Возврат 0;
	Иначе
		Возврат ВычислитьХешСтрокиПоАлгоритмуCRC32(НормализованнаяСтрока); 
	КонецЕсли;

КонецФункции // ПолучитьХешОсей()
	
Функция ДобавитьМеру(Объект, НаборЗаписей, Данные, Оси)
	
	If ValueIsFilled(Данные.RecordType) Then
		RecordType = Данные.RecordType;
		Значение = Данные.Value;
	Else
		If Данные.Balance = AccountType.Passive Then
			RecordType = ?(Данные.Value > 0, Enums.velpo_BalanceTypes.Credit, Enums.velpo_BalanceTypes.Debit);
		Else
			RecordType = ?(Данные.Value > 0, Enums.velpo_BalanceTypes.Debit, Enums.velpo_BalanceTypes.Credit);
		EndIf;
		Значение = ?(Данные.Value < 0, -Данные.Value, Данные.Value); 
	EndIf;
		
	ТаблицаПоказателейОсей = ПолучитьПоказателиДляЗаполнения(Объект, Данные, Оси, RecordType);
	Если ТаблицаПоказателейОсей.Количество() = 0 Тогда
		Возврат Ложь;
	КонецЕсли;
	
	Для каждого СтрокаПоказателей Из ТаблицаПоказателейОсей Цикл
		
		Запись = 	НаборЗаписей.Добавить();
		Запись.Period = Объект.Date; 
		Запись.Recorder = Объект.Ref;
		Запись.BusinessUnit = Объект.BusinessUnit;
		Запись.RecordType = СтрокаПоказателей.ВидДвижения;
		Запись.Value = Значение;
		
		Запись.Account = СтрокаПоказателей.Concept;
		МассивВидовОсей = СтрокаПоказателей.AxisTypes;
		
		Для каждого ВидОси Из МассивВидовОсей Цикл
			Запись.Субконто.Вставить(ВидОси, Оси[ВидОси]);
		КонецЦикла; 
		
	КонецЦикла; 
	
	Возврат Истина;
	
КонецФункции

Функция ДобавитьСведение(Объект, НаборЗаписей, НаборЗначений, Данные, Оси, ИндексНаборЗаписейНеДеньги, ИндексНаборЗначений, КлючЗначенияМаксимум)
	
	ТаблицаПоказателейОсей = ПолучитьПоказателиДляЗаполнения(Объект, Данные, Оси);
	Если ТаблицаПоказателейОсей.Количество() = 0 Тогда
		Возврат Ложь;
	КонецЕсли;
	Для каждого СтрокаПоказателей Из ТаблицаПоказателейОсей Цикл
		
		КэшОсей = Новый Соответствие;
		Для каждого ВидОси Из СтрокаПоказателей.AxisTypes Цикл
			КэшОсей.Вставить(ВидОси, Оси[ВидОси]);
		КонецЦикла; 
		
		ХешОсей = ПолучитьХешОсей(КэшОсей);
		КлючЗначения = 0;
		TheSameDoc = False;
		
		СтруктураПоиска = Новый Структура("BusinessUnit, AxesHash, Счет");
		СтруктураПоиска.BusinessUnit = Объект.BusinessUnit;
		СтруктураПоиска.AxesHash = ХешОсей;
		СтруктураПоиска.Счет = СтрокаПоказателей.Concept;
		
		МассивИндексов = ИндексНаборЗаписейНеДеньги.НайтиСтроки(СтруктураПоиска);
		Для каждого СтрокаИндекса Из МассивИндексов Цикл
			КлючЗначения = Макс(КлючЗначения, СтрокаИндекса.Key);
		КонецЦикла;
		Если КлючЗначения > 0 Тогда
			СтрокаЗначений = ИндексНаборЗначений.Найти(КлючЗначения, "Key");
			Если СтрокаЗначений.Value = Данные.Value И СтрокаЗначений.Text = Данные.Text Тогда
				Продолжить;
			КонецЕсли;
			TheSameDoc = True;
		Иначе
			Запрос = Новый Запрос;
			Запрос.УстановитьПараметр("BusinessUnit", Объект.BusinessUnit); 
			Запрос.УстановитьПараметр("AxesHash", ХешОсей); 
			Запрос.УстановитьПараметр("Счет", СтрокаПоказателей.Concept); 
			ТекстЗапроса =
			"ВЫБРАТЬ ПЕРВЫЕ 1
			|	МАКСИМУМ(СведенияПоказателей.Key) AS Key
			|ИЗ
			|	РегистрБухгалтерии.InfoEntries КАК СведенияПоказателей
			|ГДЕ
			|	СведенияПоказателей.Счет = &Счет
			|	И СведенияПоказателей.AxesHash = &AxesHash
			|	И СведенияПоказателей.BusinessUnit = &BusinessUnit
			|";
			Запрос.Текст = ТекстЗапроса;
			РезультатЗапроса = Запрос.Выполнить();
			ВыборкаДвижений = РезультатЗапроса.Выбрать();
			ВыборкаДвижений.Следующий();
			Если ВыборкаДвижений.Key = NULL Тогда
				КлючЗначения = КлючЗначенияМаксимум + 1;
				КлючЗначенияМаксимум = Макс(КлючЗначенияМаксимум, КлючЗначения);
			Иначе
				КлючЗначения = ВыборкаДвижений.Key;
				Запрос.УстановитьПараметр("Period", Объект.Date);
				Запрос.УстановитьПараметр("Key", КлючЗначения);
				Запрос.Текст = 
				"ВЫБРАТЬ
				|	Recorder,
				|	Value,
				|	Text	
				|ИЗ
				|	РегистрСведений.GenValues.СрезПоследних(&Period, Key = &Key)
				|";
				ВыборкаЗначение = Запрос.Выполнить().Выбрать();
				Если ВыборкаЗначение.Следующий() Тогда
					If ВыборкаЗначение.Recorder = Объект.Ref Then
						TheSameDoc = True;
					EndIf;
					Если ВыборкаЗначение.Value = Данные.Value И ВыборкаЗначение.Text = Данные.Text Тогда
						Продолжить;
					КонецЕсли;
				КонецЕсли;
			КонецЕсли;
		КонецЕсли;

		If TheSameDoc Then
			КлючЗначения = Макс(КлючЗначенияМаксимум, КлючЗначения) + 1;	
			КлючЗначенияМаксимум = Макс(КлючЗначенияМаксимум, КлючЗначения);
		EndIf;

		Запись = 	НаборЗаписей.Добавить();
		Запись.Period = Объект.Date; 
		Запись.Регистратор = Объект.Ref;
		Запись.BusinessUnit = Объект.BusinessUnit;
		Запись.ВидДвижения = ВидДвиженияБухгалтерии.Дебет;
		Запись.AxesHash = ХешОсей;
		Запись.Key = КлючЗначения;
		Запись.Valid = 1;
		
		Запись.Счет = СтрокаПоказателей.Concept;
		
		Для каждого КэшОсь Из КэшОсей Цикл
			Запись.Субконто.Вставить(КэшОсь.Ключ, КэшОсь.Value);
		КонецЦикла; 
						
		ЗаписьЗначения = НаборЗначений.Добавить();
		ЗаписьЗначения.Period = Объект.Date;
		ЗаписьЗначения.Регистратор = Объект.Ref;
		ЗаписьЗначения.Key = КлючЗначения;
		ЗаписьЗначения.Value = Данные.Value;
		ЗаписьЗначения.Text = Данные.Text;
		
		СтрокаИндексНаборЗаписейНеДеньги = ИндексНаборЗаписейНеДеньги.Добавить();
		ЗаполнитьЗначенияСвойств(СтрокаИндексНаборЗаписейНеДеньги, Запись, "BusinessUnit, AxesHash, Key, Счет");  
		
		СтрокаИндексНаборЗначений = ИндексНаборЗначений.Добавить();
		ЗаполнитьЗначенияСвойств(СтрокаИндексНаборЗначений, ЗаписьЗначения, "Key, Value, Text");  
		
	КонецЦикла; 
		
	Возврат Истина;
	
КонецФункции

Процедура ДобавитьПоказательОсей(Показатель, ВидДвижения, ТаблицаПоказателейОсей)

	СтрокаПоказатель = ТаблицаПоказателейОсей.Добавить();
	СтрокаПоказатель.Concept = Показатель;
	СтрокаПоказатель.ВидДвижения = velpo_BusinessReportingCashed.GetAccountingRecordType(ВидДвижения);
	СтрокаПоказатель.AxisTypes = velpo_BusinessReportingCashed.GetAxisTypeArray(Показатель);
	
КонецПроцедуры


Procedure DeleteTheSameDocumentForPeriod(DocObj) Export

	Query = New Query;
	Query.SetParameter("Component",  DocObj.Component);
	Query.SetParameter("BeginOfPeriod",  DocObj.BeginOfPeriod);
	Query.SetParameter("Date",  DocObj.Date);
	Query.SetParameter("BusinessUnit",  DocObj.BusinessUnit);
	Query.SetParameter("SourceDocument",  DocObj.SourceDocument);
	Query.Text = 
	"SELECT
	|	Fact.Ref AS Ref
	|FROM
	|	Document.Fact AS Fact
	|WHERE
	|	Fact.Component = &Component
	|	AND Fact.Date = &Date
	|	AND Fact.BeginOfPeriod = &BeginOfPeriod
	|	AND Fact.BusinessUnit = &BusinessUnit
	|	AND Fact.SourceDocument = &SourceDocument
	|	AND Fact.PointOfChange = 0";
	
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Selection.Ref.GetObject().Delete();	
	EndDo;

EndProcedure

Procedure AddZeroMeasureRecord(BusinessUnit, RecordTypeStr, Selection, RecordSet)

	Value = Selection[RecordTypeStr];
	If  Value = 0 Then
		Return;
	EndIf;
	
	Record = 	RecordSet.Добавить();
	Record.Period = Selection.Period; 
	Record.BusinessUnit = BusinessUnit;
	Record.RecordType = AccountingRecordType[RecordTypeStr];
	Record.Value = -Value;
	Record.Account = Selection.Concept;
	
	For i = 1 To 25 Do
		Index = String(i);
		AxisType = Selection["AxisType" + i];
		If ValueIsFilled(AxisType) Then
			Record.ExtDimensions.Insert(AxisType, Selection["Axis" + i]);
		EndIf;
	EndDo; 

EndProcedure

Procedure SetZeroMeasureBalance(BeginOfPeriod, EndOfPeriod, BusinessUnit, RecordSet = Undefined) Export
	
	NewRec = (RecordSet = Undefined);
	If NewRec Then
		RecordSet = РегистрыБухгалтерии.MeasureEntries.СоздатьНаборЗаписей();
		Запрос = Новый Запрос;
		Запрос.УстановитьПараметр("BeginOfPeriod", BeginOfPeriod);
		Запрос.УстановитьПараметр("EndOfPeriod", EndOfDay(BeginOfPeriod));
		Запрос.SetParameter("BusinessUnit",  BusinessUnit);

		Запрос.Текст =
		"ВЫБРАТЬ ПЕРВЫЕ 1
		|	Ссылка
		|ИЗ
		|	Документ.Fact
		|ГДЕ
		|	Проведен
		|	И BusinessUnit = &BusinessUnit
		|	И BeginOfPeriod = &BeginOfPeriod
		|	И Date = &EndOfPeriod
		|";
		Выборка = Запрос.Выполнить().Выбрать();
		Если Выборка.Следующий() Тогда
			RecordSet.Отбор.Регистратор.Установить(Выборка.Ссылка);
		Иначе
			DocumentXBRL = Documents.velpo_Fact.Create(BeginOfPeriod, BeginOfPeriod, BusinessUnit);	
			DocumentXBRL.PointOfChange = 0;
			DocumentXBRL.Записать(РежимЗаписиДокумента.Проведение);
			RecordSet.Отбор.Регистратор.Установить(DocumentXBRL.Ссылка);
		КонецЕсли;
	EndIf;
	
	ResCount = 0;
	Query = New Query;
	Query.SetParameter("BeginOfPeriod",  BeginOfPeriod);
	Query.SetParameter("EndOfPeriod",  New Boundary(EndOfDay(EndOfPeriod), BoundaryType.Including));
	Query.SetParameter("BeginOfMonth",  BegOfMonth(BeginOfPeriod));
	Query.SetParameter("BeginOfPeriodBorder",  New Boundary(BegOfMonth(BeginOfPeriod), BoundaryType.Excluding));
	Query.SetParameter("BusinessUnit",  BusinessUnit);
	Query.SetParameter("ConceptArrays", RecordSet.UnloadColumn("Account"));

	// rests
	Text =
	"SELECT
	|	&BeginOfMonth AS Period,
	|	MeasureEntriesBalance.Account AS Concept,";
	For i = 1 To 25 Do
		Index = String(i);
		Text = Text + 
		"	MeasureEntriesBalance.ExtDimension" + Index + " AS Axis" + Index + ",
		|	MeasureEntriesBalance.ExtDimension" + Index + ".Owner AS AxisType" + Index + ",
		|"
	EndDo; 
	Text = Text +
	"	MeasureEntriesBalance.ValueBalanceDr AS Debit,
	|	MeasureEntriesBalance.ValueBalanceCr AS Credit
	|FROM
	|	AccountingRegister.MeasureEntries.Balance(&BeginOfPeriodBorder, Account.TurnoversOnly = FALSE, , BusinessUnit = &BusinessUnit) AS MeasureEntriesBalance
	|;
	|";
	
	// turnovers
	If ValueIsFilled(BeginOfPeriod) AND Not NewRec Then
		ResCount = ResCount + 1;
		Text = Text +
		
		"SELECT
		|	&BeginOfMonth AS Period,
		|	MeasureEntriesTurnovers.Account AS Concept,";
		For i = 1 To 25 Do
			Index = String(i);
			Text = Text + 
			"	MeasureEntriesTurnovers.ExtDimension" + Index + " AS Axis" + Index + ",
			|	MeasureEntriesTurnovers.ExtDimension" + Index + ".Owner AS AxisType" + Index + ",
			|"
		EndDo; 
		Text = Text +
		"	MeasureEntriesTurnovers.ValueTurnoverDr AS Debit,
		|	MeasureEntriesTurnovers.ValueTurnoverCr AS Credit
		|FROM
		|	AccountingRegister.MeasureEntries.Turnovers(&BeginOfPeriod, &EndOfPeriod, Period, Account IN HIERARCHY (&ConceptArrays) AND Account.TurnoversOnly = TRUE, , BusinessUnit = &BusinessUnit) AS MeasureEntriesTurnovers
		|";
	EndIf;
	Query.Text = Text; 	
	Result = Query.ExecuteBatch();
	For i = 0 To ResCount Do
		Selection = Result[i].Select();
		While Selection.Next() Do
			AddZeroMeasureRecord(BusinessUnit, "Debit", Selection, RecordSet);
			AddZeroMeasureRecord(BusinessUnit, "Credit", Selection, RecordSet);
		EndDo;	
	EndDo; 
	
	If NewRec Then
		RecordSet.Записать(True);
	EndIf;
	
EndProcedure

Procedure FillDataInCubes() Export
	
	УстановитьПривилегированныйРежим(Истина);
	
	Запрос = Новый Запрос;
	Запрос.Текст = 
	"ВЫБРАТЬ
	|	МАКСИМУМ(Key) КАК Key
	|ИЗ
	|	РегистрСведений.GenValues
	|";
	ВыборкаМаксимум = Запрос.Выполнить().Выбрать();
	ВыборкаМаксимум.Следующий();
	КлючЗначенияМаксимум = ?(ВыборкаМаксимум.Key = NULL, 0, ВыборкаМаксимум.Key);
	
	// get data
	Query = New Query;
	Query.Text = GetQueryTextFacts();
	РезультатЗапроса = Query.Выполнить();
	
	НачатьТранзакцию();
	
	БлокировкаДанных = Новый БлокировкаДанных;
	
	ЭлементБлокировки = БлокировкаДанных.Добавить("Документ.Fact");
	ЭлементБлокировки.ИсточникДанных = РезультатЗапроса;
	ЭлементБлокировки.ИспользоватьИзИсточникаДанных("Ref", "Ref");
	БлокировкаДанных.Заблокировать();
	
	сч = 1;
	ВыборкаДокументов = РезультатЗапроса.Выбрать();
	Пока ВыборкаДокументов.Следующий() Цикл
		
		Если ВыборкаДокументов.DeletionMark Тогда
			ДокументОбъект = ВыборкаДокументов.Ref.ПолучитьОбъект();
			ДокументОбъект.Удалить();
		ИначеЕсли ВыборкаДокументов.Error Тогда
			Продолжить;
		Иначе
			ОбФакт = ВыборкаДокументов.Ref.ПолучитьОбъект();
			DeleteTheSameDocumentForPeriod(ОбФакт);
			
			Query.УстановитьПараметр("Fact", ВыборкаДокументов.Ref);
			Query.Текст = GetQueryTextConcepts();
			МассивРезультатов = Query.ВыполнитьПакет();
			ТаблицаОсей = МассивРезультатов[1].Выгрузить();
			ТаблицаОсей.Индексы.Добавить("RecordID");
			РезультатПоказателей = МассивРезультатов[0];
			ВыборкаПоказателей = РезультатПоказателей.Выбрать();
			ЕстьОшибки = Ложь; 
			
			НаборЗаписейДеньги = РегистрыБухгалтерии.MeasureEntries.СоздатьНаборЗаписей();
			НаборЗаписейДеньги.Отбор.Регистратор.Установить(ВыборкаДокументов.Ref);
			
			НаборЗаписейНеДеньги = РегистрыБухгалтерии.InfoEntries.СоздатьНаборЗаписей();
			НаборЗаписейНеДеньги.Отбор.Регистратор.Установить(ВыборкаДокументов.Ref);
			ИндексНаборЗаписейНеДеньги = НаборЗаписейНеДеньги.Выгрузить(, "BusinessUnit, AxesHash, Key, Счет"); 
			ИндексНаборЗаписейНеДеньги.Индексы.Добавить("BusinessUnit, AxesHash, Счет, Key");
	
			НаборЗначений = РегистрыСведений.GenValues.СоздатьНаборЗаписей();
			НаборЗначений.Отбор.Регистратор.Установить(ВыборкаДокументов.Ref);
			ИндексНаборЗначений = НаборЗначений.Выгрузить(, "Key, Value,  Text");
			ИндексНаборЗначений.Индексы.Добавить("Key, Value,  Text");
			
			Пока ВыборкаПоказателей.Следующий() Цикл
				
				Если ВыборкаПоказателей.ConceptType = Enums.velpo_BaseDataTypes.Enumeration Тогда
					Если ЗначениеЗаполнено(ВыборкаПоказателей.Value) Тогда
						ИмяЗначения = velpo_BusinessReportingCashed.GetConceptValueName(ВыборкаПоказателей.Value);
						Если ЗначениеЗаполнено(ИмяЗначения) Тогда
							Если НЕ velpo_BusinessReporting.ПроверитьВхождениеЭлементаВВидыЗначений(ВыборкаПоказателей.DataType, ВыборкаПоказателей.Value) Тогда
								velpo_BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,   НСтр("ru='Неверное значение перечисления показателя '")  + Строка(ВыборкаПоказателей.Concept) + ": " + Строка(ВыборкаПоказателей.Value), Истина, ЕстьОшибки); 
							КонецЕсли;
						Иначе
							velpo_BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,   НСтр("ru='Нельзя получить имя значения показателя '")  + Строка(ВыборкаПоказателей.Concept), Истина, ЕстьОшибки); 
						КонецЕсли;
					Иначе
						velpo_BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,   НСтр("ru='Не заполнено значение показателя '")  + Строка(ВыборкаПоказателей.Concept), Истина, ЕстьОшибки); 
					КонецЕсли;
				ИначеЕсли ВыборкаПоказателей.ConceptVariant = Enums.velpo_ConceptTypes.Measure Тогда
					Если ТипЗнч(ВыборкаПоказателей.Value) <> Тип("Число") Тогда
						velpo_BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,   НСтр("ru='Нечисловое значение показателя '")  + Строка(ВыборкаПоказателей.Concept), Истина, ЕстьОшибки); 
					КонецЕсли;
				КонецЕсли;
				
				МассивОсей = ТаблицаОсей.НайтиСтроки(Новый Структура("RecordID", ВыборкаПоказателей.RecordID));
				СоответствиеОсей = Новый Соответствие;
				Для каждого СтрокаОсей Из МассивОсей Цикл
					ТипОси = velpo_BusinessReportingCashed.GetAxisValueType(СтрокаОсей.Axis);
					ЗначениеОси = Catalogs.AxisMembers.GetAxisValue(СтрокаОсей.Axis);
					Если ЗначениеОси = Неопределено Тогда
						//BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,  НСтр("ru='Не заполнено значение вида оси '") + Строка(СтрокаОсей.AxisValueType), Истина, ЕстьОшибки);
					Иначе
						Если ЗначениеЗаполнено(СтрокаОсей.TypedDimensionName) Тогда
							Если ТипОси = Перечисления.AxisValueTypes.Ref Тогда
								Попытка
									ЗначениеОси = Строка(ЗначениеОси.УникальныйИдентификатор());
								Исключение
									velpo_BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,   НСтр("ru='Нельзя получить идентификатор вида оси '")  + Строка(СтрокаОсей.AxisValueType), Истина, ЕстьОшибки); 
								КонецПопытки;
							Иначе
							КонецЕсли;
						Иначе
							ИмяОси = Неопределено;
							Если ТипОси = Перечисления.AxisValueTypes.Ref Тогда
								ИмяОси = velpo_BusinessReportingCashed.GetAxisValueName(ЗначениеОси);
							КонецЕсли;
							Если НЕ ЗначениеЗаполнено(ИмяОси) Тогда
								velpo_BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,   НСтр("ru='Нельзя получить идентификатор вида оси '")  + Строка(СтрокаОсей.AxisType), Истина, ЕстьОшибки); 
							КонецЕсли;
						КонецЕсли;
					КонецЕсли;
					СоответствиеОсей.Вставить(СтрокаОсей.AxisType, СтрокаОсей.Axis);
				КонецЦикла; 
				Если ВыборкаПоказателей.ConceptVariant = Enums.velpo_ConceptTypes.Measure Тогда
					ЕстьДобавлениеПоказателя = ДобавитьМеру(ВыборкаДокументов, НаборЗаписейДеньги, ВыборкаПоказателей, СоответствиеОсей);	
				Иначе
					ЕстьДобавлениеПоказателя = ДобавитьСведение(ВыборкаДокументов, НаборЗаписейНеДеньги, НаборЗначений, ВыборкаПоказателей, СоответствиеОсей, ИндексНаборЗаписейНеДеньги, ИндексНаборЗначений, КлючЗначенияМаксимум);
				КонецЕсли;
				Если НЕ ЕстьДобавлениеПоказателя Тогда
					velpo_BusinessReporting.СообщитьОбОшибкиДанных(ВыборкаПоказателей, РезультатПоказателей.Колонки,  НСтр("ru='Не удалось записать показатель в кубы: '") + Строка(ВыборкаПоказателей.Concept), Истина, ЕстьОшибки);
				КонецЕсли;
			КонецЦикла;
				
			Если  ЕстьОшибки Тогда
				ОбФакт.Error = Истина;
				velpo_BusinessReporting.ОчиститьРегистрДанных(РегистрыБухгалтерии.MeasureEntries, ВыборкаДокументов.Ref);
				velpo_BusinessReporting.ОчиститьРегистрДанных(РегистрыБухгалтерии.InfoEntries, ВыборкаДокументов.Ref);
				velpo_BusinessReporting.ОчиститьРегистрДанных(РегистрыСведений.GenValues, ВыборкаДокументов.Ref);
			Иначе
				ОбФакт.PointOfChange = 0;
				If ОбФакт.IsLoaded Then
					SetZeroMeasureBalance(?(ЗначениеЗаполнено(ОбФакт.BeginOfPeriod), ОбФакт.BeginOfPeriod, BegOfMonth(ОбФакт.Date)), ОбФакт.Date, ОбФакт.BusinessUnit, НаборЗаписейДеньги);
				EndIf;
				НаборЗаписейДеньги.Записать(Ложь);
				НаборЗаписейНеДеньги.Записать(Ложь);
				НаборЗначений.Записать(Ложь);
				velpo_BusinessReporting.ОчиститьРегистрДанных(РегистрыСведений.OperationalConceptValues, ВыборкаДокументов.Ref);
				velpo_BusinessReporting.ОчиститьРегистрДанных(РегистрыСведений.OperationalAxes, ВыборкаДокументов.Ref);
			КонецЕсли;
			
			ОбФакт.Записать(РежимЗаписиДокумента.Запись);
			
		КонецЕсли;
		
		Если сч % 1000 = 0 Тогда
			ЗафиксироватьТранзакцию();
			НачатьТранзакцию();
			
			БлокировкаДанных = Новый БлокировкаДанных;
			
			ЭлементБлокировки = БлокировкаДанных.Добавить("Документ.Факт");
			ЭлементБлокировки.ИсточникДанных = РезультатЗапроса;
			ЭлементБлокировки.ИспользоватьИзИсточникаДанных("Ref", "Ref");
			БлокировкаДанных.Заблокировать();

		КонецЕсли;
		
		сч = сч + 1;
	КонецЦикла;
		
	ЗафиксироватьТранзакцию();
	
EndProcedure

// TODO

Процедура УстановитьРасчетныйПоказатель(Показатель, ВидДвижения, ТаблицаПоказателейОсей)
	
	ТаблицаРасчета = velpo_BusinessReportingCashed.ПолучитьТаблицуРасчетныхПоказателей(Показатель, ВидДвижения);
	Для каждого СтрокаРасчета ИЗ ТаблицаРасчета Цикл
		Если ВидДвижения = "Дебет" И СтрокаРасчета.Дебетовый И СтрокаРасчета.ВидСчета = ВидСчета.Пассивный Тогда
			ВидДвиженияПоказателя = "Кредит";
		ИначеЕсли ВидДвижения = "Кредит" И СтрокаРасчета.Кредитовый И СтрокаРасчета.ВидСчета = ВидСчета.Активный Тогда
			ВидДвиженияПоказателя = "Дебет";
		Иначе
			ВидДвиженияПоказателя = ВидДвижения;
		КонецЕсли;
		ДобавитьПоказательОсей(СтрокаРасчета.Concept, ВидДвиженияПоказателя, ТаблицаПоказателейОсей);
		УстановитьРасчетныйПоказатель(СтрокаРасчета.Concept, ВидДвижения, ТаблицаПоказателейОсей);
	КонецЦикла;

КонецПроцедуры
