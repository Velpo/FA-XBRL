///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServer
Function GetLegalTypesFromResult(ResultValueType, LegalTypes)

		TypesArray = New Array;
		FieldTypesArray = ResultValueType.Types();
		For Each FieldType In FieldTypesArray Do
			If LegalTypes.ContainsType(FieldType) Then
				TypesArray.Add(FieldType);	
			EndIf;
		EndDo; 
			
		If TypesArray.Count() > 0 Then 
			If ResultValueType.NumberQualifiers.Digits > 26 Or ResultValueType.NumberQualifiers.FractionDigits > 6 Then
				ResultNumberQualifiers = New NumberQualifiers(Min(ResultValueType.NumberQualifiers.Digits, 26), Min(ResultValueType.NumberQualifiers.FractionDigits, 6), ResultValueType.NumberQualifiers.AllowedSign);
			Else
				ResultNumberQualifiers = ResultValueType.NumberQualifiers;
			EndIf;
			If ResultValueType.StringQualifiers.Length > 1024 Then
				ResultStringQualifiers = New StringQualifiers(Min(ResultValueType.StringQualifiers.Length, 1024), ResultValueType.StringQualifiers.AllowedLength);
			Else
				ResultStringQualifiers = ResultValueType.StringQualifiers;
			EndIf;
			Return New TypeDescription(TypesArray, ResultNumberQualifiers, ResultStringQualifiers, ResultValueType.DateQualifiers, ResultValueType.BinaryDataQualifiers);
		Else
			Return LegalTypes;
		EndIf;

EndFunction // GetLegalTypesFromResult()

&AtServer
Procedure SetUpParameters()

	Object.SourceParameters.Clear();
	
	Query = Новый Query;
	Query.Text = Object.SourceText;

	// Fill  table parameters.
	QueryParams = Query.FindParameters();
	ValueParams = Object.SourceParameters.Unload().UnloadColumn("Parameter");
	
	LegalTypes = Metadata.ChartsOfCharacteristicTypes.velpo_UserDefinedParameters.Type;
	
	For Each QueryParDescription Из QueryParams Do
		
		ParamRef = ChartsOfCharacteristicTypes.velpo_UserDefinedParameters.FindByCode(QueryParDescription.Name);
		If Not ValueIsFilled(ParamRef) Then
			ParamObj = ChartsOfCharacteristicTypes.velpo_UserDefinedParameters.CreateItem();
			ParamObj.Code = QueryParDescription.Name;
			ParamObj.ValueType =  GetLegalTypesFromResult(QueryParDescription.ValueType, LegalTypes);
			ParamObj.Write();
			ParamRef = ParamObj.Ref;
		EndIf;
		
		If ValueParams.Find(ParamRef) = Undefined Then
			LineParams = Object.SourceParameters.Add();
			LineParams.Parameter = ParamRef; 
		EndIf;
		
	EndDo;

EndProcedure // SetUpParameters()

&AtClient
Procedure FillParameters(Command)
	
	Object.SourceText = ThisForm.QueryText.GetText(); 
	SetUpParameters();	
	
EndProcedure

&AtClient
Procedure QueryConstruction(Command)
	
	//#If ThickClientManagedApplication Then

		QueryWizardNotifyDescription = New NotifyDescription(
			"QueryWizardAfterShow",
			ThisForm);
			
		Text = ThisForm.QueryText.GetText();
		If ValueIsFilled(Text) Then
			QueryWizard = New QueryWizard(Text);
		Else
			QueryWizard = New QueryWizard;
		EndIf;
		
		QueryWizard.Show(QueryWizardNotifyDescription);
		
	 //#EndIf;
	
 EndProcedure
 
 &AtClient
 Procedure QueryWizardAfterShow(QueryTextResult, AddParameters = Undefined) Export
	 
	 If QueryTextResult = Undefined Then
		 Return;
	EndIf;
	
	ThisForm.QueryText.SetText(QueryTextResult);
 	 
 EndProcedure // QueryWizardAfterShow()

