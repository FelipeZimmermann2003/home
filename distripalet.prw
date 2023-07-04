#INCLUDE "RWMAKE.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "APVT100.CH"

/*
 Programa distripalet.prw		Data Abr/2023		Programador: Fernando Pereira
 
 Este programa faz a leitura dos dados do palet na CB0
 Pede a localização onde vai ser guardado este palet
 E faz a distribuição

*/
User Function VTCONSUM()
	Local aAreaAnt   := GetArea()
	Private _lRet 		:= .T.
	Private _nMaxLin 	:= 12
	Private _nMaxCol 	:= 21
	Private _cCodUsr 	:= RetCodUsr()
	Private _cNomUsr	:= UsrRetName()
	Private _cPalet		:= Space(11)		// Nr do Palet
	Private _cLocal		:= Space(7)			// Nr do Local

	VtSetSize(_nMaxLin,_nMaxCol)

	DbSelectArea("CB1")
	DbSetorder(2)
	DbSeek(xFilial("CB1")+_cCodUsr)
	IF !Found()
		VtAlert("** OPERADOR NAO AUTORIZADO **","ATENCAO",.T.,3000,4)
		Return()
	EndIF
	VtClear()

	Do While .T.
		VtClear()
		@ 00,00 vtSay "LEIA ETIQUETA DO PALET"
		@ 01,00 vtGet _cPalet Picture "@!" When VtLastKey() <> 27 Valid tstnpal(_cPalet)
		vtread()
		IF VtLastKey() == 27
			vtClearBuffer()
			exit
		Else
			_Tela_dp1(_cPalet)
			_cPalet		:= Space(11)
		endIF
	EndDo
	vtClear()
	vtClearBuffer()
	RestArea(aAreaAnt)
Return()

//Tela Principal de leitura
Static Function _Tela_dp1(_cPalete)
	Private _nMaxLin 	:= 12
	Private _nMaxCol 	:= 21
	Private _cEnder	    := space(8)
	Private _Volta		:= .T.
	VtClear()
	VtSetSize(_nMaxLin,_nMaxCol)

	Do While .T.
		@ 00,00 vtSay "DISTRIBUINDO PALET   : "+_cPalete
		@ 03,00 vtSay "** LEIA O ENDERECO **"
		@ 04,00 vtGet _cEnder When VtLastKey() <> 27 Valid tstEnder(_cEnder,_cPalete)
		vtread()
		IF VtLastKey() == 27
			vtClearBuffer()
			exit
		Else
			TransARM(alltrim(_cPalete), alltrim(_cEnder))
			Return(.F.)
		endIF
	EndDo
	VtClearBuffer()
	vtKeyBoard(chr(13))
Return(.T.)

