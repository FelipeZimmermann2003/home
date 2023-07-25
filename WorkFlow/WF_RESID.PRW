#include "protheus.ch"
#include "rwmake.ch"
#include "topconn.ch"
#include "topdef.ch"
#INCLUDE "TBICONN.CH"
#INCLUDE "FILEIO.CH"

User Function WF_RESID(_cEmp,_cFil)
	Local nHandle   := 0	
	_cEmp := Iif(ValType(_cEmp)=="C",_cEmp,_cEmp[1])
	_cFil := Iif(ValType(_cFil)=="C",_cFil,_cEmp[2])
	RpcSetType(3)  // nao consome licenca

	PREPARE ENVIRONMENT EMPRESA _cEmp FILIAL _cFil TABLES "SM0","SX5","SB1","SB2","SD2","SF2"

	cQuery  := " "
	cQuery  += " SELECT C6_NUM, C6_ITEM, C6_PRODUTO, C6_LOCAL, C6_QTDVEN, C6_QTDENT, F4_ESTOQUE, F4_PODER3 "
	cQuery  += " FROM " + RetSqlName("SC5")+" SC5, "+ RetSqlName("SC6")+" SC6, " + RetSqlName("SF4")+" SF4
	cQuery  += " WHERE C6_FILIAL 	= '"+xFilial("SC6")+"' "
	cQuery  += " AND C6_BLQ         <> 'R' "
	cQuery  += " AND C6_QTDVEN      > C6_QTDENT "
	cQuery  += " AND (SELECT SUM(C6_QTDENT) FROM "+RetSqlName("SC6")+" C6 WHERE C6.D_E_L_E_T_ <> '*' AND C6.C6_FILIAL+C6.C6_NUM = SC6.C6_FILIAL+SC6.C6_NUM) > 0 "
	cQuery  += " AND C6_TES         = F4_CODIGO "
	cQuery  += " AND F4_ESTOQUE     = 'S' "
    cQuery  += " AND C5_NUM         = C6_NUM "
    cQuery  += " AND C5_NOTA        = ' ' "
    cQuery  += " AND C5_TIPO        = 'N' "
	cQuery  += " AND SC5.D_E_L_E_T_ = ' ' "
    cQuery  += " AND SC6.D_E_L_E_T_ = ' ' "
	cQuery  += " AND SF4.D_E_L_E_T_ = ' ' "
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
			_cHtml+= '    	    <p><span style="font-size: 8pt;"><font color="#4c4c4c" face="Verdana">'+OemToAnsi("<BR> <big><big><big><big>"+_cCabec+"</big></big></big></big>")
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
			_xEmail := 'felipe.zimmermann06@gmail.com'

			_mens:= 'Em anexo arquivo que contem um '+_cCabec+chr(13)+Chr(10)
			_mens+= 'Enviando E-Mail para: '+Chr(13)+_xEmail+Chr(13)

			//U_MZ_ENMAIL(_mens,_cCabec,_xEmail,"","",_aArq)
			U_FZ_ENMAIL(_mens, _cCabec, _xEmail, _aArq)

		EndIf
		_SC6->(DbCloseArea())
		DbSelectArea("SC6")

	EndIf

	RESET ENVIRONMENT

Return