&AtServer
 Procedure CreateResultsFieldsAtServer()
	 
	Query = New Query;
	Query.SetParameter("Source", Object.Ref);
	Query.Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.Ref IN HIERARCHY(&Source)
	|	AND SourceQueryComponents.Ref <> &Source
	|	AND SourceQueryComponents.IsFolder
	|";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Obj = Selection.Ref.GetObject();
		Obj.SetDeletionMark(True, True);
	EndDo;
 
 	ReportConstruction = Обработки.velpo_ReportConstruction.Создать();
	ReportConstruction.PeriodStart = BegOfDay(ThisForm.BeginOfPeriod);
	ReportConstruction.PeriodEnd = EndOfDay(ThisForm.EndOfPeriod);
	ReportConstruction.BusinessUnit = ThisForm.BusinessUnit;
	
	TempTablesManager = New TempTablesManager;
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	// set source data
	ReportConstruction.SetSourceData(Query, Object);
	
	Text = ThisForm.QueryText.GetText();
	Query.Текст = Text;
	QueryTextArray = GetQueryTextArray(Text);
	QueryResults = Query.ВыполнитьПакет();
	
	LegalTypes = Metadata.ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.Type;
	
	Index  = 0;
	
	For Each QueryResult In QueryResults  Do
		
		Index = Index + 1;
		If QueryResult = Undefined Then
			Continue;
		ElsIf QueryResult.Columns.Count() = 1 And (QueryResult.Columns[0].Name = "Count" Or QueryResult.Columns[0].Name = "Количество") Then
			Continue;
		EndIf;
		
		CodeResult = TrimAll(Object.Code) + "Result" + String(Index);
		RefResult = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.FindByCode(CodeResult, Object.Ref);
		If ValueIsFilled(RefResult) Then
			ObjResult = RefResult.GetObject();
			ObjResult.DeletionMark = False;
		Else
			ObjResult = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.CreateFolder();
			ObjResult.Parent =  Object.Ref;
			ObjResult.Code = CodeResult;
			ObjResult.IndexNum = Index;
			ObjResult.ComponentType = Enums.velpo_ComponetQueryTypes.Result;
		EndIf;
		ObjResult.Write();
		RefResult = ObjResult.Ref;
		
		ResultColumns = QueryResult.Columns;
		For Each ResultColumn In ResultColumns  Do
			RefField = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.FindByCode(ResultColumn.Name, RefResult);
			If ValueIsFilled(RefField) Then
				ObjField = RefField.GetObject();
				ObjField.DeletionMark = False;
			Else
				ObjField = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.CreateItem();
				ObjField.Parent =  RefResult;
				ObjField.Code = ResultColumn.Name;
				ObjField.ComponentType = Enums.velpo_ComponetQueryTypes.Field;
			EndIf;
						
			ObjField.ValueType = GetLegalTypesFromResult(ResultColumn.ValueType, LegalTypes);
			ObjField.Write();
			
		EndDo; 
		
	EndDo;
	
	Query = New Query;
	Query.SetParameter("Source", Object.Ref);
	Query.Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.velpo_SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.Ref IN HIERARCHY(&Source)
	|	AND SourceQueryComponents.DeletionMark
	|	AND SourceQueryComponents.ComponentType IN (VALUE(Enum.velpo_ComponetQueryTypes.Result), VALUE(Enum.velpo_ComponetQueryTypes.Field))
	|";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Obj = Selection.Ref.GetObject();
		Try
			Obj.Delete();	
		Except
		
		EndTry;
		
	EndDo;
	 
 EndProcedure

&AtClient
 Procedure CreateResultsFields(Command)
	 
	 ThisForm.Write();
	 
	 CreateResultsFieldsAtServer();
	 
 EndProcedure

&AtServer
 Procedure OnCreateAtServer(Cancel, StandardProcessing)
	 
	 ThisForm.QueryText.SetText(Object.SourceText);
	 	 
 EndProcedure