/** 
    Função Enderecar Pega os dados da leitura da etiqueta do palet
    e do endereço e monta os dados a serem gravados 
    Faz os testes de quantidade na SDA e roda a função A100Distri()
    Se deu tudo certo retorno .T. se não mostra os erros e retorna .F.
*/
Static Function TransARM(_cPalet, _cEnder)
	Local aAuto 	:= {}
	Local aItem 	:= {}
	Local aLinha 	:= {}
	Local nOpcAuto 	:= 0
	Local cDocumen 	:= ""
	Local nX        := 1
	Local _lRet		:= .T.
	Private lMsErroAuto := .F.

	DbSelectArea("CB0")
	DbSetOrder(1)
	DbSeek(xFilial("CB0")+_cPalet)
	If Found()
		_cPR			:= CB0->CB0_CODPRO                  // Cod do Produto
		_cLT			:= CB0->CB0_LOTE                    // Lote do Palet
		_dDt            := Posicione("SB8",5,xFilial("SB8")+CB0->CB0_CODPRO+CB0->CB0_LOTE,"B8_DTVALID")
		_nQT			:= CB0->CB0_QTDE                    // Quantidade do Palet
		_nQtSeg         := ConvUm(CB0->CB0_CODPRO, CB0->CB0_QTDE,0,2)       // Quant Seg.Unidade
		_nConv		    := POSICIONE('SB1',1 ,xFilial('SB1')+_cPR ,'B1_CONV')
		_cTipoP		    := POSICIONE('SB1',1 ,xFilial('SB1')+_cPR ,'B1_TIPO')
		// ------------------------------------------------------------------------

		// Preparando a quantidade a endereçar ------------------------------------
		if _cTipoP = 'PA' .OR. _cTipoP = 'PR'
			_nQuant	    := _nQT * _nConv
		else
			_nQuant	    := _nQT
		endif

		//Cabecalho a Incluir
		cDocumen := GetSxeNum("SD3","D3_DOC")
		aAdd(aAuto,{cDocumen,dDataBase})

		//Itens a Incluir
		aItem  := {}
		aLinha := {}

		// Origem
		SB1->(DbSeek(xFilial("SB1") + _cPR))
		aAdd(aLinha,{"ITEM",	   "0001"					, Nil})
		aAdd(aLinha,{"D3_COD",     SB1->B1_COD				, Nil}) // Codigo Produto origem
		aAdd(aLinha,{"D3_DESCRI",  SB1->B1_DESC				, Nil}) // Descrição Produto origem
		aAdd(aLinha,{"D3_UM", 	   SB1->B1_UM				, Nil}) // Unidade Medida origem
		aAdd(aLinha,{"D3_LOCAL",   "PRO"					, Nil}) // Armazem origem
		aAdd(aLinha,{"D3_LOCALIZ", "CORREDOR"				, Nil}) // Localização Origem

		// Destino
		aAdd(aLinha,{"D3_COD", 	   SB1->B1_COD				, Nil}) // Codigo Produto destino
		aAdd(aLinha,{"D3_DESCRI",  SB1->B1_DESC				, Nil}) // Descrição Produto destino
		aAdd(aLinha,{"D3_UM", 	   SB1->B1_UM				, Nil}) // Unidade Medida destino
		aAdd(aLinha,{"D3_LOCAL",   "DEP"					, Nil}) // Armazem destino
		aAdd(aLinha,{"D3_LOCALIZ", _cEnder					, Nil}) // Localização Destino

		aAdd(aLinha,{"D3_NUMSERI", ""						, Nil}) // Numero serie

		If SB1->B1_RASTRO == 'L'
			aAdd(aLinha,{"D3_LOTECTL", _cLT				    , Nil}) // Lote Origem
			aAdd(aLinha,{"D3_NUMLOTE", ""					, Nil}) // Sublote Origem
			aAdd(aLinha,{"D3_DTVALID", _dDt			        , Nil}) // Data Validade Origem
		EndIf

		aAdd(aLinha,{"D3_POTENCI", 0						, Nil}) // Potencia
		aAdd(aLinha,{"D3_QUANT",   _nQuant					, Nil}) // Quantidade
		aAdd(aLinha,{"D3_QTSEGUM", _nQtSeg                  , Nil}) // Seg unidade medida
		aAdd(aLinha,{"D3_ESTORNO", ""						, Nil}) // Estorno
		aAdd(aLinha,{"D3_NUMSEQ",  ""						, Nil}) // Numero Sequencia

		If SB1->B1_RASTRO == 'L'
			aAdd(aLinha,{"D3_LOTECTL", _cLT				    , Nil}) // Lote Destiono
			aAdd(aLinha,{"D3_NUMLOTE", ""					, Nil}) // Sublote Destino
			aAdd(aLinha,{"D3_DTVALID", _dDt			        , Nil}) // Data Validade Destino
		EndIf

		aAdd(aLinha,{"D3_ITEMGRD", ""						, Nil}) // Item Grade
		aAdd(aLinha,{"D3_CODLAN",  ""						, Nil}) // Cat83 Prod Origem
		aAdd(aLinha,{"D3_CODLAN",  ""						, Nil}) // Cat83 Prod Destino

		aAdd(aAuto,aLinha)

		nOpcAuto := 3 // Inclusao
		MSExecAuto({|x,y| mata261(x,y)},aAuto,nOpcAuto)
		//VtAlert(SB1->B1_COD,"ATENCAO",.T.,3000,4)
		If lMsErroAuto
			VtAlert("Entrou aqui","ATENCAO",.T.,3000,4)
			_lRet := .T.
			//MostraErro()
			cErroAuto := ""
			aErroAuto:= GetAutoGrLog()
			For nX:= 1 To Len(aErroAuto)
				cErroAuto+= aErroAuto[nX]+Chr(13)
			Next nX
			VtAlert(cErroAuto,"ATENCAO",.T.,3000,4)
			VTalert(cErroAuto)
		Else
			_lRet := .F.
			VtAlert("Enderecamento Ok!","ATENCAO",.T.,3000,4)
		EndIf
	EndIf
