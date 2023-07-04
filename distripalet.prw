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
