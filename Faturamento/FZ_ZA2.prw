#include "protheus.ch"
#include "tbiconn.ch"
#include "rwmake.ch"
#include "topconn.ch"
#INCLUDE "FILEIO.CH"
#include "colors.ch"
#include "sigawin.ch"
#INCLUDE "COLORS.CH"
#INCLUDE "JPEG.CH"
#INCLUDE "PROTHEUS.CH"
#INCLUDE "TOPCONN.CH"
#INCLUDE "FWMVCDEF.CH"
#INCLUDE "TbIconn.ch"
#INCLUDE "FWADAPTEREAI.CH"

/*CRIAR TABELA ZA2
  CRIAR TABELA ZA3*/
User Function FZ_ZA2()
	Local oBrowse

    Private CCADASTRO := "Cadatro Motivo Pedido"
	Private aRotina := MenuDef()

	oBrowse := FWMBrowse():New()
	oBrowse:SetAlias("ZA2")
	oBrowse:SetDescription("Cadatro Motivo Pedido")
	oBrowse:DisableDetails()
	oBrowse:Activate()

Return()

Static Function MenuDef()

	Local aRotina := {}


	ADD OPTION aRotina TITLE "Visualizar"   ACTION 'AxVisual' OPERATION MODEL_OPERATION_VIEW ACCESS 0 //STR0012 - Visualizar
	ADD OPTION aRotina TITLE "Incluir"      ACTION 'AxInclui' OPERATION OP_INCLUIR ACCESS 0    //STR0013 - Incluir
	ADD OPTION aRotina TITLE "Alterar"      ACTION 'AxAltera' OPERATION OP_ALTERAR ACCESS 0    //STR0014 - Alterar
	ADD OPTION aRotina TITLE "Excluir"      ACTION 'AxDeleta' OPERATION OP_EXCLUIR ACCESS 0    //STR0015 - Excluir

Return aRotina
 