///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Var SettingsVar;

Function NormalizeString(Val Text)
	
	Text = СокрЛП(Text);
	//Текст = СтрЗаменить(Текст, """", "&quot;");
	Text = StrReplace(Text, "©", "&copy;");
	Text = StrReplace(Text, "®", "&reg;");
	Text = StrReplace(Text, "™", "&trade;");
	Text = StrReplace(Text, "„", "&bdquo;");
	Text = StrReplace(Text, "“", "&ldquo;");
	//Текст = СтрЗаменить(Текст, "«", "&laquo;");
	//Текст = СтрЗаменить(Текст, "»", "&raquo;");
	//Текст = СтрЗаменить(Текст, ">", "&gt;");
	//Текст = СтрЗаменить(Текст, "<", "&lt;");
	//Текст = СтрЗаменить(Текст, "≥", "&ge");
	//Текст = СтрЗаменить(Текст, "≤", "&le");
	Text = StrReplace(Text, "≈", "&asymp;");
	Text = StrReplace(Text, "≠", "&ne;");
	Text = StrReplace(Text, "≡", "&equiv;");
	Text = StrReplace(Text, "§", "&sect;");
	Text = StrReplace(Text, "&", "&amp;");
	Text = StrReplace(Text, "∞", "&infin;");
	Return Text;
	
EndFunction

Function GetTypedValue(Val Value)
	
	ValueType = TypeOf(Value);
	If 	velpo_CommonFunctions.IsReference(ValueType) Then
		MetaValue = Value.Metadata();
		ValueStr = NormalizeString(ValueStr + Left(TrimL(String(Value)), 20) + "_" + String(Value.UUID()));
	Else
		ValueStr = XMLString(Value);
	EndIf;
	
	Return ValueStr;
	
EndFunction // GetTypedValue()


