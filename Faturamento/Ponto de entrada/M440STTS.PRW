#INCLUDE "rwmake.ch"
#INCLUDE "PROTHEUS.CH"
#include "topconn.ch"

/*CRIAR CAMPO C5_PEDFIL*/
USER FUNCTION M440STTS()
	Local _lRet 		:= .T.
	Local _nx			:= 1
	Local nPosLib  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_QTDLIB" })
	Local nPosVen  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_QTDVEN" })
	Local nPosPrc  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_PRCVEN" })
	Local nPosUni  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_PRUNIT" })
	Local nPosTes  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_TES"    })
	Local nPosPro  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_PRODUTO"})
	Local nPosIte  	:= Ascan(Aheader,{|x| AllTrim(x[2]) == "C6_ITEM"   })
	Private lMsErroAuto := .F.
	Private lMsHelpAuto := .T.
	Private _aCabec 	:= {}
	Private _aItens 	:= {}
	Private _nItem		:= "01"
	Private _cPedido 	:= SC5->C5_NUM
	Private _cTabela 	:= SC5->C5_TABELA
	Private _cCliente	:= SC5->C5_CLIENTE
	Private _cLoja		:= SC5->C5_LOJACLI
	Private _cLojaEnt	:= SC5->C5_LOJAENT
	Private _cCodPag	:= SC5->C5_CONDPAG
	Private _cTpFrete	:= SC5->C5_TPFRETE
	If SC5->C5_TIPO = "N"
		For _nx:=1 To Len(aCols)
			If aCols[_nx,nPosLib] < aCols[_nx,nPosVen] .And. aCols[_nx,nPosVen]-aCols[_nx,nPosLib] > 0
				DbSelectArea("SC6")
				DbSeek(xFilial("SC6")+SC5->C5_NUM+aCols[_nx,nPosIte]+aCols[_nx,nPosPro])
				If Found()
					_aLinha := {}
					aadd(_aLinha,{"C6_ITEM"	 	,_nItem									,Nil})
					aadd(_aLinha,{"C6_PRODUTO"	,SC6->C6_PRODUTO						,Nil})
					aadd(_aLinha,{"C6_QTDVEN" 	,aCols[_nx,nPosVen]-aCols[_nx,nPosLib]	,Nil})
					aadd(_aLinha,{"C6_PRCVEN"	,aCols[_nx,nPosPrc]						,Nil})
					aadd(_aLinha,{"C6_PRUNIT" 	,aCols[_nx,nPosUni]						,Nil})
					aadd(_aLinha,{"C6_VALOR"  	,(aCols[_nx,nPosVen]-aCols[_nx,nPosLib])*A410Arred(aCols[_nx,nPosPrc],"C6_PRCVEN"),Nil})
					aadd(_aLinha,{"C6_TES"   	,aCols[_nx,nPosTes]					     ,Nil})
					aadd(_aItens,_aLinha)
					_nItem := soma1(_nItem)
					If aCols[_nx,nPosLib] > 0
						aCols[_nx,nPosVen] := aCols[_nx,nPosLib]
						DbSelectArea("SC6")
						DbSeek(xFilial("SC6")+SC5->C5_NUM+aCols[_nx,nPosIte]+aCols[_nx,nPosPro])
						If Found()
							RecLock("SC6",.F.)
							SC6->C6_QTDVEN := aCols[_nx,nPosLib]
							SC6->(MsUnlock())
						EndIf
					Else
						DbSelectArea("SC6")
						DbSeek(xFilial("SC6")+SC5->C5_NUM+aCols[_nx,nPosIte]+aCols[_nx,nPosPro])
						If Found()
							RecLock("SC6",.F.)
							SC6->(DbDelete())
							SC6->(MsUnlock())
						EndIf
					EndIf
					_aSc6Tmp := SC6->(GetArea())
					DbSelectArea("SC9")
					SC9->(DbSetOrder(1))
					SC9->(DbSeek(xFilial("SC9")+SC6->C6_NUM))
					Do While !SC9->(EOF()) .And. SC9->C9_FILIAL+SC9->C9_PEDIDO == xFilial("SC9")+SC6->C6_NUM
						if SC9->C9_PEDIDO = SC6->C6_NUM .AND. SC9->C9_ITEM = SC6->C6_ITEM .AND. SC9->C9_PRODUTO = SC6->C6_PRODUTO
							Begin Transaction
								SC9->(a460Estorna())
							End Transaction
						EndIf
						SC9->(DBSKIP())
					EndDo
					RestArea(_aSc6Tmp)
				EndIf
			EndIf
		Next
		If Len(_aLinha) > 0
			AbreTela()
			FWMsgRun(, {|oSay| GeraPed() }, "Processando", "Criando Pedido Filho")
		EndIf
	EndIf
