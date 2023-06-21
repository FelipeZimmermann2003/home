#INCLUDE "TOTVS.CH"

//--------------------------------------------------------------------------------------
/*/{Protheus.doc} MT100TOK
@Type			: Fun��o de Usu�rio
@Sample			: U_MT100TOK()
@Description	: Ponto de entrada chamado na fun��o A103Tudok() e usado para validar a inclusao da NF
@Param			: Nenhum
@Return			: lRet - (logico)
                  � esperada como retorno uma vari�vel l�gica onde: 
				  .T. -> atualizara o movimento, de acordo com os dados digitados.
				  .F. -> n�o prosseguir� com a grava��o da NF.
@ --------------|-----------------------------------------------------------------------
@Author			: Evandro Mugnol
@Since			: Jan/2023
@version		: Protheus 12.1.33 e posteriores
@Comments		: Esse Ponto de Entrada � chamado 2 vezes dentro da rotina A103Tudok(). 
                  Para o controle do n�mero de vezes em que ele � chamado foi criada a 
				  vari�vel l�gica lMT100TOK, que quando for definida como (.F.) o ponto 
				  de entrada ser� chamado somente uma vez.
/*/
//--------------------------------------------------------------------------------------
User Function MT100TOK()

	Local _aArea    := FWGetArea()
	Local _aAreaSF1 := SF1->(FWGetArea())
	Local _lRet     := .T.
	Local _nLinha

	lMT100TOK := .F.

	If cTipo == "D"
		For _nLinha := 1 to Len(aCols)

			If !GDDeleted(_nLinha) .And. _lRet	// Valida se a linha n�o estiver deletada
				If Empty(GdFieldGet("D1_XSETDEV", _nLinha)) .Or. Empty(GdFieldGet("D1_XMOTDEV", _nLinha))
					MsgAlert("Item / Produto: " + AllTrim(GdFieldGet("D1_ITEM", _nLinha)) + " / " + AllTrim(GdFieldGet("D1_COD", _nLinha)) + " est� com Setor ou Motivo Devolu��o em branco. Favor Informar em todos os itens.", "Aten��o")
					_lRet := .F.
				EndIf
			Endif

		Next _nLinha
	EndIf

	FWRestArea(_aAreaSF1)
	FWRestArea(_aArea)

Return(_lRet)
