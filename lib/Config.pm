#use Image::Size;
use Date::Calc qw(
	Today
	Delta_Days
	Add_Delta_YM
	Add_Delta_Days
	Day_of_Week
	Days_in_Month
	Monday_of_Week
	Week_of_Year
);

#sub Week_Number_Shift {
#
#	my ($year) = @_;
#	
#	my ($w, $y) = Date::Calc::Week_of_Year ($year, 1, 1);
#	
#	return $year == $y ? 0 : 1;
#
#}
#
#sub Week_of_Year {
#
#	my ($year, $month, $day) = @_;
#	
#	my ($w, $y) = Date::Calc::Week_of_Year ($year, $month, $day);
#	
#	return ($w + Week_Number_Shift ($y), $y);
#
#}
#
#sub Monday_of_Week {
#
#	my ($week, $year) = @_;
#	
#	$week -= Week_Number_Shift ($year);
#	
#	return Date::Calc::Monday_of_Week ($week, $year);
#
#}

use URI::Escape;
use Digest::MD5 'md5_hex';
use LockFile::Simple qw(lock trylock unlock);

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
	core_recycle_ids => 0,
	core_unlimit_xls => 1,
	core_skip_boot   => 1,
	
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
		
			edit   => '�diter (F4)',
			cancel => 'retour (Echap)',
			ok     => 'enregistrer (Ctrl-Entr�e)',
			delete => 'supprimer (Ctrl-Supp)',
		
		}
	
	}

};

our @day_names = qw(
	Lundi
	Mardi
	Mercredi
	Jeudi
	Vendredi
	Samedi
	Dimanche
);

our @month_names = qw(
	janvier
	f�vrier
	mars
	avril
	mai
	juin
	juillet
	ao�t
	septembre
	octobre
	novembre
	d�cembre
);

our @month_names_1 = ('', @month_names);

sub get_skin_name {

	$_REQUEST {__dump} ? 'Dumper' :
	$_REQUEST {xls}    ? 'XL' :
	'TurboMilk'
	
}

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
			label  => 'Semaines mod�les (F3)',
			hotkey => {code => F3},
		},
		
	],
	
};

our $DB_MODEL = {

	default_columns => {
		id   => {TYPE_NAME  => 'int', _EXTRA => 'auto_increment', _PK    => 1},
		fake => {TYPE_NAME  => 'bigint'},
	},

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
			confirm => 'Supprimer cette fiche, vous �tes s�r ?',
			off     => $data -> {fake} != 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup},
		},		
		{
			icon    => 'create',
			label   => 'restaurer',
			href    => {action => 'undelete'},
			target  => 'invisible',
			confirm => 'Restaurer cette fiche, vous �tes s�r ?',
			off     => $data -> {fake} >= 0 || !$_REQUEST {__read_only} || $_REQUEST {__popup},
		}
	);

}

################################################################################

sub iframe_alerts {

	my $salt = rand * time;

	return <<EOH;
		<iframe style="display:none" name="alerts" src="$_REQUEST{__uri}?sid=$_REQUEST{sid}&type=alerts&_salt=$salt">
		</iframe>
EOH

}

################################################################################

sub support_menu {
	
	foreach (split /,/, $_USER -> {options}) {
	
		$_USER -> {options_hash} -> {$_} = 1;
		
	}

	$_USER -> {options_hash} -> {support} or return ();

    return {
    
		label => 'Support',
		name  => 'tasks',
    	
    	items => [
    	
    		{
				label => 'Correspondance',
				name  => 'task_notes',
			},
			
		],
    	
    }

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
				label => "Droits d'acc�s",
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
				label => 'Utilisateurs mensuel',
			},
			{
				href  => "/?type=stats_prestations&month=-1",
				label => 'Utilisateur annuel',
			},

		);
		
	}
	
	my @inscriptions = ();
	
	if ($organisation -> {ids_roles_inscriptions} =~ /\,$$_USER{id_role}\,/) {
		
		@inscriptions = (

			{
				name  => 'stats_inscriptions',
				label => 'RDV par prestation',
			},
			{
				href  => "/?type=stats_inscriptions&month=$month",
				label => 'RDV mensuel',
			},
			{
				href  => "/?type=stats_inscriptions&month=-1",
				label => 'RDV annuel',
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

################################################################################

sub draw_auth_toolbar {

	j q {$('#body_table tr:first', top.document).hide ()};
	
};

1;
