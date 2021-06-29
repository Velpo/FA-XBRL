///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////

&AtServer
Procedure GenerateDataAtServer()
	
	Obj = ThisForm.FormAttributeToValue("Object");
	
	If Object.ByQuater Then
		CurrentEndPeriod = EndOfQuarter(Object.BeginOfPeriod);
		EndOfPeriod = EndOfDay(Object.EndOfPeriod);
		While CurrentEndPeriod <= EndOfPeriod Do
			Obj = ThisForm.FormAttributeToValue("Object");
			Obj.BeginOfPeriod = BegOfQuarter(CurrentEndPeriod);
			Obj.EndOfPeriod = CurrentEndPeriod;
			Obj.GenerateData();
			CurrentEndPeriod = EndOfQuarter(CurrentEndPeriod + 1);
		EndDo;
	Else
		Obj = ThisForm.FormAttributeToValue("Object");
		Obj.GenerateData();
	EndIf;
	
EndProcedure

&AtClient
Procedure GenerateData(Command)
	GenerateDataAtServer();
	Предупреждение("Формирование выполнено!");
EndProcedure

&AtClient
Procedure PreviousMonth(Команда)
	Object.BeginOfPeriod = BegOfMonth(AddMonth(Object.BeginOfPeriod, -1));
	Object.EndOfPeriod = EndOfMonth(AddMonth(Object.EndOfPeriod, -1));
EndProcedure

&AtClient
Procedure NextMonth(Команда)
	Object.BeginOfPeriod = BegOfMonth(AddMonth(Object.BeginOfPeriod, 1));
	Object.EndOfPeriod = EndOfMonth(AddMonth(Object.EndOfPeriod, 1));
EndProcedure

