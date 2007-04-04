#use Image::Size;
use Date::Calc qw(
	Today
	Delta_Days
	Add_Delta_YM
	Add_Delta_Days
	Monday_of_Week
	Week_of_Year
	Day_of_Week
	Days_in_Month
);
use URI::Escape;
use Digest::MD5 'md5_hex';

our $fake_select = {
	type    => 'input_select',
	name    => 'fake',
	values  => [
		{id => '0,-1', label => 'Tous'},
		{id => '-1', label => 'Supprimés'},
	],
	empty   => 'Actuels',
};

our $conf = {

	page_title => 'GestPlan',
	
	portion => 50,
	session_timeout => 30,
	lock_timeout => 10,
	
	max_len => 50,
	
	number_format => {
		-thousands_sep   => ' ',
		-decimal_point   => ',',
	},
	
	core_auto_esc   => 2,
	core_auto_edit  => 1,
	core_show_icons => 1,
	core_hide_row_buttons => 2,
	core_recycle_ids => 1,
	core_unlimit_xls => 1,
	
#	db_temporality => ['workbook', 'vacations'],
	
#	auto_load => [qw (
#		in_docs
#		in_docs_resolutions
#		out_docs
#		in_orders
#		in_orders_resolutions
#		letters
#		letters_resolutions
#	)],
	
	kb_options_menu    => {alt => 1},
	kb_options_buttons => {ctrl => 1},
	
	lang => 'FRE',
		
	i18n => {
	
		FRE => {
		
			edit   => 'éditer (F4)',
			cancel => 'retour (Esc)',
			ok     => 'appliquer (Ctrl-Enter)',
			delete => 'supprimer (Ctrl-Del)',
		
		}
	
	}

};

our @day_names = qw(
	Lundi
	Mardi
	Mercredi
	Jeudi
	Vendredi
);

our @month_names = qw(
	janvier
	février
	mars
	avril
	mai
	juin
	juillet
	août
	séptembre
	octobre
	novembre
	décembre
);

our @month_names_1 = ('', @month_names);

our $people_numbers = [
	{id => 1, label => '1'},
	{id => 2, label => '1+'},
	{id => 3, label => 'plusieurs'},
];

sub user_menu {
	
	my ($item) = @_;
	
	return undef if $item -> {fake} > 0;

	return [

		{
			type   => 'users',
			label  => 'Fiche (F2)',
			hotkey => {code => F2},
		},
		{
			type   => 'users_model',
			label  => 'Semaine modèle (F3)',
			hotkey => {code => F3},
		},
		
	],
	
};

