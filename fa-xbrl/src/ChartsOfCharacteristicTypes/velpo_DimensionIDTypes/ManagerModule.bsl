///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

Procedure SetDeletionMarkForItems(Ref) Export

	Query = New Query;
	Query.SetParameter("Ref", Ref);
	Query.Text = 
	"SELECT
	|	SourceQueryComponents.Ref AS Ref
	|FROM
	|	ChartOfCharacteristicTypes.SourceQueryComponents AS SourceQueryComponents
	|WHERE
	|	SourceQueryComponents.Ref IN HIERARCHY(&Ref)
	|	AND SourceQueryComponents.Ref <> &Ref
	|	AND SourceQueryComponents.DeletionMark = FALSE
	|";
	Selection = Query.Execute().Select();
	While Selection.Next() Do
		Obj = Selection.Ref.GetObject();
		If Not Obj.DeletionMark Then
			Obj.SetDeletionMark(True, True);
		EndIf;
	EndDo;

EndProcedure
