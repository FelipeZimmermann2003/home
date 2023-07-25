#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#include "topdef.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "FILEIO.CH"

User Function WF_RESID(_xcFilial)
	Local nHandle   := 0
    Local _cFilial  := iif(_xcFilial==Nil,"00",_xcFilial)
	RpcSetType(3)  // nao consome licenca

	PREPARE ENVIRONMENT EMPRESA "01" FILIAL _cFilial TABLES "SM0","SX5","SB1","SB2","SD2","SF2"

	cQuery  := " "
	cQuery  += " SELECT C6_NUM, C6_ITEM, C6_PRODUTO, C6_LOCAL, C6_QTDVEN, C6_QTDENT, F4_ESTOQUE, F4_PODER3 "
	cQuery  += " FROM " + RetSqlName("SC5")+" SC5, "+ RetSqlName("SC6")+" SC6, " + RetSqlName("SF4")+" SF4
	cQuery  += " WHERE C6_FILIAL 	= '"+xFilial("SC6")+"' "
	cQuery  += " AND C6_BLQ         <> 'R' "
	cQuery  += " AND C6_QTDVEN      > C6_QTDENT "
	cQuery  += " AND C6_QTDENT      > 0 "
	cQuery  += " AND C6_TES         = F4_CODIGO "
	cQuery  += " AND F4_ESTOQUE     = 'S' "
    cQuery  += " AND C5_NUM         = C6_NUM "
    cQuery  += " AND C5_NOTA        = '' "
    cQuery  += " AND C5_TIPO        = 'N' "
	cQuery  += " AND SC5.D_E_L_E_T_ = '' "
    cQuery  += " AND SC6.D_E_L_E_T_ = '' "
	cQuery  += " AND SF4.D_E_L_E_T_ = '' "
	cQuery  += " AND C6_QTDVEN      > 10 "
	cQuery  += " AND (C6_QTDVEN - C6_QTDENT) <= 0.600 "
	cQuery  += " ORDER BY 1, 2, 3 "

	DbUseArea(.t., 'TOPCONN',TcGenQry(,,cQuery),'_SC6',.t.,.f.)
	DbSelectArea("_SC6")
	_SC6->(DbGoTop())
	If !_SC6->(EOF())
		Private cAnexos    := '\spool\RESIDUOS_ELIMINADOS.HTM'

		if File (cAnexos)
			FERASE (cAnexos)
		Endif
		If (nHandle:= FCREATE(cAnexos,FC_NORMAL)) <> -1
			_cCabec := "Resíduos de Pedidos - "+dtoc(dDataBase)
			_cHtml:= '<html><title>'+OemToAnsi( _cCabec)+'</title><body>'
			_cCor := ""
			_cHtml:= '<table height="15" cellspacing="1" width="100%" border="1" cellspacing="0" bordercolordark="white" bordercolorlight="black">'
			_cHtml+= '    <tr>'
			_cHtml+= '    	 <td bordercolor="white" bordercolorlight="white" bordercolordark="white" align="center" bgcolor="white" height="0" width="1200">
			_cHtml+= '    	    <p><span style="font-size: 8pt;"><font color="#4c4c4c" face="Verdana">'+OemToAnsi( "<BR> <big><big><big><big>"+_cCabec+"</big></big></big></big>")
			_cHtml+= '			</font></span></p>'
			_cHtml+= '        </td>'
			_cHtml+= '	</tr>'
			_cHtml+= '</table>'
			_cHtml+= '<table style="width: 100%;" border="1"> '
			_cHtml+= '   <tr>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Pedido</font></span></td>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Item</font></span></td>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Produto</font></span></td>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Descricao</font></span></td>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Qtde Venda</font></span></td>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Qtde Entregue</font></span></td>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Saldo <B>* Ate 0.600</font></span></td>'
			_cHtml+= '      <td style="text-align: center;" colspan="1" rowspan="1" bgcolor="#999999"><span style="font-size: 8pt;"><font align="center" color="#ffffff" face="Verdana">Status</font></span></td>'
			_cHtml+= '    </tr>'
			FWRITE( nHandle, _cHtml )

			Do While !_SC6->(EOF())
            	_cStatus    := "Pendente"
            	DbSelectArea("SC6")
				DbSetOrder(1)
				DbSeek(xFilial("SC6")+_SC6->C6_NUM+_SC6->C6_ITEM)
                if Found()
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
                    If _SC6->F4_PODER3 <> "R" .And. _SC6->F4_PODER3 <> "D"
                        MaResDoFat(SC6->(Recno()))
						MaLiberOk({ SC6->C6_NUM },.T.)
                    EndIf
                    RestArea(_aSc6Tmp)
                    If Alltrim(SC6->C6_BLQ) = "R"
                        _cStatus    := "Resíduo Eliminado"   
                    Endif
                    _cCor := ""
                    _cHtml:= '<tr>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: center; '+_cCor+'"><font size="1">'+SC6->C6_NUM+'</font></td>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: center; '+_cCor+'"><font size="1">'+SC6->C6_ITEM+'</font></td>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: center; '+_cCor+'"><font size="1">'+SC6->C6_PRODUTO+'</font></td>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: left; '+_cCor+'"><font size="1">'+Alltrim(Posicione("SB1",1,xFilial("SB1")+SC6->C6_PRODUTO,"SB1->B1_DESC"))+'</font></td>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: right; '+_cCor+'"><font size="1">'+Transform(SC6->C6_QTDVEN, "@E 999,999.999")+'</font></td>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: right; '+_cCor+'"><font size="1">'+Transform(SC6->C6_QTDENT, "@E 999,999.999")+'</font></td>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: right; '+_cCor+'"><font size="1">'+Transform((SC6->C6_QTDVEN - SC6->C6_QTDENT), "@E 999,999.999")+'</font></td>'
                    _cHtml+= '    <td style="color: rgb(51, 51, 51); font-family: Arial; text-align: center; '+_cCor+'"><font size="1">'+_cStatus+'</font></td>'
                    _cHtml+= '</tr>'
                    FWRITE( nHandle, _cHtml )                
                EndIf
				DbSelectArea("_SC6")
				_SC6->(DbSkip())
			EndDo
			fClose(nHandle)
			_aArq := {}

			AADD(_aArq  ,cAnexos)
			_xEmail := 'comercial@zandei.com.br;comercial3@zandei.com.br;daniele@zandei.com.br;atendimento@zandei.com.br'

			_mens:= 'Em anexo arquivo que contem um '+_cCabec+chr(13)+Chr(10)
			_mens+= 'Enviando E-Mail para: '+Chr(13)+_xEmail+Chr(13)

			U_MZ_ENMAIL(_mens,_cCabec,_xEmail,"","",_aArq)

		EndIf
		_SC6->(DbCloseArea())
		DbSelectArea("SC6")

	EndIf

	RESET ENVIRONMENT

Return