Static Function FZ_ENMAIL(cEmails, cTitulo, cTexto, cAnexo, cCCEmails, cCOEmails, cConta, cPass, cRemetente, cServer, nPorta, lSSL, lTSL, SMTPTime)

	Local oServer
	Local oMessage
	Local lRet			:= .T.
	Local aAnexos     	:= {}
	Local cTxtTMP     	:= ""
	Local i				:= 0
	Local cMessage 		:= ""

	Default cEmails		:= ""
	Default cTitulo		:= ""
	Default cTexto		:= ""
	Default cAnexo		:= ""
	Default cCCEmails	:= "" //E-mail Cópia
	Default cCOEmails	:= "" //E-mail Cópia Oculta
	Default cConta   	:= SuperGetMv("MV_RELACNT")
	Default cPass 		:= SuperGetMv("MV_RELPSW")
	Default cRemetente	:= SuperGetMv("MV_RELACNT")
	Default cServer    	:= Iif(!":"$SuperGetMv("MV_RELSERV"),SuperGetMv("MV_RELSERV"),SubStr(SuperGetMv("MV_RELSERV"),1,AT(":",SuperGetMv("MV_RELSERV"))-1))
	Default nPorta      := Val(iif(!":"$SuperGetMv("MV_RELSERV"),"587",SubStr(SuperGetMv("MV_RELSERV"),AT(":",SuperGetMv("MV_RELSERV"))+1,len(SuperGetMv("MV_RELSERV")))))
	Default lSSL       	:= SuperGetMv("MV_RELSSL")
	Default lTSL       	:= SuperGetMv("MV_RELTLS")
	Default SMTPTime   	:= SuperGetMv("MV_RELTIME")
   

	//Cria a conexão com o server STMP ( Envio de e-mail )
	oServer := tMailManager():New()
	oServer:SetUseSSL(lSSL)
	oServer:SetUseTLS(lTSL)
	oServer:Init( "", cServer, cConta, cPass, 0, nPorta)
	
	//seta um tempo de time out com servidor de 1min
	If oServer:SetSmtpTimeOut(SMTPTime) != 0
		cMessage := "Falha ao setar o time out do SMTP."+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

		lRet := .F.
		Return lRet
	EndIf
   
	//realiza a conexão SMTP
	n:=oServer:SmtpConnect()
	cErro := oServer:GetErrorString(n)
	If n!= 0
		cMessage := "Falha ao conectar no SMTP."+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

		lRet := .F.
		Return lRet
	EndIf
	// Alterado a posição da autenticação após conetcar no SMTP
	oServer:SMTPAuth(cConta, cPass)

	//Apos a conexão, cria o objeto da mensagem                             
	oMessage := tMailMessage():New()
   
	//Limpa o objeto
	oMessage:Clear()
   
	//Popula com os dados de envio
	oMessage:cFrom := cConta
	oMessage:cTo := cEmails
	
	If !Empty(cCCEmails)
		oMessage:cCc := cCCEmails
	EndIf
	
	If !Empty(cCOEmails)	
		oMessage:cBcc := cCOEmails
	EndIf
	
	oMessage:cSubject := cTitulo
	oMessage:cBody := cTexto
   
	//+----------------------------------------+   
	//|Adiciona um attach
	//+----------------------------------------+
	//Verifica se existem mais de um arquivo para ser adcionado
	//e adciona cada um idividualmente
	If !Empty(cAnexo)
		//Monta array de Anexos
		If AT(";",cAnexo)>0
			For i:=1 to Len(cAnexo)
				If Substr(cAnexo,i,1)==";"
					AADD(aAnexos,cTxtTmp)
					cTxtTmp := ""
				Else
					cTxtTMP += Substr(cAnexo,i,1)
				EndIF

				If i == Len(cAnexo) .AND. !Empty(cTxtTmp)
					AADD(aAnexos,cTxtTmp)
					cTxtTmp := ""
				EndIf
			Next
		
			For i:= 1 to Len(aAnexos)
				If oMessage:AttachFile(aAnexos[i]) < 0
					cMessage := "Erro ao atachar o arquivo."+ CRLF   
					FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

					Return .F.
				Else
					//adiciona uma tag informando que é um attach e o nome do arq
					oMessage:AddAtthTag( aAnexos[i])
				EndIf
			Next
		Else
			If oMessage:AttachFile( cAnexo ) < 0
				cMessage := "Erro ao atachar o arquivo."+ CRLF   
				FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)

				Return .F.
			Else
				//adiciona uma tag informando que é um attach e o nome do arq
				oMessage:AddAtthTag(cAnexo)
			EndIf
		EndIf
	EndIf
   
	//Envia o e-mail
	n := oMessage:Send(oServer)

	cErro := oServer:GetErrorString(n)

	If n != 0
		cMessage := "Erro ao enviar o e-mail mensagem: "+cErro+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)
		
		lRet := .F.
	EndIf
   
  //Desconecta do servidor
	If oServer:SmtpDisconnect() != 0
		cMessage := "Erro ao disconectar do servidor SMTP."+ CRLF   
		FWLogMsg("WARN", "", "UNIAP001", "UNIAP01C", "", "", cMessage, 0, 0)
		
		lRet := .F.
		Return lRet
	EndIf

Return lRet
