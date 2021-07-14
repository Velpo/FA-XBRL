///////////////////////////////////////////////////////////////////////////////////////////////////////
// FA-XBRL, Bookkeeping and XBRL proccessor
//
// @author: Paul Tarasov
//	@email: paul.tarasov@velpo.ru
// 
// Copyright (c) 2021 Paul Tarasov (Velpo)
///////////////////////////////////////////////////////////////////////////////////////////////////////


Procedure BeforeWrite(Cancel, WriteMode, PostingMode)

	ThisObject.User = InfoBaseUsers.CurrentUser().Name;
	ThisObject.ChangeDate = CurrentDate();
	
EndProcedure