&AtServer
 Procedure BeforeWriteAtServer(Cancel, CurrentObject, WriteParameters)
	 
	 CurrentObject.SourceText = ThisForm.QueryText.GetText();
	 
 EndProcedure

 #Region REMAKE
 
 &AtServer
 Функция ВыполнитьЗапрос()
	 
 	ReportConstruction = Обработки.velpo_ReportConstruction.Создать();
	ReportConstruction.PeriodStart = BegOfDay(ThisForm.BeginOfPeriod);
	ReportConstruction.PeriodEnd = EndOfDay(ThisForm.EndOfPeriod);
	ReportConstruction.BusinessUnit = ThisForm.BusinessUnit;
	
	TempTablesManager = New TempTablesManager;
	Query = New Query;
	Query.TempTablesManager = TempTablesManager;
	// set source data
	ReportConstruction.SetSourceData(Query, Object);
	
	Text = ThisForm.QueryText.GetText();
	Query.Текст = Text;
	QueryTextArray = GetQueryTextArray(Text);
	ResultArray = Query.ВыполнитьПакет();
	
	ThisForm.Result.Clear();
	Int = 0;
	CountQuery = ResultArray.Count(); 
	For Each QueryResult In ResultArray  Do
	
		If QueryResult = Undefined Then
			Int = Int + 1;
			Continue;
		ElsIf QueryResult.Columns.Count() = 1 And (QueryResult.Columns[0].Name = "Count" Or QueryResult.Columns[0].Name = "Количество") Then
			Int = Int + 1;
			Continue;
		EndIf;

		Text  = QueryTextArray[Int];		
		
		МассивШириныКолонок 					= Новый Массив;
		Свертка 								= ОпределитьСвертку(Int, CountQuery);
		
		Int = Int + 1;

		ИмяЗапроса 	= String(Int) + ". " + ПолучитьИмяЗапроса(Text);
		Иерархия   	= НаличиеИерархииВЗапросе(Text);
		
		ColumnWeightArray = New Array;
		ТД = ВывестиРезультатОдногоЗапроса(ИмяЗапроса, QueryResult, Свертка, Иерархия, ColumnWeightArray);
		ThisForm.Result.Вывести(ТД);

	EndDo; 
	
	Query.TempTablesManager.Закрыть();
	
КонецФункции

// Возвращает массив текстов запросов.
//
// Параметры:
//	ТекстЗапроса - Текст передаваемого запроса.
//
 &AtServer
Функция GetQueryTextArray(знач ТекстЗапроса)
	
	МассивТекстов = Новый Массив;
	Пока Не ПустаяСтрока(ТекстЗапроса) Цикл
		ТочкаСЗапятой = ";";
		ПозицияТочкиСЗапятой = СтрНайти(ТекстЗапроса, ТочкаСЗапятой);
		Если Сред(ТекстЗапроса, ПозицияТочкиСЗапятой - 1, 1) = "\" Тогда
			ПозицияТочкиСЗапятой = 0;
		КонецЕсли;
		Если ПозицияТочкиСЗапятой = 0 Тогда
			ТекстОчередногоЗапроса 	= ТекстЗапроса;
			ПозицияТочкиСЗапятой	= СтрДлина(ТекстЗапроса);
		Иначе
			ТекстОчередногоЗапроса = Лев(ТекстЗапроса, ПозицияТочкиСЗапятой - 1);
		КонецЕсли;	
		Если Не ПустаяСтрока(ТекстОчередногоЗапроса) Тогда 
			МассивТекстов.Добавить(СокрЛП(ТекстОчередногоЗапроса));
		КонецЕсли;	
		ТекстЗапроса = Сред(ТекстЗапроса, ПозицияТочкиСЗапятой + 1);
	КонецЦикла;
	
	Возврат МассивТекстов;
	
КонецФункции	

// Возвращает есть ли в запросе иерархия.
//
// Параметры:
//	ТекстЗапроса - текст запроса.
//
 &AtServer
