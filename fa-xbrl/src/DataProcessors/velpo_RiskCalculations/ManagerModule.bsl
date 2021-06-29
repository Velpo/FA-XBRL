///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

#If Server Or ThickClientOrdinaryApplication Or ExternalConnection Then

#Region Public

Procedure AddDynamicListColumns(List, AccountStructure, ColumnArray) Export
	
	Form = List.Parent;
	ListName = List.Name;
	ManagedFormType = Type("ManagedForm");
	BooleanType = Type("Boolean");
	NumberType = Type("Number");
	
	While TypeOf(Form) <> ManagedFormType Do
		Form = Form.Parent;
	EndDo;
	
	For Each ColumnName In ColumnArray Do
		
		ColumnData = AccountStructure[ColumnName];
		
		ColumnElement = Form.Items.Add(ListName + ColumnName, Type("FormField"), List);
		ColumnElement.Title = ColumnData.Description;
		ColumnElement.DataPath = ListName + "." + ColumnName;
		
		If Not ListName = "BalanceData" Then
			ColumnElement.MarkNegatives = True;
		EndIf;
		
		ColumnElement.ShowInHeader = True;				
		ColumnElement.HeaderHorizontalAlign = ItemHorizontalLocation.Center;
		ColumnElement.FooterHorizontalAlign = ItemHorizontalLocation.Right;
				
		If  ColumnData.ValueType.ContainsType(NumberType) Then
			NumberQualifiers = ColumnData.ValueType.NumberQualifiers;
			FormatText = ?(ListName = "BalanceData", "NN=0; ", "") + "ND=" + String(NumberQualifiers.Digits) +  "; NFD=" + String(NumberQualifiers.FractionDigits);
		    ColumnElement.Format = FormatText;
			If (ListName = "OwnFundData" Or ListName = "BalanceData") And ColumnData.IsCalculation Then
				ColumnElement.FooterDataPath = ColumnName + "_Footer";
			EndIf;
		ElsIf ColumnData.ValueType.ContainsType(BooleanType) Then
			ColumnElement.Format = "BF=";
		EndIf; 
	
		ColumnElement.ToolTip = ColumnData.Description;
		If ColumnData.IsCalculation Then
			ColumnElement.BackColor = StyleColors.ImportantColor;
			ColumnElement.TitleBackColor = StyleColors.ImportantColor;
		ElsIf ColumnData.IsUnload Then
			ColumnElement.BackColor = StyleColors.NavigationColor;
			ColumnElement.TitleBackColor = StyleColors.NavigationColor;
		Else
			ColumnElement.BackColor = StyleColors.ReportGroup2BackColor;
		EndIf;
		
	EndDo;

EndProcedure

#EndRegion

#Region Private


#EndRegion

#EndIf