our $DB_MODEL = {

	default_columns => {
		id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK    => 1},
		fake => {TYPE_NAME  => 'bigint'},
	},

	tables => {	
	
		roles => {
		
			data => [
				{id => 1, fake => 0, name => 'admin',      label => 'Administrateur'},
				{id => 2, fake => 0, name => 'conseiller', label => 'Utilisateur'},
				{id => 3, fake => 0, name => 'accueil',    label => 'Utilisateur restreint'},
				{id => 4, fake => 0, name => 'superadmin', label => 'Administrateur global'},
			]
			
		},

		users => {
				
			columns => {
							
				nom    => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				prenom => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				label  => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},

				dt_start    => {TYPE_NAME => 'date'},
				dt_finish   => {TYPE_NAME => 'date'},

				refresh_period  => {TYPE_NAME => 'int', NULLABLE => 0, COLUMN_DEFAULT => 60},

				id_organisation => {TYPE_NAME => 'int'},
				id_site         => {TYPE_NAME => 'int'},
				id_group        => {TYPE_NAME => 'int'},

			},

#			data => [
#				{id => 1, name => 'Admin par défaut', login => 'admin', label => 'Admin par défaut', password => '606706ad6665ce1e', id_role => 1},
#			],
			
		},
		
		organisations => {
			
			aliases => ['partners'],

			columns => {				
				label        => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				ids_partners => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				href         => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				ids_roles_prestations  => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				ids_roles_inscriptions => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			},
			
		},
		
		vocs => {

			columns => {				
				label           => {TYPE_NAME    => 'varchar', COLUMN_SIZE  => 255},
				id_organisation => {TYPE_NAME => 'int'},
			},
			
		},

		ext_field_types => {

			columns => {				
				label    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				sql_type => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				max_len  => {TYPE_NAME => 'int'},
				id_organisation => {TYPE_NAME => 'int'},
			},
			
			data => [
				{id => 1, fake => 0, label => 'liste choix',    sql_type => 'INT',     max_len => 0},
				{id => 2, fake => 0, label => 'numérique',      sql_type => 'DECIMAL', max_len => 254},
				{id => 3, fake => 0, label => 'alphanumérique', sql_type => 'VARCHAR', max_len => 255},
				{id => 4, fake => 0, label => 'logique',        sql_type => 'TINYINT', max_len => 0},
				{id => 5, fake => 0, label => 'long texte',     sql_type => 'TEXT',    max_len => 0},
			],
			
		},

		day_periods => {

			columns => {				
				label    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			},
			
			data => [
				{id => 1, fake => 0, label => 'matin'},
				{id => 2, fake => 0, label => 'après-midi'},
				{id => 3, fake => 0, label => 'tous'},
			],
			
		},

		ext_fields => {

			columns => {				
				label           => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				id_field_type   => {TYPE_NAME => 'int'},
				id_voc          => {TYPE_NAME => 'int'},
				length          => {TYPE_NAME => 'int'},
				ord             => {TYPE_NAME => 'int'},
				id_organisation => {TYPE_NAME => 'int'},
			},
			
		},

		prestation_type_groups => {

			columns => {				
				label          => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				color          => {TYPE_NAME => 'char', COLUMN_SIZE  => 6, NULLABLE => 0, COLUMN_DEFAULT => 'FFFFD0'},
			},			

		},

		prestation_type_group_colors => {

			columns => {				
				id_prestation_type_group => {TYPE_NAME => 'int'},
				id_organisation          => {TYPE_NAME => 'int'},
				color                    => {TYPE_NAME => 'char', COLUMN_SIZE  => 6, NULLABLE => 0, COLUMN_DEFAULT => 'FFFFD0'},
			},			
			
			keys => {
				id_prestation_type_group => 'id_prestation_type_group',
			},

		},

		prestation_types => {

			columns => {				
				label                      => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				label_short                => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				id_prestation_type_group   => {TYPE_NAME => 'int'},
				length                     => {TYPE_NAME => 'int'},
				length_ext                 => {TYPE_NAME => 'int'},
				id_day_period              => {TYPE_NAME => 'int', NULLABLE => 0, COLUMN_DEFAULT => 3},
				is_half_hour               => {TYPE_NAME => 'tinyint'},
				is_multiday                => {TYPE_NAME => 'tinyint'},
				is_placeable_by_conseiller => {TYPE_NAME => 'tinyint'},
				is_private                 => {TYPE_NAME => 'tinyint'},
				ids_ext_fields             => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				ids_roles                  => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				ids_rooms                  => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				ids_users                  => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				id_people_number           => {TYPE_NAME => 'int'},
				is_to_edit                 => {TYPE_NAME => 'tinyint'},
				id_organisation            => {TYPE_NAME => 'int'},
				is_open                    => {TYPE_NAME => 'tinyint'},
				no_stats                   => {TYPE_NAME => 'tinyint'},
				time_step                  => {TYPE_NAME => 'tinyint'},
				half_1_h                   => {TYPE_NAME => 'tinyint'},
				half_1_m                   => {TYPE_NAME => 'tinyint'},
				half_2_h                   => {TYPE_NAME => 'tinyint'},
				half_2_m                   => {TYPE_NAME => 'tinyint'},
			},
			
			data => [
				{
					id          => -1,
					fake        => -2,
					label       => 'Retraîte',
					label_short => 'RET',
					is_multiday => 1,
				},
			],
			
		},

		prestation_types_ext_fields => {

			columns => {				
				id_prestation_type => {TYPE_NAME => 'int'},
				id_ext_field       => {TYPE_NAME => 'int'},
				ord                => {TYPE_NAME => 'int'},
			},
			
			keys => {
				id_prestation_type => 'id_prestation_type',
			},

		},

		inscriptions => {
				
			columns => {				

				id_prestation  => {TYPE_NAME => 'int'},
				
				label          => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

				nom            => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				prenom         => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

				hour           => {TYPE_NAME => 'tinyint'},
				minute         => {TYPE_NAME => 'tinyint'},

				hour_start     => {TYPE_NAME => 'tinyint'},
				minute_start   => {TYPE_NAME => 'tinyint'},

				hour_finish    => {TYPE_NAME => 'tinyint'},
				minute_finish  => {TYPE_NAME => 'tinyint'},

				id_user        => {TYPE_NAME => 'int'},
				
			},
			
			keys => {
				'id_prestation' => 'id_prestation',
			},
			
		},

		prestations => {
				
			columns => {				

				dt_start    => {TYPE_NAME => 'date'},
				half_start  => {TYPE_NAME => 'tinyint'},

				dt_finish   => {TYPE_NAME => 'date'},
				half_finish => {TYPE_NAME => 'tinyint'},

				id_user     => {TYPE_NAME => 'int'},
 				id_users    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

				id_prestation_type => {TYPE_NAME => 'int'},

				note        => {TYPE_NAME => 'text'},

				id_prestation_model => {TYPE_NAME => 'int'},

 			},
			
		},
		
		prestation_models => {
				
			columns => {				

				day_start   => {TYPE_NAME => 'int'},
				half_start  => {TYPE_NAME => 'tinyint'},

				day_finish  => {TYPE_NAME => 'int'},
				half_finish => {TYPE_NAME => 'tinyint'},

				id_user     => {TYPE_NAME => 'int'},
 				id_users    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},

				id_prestation_type => {TYPE_NAME => 'int'},

				note        => {TYPE_NAME => 'text'},
				is_odd      => {TYPE_NAME => 'tinyint', NULLABLE => 0, COLUMN_DEFAULT => 0},

 			},
 			
 			keys => {
 				id_user => 'id_user',
			},
			
		},

		off_periods => {
				
			columns => {				

				dt_start    => {TYPE_NAME => 'date'},
				half_start  => {TYPE_NAME => 'tinyint'},

				dt_finish   => {TYPE_NAME => 'date'},
				half_finish => {TYPE_NAME => 'tinyint'},

				id_user     => {TYPE_NAME => 'int'},

			},
			
		},

		alerts => {
				
			columns => {				

				id_inscription => {TYPE_NAME => 'int'},
				id_user        => {TYPE_NAME => 'int'},

			},
			
		},

		week_status_types => {

			columns => {				
				label    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
			},
			
			data => [
				{id => 1, fake => 0, label => 'Construction'},
				{id => 2, fake => 0, label => 'Actif'},
				{id => 3, fake => 0, label => 'Clôt'},
			],
			
		},

		week_status => {

			columns => {				
				id_week_status_type => {TYPE_NAME => 'int'},
				year => {TYPE_NAME => 'int'},
				week => {TYPE_NAME => 'int'},
				id_organisation => {TYPE_NAME => 'int'},
			},
			
		},
		
		rooms => {

			columns => {				
				label           => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				id_organisation => {TYPE_NAME => 'int'},
				id_site         => {TYPE_NAME => 'int'},
			},
						
		},

		sites => {

			columns => {				
				label    => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				id_organisation => {TYPE_NAME => 'int'},
			},
						
		},

		groups => {

			columns => {				
				label           => {TYPE_NAME => 'varchar', COLUMN_SIZE  => 255},
				ord             => {TYPE_NAME => 'int'},
				id_organisation => {TYPE_NAME => 'int'},
				id_role         => {TYPE_NAME => 'int'},
			},
						
		},
		
		prestations_rooms => {
				
			columns => {				

				id_prestation  => {TYPE_NAME => 'int'},				
				id_room        => {TYPE_NAME => 'int'},				

				dt_start       => {TYPE_NAME => 'date'},
				half_start     => {TYPE_NAME => 'tinyint'},

				dt_finish      => {TYPE_NAME => 'date'},
				half_finish    => {TYPE_NAME => 'tinyint'},
				
			},
			
			keys => {
				'id_prestation' => 'id_prestation',
			},
			
		},
		
		
	}

};

