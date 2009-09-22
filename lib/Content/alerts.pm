################################################################################

sub do_purge_alerts {

	sql_do ("DELETE FROM alerts WHERE id IN ($_REQUEST{_ids})");
	
}

################################################################################

sub select_alerts {

	$_REQUEST {__no_focus}     = 1;	
	$_REQUEST {__meta_refresh} = 60;
	
	my $meta_refresh = qq {<META HTTP-EQUIV=Refresh CONTENT="$_REQUEST{__meta_refresh}; URL=@{[create_url()]}&__no_focus=1">};

	my $alerts = sql_select_all (<<EOS, $_USER -> {id}, sprintf ('%04d-%02d-%02d', Today ()));
		SELECT
			inscriptions.*
			, alerts.id
		FROM
			alerts
			INNER JOIN inscriptions ON alerts.id_inscription = inscriptions.id
			INNER JOIN prestations  ON inscriptions.id_prestation = prestations.id
		WHERE
			alerts.id_user = ?
			AND prestations.dt_start = ?
		ORDER BY
			inscriptions.nom
			, inscriptions.prenom
EOS

	@$alerts or return out_html ({}, qq{<html><head>$meta_refresh</head></html>'});
	
	my $ids = ids ($alerts);	

	sql_do ("DELETE FROM alerts WHERE id IN ($ids)");

	my ($data) = @_;

	my $text = '';
	
	my $ids = '-1,';
	
	foreach my $alert (@$alerts) {

		$text .= "$$alert{nom} $$alert{prenom} est arrivé(e) à $$alert{hour}h$$alert{minute}.\\n";
		
		$ids  .= $alert -> {id};
		$ids  .= ',';
	
	}
	
	$ids  .= '-1';

	$text or return '';
	
	my $salt = rand * time;

	out_html ({}, <<EOH);
<html>
	<head>
		
		$meta_refresh
		
		<script>
		
			function l () {
		
				var w = window;
			
				for (var i = 0; i < 10; i ++) {
					
					if (!w.parent) break;
					
					w = w.parent;
					
				}
				
				if (! $_USER->{no_popup}) w.showModalDialog ('/i/close.html?$_REQUEST{salt}', window);
				
				w.alert ("$text");
				
			}
					
		</script>
	</head>
	<body onload="l()">
	</body>
EOH

}

1;
