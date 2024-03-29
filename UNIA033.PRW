#include 'protheus.ch'
#include 'parmtype.ch'
#Include 'FWMVCDef.ch'

/*/{Protheus.doc} UNIA033
//TODO 
@description Valida��o inclus�o Contas a Pagar X Verbas
@author Willian Kaneta
@since 25/04/2017
@version 1.0

@type function
/*/
user function UNIA033()
	Local lRet 		:= .T.
	Local aArea 	:= GetArea()
	Local aAreaSA2 	:= SA2->(GetArea())
		
	If !Empty(M->E2_CODVERB)
		If !Empty(M->E2_FORNECE)
			DbSelectArea("SA2")
			SA2->(DbSetOrder(1))

			If SA2->(MsSeek(xFilial("SA2")+M->E2_FORNECE+M->E2_LOJA))
				DbSelectArea("SA1")
				SA1->(DbSetOrder(3))

				If SA1->(MsSeek(xFilial("SA1")+SA2->A2_CGC))
					DbSelectArea("SZ2")
					SZ2->(DbSetorder(1))

					If MsSeek(xFilial("SZ2")+M->E2_CODVERB+PADR(SA1->A1_COD,TAMSX3("Z2_CLIENTE")[1])+SA1->A1_LOJA)
						If SZ2->Z2_APROV == "1"
							If M->E2_EMISSAO > SZ2->Z2_VIGFIM .OR. M->E2_EMISSAO < SZ2->Z2_VIGINI
								Help(NIL, NIL, "HELP", NIL, "Data de emiss�o fora da vigencia do cadastro de verbas!", 1,0, NIL, NIL, NIL, NIL, NIL,;
									{"Verificar o valor da verba X valor do item informado"})
								lRet := .F.
							Else
								If M->E2_VALOR > SZ2->Z2_VALOR
									Help(NIL, NIL, "HELP", NIL, "Valor Acima do Saldo da Verba!", 1,0, NIL, NIL, NIL, NIL, NIL,;
									{"Verificar o valor da verba X valor do item informado"})
									lRet := .F.
								EndIf
							EndIf
						Else
							Help(NIL, NIL, "HELP", NIL, "Verba n�o Aprovada para o cliente: "+SA1->A1_COD+"Loja: "+SA1->A1_LOJA, 1,0, NIL, NIL, NIL, NIL, NIL,;
								{"� necess�rio aprovar a Verba no cadastro de Verbas para poder utilizar!"})
							lRet := .F.
						EndIf
					Else
						Help(NIL, NIL, "HELP", NIL, "Cliente n�o cadastrado no cadastro de Verbas!", 1,0, NIL, NIL, NIL, NIL, NIL,;
							{"Verificar se o cliente est� cadastrado no cadastro de verbas ou selecionar a verba correta para o cliente."})
						lRet := .F.
					EndIf
				Else
					Help(NIL, NIL, "HELP", NIL, "Cliente n�o localizado no cadastro de Cliente com o CNPJ/CPF: "+Alltrim(SA2->A2_CGC), 1,0, NIL, NIL, NIL, NIL, NIL,;
						{"Verificar se o fornecedor est� cadastrado como cliente Cadastro de Clientes, e se possui cadastro no Cadastro de Verbas."})
					lRet := .F.
				EndIf
			EndIf
		Else
			Help(NIL, NIL, "HELP", NIL, "C�digo do fornecedor n�o informado!", 1,0, NIL, NIL, NIL, NIL, NIL,;
				{"Informar o c�digo do fornecedor, campo E2_FORNECE."})
			lRet := .F.
		EndIf
	EndIf

	RestArea(aAreaSA2)
	RestArea(aArea)
Return lRet
