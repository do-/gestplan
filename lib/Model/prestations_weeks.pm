columns => {

	year            => {TYPE_NAME => 'int'},
	week            => {TYPE_NAME => 'tinyint'},
	id_organisation => {TYPE_NAME => 'int'},
	id_prestation   => {TYPE_NAME => 'int'},

},

keys => {

	id_prestation => 'id_prestation',
	year          => 'year, id_organisation, id_prestation',

},

