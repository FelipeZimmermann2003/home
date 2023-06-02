#Include "Totvs.ch"

/*/{Protheus.doc} MT150ROT
    Fun��o da atualiza��o de cota��es. EM QUE PONTO : No inico da rotina e antes da execu��o da Mbrowse da cota��o, utilizado para adicionar mais op��es no aRotina.
    @type  Function
    @author Denis Rodrigues
    @since 19/04/2022
    @version version
    @param param_name, param_type, param_descr
    @return return_var, return_type, return_description
    @example (examples)
    @see https://tdn.totvs.com/pages/releaseview.action?pageId=6085637
/*/
User Function MT150ROT()

    aAdd ( aRotina, { 'Mensagem Forn.',"U_TRSF150(SC8->C8_NUM,SC8->C8_FORNECE,SC8->C8_LOJA)", 0, 4 } )
    
Return( aRotina )