################################################################################

sub week_status {

		my ($date, $id_organisation) = @_;	
		
		$id_organisation ||= $_USER -> {id_organisation};
		
		my @date  = reverse split /\D+/, $date;
		
		my $status = sql_select_scalar ('SELECT id_week_status_type FROM week_status WHERE week = ? AND year = ? AND id_organisation = ?', Week_of_Year (@date), $id_organisation);
		
		$status ||= is_past ($date) ? 3 : 1;
			
		return $status;

}

################################################################################

sub is_past {

		my ($date) = @_;	
		
		my @wdate  = Week_of_Year (reverse split /\D+/, $date);

		my @wtoday = Week_of_Year (Today);

		return 0 if $wdate [1] > $wtoday [1];		
		return 1 if $wdate [1] < $wtoday [1];		
		return 1 if $wdate [0] < $wtoday [0];		
		return 0;

}

################################################################################

sub get_page {}

################################################################################

sub __d {
	my ($data, @fields) = @_;	
	map {$data -> {$_} =~ s{(\d\d\d\d)-(\d\d)-(\d\d)}{$3\/$2\/$1}} @fields;	
	map {$data -> {$_} =~ s{00\/00\/0000}{}} @fields;	
}

################################################################################

sub del {

	my ($data) = @_;
	
	return () if $_REQUEST {__no_navigation};
	
	return (
		{
			preset  => 'delete',
			href    => {action => 'delete'},
			target  => 'invisible',
			confirm => 'Supprimer cette fiche, vous êtes sûr ?',
			off     => $data -> {fake} != 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup},
		},		
		{
			icon    => 'create',
			label   => 'restaurer',
			href    => {action => 'undelete'},
			target  => 'invisible',
			confirm => 'Restaurer cette fiche, vous êtes sûr ?',
			off     => $data -> {fake} >= 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup},
		}
	);

}