Return(_lRet)

Static Function Enderecar(_cPalet, _cEnder)
	Local aAreaAnt   := GetArea()
	Local aAreaSB2   := SB2->(GetArea())
	Local aAreaSB8   := SB8->(GetArea())
	Local aAreaSBE   := SBE->(GetArea())
	Local aAreaSBF   := SBF->(GetArea())
	Local aAreaSDA   := SDA->(GetArea())
	Local aAreaSDB   := SDB->(GetArea())
	Local aCabSDA       := {}
	Local aItSDB        := {}
	Local _aItensSDB    := {}
	Local nX            := 0
	Private _lret	:= .T.

	_aArea 			:= getarea ()

	// Pega os dados na CB0 e na SB1 -----------------------------------------
	DbSelectArea("CB0")
	DbSetOrder(1)
	DbSeek(xFilial("CB0") + _cPalet)
	_cPR			:= CB0->CB0_CODPRO                  // Cod do Produto
	_cLT			:= CB0->CB0_LOTE                    // Lote do Palet
	_LocEnc		    := CB0->CB0_LOCAL                   // Local Padrão
	_nQT			:= CB0->CB0_QTDE                    // Quantidade do Palet
	_nQtSeg         := ConvUm(CB0->CB0_CODPRO, CB0->CB0_QTDE,0,2)       // Quant Seg.Unidade
	_cCodEti        := CB0->CB0_CODETI                  // Nr da Etiqueta

	_nConv		    := POSICIONE('SB1',  1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_CONV')
	_cSegum		    := POSICIONE('SB1',  1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_SEGUM')
	_cTipoP		    := POSICIONE('SB1',  1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_TIPO')
	_cLocPad        := POSICIONE('SB1',  1, xFilial('SB1') + SC2->C2_PRODUTO, 'B1_LOCPAD')
	// ------------------------------------------------------------------------

	// Preparando a quantidade a endereçar ------------------------------------
	if _cTipoP = 'PA' .OR. _cTipoP = 'PR'
		_nQuant	    := _nQT * _nConv
	else
		_nQuant	    := _nQT
	endif
	// ------------------------------------------------------------------------

	// Prepara o que vai ir no documento do endereçamento com informações da CB0
	_cDoc           = " Lote " + CB0->CB0_LOTE + " Local " + CB0->CB0_LOCAL
	// ------------------------------------------------------------------------

    /** Distribuindo Saldos */
	_sQuery := " "
	_sQuery += " SELECT D3_FILIAL FILIAL, D3_COD COD, D3_TM TM, D3_UM UM, D3_QUANT QUANT, D3_LOTECTL LTCTL, "
	_sQuery += " D3_NUMLOTE NUMLOTE, D3_SEGUM QTDSEG, D3_OBS OBS, D3_NUMSEQ NUMSEQ, D3_DOC DOC, D3_LOCAL LOC, "
	_sQuery += " D3_NUMSERI SERI, D3_CODFOR FORNEC, D3_LOJAFOR LOJA "
	_sQuery += " FROM "+RetSQLName("SD3")+" SD3 "
	_sQuery += " WHERE SD3.D_E_L_E_T_ 	<> '*' "
	_sQuery += "   AND D3_FILIAL   	= '" + xFilial("SD3") + "' "
	_sQuery += "   AND D3_COD 	    = '" + _cPR + "' "
	_sQuery += "   AND D3_TM	 	= '499' "
	_sQuery += "   AND D3_CF	 	= 'DE4' "
	_sQuery += "   AND D3_LOCAL     = 'DEP' "
	_sQuery += "   AND D3_OBS	 	= '"+_cCodEti+"' "
	DbUseArea(.t., 'TOPCONN', TcGenQry (,, _sQuery), "_SD3", .f., .t.)

	Do While !_SD3->(EOF())
		_Prod   := _SD3->COD
		_Local  := _SD3->LOC
		_NumSeq := _SD3->NUMSEQ
		_Doc    := _SD3->DOC
		_Serie  := _SD3->SERI
		_Forne  := _SD3->FORNEC
		_Loja   := _SD3->LOJA
		_qtdsd3 := _SD3->QUANT
		_qtdSeg := _SD3->QTDSEG
		_loteCt := _SD3->LTCTL
		_numLot := _SD3->NUMLOTE

		DbSelectArea("SDA")
		DbSetOrder(1)
		DbSeek(xFilial('SDA')+_Prod+_Local+_NumSeq+_Doc)
		Do While !SDA->(Eof())
			if SDA->DA_SALDO > 0 .and. SDA->DA_SALDO >= _nQuant
				aCabSDA       := {}
				aItSDB        := {}
				_aItensSDB    := {}
				lMsErroAuto := .F.
				//Cabecalho com a informaçãoo do item e NumSeq que sera endereçado.
				aCabSDA := {{"DA_PRODUTO" ,SDA->DA_PRODUTO,Nil},;
					{"DA_NUMSEQ"  ,SDA->DA_NUMSEQ,Nil}}
				//Dados do item que será endereçado
				aItSDB := {{"DB_ITEM"     ,"0001"      ,Nil},;
					{"DB_ESTORNO"  ," "       ,Nil},;
					{"DB_LOCALIZ"  ,_cEnder    ,Nil},;
					{"DB_DATA"    ,dDataBase   ,Nil},;
					{"DB_QUANT"  ,_nQuant      ,Nil}}
				aadd(_aItensSDB,aitSDB)

				//Executa o endere?amento do item
				MATA265( aCabSDA, _aItensSDB, 3)
				If lMsErroAuto
					//MostraErro()
					cErroAuto := ""
					aErroAuto:= GetAutoGrLog()
					For nX:= 1 To Len(aErroAuto)
						cErroAuto+= aErroAuto[nX]+Chr(13)
					Next nX
					VTalert(cErroAuto)
				Else
					VtAlert("Enderecamento Ok!","ATENCAO",.T.,3000,4)
				Endif

				//// Aqui faz a distribuição
				//cItem	:=	A265UltIt('C')
				//CriaSDB(DA_PRODUTO, DA_LOCAL, _nQuant, _cEnder, _Serie, SDA->DA_DOC, SDA->DA_SERIE, SDA->DA_CLIFOR, SDA->DA_LOJA, SDA->DA_TIPONF, SDA->DA_ORIGEM, IIf(SDA->DA_DATA>=dUlMes,SDA->DA_DATA,dDataBase) , SDA->DA_LOTECTL, SDA->DA_NUMLOTE, SDA->DA_NUMSEQ, '499', 'D', StrZero(Val(cItem)+1, Len(cItem)), .F., If(QtdComp(SDA->DA_EMPENHO)>QtdComp(0),_nQuant,0),_nQtSeg)
				////-- Atualiza o Saldo no SDA
				//RecLock('SDA', .F.)
				//Replace DA_SALDO   With (DA_SALDO-SDB->DB_QUANT)
				//Replace DA_EMPENHO With (DA_EMPENHO-SDB->DB_EMPENHO)
				//Replace DA_QTSEGUM With (DA_QTSEGUM - SDB->DB_QTSEGUM)
				//Replace DA_EMP2    With (DA_EMP2 - SDB->DB_EMP2)
				//MsUnlock()
//
				////-- Baixa Saldo a Classificar no SB2
				//SB2->(dbSetOrder(1))
				//SB2->(dbSeek(xFilial("SB2")+SDA->DA_PRODUTO+SDA->DA_LOCAL))
				//RecLock('SB2', .F.)
				//Replace B2_QACLASS With (B2_QACLASS-SDB->DB_QUANT)
				//MsUnlock()
//
				////-- Baixa Saldo Empenhado (Ref. ao Saldo a Classificar) no SB8
				//If Rastro(SDA->DA_PRODUTO)
				//	dbSelectArea('SB8')
				//	dbSetOrder(3)
				//	If Rastro(SDA->DA_PRODUTO, 'S')
				//		If dbSeek(cSeek:=xFilial('SB8')+SDA->DA_PRODUTO+SDA->DA_LOCAL+SDA->DA_LOTECTL+SDA->DA_NUMLOTE, .F.)
				//			RecLock('SB8', .F.)
				//			Replace B8_QACLASS With (B8_QACLASS-SDB->DB_QUANT)
				//			Replace B8_QACLAS2 With (B8_QACLAS2-SDB->DB_QTSEGUM)
				//			MsUnlock()
				//		EndIf
				//	Else
				//		nEmpenho := SDB->DB_QUANT
				//		nEmpenh2 := SDB->DB_QTSEGUM
				//		dbSeek(cSeek:=xFilial('SB8')+SDA->DA_PRODUTO+SDA->DA_LOCAL+SDA->DA_LOTECTL, .T.)
				//		Do While !Eof() .And. QtdComp(nEmpenho) > QtdComp(0) .And. cSeek == B8_FILIAL+B8_PRODUTO+B8_LOCAL+B8_LOTECTL
				//			If QtdComp(nBaixa:=If(QtdComp(B8_QACLASS)<QtdComp(nEmpenho),B8_QACLASS,nEmpenho)) > QtdComp(0)
				//				nBaixa2:=If(QtdComp(B8_QACLAS2)<QtdComp(nEmpenh2),B8_QACLAS2,nEmpenh2)
				//				Reclock('SB8', .F.)
				//				Replace B8_QACLASS With (B8_QACLASS-nBaixa)
				//				Replace B8_QACLAS2 With (B8_QACLAS2-nBaixa2)
				//				MsUnlock()
				//				nEmpenho -= nBaixa
				//			EndIf
				//			dbSkip()
				//		EndDo
				//	EndIf
				//EndIf

				//-- Cria Saldo no SBF baseado no movimento do SDB
				//GravaSBF('SDB')
			Endif
			exit
		Enddo


		_SD3->(dbSkip())
	EndDo

	// ------------------------------------------------------------------------

	VTBeep()
	_SD3->(DbCloseArea())
	RestArea(aAreaSDB)
	RestArea(aAreaSDA)
	RestArea(aAreaSBF)
	RestArea(aAreaSBE)
	RestArea(aAreaSB8)
	RestArea(aAreaSB2)
	RestArea(aAreaAnt)
	Restarea(_aArea)

Return(_lret)

// Testa se o endereço é válido
Static Function tstEnder(endereco,_cPalete)
	Local _Rto 		:= .T.
	_aArea 			:= getarea()
	IF Empty(endereco)
		VtAlert("ENDEREÇO INVALIDO","ATENCAO",.T.,3000,4)
		_Rto        := .F.
	Else
		DbSelectArea("SBE")
		DbSetOrder(1)
		DbSeek(xFilial("SBE")+"DEP"+endereco)
		IF !Found()
			VtAlert("ENDERECO NAO EXISTENTE..","ATENCAO",.T.,3000,4)
			_Rto    := .F.
		EndIF
	EndIF
	Restarea(_aArea)
Return(_Rto)

// Teste etiqueta Inválida / Não existente / Já utilizada / Produto não pertence a ordem 
Static Function tstnpal(codeti)
	Private _Rt3 	:= .T.
	_aArea 		    := getarea ()
	codeti		    := Alltrim(codeti)

	IF Empty(codeti)
		VtAlert("CÓDIGO DE PALET INVÁLIDO", "ATENCAO", .T., 3000, 4)
		_Rt3 := .F.
	EndIF

	// Testa a etiqueta na CB0 ----------------------------------------------
	IF _Rt3
		_Filial:= cFilAnt
		_cProd := ""
		_nQT   := 0
		DbSelectArea("CB0")
		DbSetOrder(1)
		DbSeek(xFilial("CB0")+codeti)
		IF !Found()
			VtAlert("ETIQUETA NAO EXISTE", "ATENCAO", .T., 3000, 4)
			_Rt3    := .F.
		ElseIF CB0->CB0_STATUS<>'E'
			VtAlert("ETIQUETA AINDA NAO APONTADA", "ATENCAO", .T., 3000, 4)
			_rt3    := .F.
		Else
			_cProd	    := CB0->CB0_CODPRO                  // Código do Produto
			_nQT		:= CB0->CB0_QTDE                    // Quantidade do Palet
			_Filial	    := xFilial("CB0")
		EndIF
	EndIF
	Restarea(_aArea)
Return(_Rt3)
