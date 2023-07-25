#Include 'totvs.ch'

/*/{Protheus.doc} User Function LJ7041 
	O ponto de entrada LJ7041 ocorre antes de chamar a fun��o Lj7VerEst (que valida o saldo em estoque do almoxarifado) 
	e permite ao cliente personalizar dinamicamente o almoxarifado padr�o do item de venda, alterando o conte�do da 
	vari�vel cLocal na inclus�o.
	@type  Function
	@author Daniel Barcelos
	@since 04/01/2022
	@version 1.0
	@param param_name, param_type, param_descr
	@return return_var, return_type, return_description
	@example(examples)
	@see (links_or_references)
/*/
 
User function LJ7041() 

	Local cLocLj := GetMv("ES_LOCLOJ")

Return cLocLj   
   

User Function GTL2TGRT()
	
	Local _nPosLocal := aScan( aHeaderDet, { |x| Trim(x[2]) == 'LR_LOCAL' })
	Local _cLocal    := GetMv("ES_LOCLOJ") //C�digo do Armaz�m

	If Len(aColsDet) >= n
    	aColsDet[n][_nPosLocal] := _cLocal //C�digo do Armaz�m
	Endif

Return _cLocal   

