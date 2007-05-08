################################################################################

sub do_purge_alerts {

	sql_do ("DELETE FROM alerts WHERE id IN ($_REQUEST{_ids})");
	
}

################################################################################

sub select_alerts {

	$_REQUEST {__no_focus}     = 1;	
	$_REQUEST {__meta_refresh} = 60;

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
	
	if (@$alerts) {
		my $ids = ids ($alerts);	
		sql_do ("DELETE FROM alerts WHERE id IN ($ids)");
	}
	
	return {
		alerts => $alerts,
	};
	
}

1;
