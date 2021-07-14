
&AtServer
Procedure SetConceptValueList()

	Items.ConceptLinksValue.ChoiceList.Clear();
	Items.ConceptLinksValue.ListChoiceMode = False;
	
	If ValueIsFilled(Object.DataType) Then
		Query = New Query;
		Query.SetParameter("DataType", Object.DataType);
		Query.Text =
		"SELECT
		|	Member
		|FROM
		|	ChartOfCharacteristicTypes.ConceptValueTypes.Members
		|WHERE
		|	Ref = &DataType
		|";
		MemberValues = Query.Execute().Unload().UnloadColumn("Member");
		If MemberValues.Count() > 0 Then
			Items.ConceptLinksValue.ChoiceList.LoadValues(MemberValues);
			Items.ConceptLinksValue.ListChoiceMode = True;
		EndIf;
		
	EndIf;

EndProcedure // SetConceptValueList()

&AtServer
Procedure SetConceptValueType()

	If ValueIsFilled(Object.Concept) Then
		Object.DataType = velpo_CommonFunctions.ObjectAttributeValue(Object.Concept, "DataType");
	Else
		Object.DataType = Undefined;
	EndIf; 

	SetConceptValueList();
	
EndProcedure // SetConceptValueType()

&AtServer
Procedure OnCreateAtServer(Cancel, StandardProcessing)
	
	If Object.Ref.IsEmpty() AND ValueIsFilled(Parameters.Result) Then
		Object.AxisType = Parameters.AxisType;
		Object.Concept = Parameters.Concept;
		Object.Result = Parameters.Result;
		Object.Owner = Parameters.Field;
		If ValueIsFilled(Object.Concept) Then
			Object.LinkType = Enums.velpo_FieldQueryLinkTypes.Concept;
			Object.AxisType =  Undefined;
		Else
			Object.LinkType = Enums.velpo_FieldQueryLinkTypes.AxisType;
			Object.Concept =  Undefined;
		EndIf;
		SetConceptValueType();
	Else
		SetConceptValueList();
	EndIf;
			
EndProcedure

&AtClient
Procedure AfterWrite(WriteParameters)
	
	Notify("NewLink", Object.Ref);
	
EndProcedure

&AtClient
Procedure ConceptOnChange(Item)
	
	SetConceptValueType();
	
EndProcedure

&AtClient
Procedure ConceptValueTypeOnChange(Item)
	
	SetConceptValueList();
	
EndProcedure

&AtClient
Procedure ConceptLinksBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	Object.UseSourceValue = False;
	
EndProcedure

&AtClient
Procedure AxisLinksBeforeEditEnd(Item, NewRow, CancelEdit, Cancel)
	
	Object.UseSourceValue = False;
	
EndProcedure



&НаСервере
Процедура AutofillНаСервере()
	
	Query = New Query;
	Query.SetParameter("AxisType", Object.AxisType);
	Query.Text  =
	"SELECT
	|	Ref AS Axis, 
	|	Description
	|FROM
	|	Catalog.DomainMembers
	|WHERE
	|	Owner = &AxisType
	|";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		AxisLinksLine = Object.AxisLinks.Add();
		AxisLinksLine.Axis = Selection.Axis;
		FieldValue = "";
		Len = StrLen(Selection.Description);
		For i = 1 To Len Do
			Letter = Mid(Selection.Description, i, 1);
			If СтрНайти("0123456789", Letter) > 0 Then
				FieldValue = FieldValue + Letter;
			Else
				Break;
			EndIf;
		EndDo;
		AxisLinksLine.FieldValue = FieldValue;
	EndDo;
		
КонецПроцедуры

&НаКлиенте
Процедура Autofill(Команда)
	AutofillНаСервере();
КонецПроцедуры

&НаКлиенте
Процедура LoadFromValueList(Команда)

	ОткрытьФорму("Справочник.FieldQueryLinks.Форма.LoadFromValueList",, ThisForm);
	
КонецПроцедуры

&НаКлиенте
Процедура ОбработкаОповещения(ИмяСобытия, Параметр, Источник)
	
	If ИмяСобытия = "LoadFromValueList" Then
		For Each FilterLine In Параметр Do
			Line = Object.FieldFilters.Add();
			FillPropertyValues(Line, FilterLine);
		EndDo;
	EndIf;
	
КонецПроцедуры

&НаСервере
Процедура AutofillConceptsНаСервере()
	
		Query = New Query;
		Query.SetParameter("DataType", Object.DataType);
		Query.Text =
		"SELECT
		|	Member
		|FROM
		|	ChartOfCharacteristicTypes.ConceptValueTypes.Members
		|WHERE
		|	Ref = &DataType
		|";
		MemberValues = Query.Execute().Unload().UnloadColumn("Member");
		If MemberValues.Count() > 0 Then
			
			For each Member In MemberValues Do
				AxisLinksLine = Object.ConceptLinks.Add();
				AxisLinksLine.FieldValue = TrimAll(String(Member));
				AxisLinksLine.Value = Member;
			EndDo;
			
		EndIf;

		
КонецПроцедуры

&НаКлиенте
Процедура AutofillConcepts(Команда)
	AutofillConceptsНаСервере();
КонецПроцедуры