Function GetFactsTextQuery()

	Text = 
	"SELECT
	|	// 0 get instance
	|	Instances.Ref AS Instance
	|INTO
	|	VT_Instances
	|FROM
	|	Document.Instance AS Instances
	|WHERE
	|	Instances.Date = &Period
	|	AND Instances.BusinessUnit = &BusinessUnit
	|	AND Instances.Taxonomy = &Taxonomy
	|	AND Instances.EntryPoint = &EntryPoint
	|	AND 
	|		CASE
	|				WHEN &HasTableFilter THEN
	|					Instances.RoleTable IN (&RoleTableArray)
	|				ELSE
	|					TRUE
	|		END
	|INDEX BY
	|	Instance
	|;
	|SELECT
	|	// 1 periods
	|	InstancePeriods.PeriodID AS PeriodID,
	|	InstancePeriods.StartDate AS StartDate,
	|	InstancePeriods.EndDate AS EndDate,
	|	InstancePeriods.Instant AS Instant
	|INTO
	|	VT_Periods
	|FROM
	|	InformationRegister.InstancePeriods AS InstancePeriods
	|	
	|	INNER JOIN  VT_Instances AS Instances
	|	ON InstancePeriods.Instance = Instances.Instance
	|INDEX BY
	|	PeriodID	
	|;
	|SELECT
	|	// 2 instances
	|	InstanceRecords.Concept AS Concept,
	|	InstanceRecords.Unit AS Unit,
	|	InstanceRecords.Value AS Value,
	|	InstanceRecords.Text AS Text,
	|	InstanceRecords.ScenarioID AS ScenarioID,
	|	TablePeriods.StartDate AS StartDate,
	|	TablePeriods.EndDate AS EndDate,
	|	TablePeriods.Instant AS Instant,
	|	TablePeriods.PeriodID AS PeriodID
	|INTO
	|	VT_Records
	|FROM
	|	InformationRegister.InstanceRecords AS InstanceRecords
	|	
	|	INNER JOIN  VT_Instances AS TableInstances
	|	ON InstanceRecords.Instance = TableInstances.Instance
	|
	|	INNER JOIN  VT_Periods AS TablePeriods
	|	ON InstanceRecords.PeriodID = TablePeriods.PeriodID
	|INDEX BY
	|	ScenarioID,
	|	Instant,
	|	StartDate,
	|	EndDate
	|;
	|SELECT DISTINCT
	|	// 3 periods
	|	TableRecords.ScenarioID,
	|	TableRecords.Instant,
	|	TableRecords.StartDate,
	|	TableRecords.EndDate
	|INTO
	|	VT_RecordsScenarioPeriods
	|FROM
	|	VT_Records AS TableRecords
	|INDEX BY
	|	Instant,
	|	StartDate,
	|	EndDate,
	|	ScenarioID
	|;
	|SELECT
	|	// 4 scenarios
	|	InstanceScenarios.ScenarioID AS ScenarioID,
	|	InstanceScenarios.Axis AS Axis,
	|	InstanceScenarios.Value AS Value
	|INTO
	|	VT_Scenarios
	|FROM
	|	InformationRegister.InstanceScenarios AS InstanceScenarios
	|	
	|	INNER JOIN  VT_Instances AS TableInstances
	|	ON InstanceScenarios.Instance = TableInstances.Instance
	|INDEX BY
	|	ScenarioID
	|;
	|SELECT
	|	// 5 scenarios
	|	TableRecordsScenarioPeriods.ScenarioID AS ScenarioID,
	|	TableRecordsScenarioPeriods.Instant AS Instant,
	|	TableRecordsScenarioPeriods.StartDate AS StartDate,
	|	TableRecordsScenarioPeriods.EndDate AS EndDate,
	|	ISNULL(TableScenarios.Axis, VALUE(ChartOfCharacteristicTypes.HypercubeAxes.EmptyRef)) AS Axis,
	|	ISNULL(TableScenarios.Value, VALUE(Catalog.MemberValues.EmptyRef)) AS Value
	|INTO
	|	VT_ContextData
	|FROM
	|	VT_RecordsScenarioPeriods AS TableRecordsScenarioPeriods
	|
	|	LEFT JOIN VT_Scenarios AS TableScenarios
	|	ON TableRecordsScenarioPeriods.ScenarioID = TableScenarios.ScenarioID
	|INDEX BY
	|	ScenarioID,	
	|	Instant,
	|	StartDate,
	|	EndDate
	|;
	|SELECT
	|	// 6 context
	|	TableContextData.ScenarioID AS ScenarioID,
	|	TableContextData.Instant AS Instant,
	|	TableContextData.StartDate AS StartDate,
	|	TableContextData.EndDate AS EndDate,
	|	TableContextData.Axis AS Axis,
	|	TableContextData.Value AS Value,
	|	ISNULL(TableContextData.Axis.QName,"""") AS AxisQName,
	|	ISNULL(TableContextData.Value.QName, """") AS ValueQName,
	|	CASE
	|		WHEN TableContextData.Axis.HypercudeAxisType= VALUE(Enum.HypercubeAxisTypes.TypedDimension)
	|			THEN TRUE
	|		ELSE
	|			FALSE
	|	END IsTyped,
	|	ISNULL(TableContextData.Axis.DataType.QName, """") AS TypedName
	|FROM
	|	VT_ContextData AS TableContextData
	|;
	|SELECT
	|	// 7 records
	|	TableRecords.ScenarioID AS ScenarioID,
	|	ISNULL(TableRecords.Concept.DataType.BaseType, VALUE(Enum.BaseDataTypes.String)) AS BaseType,
	|	ISNULL(TableRecords.Concept.QName, """") AS ConceptQName,
	|	TableRecords.Concept AS Concept,
	|	TableRecords.Unit AS Unit,
	|	TableRecords.Value AS Value,
	|	ISNULL(TableRecords.Value.QName, """") AS ValueQName,
	|	TableRecords.Text AS Text,
	|	TableRecords.Instant AS Instant,
	|	TableRecords.StartDate AS StartDate,
	|	TableRecords.EndDate AS EndDate
	|FROM
	|	VT_Records AS TableRecords
	|;
	|SELECT DISTINCT
	|	// 8 distinct scenarios
	|	TableContextData.ScenarioID AS ScenarioID,
	|	TableContextData.Instant AS Instant,
	|	TableContextData.StartDate AS StartDate,
	|	TableContextData.EndDate AS EndDate
	|FROM
	|	VT_ContextData AS TableContextData
	|;
	|SELECT DISTINCT
	|	// 9 distinct axis
	|	Axis
	|FROM
	|	VT_ContextData
	|";	
	
	Return Text;
	
EndFunction // GetTableTextQuery() 

Procedure WriteXBRLDeclaration(TextWriter)

	TextWriter.WriteLine("<?xml version=""1.0"" encoding=""utf-8""?>");
	TextWriter.WriteLine("<?instance-generator id=""Velpo.FinancialAccounting.XBRL"" creationdate=""" + XMLString(CurrentDate()) + """?>");
	TextWriter.WriteLine("<xbrli:xbrl xmlns:link=""http://www.xbrl.org/2003/linkbase"" xmlns:xbrldt=""http://xbrl.org/2005/xbrldt"" xmlns:xbrli=""http://www.xbrl.org/2003/instance"" xmlns:xbrldi=""http://xbrl.org/2006/xbrldi"" xmlns:xlink=""http://www.w3.org/1999/xlink"" xmlns:iso4217=""http://www.xbrl.org/2003/iso4217"" xmlns:ins-dic=""http://www.cbr.ru/xbrl/nso/ins/dic/ins-dic"" xmlns:nfo-dic=""http://www.cbr.ru/xbrl/nso/nfo/dic"" xmlns:dim-int=""http://www.cbr.ru/xbrl/udr/dim/dim-int"" xmlns:mem-int=""http://www.cbr.ru/xbrl/udr/dom/mem-int"" xmlns:ifrs-full=""http://xbrl.ifrs.org/taxonomy/2015-03-11/ifrs-full"" xmlns:ifrs-ru=""http://www.cbr.ru/xbrl/bfo/dict"" xmlns:cbr-coa-dic=""http://www.cbr.ru/xbrl/eps/cbr-coa"">");
	
	EntryPointName = velpo_CommonFunctions.ObjectAttributeValue(ThisObject.EntryPoint, "Name");
	
	If ThisObject.DebugMode Then
		TextWriter.WriteLine("	<link:schemaRef xlink:type=""simple"" xlink:href=""c:\velpo\taxonomies\final_4_0\www.cbr.ru\xbrl\nso\ins\rep\2021-04-01\ep\" + EntryPointName + ".xsd""/>");	
	Else
		TextWriter.WriteLine("	<link:schemaRef xlink:type=""simple"" xlink:href=""http://www.cbr.ru/xbrl/nso/ins/rep/2021-04-01/ep/" + EntryPointName + ".xsd""/>");	
	EndIf;

EndProcedure // WriteXBRLDeclaration()

Procedure WriteXBRLUnits(TextWriter)

	TextWriter.WriteLine("	<xbrli:unit id=""pure"">");
	TextWriter.WriteLine("		<xbrli:measure>xbrli:pure</xbrli:measure>");
	TextWriter.WriteLine("	</xbrli:unit>");
	TextWriter.WriteLine("	<xbrli:unit id=""RUB"">");
	TextWriter.WriteLine("		<xbrli:measure>iso4217:RUB</xbrli:measure>");
	TextWriter.WriteLine("	</xbrli:unit>");

EndProcedure // WriteXBRLDeclaration()

Procedure WriteXBRLContext(TextWriter)
	
	Counter = 0;
	
	For Each ContextLine In SettingsVar.ContextTable Do
	
		Counter = Counter + 1;
		ContextLine.Context = "ctx" + Format(Counter, "NG=");
		
		SettingsVar.ContextMap.Insert(ContextLine.NumberID, ContextLine.Context);
		
		TextWriter.WriteLine("	<xbrli:context id=""" + ContextLine.Context + """>");
    	TextWriter.WriteLine("		<xbrli:entity>");
    	TextWriter.WriteLine("  			<xbrli:identifier scheme=""http://www.cbr.ru"">" + SettingsVar.Identifier + "</xbrli:identifier>");
    	TextWriter.WriteLine("		</xbrli:entity>");
		
		If ValueIsFilled(ContextLine.Instant) Тогда
			TextWriter.WriteLine("		<xbrli:period>");
    		TextWriter.WriteLine("  			<xbrli:instant>" + Format(ContextLine.Instant, "ДФ=yyyy-MM-dd") + "</xbrli:instant>");
    		TextWriter.WriteLine("		</xbrli:period>");
		Else
    		TextWriter.WriteLine("		<xbrli:period>");
      		TextWriter.WriteLine("			<xbrli:startDate>" + Format(ContextLine.StartDate, "DF=yyyy-MM-dd") + "</xbrli:startDate>");
      		TextWriter.WriteLine("			<xbrli:endDate>" + Format(ContextLine.EndDate, "DF=yyyy-MM-dd") + "</xbrli:endDate>");
    		TextWriter.WriteLine("		</xbrli:period>");
		EndIf;
		
		FilterStructure = New Structure("ScenarioID, Instant, StartDate, EndDate");
		FillPropertyValues(FilterStructure, ContextLine); 
		ContexArray = SettingsVar.ContextDataTable.FindRows(FilterStructure);
	
		Если ContexArray.Count() > 0 And ValueIsFilled(ContexArray[0].Axis) Then
			TextWriter.WriteLine("		<xbrli:scenario>");
			For Each ContextLine In ContexArray Do
				
				If Not ValueIsFilled(ContextLine.Value) Then
					velpo_CommonFunctionsClientServer.MessageToUser(
						NStr("en = 'error.'; ru = 'Не указано обязательное поле в контексте '") + String(ContextLine.Axis));
					ContextLine.Value = "______ОШИБКА!!!!_______";
					ContextLine.ValueQName = "______ОШИБКА!!!!_______";
				EndIf;
				
				If ContextLine.IsTyped Then
					TextWriter.ЗаписатьСтроку("		<xbrldi:typedMember dimension=""" + ContextLine.AxisQName + """>");
					If ValueIsFilled(ContextLine.ValueQName) Then
						TextWriter.WriteLine("			<" + ContextLine.TypedName + ">" + ContextLine.ValueQName + "</" + ContextLine.TypedName + ">");
					Else
						TextWriter.WriteLine("			<" + ContextLine.TypedName + ">" + GetTypedValue(ContextLine.Value) + "</" + ContextLine.TypedName + ">");
					EndIf;
      				TextWriter.WriteLine("		</xbrldi:typedMember>");
				Else
					TextWriter.WriteLine("  			<xbrldi:explicitMember dimension=""" + ContextLine.AxisQName + """>" + ContextLine.ValueQName + "</xbrldi:explicitMember>");
				EndIf;
			EndDo;
    		TextWriter.WriteLine("		</xbrli:scenario>");
		КонецЕсли;
  		TextWriter.WriteLine("	</xbrli:context>");
	EndDo; 
	   	
EndProcedure

Procedure WriteXBRLFacts(TextWriter)
	
	FilterStructure = New Structure("ScenarioID, Instant, StartDate, EndDate");
	
	For Each RecordLine In SettingsVar.RecordsTable  Do
		
		FillPropertyValues(FilterStructure, RecordLine); 
		
		RemapArray = SettingsVar.RemapTable.FindRows(FilterStructure);
		Context = SettingsVar.ContextMap[RemapArray[0].NumberID];
		
		ConceptData =  SettingsVar.ConceptMap[RecordLine.Concept];
		If ConceptData = Undefined Then
			ConceptData = New Map;
			SettingsVar.ConceptMap.Insert(RecordLine.Concept, ConceptData);
		Else
			ContextData = ConceptData[Context];
			If ContextData <> Undefined Then
				Continue;
			EndIf;
		EndIf;
		
		ConceptData.Insert(Context, Context);
		
		If RecordLine.BaseType = Enums.velpo_BaseDataTypes.MonetaryItemType Then
			If RecordLine.Value = 0 Then
				Continue;
			EndIf;
			TextWriter.WriteLine("	<" + RecordLine.ConceptQName + " decimals=""2"" contextRef=""" + Context + """ unitRef=""RUB"">" + Format(RecordLine.Value, "NFD=2; NDS=.; NG=") + "</" + RecordLine.ConceptQName +">");
		ElsIf RecordLine.BaseType = Enums.velpo_BaseDataTypes.sharesItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.percentItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.perShareItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.decimalItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.floatItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.float
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.intItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.integerItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.int
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.integer Then
			If RecordLine.Value = 0 Then
				Continue;
			EndIf;
			TextWriter.WriteLine("	<" + RecordLine.ConceptQName + " decimals=""0"" contextRef=""" + Context + """ unitRef=""pure"">" + XMLСтрока(RecordLine.Value) + "</" + RecordLine.ConceptQName +">");
		ElsIf RecordLine.BaseType = Enums.velpo_BaseDataTypes.dateItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.date Тогда
			If RecordLine.Value = '0001-01-01' Then
				Continue;
			EndIf;
			TextWriter.WriteLine("	<" + RecordLine.ConceptQName + " contextRef=""" + Context  + """>" + Format(RecordLine.Value, "DF=yyyy-MM-dd") + "</" + RecordLine.ConceptQName +">");
		ElsIf RecordLine.BaseType = Enums.velpo_BaseDataTypes.dateTimeItemType
			OR RecordLine.BaseType = Enums.velpo_BaseDataTypes.dateTime Тогда
			If RecordLine.Value = '0001-01-01' Then
				Continue;
			EndIf;
			TextWriter.WriteLine("	<" + RecordLine.ConceptQName + " contextRef=""" + Context  + """>" + XMLString(RecordLine.Value) + "</" + RecordLine.ConceptQName +">");
		ИначеЕсли RecordLine.BaseType = Enums.velpo_BaseDataTypes.enumerationItemType Тогда
			If ValueIsFilled(RecordLine.Value) Then
				TextWriter.WriteLine("	<" + RecordLine.ConceptQName + " contextRef=""" +  Context + """>" + RecordLine.ValueQName + "</" + RecordLine.ConceptQName +">");
			EndIf;
		Иначе
			If Not ValueIsFilled(RecordLine.Value) Then
				Continue;
			EndIf;
			If ValueIsFilled(RecordLine.Text) Then
				TextWriter.WriteLine("	<" + RecordLine.ConceptQName + " contextRef=""" + Context + """>" + NormalizeString(XMLString(RecordLine.Text)) + "</" + RecordLine.ConceptQName +">");
			Else
				TextWriter.WriteLine("	<" + RecordLine.ConceptQName + " contextRef=""" + Context + """>" + NormalizeString(GetTypedValue(RecordLine.Value)) + "</" + RecordLine.ConceptQName +">");
			EndIf;
		КонецЕсли;
		
	EndDo;  
	
КонецПроцедуры // ЗаписатьПоказательXBRL()

Procedure RemapScenario()

	AxisMap = New Map;
	
	RemapTable = New ValueTable;
	RemapTable.Columns.Add("NumberID", velpo_CommonFunctions.NumberTypeDescription(10));
	RemapTable.Columns.Add("ScenarioID", New TypeDescription("UUID"));
	RemapTable.Columns.Add("Instant", velpo_CommonFunctions.DateTypeDescription(DateFractions.DateTime));
	RemapTable.Columns.Add("StartDate", velpo_CommonFunctions.DateTypeDescription(DateFractions.DateTime));
	RemapTable.Columns.Add("EndDate", velpo_CommonFunctions.DateTypeDescription(DateFractions.DateTime));
	
	IndexString = "NumberID,Instant,StartDate,EndDate";
	SelectString = "VT.NumberID,VT.Instant,VT.StartDate,VT.EndDate,VT.ScenarioID";
	JoinString = "VT.Instant=VT2.Instant AND VT.StartDate=VT2.StartDate AND VT.EndDate=VT2.EndDate";
	
	i = 0;
	For Each AxisLine In SettingsVar.AxisTable Do
		i = i + 1;
		Index ="Axis_" + Format(i, "NG=");
		AxisMap.Insert(AxisLine.Axis, Index);
		RemapTable.Columns.Add(Index, velpo_TaxonomyUpdateServerCashed.GetAllTypes());
		IndexString = IndexString + "," + Index;
		SelectString = SelectString + ",VT." + Index;
		JoinString = JoinString + " AND VT." + Index + "=VT2." + Index;
	EndDo; 
	
	FilterStructure = New Structure("ScenarioID, Instant, StartDate, EndDate");
	
	i = 0;
	For Each ScenarioLine In SettingsVar.ContextIDTable Do
		i = i + 1;
		FillPropertyValues(FilterStructure, ScenarioLine);
		ContextArray = SettingsVar.ContextDataTable.FindRows(FilterStructure);
		RemapLine = RemapTable.Add();
		RemapLine.NumberID = i;
		FillPropertyValues(RemapLine, ScenarioLine); 
		For Each ContextLine In ContextArray Do
			For 	Each AxisData In AxisMap Do
				If ContextLine.Axis = AxisData.Key Then
					RemapLine[AxisData.Value] = ContextLine.Value;
				EndIf;
			EndDo;
		EndDo; 
	EndDo;
	
	Query = New Query;
	Query.SetParameter("RemapTable", RemapTable);
	Query.Text =
	"SELECT
	|	// 0
	|	" + SelectString + "
	|INTO
	|	VT_RemapTable
	|FROM
	|	&RemapTable AS VT
	|;
	|SELECT
	|	// 1
	|" + SelectString + "
	|INTO
	|	VT_DistinctRemap
	|FROM
	|	VT_RemapTable AS VT
	|
	|	LEFT JOIN  VT_RemapTable AS VT2
	|	ON " + JoinString + "
	|		AND VT.NumberID < VT2.NumberID
	|WHERE
	|	VT2.NumberID IS NULL
	|;
	|SELECT
	|	// 2
	|	VT.ScenarioID AS ScenarioID,
	|	VT.Instant AS Instant,
	|	VT.StartDate AS StartDate,
	|	VT.EndDate AS EndDate,
	|	VT2.NumberID AS NumberID
	|FROM
	|	VT_RemapTable AS VT
	|
	|	INNER JOIN VT_DistinctRemap AS VT2
	|	ON " + JoinString + "
	|;
	|SELECT
	|	// 3
	|	VT.NumberID AS NumberID,
	|	VT.ScenarioID AS ScenarioID,
	|	VT.Instant AS Instant,
	|	VT.StartDate AS StartDate,
	|	VT.EndDate AS EndDate
	|FROM
	| VT_DistinctRemap AS VT
	|ORDER BY
	|	Instant ASC,
	|	StartDate ASC,
	|	EndDate ASC
	|";
	
	ResultArray = Query.ExecuteBatch();
	
	RemapTable = ResultArray[2].Unload();
	RemapTable.Indexes.Add("ScenarioID, Instant, StartDate, EndDate");
	
	ContextTable = ResultArray[3].Unload();
	ContextTable.Columns.Add("Context", velpo_CommonFunctions.StringTypeDescription("500"));
	ContextTable.Indexes.Add("NumberID");
	
	SettingsVar.Insert("RemapTable", RemapTable);
	SettingsVar.Insert("ContextTable", ContextTable);
			
EndProcedure

Procedure SetSettings()

	SettingsVar = New Structure;
	
	Query = New Query;
	Query.SetParameter("Period", ThisObject.Period);
	Query.SetParameter("BusinessUnit", ThisObject.BusinessUnit);
	Query.SetParameter("Taxonomy", ThisObject.Taxonomy);
	Query.SetParameter("EntryPoint", ThisObject.EntryPoint);
	Query.Text = GetFactsTextQuery(); 
	
	RoleTableArray = New Array;
	For Each RoleItem In ThisObject.RoleTablesList  Do
		If RoleItem.Check Then
			RoleTableArray.Add(RoleItem.Value);
		EndIf;
	EndDo; 
	Query.SetParameter("RoleTableArray", RoleTableArray);
	Query.SetParameter("HasTableFilter", (RoleTableArray.Count() > 0));
	
	ResultArray = Query.ExecuteBatch();
	
	ContextDataTable = ResultArray[6].Unload(QueryResultIteration.Linear);
	ContextDataTable.Indexes.Add("ScenarioID, Instant, StartDate, EndDate");
	
	RecordsTable = ResultArray[7].Unload(QueryResultIteration.Linear);
	
	ContextIDTable = ResultArray[8].Unload(QueryResultIteration.Linear);
	
	AxisTable = ResultArray[9].Unload(QueryResultIteration.Linear);
	
	SettingsVar.Insert("ContextDataTable", ContextDataTable);
	SettingsVar.Insert("RecordsTable", RecordsTable);
	SettingsVar.Insert("ContextIDTable", ContextIDTable);
	SettingsVar.Insert("AxisTable", AxisTable);
	SettingsVar.Insert("RemapTable", New ValueTable);
	SettingsVar.Insert("ContextTable", New ValueTable);
	SettingsVar.Insert("ContextMap", New Map);
	SettingsVar.Insert("ConceptMap", New Map);
	SettingsVar.Insert("Identifier", velpo_CommonFunctions.ObjectAttributeValue(ThisObject.BusinessUnit, "Identifier"));
	
EndProcedure

Function UnloadInstance() Export
	
	// 1 setting up 
	SetSettings();
	
	// 2 remap
	RemapScenario();
	
	// 3 start text object
	ThisObject.PathToServerTempFile= GetTempFileName("xbrl");
	FileStream = New FileStream(ThisObject.PathToServerTempFile, FileOpenMode.Create);
	TextWriter = New TextWriter(FileStream, TextEncoding.UTF8);
	
	// 4 declaration
	WriteXBRLDeclaration(TextWriter);
	
	// 5 context
	WriteXBRLContext(TextWriter);
	
	// 6 units
	WriteXBRLUnits(TextWriter);
	
	// 7 units
	WriteXBRLFacts(TextWriter);
	
	// 8 end 
	TextWriter.WriteLine("</xbrli:xbrl>");
	TextWriter.Close();
	FileStream.Закрыть();
	TextWriter = Undefined;
	FileStream = Undefined;
	
	// 9 return
	BinaryData = New BinaryData(ThisObject.PathToServerTempFile); 
	Return PutToTempStorage(BinaryData);
	
EndFunction // UnloadInstance()

 
