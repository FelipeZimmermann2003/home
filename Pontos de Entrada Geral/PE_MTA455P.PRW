#INCLUDE "rwmake.ch"
#INCLUDE "protheus.ch"
/*
+-----------+-----------+-------+------------------------------------------------------+------+----------+
| Funcao    | MTA455P   | Autor | Manoel M Mariante                                    | Data |fev/2022  |
|-----------+-----------+-------+------------------------------------------------------+------+----------|
| Descricao | PE na rotina de Libera��o de Estoque MATA455 para n�o permitir liberar quando a filial     |
|           | possui WMS                                                                                 |
|           |                                                                                            |
|-----------+--------------------------------------------------------------------------------------------|
| Sintaxe   | ponto de entrada na MATA455                                                                |
+-----------+--------------------------------------------------------------------------------------------+
*/
User Function MTA455P()
	Local lRet:=.t.
	IF xFilial('SC9')$SuperGetMV('ES_FILWMS',.f.,'0104/0105')
		MsgInfo('Libera��o Manual de Estoque N�o Permitida Nessa Filial',alltrim(sb1->b1_desc))
		lRet:=.f.
	End

Return lRet
