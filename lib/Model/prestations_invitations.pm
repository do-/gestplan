label => 'Prestations cr��es comme invitations',

columns => {

	id_prestation  => '(prestations)',  # La prestation-invitation
	id_inscription => '(inscriptions)', # L'inscription pour laquelle cette prestation est cr��e

},

keys => {
	id_prestation => 'id_prestation',
},