Функция НаличиеИерархииВЗапросе(ТекстЗапроса)
	Итоги	= "ИТОГИ";
	Позиция	= СтрНайти(ВРег(ТекстЗапроса), Итоги);
	
	Возврат ?(Позиция = 0, Ложь, Истина);
КонецФункции

// Возвращает имя запроса из текста запроса.
//
// Параметры:
//	ТекстЗапроса - текст запроса.
//
 &AtServer
Функция ПолучитьИмяЗапроса(знач ТекстЗапроса)
	РезультатЗначение = НСтр("ru = 'Запрос:'") + " ";
	ДлинаТекста = СтрДлина(ТекстЗапроса);
	ФлагПредлогаИЗ = Истина;
	
	
	Пока ФлагПредлогаИЗ Цикл 
		СловоИЗ = "ИЗ";
		ДлинаИЗ = СтрДлина(СловоИЗ);
		ПозицияИЗ = СтрНайти(ВРег(ТекстЗапроса), СловоИЗ);
		Если ПозицияИЗ = 0 Тогда
			Возврат РезультатЗначение;
		КонецЕсли;
		
		СимволДоИЗ = Сред(ТекстЗапроса, ПозицияИЗ - 1, 1);
		СимволПослеИЗ = Сред(ТекстЗапроса, ПозицияИЗ + ДлинаИЗ, 1);
		Если ПустаяСтрока(СимволДоИЗ) И ПустаяСтрока(СимволПослеИЗ) Тогда 
			ФлагПредлогаИЗ = Ложь;
		Иначе     
			ТекстЗапроса = Сред(ТекстЗапроса, ПозицияИЗ + ДлинаИЗ);
		КонецЕсли;
	КонецЦикла;
	
	НачальнаяПозиция = ПозицияИЗ + ДлинаИЗ;
	
	Для Индекс = НачальнаяПозиция По ДлинаТекста Цикл 
		Символ = Сред(ТекстЗапроса, Индекс, 1);
		Если Не ПустаяСтрока(Символ) Тогда
			Прервать;
		КонецЕсли;	
	КонецЦикла;	
	
	// Формирование имени таблицы.
	Для ИндексЗапроса = Индекс По ДлинаТекста Цикл 
		Символ = Сред(ТекстЗапроса, ИндексЗапроса, 1);
		Если Не ПустаяСтрока(Символ) Тогда
			РезультатЗначение = РезультатЗначение + Символ;
		Иначе
			Прервать;
		КонецЕсли;
	КонецЦикла;
	
	Возврат РезультатЗначение;
КонецФункции

// Вывод результат запроса в табличный документ.
//
// Параметры:
//   ИмяЗапроса - Строка - имя запроса.
//   РезультатЗапроса - результат запроса.
//   Открыта - свернуть результат одного запроса в выводимом табличном документе.
//  ПараметрыВыводаЗапроса - Структура - Параметры вывода запроса.
//    * ВыводитьВременныеТаблицы - выводить временные таблицы или нет.
//    * ВыводитьИдентификатор - выводить GUID для ссылок или нет.
//    * ПорядокОбхода - порядок обхода результата запроса.
//    * ИспользованиеЧередования - использовать чередование или нет в результирующем табличном документе.
//   Иерархия - наличие итогов в запросе.
//   КоличествоСтрок - Число - Количество строк в результате данного запроса.
//   МассивШириныКолонок - массив максимальной ширины каждой колонки.
//
 &AtServer
