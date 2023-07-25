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
		AbreTela()
		FWMsgRun(, {|oSay| GeraPed() }, "Processando", "Criando Pedido Filho")
	EndIf


Return(_lRet)

Static Function AbreTela()

Return

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
