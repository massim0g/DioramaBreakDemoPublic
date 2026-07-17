# q0
![[]]
(Elle avait raison...)

>Non, elle avait tort.
>Ça n'a plus d'importance maintenant.
>	`revivalPoints+=1`
>C'est réducteur.

`revivalAdvance`

# q1
![[]]
(Je ne savais pas dans quoi je m'embarquais...)

>Tu peux le gérer.
>	`revivalPoints-=1`
>Je peux le gérer.
>	`revivalPoints+=1`
>On peut le gérer.
>	`revivalPoints+=1`

`revivalAdvance`
# q2
![[]]
(J'ai jamais demandé ça...)

>Si, en fait.
>Pas tout ça.
>	`revivalPoints+=1`
>Rappel que t'es né pour ça.
>	`revivalPoints-=1`

`revivalAdvance`

# q3
![[]]
(Je ne trouverai jamais ce que je cherche...)

>Pas avec cette attitude.
>	`revivalPoints+=1`
>Tu ne trouveras rien si tu meurs ici.
>Tu cherches quoi, exactement?
>	`revivalPoints-=1`

`revivalAdvance`

# q4
![[]]
`if proBladeShattered`
	(Mon épée...)
	>On t'en trouvera une nouvelle.
	>Désolé.
	>	`revivalPoints+=1`
	>C'est juste une épée. Ta vie est en jeu.
	>	`revivalPoints-=1`
`else`
	![[]]
	(Pourquoi je me suis donné la peine de m'entraîner...)
	>Tu adores ça.
	>	`revivalPoints+=1`
	>T'es doué.
	>T'étais obligé.
	>	`revivalPoints-=1`

`revivalAdvance`

# q5
(...)
>Lève-toi! S'il te plaît!
>	`revivalPoints+=1`
>Lève-toi.
>	`revivalPoints-=1`
>Pro!
>	`revivalPoints+=1`

`revivalAdvance`

# revivalStart
`c,revivalStart`
![[]]
`p,2`
(...)
`revivalAdvance`
# revivalSuccess
![[]]
(...)
![[proMeditating.png]]
(...)
![[pro.png]]
(Hm?)
(Qu'est-ce qui se passe?)
![[proMildlyConflicted.png]]
(C'est comme si tu m'appelais dans mon rêve...)
(C'était... pas désagréable.)

>Debout!

![[proMildSurprise.png]]
(Ah!)
![[proDetermined.png]]
(C'est parti!)

`revivalEnd,true`
`x`
# revivalFailure
(... j'aimerais juste qu'ils me laissent tous tranquille.)

`revivalEnd,false`
`x`
# revivalGuaranteedCatch
(...)
![[proExhausted.png]]
(Urgh... quoi...)
![[proCynical.png]]
(...qu'est-ce qui se passe?)
(J'ai l'impression d'avoir fait un cauchemar.)
(Tu... disais quelque chose?)

>Debout!

![[proMildSurprise.png]]
(Oh! O-oui!)

`revivalEnd,true`
`x`