Функция ВывестиРезультатОдногоЗапроса(ИмяЗапроса, Результат, Открыта, Иерархия, МассивШириныКолонок)
	
	РезультатЗапроса = ВыгрузкаРезультата(Результат, Иерархия);
	
	ВыходнойМакет = Новый ТабличныйДокумент;
	МакетОдногоЗапроса = Новый ТабличныйДокумент;
	
	Если РезультатЗапроса = Неопределено Тогда 
		Возврат ВыходнойМакет;
	КонецЕсли;
	
	МакетОдногоЗапроса.Очистить();
	ВыходнойМакет.Очистить();
	
	УровеньВерхний = 1;
	УровеньЗаголовкаИДеталей = 2;
	
	// Вывод в табличный документ.
	ЗаголовкиКолонок = ВывестиЗаголовкиКолонок(РезультатЗапроса, МассивШириныКолонок);
	Детали = ВывестиДетали(РезультатЗапроса, МассивШириныКолонок);
	ЗаголовокЗапроса = ВывестиЗаголовокЗапроса(ИмяЗапроса);
	
	МакетОдногоЗапроса.НачатьАвтогруппировкуСтрок();
	
	МакетОдногоЗапроса.Вывести(ЗаголовокЗапроса, УровеньВерхний);
	МакетОдногоЗапроса.Вывести(ЗаголовкиКолонок, УровеньЗаголовкаИДеталей,, Открыта);
	МакетОдногоЗапроса.Вывести(Детали, УровеньЗаголовкаИДеталей,, Открыта);
	
	МакетОдногоЗапроса.ЗакончитьАвтогруппировкуСтрок();
	
	УстановкаАвтоШирины(ВыходнойМакет, МассивШириныКолонок);
	ВыходнойМакет.Вывести(МакетОдногоЗапроса).СоздатьФорматСтрок();
	
	Возврат ВыходнойМакет;
КонецФункции

// Возвращает ТаблицуЗначений или ДеревоЗначений результата.
//
// Параметры:
//	РезультатЗапроса - результат запроса.
//  Иерархия - есть ли иерархия в запросе. 
//
 &AtServer
Функция ВыгрузкаРезультата(РезультатЗапроса, Иерархия)
	
	Если РезультатЗапроса = Неопределено Тогда 
		Возврат Неопределено;
	КонецЕсли;	
	
	Если Иерархия Тогда
		ВыгруженноеЗначение = РезультатЗапроса.Выгрузить(ОбходРезультатаЗапроса.ПоГруппировкамСИерархией);
	Иначе
		ВыгруженноеЗначение = РезультатЗапроса.Выгрузить(ОбходРезультатаЗапроса.Прямой);
	КонецЕсли;
	
	Возврат ВыгруженноеЗначение;
	
КонецФункции	

 &AtServer
Функция ВывестиЗаголовокЗапроса(ИмяЗапроса)
	ЗаголовокВывода 	= Новый ТабличныйДокумент;
	
	МакетВывода = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.GetTemplate("РезультатВыполненияЗапроса");
	
	ОбластьЗаголовок 	= МакетВывода.ПолучитьОбласть("ЗапросИмя");
	ОбластьЗаголовок.Параметры.ИмяЗапроса  		= ИмяЗапроса;
	ЗаголовокВывода.Вывести(ОбластьЗаголовок);
	
	Возврат ЗаголовокВывода;
КонецФункции

 &AtServer
Функция ВывестиЗаголовкиКолонок(Результат, МассивШириныКолонок)
	МакетВывода = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.GetTemplate("РезультатВыполненияЗапроса");
	
	ВерхнийЗаголовокКолонок		= Новый ТабличныйДокумент;
	
	ЗаголовокКолонок				= Новый ТабличныйДокумент;
	ОбластьЗаголовкиКолонок 	= МакетВывода.ПолучитьОбласть("ОбластьЯчейки");
	
	Область 	  					= ОбластьЗаголовкиКолонок.Область();
	Область.Шрифт 					= Новый Шрифт(,, Ложь);
	Область.ГоризонтальноеПоложение = ГоризонтальноеПоложение.Центр;
	Область.ЦветФона				= Новый Цвет(204, 192, 133);
	
	Индекс = 0;
	// Вывод заголовка таблицы.
	Для каждого Стр Из Результат.Колонки Цикл
		УстановкаМаксимальнойШириныВМассив(Индекс, Стр.Name, МассивШириныКолонок);
		ОбластьЗаголовкиКолонок.Параметры.Значение	= Стр.Name;
		Об = ЗаголовокКолонок.Присоединить(ОбластьЗаголовкиКолонок);
		Об.ШиринаКолонки = МассивШириныКолонок.Получить(Индекс);
		Индекс	= Индекс + 1;
	КонецЦикла;                          
	ВерхнийЗаголовокКолонок.Вывести(ЗаголовокКолонок);
	
	Возврат ВерхнийЗаголовокКолонок;
