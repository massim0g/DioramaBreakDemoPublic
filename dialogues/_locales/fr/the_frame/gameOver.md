`steward,l,neutral`
`steward,r,neutral`

`if diedTo=="consequenceAmbush"`
	[[#diedToConsequenceAmbush]]
`else if diedTo=="consequence"`
	[[#diedToConsequence]]
`else if diedTo=="hatingMinima"`
	`steward,r,annoyed`
	Wow, sérieusement...
	`steward,l,irked`
	Allons, allons. C'était leur décision.
	`steward,l,stern,neutral`
	Ceci dit, je me dois de vous mettre en garde que cultiver autant de... distance... risque de ternir votre appréciation générale de l'activité en cours.
	`steward,r,giveUp`
	Bon. Retour au dernier point de sauvegarde, alors.
	>!Quoi!? Non!
	>	`steward,r,annoyed`
	>	Vous vous attendiez à quoi?
	>	`steward,r,presenting,neutral`
	>	Haut les cœurs!
	`steward,r,neutral`
	3...2...1...
	`if !gameLoad`
		[[#loadFailed]]
	`x`

`if deathMessageDefaultSeen`
	[[#diedBefore]]

`var, deathMessageDefaultSeen, 1, persistent`

Ooh, ça fait mal.

>Que s'est-il passé?
>	`steward,l,neutral`
>	Vous avez malheureusement perdu tout moyen de maintenir votre connexion au Diorama.
>	`steward,r,cheeky`
>	Wow, quelle façon délicate d'annoncer que « tous vos amis sont morts ».
>Zut.
>	`steward,r,cheeky`
>	Wow, c'est tout ce que vous trouvez à dire face à la mort de tous vos amis?
>	>!Quoi, vous voulez que je pleure et rage?
>	>	`steward,r,cheery`
>	>	La catharsis, c'est bon pour l'âme!
>	>Je ne réalisais pas...
>	>	`steward,r,cheeky`
>	>	Oh. Et dire que je croyais que le grand flash rouge était assez évident comme signe...

`steward,r,presenting,neutral`
Bref, ne vous en faites pas, nous avons prévu cette éventualité.
`steward,l,neutral`
Oui, comme pour toute forme de déconnexion, le monde reprendra au dernier point d'attache à avoir été fixé.
C'est-à-dire, la dernière fois où vous avez approché une Fixation.
Les habitants du Diorama ne conserveront naturellement aucun souvenir des événements annulés.
`steward,l,bowing`
Sur ce, ne prenons pas davantage de votre temps.
`steward,r,cheery`
Voilà!
`steward,r,neutral`
3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`
# diedToMonsters
`x`

# diedToConsequenceAmbush
`if deathMessageConsequenceAmbushSeen`
	[[#diedBefore]]

`var, deathMessageConsequenceAmbushSeen, 1, persistent`

`steward,r,giveUp`
Ooh, ça fait mal.
`steward,l,neutral`
Oui, malheureux en effet.
Avec la mort de votre protégé, vous avez perdu tout moyen de maintenir votre connexion au Diorama.
`steward,r,cheeky`
Fallait surveiller les embuscades!

>Zut.
>	`steward,r,neutral`
>	...
>	Je sens que vous trouvez ça un peu injuste, pas vrai?
>C'est ridicule! Il n'y avait aucun moyen d'éviter ça!
>	`steward,r,cheeky`
>	« Aucun moyen d'éviter ça »?
>	Vous m'avez l'air en pleine forme, pourtant.
>	>Vous savez très bien ce que j'essaie de vous dire.
>	>Et Pro?
>	`steward,r,cheery`
>	Haha, d'accord.

`steward,r,neutral`
Vous avez droit à un nouvel essai.
`steward,r,giveUp`
Pourtant, ça devrait largement suffire pour considérer ce combat comme équitable...
`steward,r,cheeky`
...À défaut de quoi, pourquoi ne pas faire participer vos amis?

`steward,l,neutral`
Oui.
En cas de déconnexion, le monde reprendra au dernier point d'attache à avoir été fixé.
C'est-à-dire, la dernière fois où vous avez visité une Fixation.
Vous pourrez continuer à partir de là, mais les habitants du Diorama ne conserveront naturellement aucun souvenir des événements annulés.
`steward,l,presenting`
Ceci dit, dans certains cas, vous aurez l'occasion de prévenir votre protégé du danger imminent qui l'attend.

`steward,r,cheery`
Eh oui! Comme ça, tout le monde peut apprendre de vos erreurs!
`steward,r,presenting`
Alors ne ratez pas votre chance!
`steward,l,bowing`
Sur ce, ne prenons pas davantage de votre temps.
`steward,r,cheery`
Voilà!
`steward,r,neutral`
3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`

# diedToConsequence
`if deathMessageConsequenceSeen`
	[[#diedBefore]]

`var, deathMessageConsequenceSeen, 1, persistent`

`steward,r,giveUp`
Pfft. Il est coriace, celui-là, hein?

>!...ça veut dire que je dois retourner au camp?
>	`steward,r,cheery`
>	Non!

`steward,r,neutral`
Normalement on vous renverrait à la dernière Fixation visitée, mais un nouveau lien, c'est une occasion spéciale!
`steward,l,neutral`
Oui, de tels événements ne s'annulent pas si facilement.
Vous vivrez de nouveau le moment où votre nouveau lien a été scellé.
`steward,r,presenting,neutral`
N'oubliez pas, c'est du 2 contre 1 maintenant. Repoussez-le! À lui de subir la pression maintenant!
`steward,r,cheery`
Donnez-vous à fond!
`steward,r,neutral`
3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`

# diedBefore
`steward,r,giveUp`
Oups.
...
`steward,r,annoyed`
Désolée, on n'a pas eu le temps de préparer un discours pour ça.
En même temps, y'avait qu'à pas mourir plusieurs fois.
`steward,l,irked`
Je... vais vous y renvoyer.
`steward,l,neutral`
À moins que vous ne souhaitiez faire une pause?
>Ça va, renvoyez-moi.
>	`steward,l,bowing`
>	Compris.
>	`steward,l,neutral`
>	1...2...3...
>	`if !gameLoad`
>		[[#loadFailed]]
>	`x`
>Oui, j'aimerais faire une pause.
>	`steward,l,bowing`
>	Très bien. Nous attendrons votre retour avec impatience.
>	`steward,r,annoyed`
>	Pas moi! Rester planté là comme ça finit par devenir lassant, vous savez.
>	`steward,l,sternRight`
>	...
>	`steward,r,giveUp,neutral`
>	Je plaisante! Je plaisante!
>	`steward,r,cheery`
>	À bientôt!
>	`x`

`x`

# loadFailed

`steward,r,neutral`
...
`steward,r,annoyed`
...
B-bon, euh, c'est un peu gênant...
Il semble qu'il y ait eu un problème au chargement de votre fichier de sauvegarde...
`steward,r,giveUp`
Vous avez mis de la poussière dans votre carte mémoire ou quoi ?
`steward,l,irked`
Ahem. Ce n'est pas drôle.
`steward,l,irked,neutral`
Nous sommes terriblement désolés, mais nous sommes malheureusement limités dans l'aide que nous pouvons apporter dans cette situation.
`steward,l,neutral`
Votre fichier de sauvegarde se trouve dans **%APPDATA%/../Local/DioramaBreak**. Nous vous recommandons de le récupérer et de demander de l'aide sur Steam ou sur le serveur Discord officiel.
`steward,r,giveUp`
Désolé pour ça.
...
`steward,r,neutral`
Bon...
À plus.
`x`