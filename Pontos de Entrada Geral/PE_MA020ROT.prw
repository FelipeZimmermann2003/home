/*
|============================================================================|
|============================================================================|
|||-----------+---------+-------+------------------------+------+----------|||
||| Funcao    | MA020ROT| Autor | Denis Rodrigues        | Data |17/04/2019|||
|||-----------+---------+-------+------------------------+------+----------|||
||| Descricao |PE: No in�cio da Fun��o, antes da execu��o da Mbrowse dos   |||
|||           |Fornecedores, utilizado para adicionar mais op��es de       |||
|||           |menu (no aRotina).                                          |||
|||           |                                                            |||
|||-----------+------------------------------------------------------------|||
||| Sintaxe   | U_MA020ROT()                                               |||
|||-----------+------------------------------------------------------------|||
||| Parametros|                                                            |||
|||-----------+------------------------------------------------------------|||
||| Retorno   |                                                            |||
|||-----------+------------------------------------------------------------|||
|||  Uso      | Especifico Totvs RS                                        |||
|||-----------+------------------------------------------------------------|||
|||                           ULTIMAS ALTERACOES                           |||
|||-------------+--------+-------------------------------------------------|||
||| Programador | Data   | Motivo da Alteracao                             |||
|||-------------+--------+-------------------------------------------------|||
|||             |        |                                                 |||
|||-------------+--------+-------------------------------------------------|||
|============================================================================|
|============================================================================|*/
User Function MA020ROT()

	Local aArea 	:= GetArea()
	Local aRotUser	:= {}

	aAdd( aRotUser, { 'Gerar Chave Portal' , 'U_TRSF110' , 0, 2 } )
	aAdd( aRotUser, { 'Configura��o Portal', 'U_TRSF111' , 0, 4 } )
	aAdd( aRotUser, { 'Cond.Pagto Portal ' , 'U_TRSF121' , 0, 5 } )

	RestArea( aArea )

Return(aRotUser)