КонецФункции

 &AtServer
Функция ВывестиДетали(Результат, МассивШириныКолонок)
	Детали = Новый ТабличныйДокумент;
	Уровень = 1;
	Детали.НачатьАвтогруппировкуСтрок();
	
	Если ТипЗнч(Результат) = Тип("ДеревоЗначений") Тогда
		ИндексСтроки = 1;
		КоличествоКолонок = Результат.Колонки.Количество();
		ВывестиДеталиСИерархией(Детали, Результат, Уровень, КоличествоКолонок, ИндексСтроки, МассивШириныКолонок);
	КонецЕсли;
	Если ТипЗнч(Результат) = Тип("ТаблицаЗначений") Тогда
		КоличествоКолонок = Результат.Колонки.Количество();
		ВывестиДеталиБезИерархии(Детали, Результат, Уровень, КоличествоКолонок, МассивШириныКолонок);
	КонецЕсли;
	
	Детали.ЗакончитьАвтогруппировкуСтрок();
	Возврат Детали;
КонецФункции

 &AtServer
Функция ВывестиДеталиБезИерархии(ОбщиеДетали, Результат,  Уровень, КоличествоКолонок, МассивШириныКолонок)
	
	МакетВывода = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.GetTemplate("РезультатВыполненияЗапроса");
	
	ИндексСтроки = 1;
	Для каждого Строка Из Результат Цикл
		Детали = Новый ТабличныйДокумент;
		ОбластьДетали = МакетВывода.ПолучитьОбласть("ОбластьЯчейки");
		
		Область = ОбластьДетали.ТекущаяОбласть;
		Область.Шрифт = Новый Шрифт(,, Ложь);
		Область.ЦветФона = ОпределитьЦветФонаПоИндексу(ИндексСтроки, Истина);

		Для Индекс = 0 По КоличествоКолонок - 1 Цикл
			Значение = Строка.Получить(Индекс);
			
			Если ТипЗнч(Значение) = Тип("ТаблицаЗначений") Тогда 
				Значение = ПреобразоватьТаблицуЗначенийВСтроке(Значение);
			КонецЕсли;
			
			ЗначениеДляПараметра = Значение;
			Если ЭтоСсылка(ТипЗнч(Значение))  Тогда 
				//Попытка
				//	ЗначениеДляПараметра = Значение.УникальныйИдентификатор();
				//Исключение
					ЗначениеДляПараметра = Значение;
				//КонецПопытки;
			КонецЕсли;
			ОбластьДетали.Параметры.Значение = ЗначениеДляПараметра;
			ОбластьДетали.Параметры.Расшифровка = Значение;
			УстановкаМаксимальнойШириныВМассив(Индекс, ЗначениеДляПараметра, МассивШириныКолонок);
			Детали.Присоединить(ОбластьДетали);
		КонецЦикла;
		ИндексСтроки = ИндексСтроки + 1;
		ОбщиеДетали.Вывести(Детали, Уровень);
	КонецЦикла;	
КонецФункции

 &AtServer
