/*
+-----------+-----------+-------+-------------------------------------+------+----------+
| Funcao    | MA410MNU  | Autor | Manoel M Mariante                   | Data |11/2021   |
|-----------+-----------+-------+-------------------------------------+------+----------|
| Descricao | inclusao de bot�es no browse do mata410                                   |
|           |                                                                           |
|           |                                                                           |
|-----------+---------------------------------------------------------------------------|
| Sintaxe   | executado via menu                                                        |
+-----------+---------------------------------------------------------------------------+
*/
User Function MA410MNU()

	If ExistBlock('UNIA021')
		Aadd(aRotina,{'Envia para WMS'     ,"u_UNIA021()" ,0,1,0,.F.})
	End

Return NIL