################################################################################

sub iframe_alerts {

	$_USER -> {role} eq 'conseiller' or return '';
	
	my $salt = rand * time;

	return <<EOH;
		<iframe style="display:none" name="alerts" src="/?sid=$_REQUEST{sid}&type=alerts&_salt=$salt">
		</iframe>
EOH

}

################################################################################

sub extra_menu {

	my $href = sql_select_scalar ('SELECT href FROM organisations WHERE id = ?', $_USER -> {id_organisation}) or return ();
	
    return {
    	label => 'Intranet',
    	href => 'http://' . $href . '#',
    	target => '_blank',
	}		

}

################################################################################

sub stat_menu {

	my ($year, $month, $day) = Today;
	
	my @acl = ();
	
	if ($_USER -> {role} eq 'admin') {
		
		@acl = (
			
			{
				name  => 'organisations_acl',
				label => "Droits d'accès",
			},
			
		);
		
	}
	
	my $organisation = sql_select_hash ('organisations', $_USER -> {id_organisation});
	
	my @prestations = ();
	
	if ($organisation -> {ids_roles_prestations} =~ /\,$$_USER{id_role}\,/) {
		
		@prestations = (

			{
				name  => 'stats_prestations',
				label => 'Prestations par mois',
			},
			{
				href  => "/?type=stats_prestations&month=$month",
				label => 'Conseillers mensuel',
			},
			{
				href  => "/?type=stats_prestations&month=-1",
				label => 'Conseillers annuel',
			},

		);
		
	}
	
	my @inscriptions = ();
	
	if ($organisation -> {ids_roles_inscriptions} =~ /\,$$_USER{id_role}\,/) {
		
		@inscriptions = (

			{
				name  => 'stats_inscriptions',
				label => 'Jeunes par prestation',
			},
			{
				href  => "/?type=stats_inscriptions&month=$month",
				label => 'Jeunes mensuel',
			},
			{
				href  => "/?type=stats_inscriptions&month=-1",
				label => 'Jeunes annuel',
			},
			{
				href  => "/?type=stats_inscriptions&id_user=-1",
				label => 'RDV non venus',
			},

		);
		
	}
	
	my @menu = @prestations;
	
	if (@inscriptions) {
		push @menu, BREAK;
		push @menu, @inscriptions;		
	}

	if (@acl) {
		push @menu, BREAK;
		push @menu, @acl;	
	}
	
	return () if @menu == 0;	

	return {

		label   => 'Statistiques',
		no_page => 1,
		items   => \@menu,
	};

}

################################################################################

sub draw__boot {

	$_REQUEST {__no_navigation} = 1;
	
	my $propose_gzip = 0;
	if (($conf -> {core_gzip} or $preconf -> {core_gzip}) && ($r -> header_in ('Accept-Encoding') !~ /gzip/)) {
		$propose_gzip = 1;
	}

	$_REQUEST {__on_load} = <<EOJS;
	
		
		if (navigator.appVersion.indexOf ("MSIE") != -1 && navigator.appVersion.indexOf ("Opera") == -1) {

			var version=0;
			var temp = navigator.appVersion.split ("MSIE");
			version  = parseFloat (temp [1]);

			if (version < 5.5) {
				alert ("Attention! Cette application WEB requiert le navigateur MS Internet Explorer version 5.5 ou plus moderne. Pour l'instant vous utilisez " + version + '.');
				document.location.href = 'http://www.microsoft.com/ie';
				return;				
			}

		}
		else {
		
			var brand = navigator.appName;
		
			if (navigator.appVersion.indexOf ("Opera") > -1) {
				brand = 'Opera';
			}

			alert ('Attention! Cette application WEB requiert le navigateur MS Internet Explorer.');
			
		}					
						
		nope ('$_REQUEST{__uri}?type=logon&redirect_params=$_REQUEST{redirect_params}', '_self');

		setTimeout ("document.getElementById ('abuse_1').style.display = 'block'", 10000);
		
EOJS

	return <<EOH
	
			<img src="/0.gif" width=100% height=20%>
		
			<center>
						
EOH

}


1;