Функция ВывестиДеталиСИерархией(ОбщиеДетали, Результат,  Уровень, КоличествоКолонок, ИндексСтроки, МассивШириныКолонок)
	
	МакетВывода = ChartsOfCharacteristicTypes.velpo_SourceQueryComponents.GetTemplate("РезультатВыполненияЗапроса");
	Открыта = Истина;
	Подчиненные = Результат.Строки;
	
	Для Каждого Подчиненный Из Подчиненные Цикл
		Детали = Новый ТабличныйДокумент;
		ОбластьДетали = МакетВывода.ПолучитьОбласть("ОбластьЯчейки");
		
		Область = ОбластьДетали.ТекущаяОбласть;
		Область.Шрифт = Новый Шрифт(,, Ложь);
		Область.ЦветФона = ОпределитьЦветФонаПоИндексу(ИндексСтроки, Истина);
		
		Для Индекс = 0 По КоличествоКолонок - 1 Цикл 
			Значение = Подчиненный.Получить(Индекс);
			
			Если ТипЗнч(Значение) = Тип("ТаблицаЗначений") Тогда 
				Значение = ПреобразоватьТаблицуЗначенийВСтроке(Значение);
			КонецЕсли;
			
			ЗначениеДляПараметра = Значение;
			// Определение количество отступа по уровню.
			Пробел = ОпределениеОтступаПоУровню(Уровень, Индекс, Открыта);
			
			ЗначениеДляПараметра = "" + Пробел + ЗначениеДляПараметра;
			ОбластьДетали.Параметры.Значение = ЗначениеДляПараметра;
			ОбластьДетали.Параметры.Расшифровка = Значение;
			
			УстановкаМаксимальнойШириныВМассив(Индекс, ЗначениеДляПараметра, МассивШириныКолонок);
			
			Детали.Присоединить(ОбластьДетали);
		КонецЦикла;
		
		ОбщиеДетали.Вывести(Детали, Уровень,, Открыта);
		ИндексСтроки = ИндексСтроки + 1;
		ВывестиДеталиСИерархией(ОбщиеДетали, Подчиненный, Уровень + 1, КоличествоКолонок, ИндексСтроки, МассивШириныКолонок);
	КонецЦикла;
КонецФункции

// Определяет сворачивать или нет результат одного запроса.
//
// Параметры:
//	ПозицияТекущегоЗапроса - порядок запроса в пакете.
//	КоличествоВсехЗапросов - количество всех запросов в пакете.
//
 &AtServer
Функция ОпределитьСвертку(знач ПозицияТекущегоЗапроса, КоличествоВсехЗапросов)
	ПозицияТекущегоЗапроса = ПозицияТекущегоЗапроса + 1;
	
	Если КоличествоВсехЗапросов = 1 Тогда 
		РезультатЗначение = Истина;
	Иначе
		Если ПозицияТекущегоЗапроса = КоличествоВсехЗапросов Тогда 
			РезультатЗначение = Истина;
		Иначе
			РезультатЗначение = Ложь;
		КонецЕсли;
	КонецЕсли;
	
	Возврат РезультатЗначение;
КонецФункции

// Выводит строку с автошириной колонок.
//
// Параметры: 
//	РезультатЗапроса - табличный документ с результатом запроса.
//	МассивМаксШирины - массив ширины колонок для отдельного запроса.
//
 &AtServer
Процедура УстановкаАвтоШирины(РезультатЗапроса, МассивМаксШирины)
	ВерхняяГраница = МассивМаксШирины.ВГраница();
	Если ВерхняяГраница = -1 Тогда
		Возврат;
	КонецЕсли;
	
	Для Индекс = 0 По ВерхняяГраница Цикл 
		ВременныйТабличныйДокумент = Новый ТабличныйДокумент;
		Стр = ВременныйТабличныйДокумент.ПолучитьОбласть(1, Индекс + 1, 1, Индекс + 1);
		РезультатЗапроса.Присоединить(Стр).ШиринаКолонки = МассивМаксШирины.Получить(Индекс);
	КонецЦикла;
КонецПроцедуры