Return(_lRet)

Static Function AbreTela()
	Local _nx			:= 1
	Local _lRet			:= .F.
	Private aObjects   	:= {}
	Private aPosObj 	:= {}
	Private aSize      	:= MsAdvSize()
	Private aInfo      	:= {aSize[1],aSize[2],aSize[3],aSize[4],3,3}
	aPosObj:=MsObjSize(aInfo,aObjects)
	If Select("_TAB1") > 0
		DbSelectArea("_TAB1")
		_TAB1->(DbCloseArea())
	EndIf
	DbSelectArea("SX3")
	DbSetOrder(2)
	DbSeek("ZA3_MOTIVO") ; AADD(_aCampos,{ "Moti", SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL} )
	DbSeek("ZA3_DESC")   ; AADD(_aCampos,{ "Dmot", SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL} )
	DbSeek("C6_PRODUTO") ; AADD(_aCampos,{ "Prod", SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL} )
	DbSeek("B1_DESCRI")  ; AADD(_aCampos,{ "Desc", SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL} )
	DbSeek("C6_QTDVEN")  ; AADD(_aCampos,{ "Qtde", SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL} )
	DbSeek("C6_PRCVEN")  ; AADD(_aCampos,{ "Prcv", SX3->X3_TIPO, SX3->X3_TAMANHO, SX3->X3_DECIMAL} )
	oTempTable:= FWTemporaryTable():New( "_TAB1" )
	oTempTable:SetFields( _aCampos )
	oTempTable:AddIndex("INDEX1", {"Prod"} )
	oTempTable:Create()

	AADD(aObjects,{1,030,.T.,.F.,.F.})
	AADD(aObjects,{1,100,.T.,.T.,.F.})
	aPosObj:=MsObjSize(aInfo,aObjects)

	Define msdialog _oDlgFS title "Motivo" From 0,0 TO (aPosObj[2,3]/3)/2-10 ,(aPosObj[2,4]/2)/2+2 //of oMainWnd pixel

	//@ (aSize[6] /2 ) - 18, aPosObj[2,4]-165 	BUTTON oBtnFe PROMPT "&Logs ACD."				SIZE 50,15 PIXEL ACTION ( U_MZ_Z09(), _lRett := .T., _oDlgFS:End() ) OF _oDlgFS
	//@ (aSize[6] /2 ) - 18, aPosObj[2,4]-110 	BUTTON oBtnFe PROMPT "&Manutencao Eventos."		SIZE 50,15 PIXEL ACTION ( U_MZ_Z07(), _lRett := .T., _oDlgFS:End() ) OF _oDlgFS
	//@ (aSize[6] /2 ) - 18, aPosObj[2,4]-055 	BUTTON oBtnFe PROMPT "&Manutencao Prior."		SIZE 50,15 PIXEL ACTION ( U_MZ_Z08(), _lRett := .T., _oDlgFS:End() ) OF _oDlgFS

	//@ 001,aPosObj[2,4]-250 Say "Duplo Click para alterar prioridade" COLORS CLR_RED,CLR_WHITE FONT oFont OF _oDlgFS PIXEL
	//@ 006,aPosObj[2,4]-250 Say "Duplo Click no Pedido, para voltar à SEPARACAO" COLORS CLR_RED,CLR_WHITE FONT oFont OF _oDlgFS PIXEL
	//@ 003,085 Say "Pedido?" OF _oDlgFS PIXEL
	//@ 001,115 get _cFilProd Valid (_lRett := .T., _oDlgFS:End()) Size 50, 10 object _oProd

	//TBtnBmp2():New(01,350,50,25,'CANCEL' 					,,,,{||( _cFilProd:=Space(07), _lRett := .T., _oDlgFS:End())},_oDlgFS,"Limpar Filtro",,.T. )
	TBtnBmp2():New(01,(aSize[6]*2)-50 ,50,25,'FINAL' 		,,,,{||(_lRet:=_valid(),Iif(_lRet,_oDlgFS:End(),))},_oDlgFS,"Sair",,.T. )
	//TBtnBmp2():New(01,(aSize[6]*2)	  ,50,25,'PMSRRFSH' 	,,,,{||( _lRett := .T., _oDlgFS:End())},_oDlgFS,"Refresh",,.T. )
	//TBtnBmp2():New(01,(aSize[6]*2)+50 ,50,25,'FILTRO' 		,,,,{||( _lRett := .F.,_lRet:=.T., _oDlgFS:End())},_oDlgFS,"Parametro",,.T. )
	For _nx:=1 To Len(_aLinha)
		Reclock("_TAB1", .T.)
		_TAB1->Moti := space(006)
		_TAB1->Dmot := space(250)
		_TAB1->Prod := _aLinha[_nx,2]
		_TAB1->Prod := Posicione("SB1",1,xFilial("SB1")+_aLinha[_nx,2],"B1_DESCRI")
		_TAB1->Qtde := _aLinha[_nx,3]
		_TAB1->Prcv := _aLinha[_nx,4]
		MsUnLock()
	Next

	_oBrwFC1 := Nil
	_oBrwFC1:=MsBrGetDBase():New(014,003,(aSize[3]/2)-06,(aSize[4]/2)-35,,,,_oDlgFS,,,,,,,,,,,,.F.,"_TAB1",.T.,,.F.,,,)
	//_oBrwFC1:bLDblClick := {|| (_cCarHead(_TAB1->Pedi,2,_TAB1->Fili)) }
	//_oBrwFC1:bChange    := {|| (_AtuIte(_TAB1->SeqC+_TAB1->Fili+_TAB1->Pedi,1,_TAB1->Fili+_TAB1->Pedi)) }
	//_oBrwFC1:AddColumn(TCColumn():New(" "			,{||Iif(!Empty(_TAB1->STT),oOk,oNo) }   , "@!"      ,,,"CENTER"  ,010,.T.,.F.,,,,.F.,) ) //imagem
	_oBrwFC1:AddColumn(TCColumn():New("Motivo"		,{||_TAB1->Moti},,,,"CENTER",015,.F.,.F.,,,,,))
	_oBrwFC1:AddColumn(TCColumn():New("Desc. Motivo",{||_TAB1->Dmot},,,,"CENTER",105,.F.,.F.,,,,,))
	_oBrwFC1:AddColumn(TCColumn():New("Produto"		,{||_TAB1->Prod},,,,"CENTER",035,.F.,.F.,,,,,))
	_oBrwFC1:AddColumn(TCColumn():New("Descrição"  	,{||_TAB1->Desc},,,,"CENTER",105,.F.,.F.,,,,,))
	_oBrwFC1:AddColumn(TCColumn():New("Qtd. Ven."  	,{||_TAB1->Qtde},,,,"CENTER",025,.F.,.F.,,,,,))
	_oBrwFC1:AddColumn(TCColumn():New("Prc. Ven."  	,{||_TAB1->Prcv},,,,"CENTER",025,.F.,.F.,,,,,))
	_oBrwFC1:lUseDefaultColors := .F.
	//_oBrwFC1:SetBlkBackColor({|| IIf(_TAB1->ATU=="X",CLR_GRAY,IIf(_TAB1->LIN=="1",,CLR_LIGHTGRAY ))})
	_oBrwFC1:SetBlkBackColor({|| CLR_LIGHTGRAY })
	_oBrwFC1:Refresh()
