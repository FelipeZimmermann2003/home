#INCLUDE "TOTVS.CH"
#INCLUDE "RWMAKE.CH"

/*
+-----------+-------------+-------+-------------------------------------+------+----------+
| Funcao    |PE01NFESEFAZ | Autor | Manoel M Mariante                   | Data |dez/2021  |
|-----------+-------------+-------+-------------------------------------+------+----------|
| Descricao | PE na geração do XML do SEFAZ                                               |
|           | especifico UNIAGRO                                                          |
|           |                                                                             |
|-----------+-----------------------------------------------------------------------------|
| Sintaxe   | ponto de entrada no nfesefaz                                                |
|-----------+-----------------------------------------------------------------------------|
| Alterações| 22/dez - inclui o envio do email para operadores logistico                  |
|           | dd/mmm - xxxxx                                                              |
|           |                                                                             |
+-----------+-----------------------------------------------------------------------------+
*/

User Function PE01NFESEFAZ()

	Local aProd     := PARAMIXB[1]
	Local cMensCli  := PARAMIXB[2]
	Local cMensFis  := PARAMIXB[3]
	Local aDest     := PARAMIXB[4]
	Local aNota     := PARAMIXB[5]
	Local aInfoItem := PARAMIXB[6]
	Local aDupl     := PARAMIXB[7]
	Local aTransp   := PARAMIXB[8]
	Local aEntrega  := PARAMIXB[9]
	Local aRetirada := PARAMIXB[10]
	Local aVeiculo  := PARAMIXB[11]
	Local aReboque  := PARAMIXB[12]
	Local aNfVincRur:= PARAMIXB[13]
	Local aEspVol   := PARAMIXB[14]
	Local aNfVinc   := PARAMIXB[15]
	Local AdetPag   := PARAMIXB[16]
	Local aObsCont  := PARAMIXB[17]
	Local aProcRef  := PARAMIXB[18]
	Local aMed      := PARAMIXB[19]
	Local aLote     := PARAMIXB[20]
	Local aRetorno	:= {}

	Local cTipo     := ""
	Local _i

	Local aArea     := GetArea()
	Local aAreaSF2  := SF2->(GetArea())
	Local aAreaSD2  := SD2->(GetArea())

	// Uso o CFOP para identificar o tipo da nota fiscal (entrada ou saida)
	If aProd[1,7] >= '5000'
		cTipo := '1'	// saida
	Else
		cTipo := '0'	// entrada
	EndIf

	If cTipo == '1'
		// Envio da DANFE e XML para o operador logistico, controlado pelo parâmetro abaixo
		// Caso esteja preenchido enviará também para ele
		cMailWMS := Alltrim(SuperGetMV('ES_MAILWMS',.F.,''))
		
		If !Empty(cMailWMS)
			aDest[16] := Alltrim(aDest[16]) + ";" + cMailWMS
		EndIf

		// Mensagens Observações
		DbSelectArea("SD2")
        DbSetOrder(3)       
        If DbSeek(xFilial('SD2') + SF2->F2_DOC + SF2->F2_SERIE)
			cMensCli += " Pedido de venda: " + SD2->D2_PEDIDO
		EndIf

		// Mensaagens da TES        
		cMensCli += SF4->F4_FORMULA

		
		// Mensagens de LOTE E DATA VALIDADE
		For _i := 1 To Len(aInfoItem)

			SD2->(MsSeek(xFilial("SD2") + SF2->F2_DOC + SF2->F2_SERIE + SF2->F2_CLIENTE + SF2->F2_LOJA + aProd[_i,02] + aInfoItem[_i][04]))

			If !Empty(SD2->D2_LOTECTL)
				aProd[_i,25] :=	"LOTE: " + AllTrim(SD2->D2_LOTECTL) + " DTVALID: " + Dtoc(SD2->D2_DTVALID)
			EndIf

		Next _i

	EndIf

	// O retorno deve ser exatamente nesta ordem e passando o conteúdo completo dos arrays
	// pois no rdmake nfesefaz é atribuido o retorno completo para as respectivas variáveis
	// Ordem:
	//      aRetorno[1] -> aProd
	//      aRetorno[2] -> cMensCli
	//      aRetorno[3] -> cMensFis
	//      aRetorno[4] -> aDest
	//      aRetorno[5] -> aNota
	//      aRetorno[6] -> aInfoItem
	//      aRetorno[7] -> aDupl
	//      aRetorno[8] -> aTransp
	//      aRetorno[9] -> aEntrega
	//      aRetorno[10] -> aRetirada
	//      aRetorno[11] -> aVeiculo
	//      aRetorno[12] -> aReboque
	//      aRetorno[13] -> aNfVincRur
	//      aRetorno[14] -> aEspVol
	//      aRetorno[15] -> aNfVinc
	//      aRetorno[16] -> AdetPag
	//      aRetorno[17] -> aObsCont 
	//      aRetorno[18] -> aProcRef
	//      aRetorno[19] -> aMed
	//      aRetorno[20] -> aLote
	
	aadd(aRetorno,aProd)
	aadd(aRetorno,cMensCli)
	aadd(aRetorno,cMensFis)
	aadd(aRetorno,aDest)
	aadd(aRetorno,aNota)
	aadd(aRetorno,aInfoItem)
	aadd(aRetorno,aDupl)
	aadd(aRetorno,aTransp)
	aadd(aRetorno,aEntrega)
	aadd(aRetorno,aRetirada)
	aadd(aRetorno,aVeiculo)
	aadd(aRetorno,aReboque)
	aadd(aRetorno,aNfVincRur)
	aadd(aRetorno,aEspVol)
	aadd(aRetorno,aNfVinc)
	aadd(aRetorno,AdetPag)
	aadd(aRetorno,aObsCont)
	aadd(aRetorno,aProcRef)
	aadd(aRetorno,aMed)
	aadd(aRetorno,aLote)

	RestArea(aAreaSD2)
	RestArea(aAreaSF2)
	RestArea(aArea)

Return(aRetorno) 