// Устанавливает максимальную ширину ячейки для каждой колонки.
//
Процедура УстановкаМаксимальнойШириныВМассив(Индекс, знач Элем, МассивШириныКолонок)
	МаксимальнаяШиринаЯчейки    = 100;
	
	Элем = СокрП(Элем);
	Элем = СтрДлина(Элем);
	Если Индекс > МассивШириныКолонок.ВГраница() Тогда
		Если Элем < МаксимальнаяШиринаЯчейки Тогда 
			МассивШириныКолонок.Вставить(Индекс, Элем + 1);
		Иначе
			МассивШириныКолонок.Вставить(Индекс, МаксимальнаяШиринаЯчейки);
		КонецЕсли;	
	Иначе
		Макс = МассивШириныКолонок.Получить(Индекс);
		Если Элем > Макс Тогда
			Если Элем < МаксимальнаяШиринаЯчейки Тогда
				МассивШириныКолонок.Установить(Индекс, Элем + 1);
			Иначе
				МассивШириныКолонок.Установить(Индекс, МаксимальнаяШиринаЯчейки);
			КонецЕсли;	
		КонецЕсли;
	КонецЕсли;	
КонецПроцедуры	

// Возвращает цвет фона табличного документа по индексу строки и по использованию.
//
// Параметры:
//	Индекс - передаваемый индекс строки.
//	Использование - использовать или нет чередование.
//
Функция ОпределитьЦветФонаПоИндексу(Индекс, Использование)
	ЦветЧередования	= Новый Цвет(245, 242, 221);
	
	Если Не Использование Тогда
		Возврат WebЦвета.Белый;
	КонецЕсли;	
	
	Остаток = Индекс % 2;
	Если Остаток = 0 Тогда
		Цвет = ЦветЧередования;
	Иначе
		Цвет = WebЦвета.Белый;
	КонецЕсли;	
	
	Возврат Цвет;
КонецФункции

Функция ПреобразоватьТаблицуЗначенийВСтроке(ТаблицаЗначений)
	
	ПредставлениеТаблицыЗначений = "";
	Для каждого СтрокаТаблицыЗначений Из ТаблицаЗначений Цикл
		Разделитель = "";
		Для каждого ЯчейкаТаблицыЗначений Из СтрокаТаблицыЗначений Цикл
			ПредставлениеТаблицыЗначений = ПредставлениеТаблицыЗначений + Разделитель + Строка(ЯчейкаТаблицыЗначений);
			Разделитель = ";";
		КонецЦикла;
		ПредставлениеТаблицыЗначений = ПредставлениеТаблицыЗначений + Символы.ПС;
	КонецЦикла;
	Значение = ПредставлениеТаблицыЗначений;
	
	Возврат ПредставлениеТаблицыЗначений
КонецФункции

// Проверяет является ли тип ссылкой.
//
// Параметры:
//	Тип - передаваемый тип.
//
Функция ЭтоСсылка(Тип) Экспорт
	
	Возврат Справочники.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ Документы.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ Перечисления.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ ПланыВидовХарактеристик.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ ПланыСчетов.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ ПланыВидовРасчета.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ БизнесПроцессы.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ БизнесПроцессы.ТипВсеСсылкиТочекМаршрутаБизнесПроцессов().СодержитТип(Тип)
		ИЛИ Задачи.ТипВсеСсылки().СодержитТип(Тип)
		ИЛИ ПланыОбмена.ТипВсеСсылки().СодержитТип(Тип);
	
КонецФункции

// Определяет отступ по уровню.
//
// Параметры:
//	Уровень - переданный уровень в дереве.
//	НомерКолонки - номер колонки, отступ устанавливается только для первой колонки.
//	Открыта - открыта группа или нет.
//
Функция ОпределениеОтступаПоУровню(Уровень, НомерКолонки, Открыта)
	Пробел = "";
	Если НомерКолонки = 0 Тогда 
		Если Уровень > 1 Тогда 
			Для Индекс = 1 По Уровень Цикл
				Пробел = Пробел + Символы.Таб; 
			КонецЦикла;
			Открыта = Ложь;
		Иначе
			Открыта = Истина;
		КонецЕсли;
	КонецЕсли;
	Возврат Пробел;
КонецФункции

 #EndRegion 

&AtClient
 Procedure GenerateResult(Command)
	 ВыполнитьЗапрос();
 EndProcedure

&AtClient
 Procedure ResultDragStart(Item, DragParameters, Perform)
	 Message(1);
	 
 EndProcedure