Return

Static Function _valid()
	DbSelectArea("_TAB1")
	Do While !_TAB1->(EOF())
		If Empty(_TAB1->Moti)
			FwAlertWarning("Itens Sem Preencher Motivo")
			Return(.F.)
		EndIf
		_TAB1->(DBSKIP())
	EndDo
Return(.T.)

Static Function GeraPed()
	If Len(_aItens) > 0
		_cPedFil 	    := GetSxeNum("SC5","C5_NUM")
		aadd(_aCabec,{"C5_NUM",        _cPedFil,   Nil})
		aadd(_aCabec,{"C5_TIPO"	,   		"N",   Nil})
		aadd(_aCabec,{"C5_EMISSAO",   ddatabase,   Nil})
		aadd(_aCabec,{"C5_CLIENTE",   _cCliente,   Nil})
		aadd(_aCabec,{"C5_LOJACLI", 	 _cLoja,   Nil})
		aadd(_aCabec,{"C5_LOJAENT",	  _cLojaEnt,   Nil})
		aadd(_aCabec,{"C5_CONDPAG",    _cCodPag,   Nil})
		aadd(_aCabec,{"C5_TABELA",     _cTabela,   Nil})
		aadd(_aCabec,{"C5_TPFRETE",   _cTpFrete,   Nil})

		lMsErroAuto     := .F.
		MSExecAuto({|x,y,z|MATA410(x,y,z)}, _aCabec, _aItens, 3)
		If lMsErroAuto
			Mostraerro()
		Else
			FwAlertWarning("Pedido filho criado: "+Altrrim(_cPedFil))
			DbSelectArea("SC5")
			DbSeek(xFilial("SC5")+_cPedido)
			If Found()
				RecLock("SC5",.F.)
				SC5->C5_PEDFIL := _cPedFil
				SC5->(MsUnlock())
			EndIf
		EndIf
	EndIf
Return
