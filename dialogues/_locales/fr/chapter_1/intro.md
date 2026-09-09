# wakeup
`c, introSetup`

`s, 0.5`Pro?`s`

`c,momKnockOnDoor`

Pro, tu es encore là-dedans?

`p,3`

![[proMeditating.png]]
......
Non.

`c, momWalkIn`

![[salviaAngry.png]]
C'est pas croyable!

![[proMeditating.png]]
`c, proDraggedOutOfBed, false``a,0.4`Ah bon?
![[proMildSurprise.png]]
Ah-!

`a,-1`
![[proNonchalant.png]]
M'man, allez, on a largement le temps.

![[salviaSerious.png]]
Il est huit heures et quart!

![[proNonchalant.png]]
Oui.

![[salviaSerious.png]]
Tu devais y être à *sept* heures! Je croyais que tu étais déjà parti!

![[pro.png]]
Euh, non, il a dit huit heures trente.

![[salviaAngry.png]]
Il a dit *pas plus tard que* huit heures trente!

![[proNonchalant.png]]
Ouais. Donc, comme je disais, on a largement le temps.

![[salviaConcern.png]]
Je-
...
J'aurais vraiment aimé que ce jour-là, au moins, on puisse compter sur toi pour prendre les choses au sérieux.

![[proRollingEyes.png]]
Allez, je suis sûr que le <span style="color:rgb(225, 188, 105)">Mécène</span> pardonnera une ponctualité moins que parfaite.

![[salviaConcern.png]]
Peut-être.
![[salviaSerious.png]]
Mais je doute qu'il apprécie qu'on le fasse attendre. Et je *sais* que le maire ne le supportera pas.

![[proCynical.png]]
Eh bien *moi* je sais que plus j'attends, moins il aura le temps de me faire la leçon.

![[salviaConcern.png]]
Il veut juste que les choses se passent bien.
On veut tous ça.

![[proMeditating.png]]
Ouais, ouais.
![[proCynical.png]]
Tu dois me superviser pendant que je m'habille?

![[salvia.png]]
...
Dépêche-toi.

`c, proGetsReady`

`x`
# interference
`c,interference`
![[proAnnoyed.png]]
(Agh.)
![[proCynical.png]]
`if turnedInHallway`
	`a,0.7`(Pourquoi je me suis retourné...)
`else`
	`face,pro,right``p,0.4`
	`a,0.7`(C'était quoi...)

![[]]`a`PRO!

`face,pro,left`
![[proMildSurprise.png]]
(Ah!)
![[proAnnoyed.png]]
J'arrive! J'arrive!

`c, proWalksDownstairs`
# downstairs

![[salvia.png]]
Attends.

`face, pro, up` `p, 0.33`

T'y vas avec ton épée?

![[proMildSurprise.png]]
Oh. Euh...

`c, momWalksToPro`

![[salviaConcern.png]]
...
Tu comptes vraiment filer dès que c'est terminé?

![[proFacade.png]]
B-bien sûr que non.

![[salviaConcern.png]]
...
Passe au moins dire au revoir, d'accord?

![[proRollingEyes.png]]
Maman, allez.

![[salviaConcern.png]]
...

`p,2.5`

![[proMildSurprise.png]]
Euh, maman?

![[salviaConcern.png]]
Tu sais que je t'aime, hein?
Je sais que ça a été difficile-

![[proEmbarrassed.png]]
Maman. S'il te plaît. Je sais.

![[salviaConcern.png]]
Ok, ok. Pardon, c'est juste que je m'inquiète parfois.

![[proBemused.png]]
Parfois?

![[salviaConcern.png]]
...
Tu n'as pas peur?

![[proSkeptical.png]]
Je devrais? Vous me répétez tous sans cesse que tout ira bien.

![[salvia.png]]
Oh, tu as raison, il n'y a rien à craindre.
Quand même, c'est un grand changement...
...

`p,0.75`

![[pro.png]]
Ahem.

![[salviaSmiling.png]]
Oui, oui. Pardon. Au revoir. Je t'aime.

![[pro.png]]
Je t'aime aussi.

`c, proWalksOut`
# outside

![[proMeditating.png]]
...
![[pro.png]]
Bon.

`c,proWalksToHall`
`a,-1`
# hallArrival

`c, hallArrival`

![[phylloSurprised.png]]
`a,0.4`!
`c, phylloRunsOff, false`Monsieur! Monsieur le Maire! Il est là!

`a,-1`

![[]]
PRO!

`c, mayorWalksDown`

![[dendro.png]]
Quelque chose s'est passé!? Ton Mécène t'a-t-il parlé?

![[proMildSurprise.png]]
Euh... non? Pas que je sache.

![[dendroAngry.png]]
Alors qu'est-ce qui t'a retenu!?

![[pro.png]]
Oh, je crois que c'était le trac.
![[proSmirk.png]]
J'étais tout simplement paralysé à l'idée de vous décevoir.

![[dendroStern.png]]
Assez de pitreries.
Même si tu ne peux pas les entendre, ton Mécène nous observe certainement déjà.

![[proBemused.png]]
Oh? Vous *sentez déjà leur présence*?

![[dendroStern.png]]
Bah, efface-donc ce sourire de ton visage. Tu vas sentir leur présence bien assez pour nous deux.
Maintenant viens, monte sur l'autel.

`c, proAndMayorGetIntoPosition, false``a,5.66`

`a,0.7`![[dendro.png]]Phyllo, les notes.

`a`![[phyllo.png]]Oui, Monsieur.

`c, phylloHandsOverScript`

![[proSkeptical.png]]
Pourquoi il est là, lui? Vous n'aviez pas dit que c'était censé rester privé?

![[dendroAngry.png]]
Parce que je ne pouvais pas gérer les préparatifs *tout seul*!
Maintenant retourne-toi, assieds-toi et tais-toi.

![[pro.png]]
Me retourner?
`face,pro,down``p,1.2`
Pour admirer les sièges vides?

![[dendroAngry.png]]
Assieds-toi.

![[proRollingEyes.png]]
...
`c, proSits`
![[dendroClearingThroat.png]]
Ahem!
![[dendroPreaching.png]]
Nous sommes réunis ici pour sceller le lien entre le <span style="color:rgb(225, 188, 105)">Héros</span> et son Mécène.
Oyez, Grand Observateur!
Vous, qui voyez et entendez ce monde, et qui, de par-delà la vitre le maintenez en vie... 
...apportez ci-bas la transformation promise!
Sous vos auspices, nous nous libérerons de l'impasse qui nous empêtre.
`p,1`
Héros!

![[pro.png]]
Oui.

![[dendroPreaching.png]]
Ils sont là, et nous avons attendu assez longtemps!
Ferme les yeux et concentre-toi!
Tends la main, et scelle le lien!

`c, proMeditates`

![[proMeditating.png]]
(Inspire lentement... puis expire...)
`c, proConnects`
(...)
(J'espère que j'arriverai à assez bien le feindre pour qu'il me laisse partir après...)
>Bonjour.
>Tu devrais faire preuve d'un plus de respect.
>Passer.

`a,0.4`(?)
![[pro.png]](Qui a dit-)

`c, proOpensEyes`

`a`
![[proMildSurprise.png]]
(Woah.)
(C'est quoi ça?)

>*Bonjour.*
>	(!?)
>	(Impossible.)
>Je ne sais pas.
>	(??)
>Passer.
>	[[#skip]]
# dad
(Papa?)
>Non.
>Non, imbécile.
>	`proAff+=1`
>Oui.
>	`var,pretendedToBeDad,1,temp`
>	![[proSkeptical.png]]
>	(Attends, sérieux?)
>	>Non.
>	>	`proAff+=1`
>	>Oui!
>	>	(Ta voix, elle semble curieusement... quelconque.)
>	>	>Mourir, ça peut faire ça.
>	>	>	![[proAnnoyed.png]]
>	>	>	(Bon, ça suffit.)
>	>	>	(Je sais qui tu es.)
>	>	>	![[proCynical.png]]
>	>	>	(Ô Mécène, mon Mécène...)
>	>	>	[[#bond1a]]
>	>	>Ok, tu m'as eu. Je ne suis pas ton père.

![[proSmile.png]]
(Haha, je sais.)
# bond1
![[proNonchalant.png]]
(Ô Mécène, mon Mécène.)
## bond1a

`p,1.5`

![[proMildlyConflicted.png]]
(...)
(Je vais être honnête, je ne m'attendais pas à ça.)
>Tu n'as pas l'air particulièrement surpris.
>	`proAff+=1`
>	![[pro.png]]
>	(Bon, *en théorie*, on me prépare pour ça depuis la naissance.)
>	![[proNonchalant.png]]
>	(Et puis, je me sens à moitié endormi.)
>	(Alors c'est peut-être juste un rêve. Encore.)
>	>!Tu as déjà rêvé à moi?
>	>	![[proHidingSomething.png]]
>	>	(... Cauchemardé, plutôt.)
>C'est quoi un Mécène?
>	![[proMildSurprise.png]]
>	(Oh, euh...)
>	(En fait, *toi*, tu te décrirais comment?)
>	>Je suis le Player.
>	>	![[proSkeptical.png]]
>	>	(« Player »?)
>	>	![[proRollingEyes.png]]
>	>	(Ah, oui. C'est comme ça que tu t'appelles dans la prophétie.)
>	>	![[pro.png]]
>	>	(Je crois que les gens n'aimaient pas trop utiliser ce nom-là.)
>	>	![[proNonchalant.png]]
>	>	(Ça donne l'impression que t'es un flambeur.)
>	>	![[proCynical.png]]
>	>	(Ou pire...)
>	>Je suis un être humain.
>	>	![[proNonchalant.png]]
>	>	(Tiens, comme c'est égalitaire.)
>	>	>Merci!
>	>	>	`proAff+=1`
>	>	>	![[proSmirk.png]]
>	>	>	(De rien.)
>	>	>	![[pro.png]]
>	>	>	(Mais ça va vite prêter à confusion.)
>	>	>Je dis juste les choses comme elles sont.
>	>	>	`proAff+=1`
>	>	>	![[proSoftSmile.png]]
>	>	>	(Je vois.)
>	>	>	![[pro.png]]
>	>	>	(Quand même, ça va vite prêter à confusion.)
>	>	>Euh, non. Toi, évidemment, tu es un sous-humain.
>	>	>	`playerCalledProSubhuman``proAff-=2`
>	>	>	![[proMocking.png]]
>	>	>	(...)
>	>	>	(Je crois que je vais m'en tenir aux termes habituels.)
>	>Je suis Dieu.
>	>	`var,calledSelfGod,1,temp`
>	>	![[proBemused.png]]
>	>	(... Tu veux vraiment que je t'appelle comme ça?)

(Tu as un nom?)
# nameEntry

`c, startNameEntry`
`x`
# nameDone
![[proNonchalant.png]]
(« <span style="color:rgb(225, 188, 105)">`$player`</span> »...)
(C'est très, euh... intéressant.)

>Merci!
>	`proAff+=1`
>	![[proBemused.png]]
>	(Y'a pas de quoi.)
>	![[proSoftSmile.png]]
>	(...)
>	(Moi, c'est Pro.)
>Oh, et c'est quoi l'histoire avec *ton* nom?
>	![[proMildSurprise.png]]
>	(!)
>	![[proEmbarrassed.png]]
>	(Tu vois maman, je savais-)
>	![[proAnnoyed.png]]
>	(...)
>	(Pas besoin de s'y attarder.)
>	>!Je veux savoir!
>	>	(Je suis sûr que ça viendra. Plus tard.)
>	![[proSkeptical.png]]
>	(... Attends, tu connais mon nom? Depuis combien de temps tu m'observes?)
>	>Depuis ton réveil.
>	>	![[proEmbarrassed.png]]
>	>	(Ah.)
>	>	![[proAnnoyed.png]]
>	>	(Eh bien, j'espère que tu t'es bien amusé à me mater...)
>	>	[[#awakening]]
>	>Pas besoin de s'y attarder.
>	>	`proAff+=1`
>	>	![[proSmirk.png]]
>	>	(Ha.)


![[proSoftSmile.png]]
(Au plaisir de travailler avec toi...)
[[#awakening]]

# skip
![[pro.png]]
(Passer?)
>Oui.
>	![[proSkeptical.png]]
>	(Qu'est-ce que ça veut dire?)
>	>Je veux juste jouer au jeu!
>	>	![[proFrustrated.png]]
>	>	(Oh, je vois, c'est juste un *jeu* pour toi, hein?)
>	>	>Oui!
>	>	>	![[proSmirk.png]]
>	>	>	(Haha, je sais.)
>	>	>	[[#bond1]]
>	>	>Attends, non, pardon.
>	>	>	![[proSmirk.png]]
>	>	>	(Haha, t'inquiète, je m'en fiche. J'ai toujours voulu dire ça.)
>	>	>	[[#bond1]]
>	>Rien, laisse tomber.
>Non.
>	![[proSkeptical.png]]
>	(Attends, tu m'entends?)
>	>Oui.
>	>Non.

![[pro.png]]
(Tu *m'entends*...)
[[#dad]]

# awakening
`c, proStopsMeditating`

![[dendro.png]]
Tu es réveillé.
C'est fait? Comment tu te sens?

![[proVeryHaughty.png]]
...
Merveilleusement bien, Monsieur le Maire.
J'ai consommé mon union avec mon Mécène. Je suis désormais leur instrument parfait dans ce monde.

![[dendroSurprised.png]]
Ah. J-je vois...

![[proSmirk.png]]
Du moins, si je devais croire cette voix fraîchement installée dans ma tête.
C'était déjà un peu bondé mais celle-ci complète bien la chorale.

![[phyllo.png]]
`face,phyllo,left``s,0.5`haha.`s`
`face,phyllo,right``c,mayorSlamsPodium`

![[dendroAngry.png]]
Le lien, Pro! A-t-il réussi ou non!?

![[proMeditating.png]]
(Tu es encore là?)
>Oui.
>Non.

![[pro.png]]
Ouais, je les entends.

![[dendroOhReally.png]]
... Tu sembles *remarquablement* imperturbé.

![[proNonchalant.png]]
Que voulez-vous, vous m'avez si bien préparé.

![[dendro.png]]
Oui, enfin, malgré tout, est-ce que ton Mécène accepterait de se soumettre à un... examen sommaire?

>Bien sûr!
>	![[proHaughty.png]]
>	Ils sont extrêmement pressés d'aller de l'avant et ne toléreront pas qu'on leur fasse perdre leur temps.
>	>!C'est pas ce que j'ai dit!
>	>	`proAff+=1`
>	>	![[proSmirk.png]]
>	>	(Ah, oups.)
>Pas d'emblée.
>	`proAff+=1`
>	![[proHaughty.png]]
>	Ils sont impatients de voir la suite.

![[dendroOhReally.png]]
Tiens, comme ça t'arrange.
![[dendroClearingThroat.png]]
Poursuivons dans ce cas... ehm...

![[phyllo.png]]
La coordination motrice?

![[dendro.png]]
Ah oui.
Si tout s'est passé tel qu'inscrit dans la prophétie, le Mécène devrait pouvoir fusionner fluidement sa volonté avec la tienne.

![[proCynical.png]]
Super. La partie flippante où on me manipule comme une marionnette.

![[dendroStern.png]]
Ne sois pas grossier.
![[dendroOhReally.png]]
Leur guidage apparaîtra tout à fait naturel, comme si tu avais voulu faire ces mouvements toi-même.

![[proAnnoyed.png]]
Tout un réconfort...
`c,proStandsUp`
`x`

# phyllo
![[proCynical.png]]
Salut.
![[phyllo.png]]
Salut...
![[proSkeptical.png]]
(Pourquoi je parle à Phyllo?)
>J'ai des questions!
>Tu as quelque chose contre Phyllo?
>	![[proCynical.png]]
>	(C'est juste que je veux me barrer d'ici.)
>Aucune raison.

![[phylloSurprised.png]]
Le- le Mécène avait besoin de quelque chose de ma part?
![[proCynical.png]]
Non. Comme je disais, il sont très pressés d'avancer.
![[phyllo.png]]
Ah. Eh bien, 
s'ils ont besoin de quoi que ce soit, vous pouvez me trouver à la bibliothèque une fois qu'on aura fini de ranger ici.
![[proCynical.png]]
Noté.
`x`
# noMovement
![[dendroSurprised.png]]
Tu attendais la permission?

![[proMildSurprise.png]]
Je... n'ai juste pas envie de bouger?

![[dendro.png]]
Hm. Eh bien, c'était prévu.
Voyons voir... Ah. Voilà.
![[dendroClearingThroat.png]]
Ahem.
![[dendroPreaching.png]]
AU SUJET DU CONTRÔLE DES MOUVEMENTS, IL EST ÉCRIT :
« LE PLAYER PEUT UTILISER WASD OU LES TOUCHES FLÉCHÉES! »

![[proNonchalant.png]]
(Quoi que ça veuille dire.)

![[dendroPreaching.png]]
AINSI PARLE LA PROPHÉTIE!
`x`
# dendro

`if !insigniaReceived`
	[[#dendroInsignia]]

![[dendro.png]]
Oui...?

![[pro.png]]
Oh, euh... j'ai juste ressenti le besoin d'attirer votre attention.

![[dendro.png]]
Fascinant.
Le Mécène a peut-être une question pour moi?

>Oui.
>	![[proHidingSomething.png]]
>	C'est le cas.
>	Mais, euh, ils ne veulent pas en discuter maintenant.
>	![[dendroSurprised.png]]
>	Je vois. Ils veulent sûrement prendre leurs repères avant tout.
>	![[dendro.png]]
>	Très bien, mon bureau est toujours ouvert.
>Non.
>	![[pro.png]]
>	Non.
>	![[dendroSurprised.png]]
>	Ah.
>	![[proSmile.png]]
>	(Wow, il a l'air sincèrement déçu.)

`x`

## dendroInsignia
![[dendro.png]]
Tiens, avant que j'oublie...
`itemCollect,stromalInsignia``insigniaReceived`
...ce badge servira à prouver ton statut auprès des bonnes personnes une fois que tu auras quitté le village.
Tu n'en auras pas besoin avant un moment, mais garde-le sur toi au cas où.
![[proNonchalant.png]]
« Avant un moment ». Ouais.
![[proThinking.png]]
...
![[proSkeptical.png]]
...au cas où quoi?
Et qui serait même au courant? C'était pas le but du <span style="color:rgb(225, 188, 105)">confinement</span> que personne dehors soit au courant?
![[dendroClearingThroat.png]]
...
Nous en discuterons plus tard, dans mon bureau.`dendroOfficeMentioned`
![[proNonchalant.png]]
... Ok.
![[dendro.png]]
C'est la porte à gauche, juste là-bas.
![[proCynical.png]]
Je sais.
![[dendroStern.png]]
Tiens! Ça m'étonne, vu la rareté de tes visites.
![[proFrustrated.png]]
...
`x`
# leaving
`if !insigniaReceived`
	`if seen`
		![[proNonchalant.png]]
		(Allons voir ce qu'il a à me donner.)
	`else`
		![[dendroSurprised.png]]
		Ah, avant que tu partes...
		![[dendro.png]]
		Viens ici, j'ai quelque chose à te donner.
		![[proSkeptical.png]]
		...?
	`walkBack,up`
	`x`

![[dendro.png]]
Prêt à partir?

>Oui.
>	![[pro.png]]
>	On dirait bien.
>	![[dendro.png]]
>	Oui, le Mécène doit vouloir jeter un coup d'œil.
>	Ça vous donnera le temps de vous acclimater. Explorez le village à votre guise.
>	Je serai dans mon bureau.
>	![[proCynical.png]]
>	Vous n'allez pas me suivre partout?
>	![[dendro.png]]
>	Comme tu as dû le constater pendant la cérémonie, les <span style="color:rgb(225, 188, 105)">prophéties</span> étaient claires quant à garder le faste au minimum.
>	![[dendroOhReally.png]]
>	Pas de grande procession, hélas.
>	![[dendro.png]]
>	Mais je suis sûr que les autres voudront tous te parler.
>	![[proCynical.png]]
>	Super.
>	![[pro.png]]
>	Bon, au revoir alors.
>	![[dendroStern.png]]
>	Bonne chance!
>	`c,proWalksIntoLobby`
>Non.
>	`if !seen`
>		![[proAnnoyed.png]]
>		`a,0.4`(*Agh*-)
>		`a`(Je *veux* partir, mais c'est comme si ma tête hurle de ne pas le faire...)
>		(Tu veux bien arrêter!?)
>		![[dendro.png]]
>		Pro?
>		![[proCynical.png]]
>		Euh, non, je ne pars pas encore.
>	`else`
>		![[proCynical.png]]
>		Pas encore.
>		![[dendro.png]]
>		Prends tout le temps qu'il te faut.
>	`walkBack,up`

`x`
# eavesdrop
`if introDone`
	`x`

![[pro.png]]
(...)
(Je les entends discuter...)
(Allons jeter un œil...)

![[phylloConcerned.png]]
Monsieur le Maire...
Est-ce qu'on va s'en sortir?

![[dendro.png]]
Nos créateurs savent ce qu'ils font.
![[dendroClearingThroat.png]]
Malgré les apparences.

![[phylloConcerned.png]]
Comment pouvez-vous être si confiant?
On n'a même pas pu faire les tests...

![[dendro.png]]
C'était juste pour notre tranquillité d'esprit. Testées ou non, les prophéties sont infaillibles.
...
Sois tranquille.
Aussi longtemps que Mécène se soucie assez de mener son rôle à bien, rien ne pourra se mettre en travers du Héros.
Compétent ou non.

![[proCynical.png]]
(... Merci pour l'encouragement.)

![[phylloConcerned.png]]
« Aussi longtemps que »?

![[dendroStern.png]]
...
Mieux vaut ne pas s'attarder là-dessus.
![[dendro.png]]
Viens, aide-moi à ranger.

![[phylloConcerned.png]]
... Oui, Monsieur le Maire.

`x`

# exitingTownHall
`c,exitedTownHall`
![[proNonchalant.png]]
(Ok.)
(On t'a envoyé pour te débarrasser de tous les <span style="color:rgb(225, 188, 105)">monstres</span>, pas vrai? Bien. Je parie que tu veux t'y mettre.)
(La sortie du village est sur ma gauche.)
(Descends ces escaliers, puis remonte vers le tronc de l'arbre.)

## exitingTownHallChoice
>Compris.
>	`proAff+=1`
>	`x`
>Je ne sais même pas de quelles sortes de monstres tu parles.[[#exitingTownHallA]]
>En fait, je croyais que c'était plutôt un jeu de ferme.[[#exitingTownHallB]]
>Pourquoi tu es si pressé de partir?[[#exitingTownHallC]]

### exitingTownHallA
![[proMildSurprise.png]]
(Eh bien, euh...)
![[proFacade.png]]
(Quoi de mieux que d'aller en trouver un pour apprendre?)
![[pro.png]]
(Allons-y.)
[[#exitingTownHallChoice]]

### exitingTownHallB
![[proSkeptical.png]]
(...)
(... C'est quoi ça?)

>Oh, tu sais, on traîne, on cultive, on développe le village, on drague les villageois peut-être. Et on combat des monstres à temps perdu.
>	![[proMildSurprise.png]]
>	Oh.
>	(Non. Tu- tu as été *mal informé*.)
>	![[proEmbarrassed.png]]
>	(On n'a besoin ni de plus de ferme, ni de finances, ni de... batifolage.)
>	![[proAnnoyed.png]]
>	(Et le développement urbain est bloqué par les monstres.)
>	(*Que* des monstres.)
>	![[proCynical.png]]
>	(Donc si tu veux aider avec *ça*, allons nous occuper d'*eux*.)
>	(Loin d'ici.)
>	[[#exitingTownHallChoice]]
>Oublie ça.
>	![[proFacade.png]]
>	(Ok. Allons-y alors.)
>	[[#exitingTownHallChoice]]


### exitingTownHallC
![[proAnnoyed.png]]
(Parce que si on ne *part* pas, ça veut dire qu'on *reste*. Quant à moi, on tombera rapidement dans le statu quo.)
![[proCynical.png]]
(Et même si tu veux juste regarder un peu autour,)
(je n'ai pas attendu ce moment pendant 20 ans juste pour servir de guide touristique.)
![[proConflicted.png]]
(De toute façon...)
![[proHidingSomething.png]]
(Y'a rien à faire ici ni personne qui mérite qu'on leur parle.)

>Ok. Allons-y alors.
>	`proAff+=1`
>	![[pro.png]]
>	(Rappelle-toi : descends les escaliers, remonte vers le tronc, puis prends les escaliers à gauche.)
>Je veux quand même regarder un peu.
>	![[proAnnoyed.png]]
>	Urgh...
>	(Si tu y tiens *vraiment*.)
>	![[proCynical.png]]
>	(Mais crois-moi, tu t'ennuieras en moins d'une heure.)
>Et ta mère?
>	`proAff+=2`
>	![[proHidingSomething.png]]
>	(... Elle s'en remettra.)
>	![[proMildlyConflicted.png]]
>	(...)
>	![[proThinking.png]]
>	(Ah, maintenant que j'y pense...)
>	![[pro.png]]
>	(J'ai laissé des affaires dans ma chambre.)`prosRoomMentioned`
>	![[proNonchalant.png]]
>	(Alors on *devrait* faire tour avant de partir.)
>Comment je suis censé découvrir ton cool backstory autrement?
>	![[proAnnoyed.png]]
>	Tu n'as pas besoin de-
>	![[proCynical.png]]
>	(Je ne vois pas en quoi ça t'aiderait à accomplir ta mission.)
>	>C'est important d'entretenir des bons rapports.
>	>	`proAff+=1`
>	>	![[proHidingSomething.png]]
>	>	Mm...
>	>Peut-être que je veux juste t'embêter.
>	>	`proAff-=0.5`
>	>	![[proAnnoyed.png]]
>	>	Urgh...


`x`

# wentLeft
![[proCynical.png]]
(Euh, j'ai dit *ma* gauche.)

>Oups, pardon!
>	(Tu me fais face...?)
>Je veux explorer.
>	![[proAnnoyed.png]]
>	(Bon, finissons-en alors.)

`x`

# runTutorial
![[proCynical.png]]
(Est-ce qu'on va juste marcher tout le long?)

>C'est important de se ménager.
>	![[proAnnoyed.png]]
>	(Je suis capable de courir un peu...)
>Comment je fais pour te faire courir?
>	![[proMocking.png]]
>	(De quoi tu-)
>	![[proThinking.png]]
>	(Oh. Attends. Le maire a mentionné un truc à ce sujet...)
>	`if gamepad`
>		(... quelque chose à propos d'un **X**? Je ne me souviens plus trop.)
>	`else`
>		(... quelque chose à propos de **Shift**? Je ne me souviens plus trop.)

`x`
# name
`if pnee,god,dieu,deus,g-d`
	`if calledSelfGod`
		![[proDisdainful.png]]
		(Allez, sérieux.)
		(Je sais que tu n'es pas un dieu.)
		![[proBemused.png]]
		(Si t'es à ce point désespéré, je peux te considérer comme une petite fée bizarre sur mon épaule.)
		![[proMocking.png]]
		(Mais j'aurais quand même besoin de ton nom.)
		[[#nameEntry]]
	`else`
		`var,calledSelfGod,1,temp`
		![[proBemused.png]]
		(... Tu veux vraiment que je t'appelle comme ça?)
		(Allez, c'est quoi ton vrai nom?)
		[[#nameEntry]]
`else if pnee,pro`
	![[proAnnoyed.png]]
	(Non, je demande *ton* nom à toi.)
	>Ouais. C'est mon nom.
	>	![[proCynical.png]]
	>	(C'est... une sacrée coïncidence.)
	>	![[proMildlyConflicted.png]]
	>	(...)
	>	![[proNonchalant.png]]
	>	(Bon, d'accord.)
	>	![[proThinking.png]]
	>	(Mais c'était le mien en premier. Alors je vais juste t'appeler... P.)`player=P`
	>	>Ok.
	>	>Non!
	>	>	![[proBemused.png]]
	>	>	(Ça me semble équitable.)
	>	>	(Sauf si tu veux que je t'appelle autrement?)
	>	>	>D'accord.
	>	>	>	[[#nameEntry]]
	>	>	>Tant pis, va pour P.
	>	>	>	![[proSmirk.png]]
	>	>	>	Super!
	>	![[proNonchalant.png]]
	>	(... Au plaisir de travailler avec toi.)
	>	[[#awakening]]
	>Ah, oui.
	>	[[#nameEntry]]
`else if pnee,minima`
	`hdOverlay,true`
	Désolé mon gars, celui-là est déjà pris.
	Bien tenté quand même.
	`hdOverlay`
	[[#nameEntry]]
`else if pnee,salvia`
	![[proCynical.png]]
	`if pretendedToBeDad`
		(D'abord mon père et maintenant ça?)
	`else`
		(... Sérieux?)
	>Quoi? C'est mon nom.
	>	![[proAnnoyed.png]]
	>	(... Et celui de ma mère.)
	>	(Purée...)
	>	![[proCynical.png]]
	>	(Juste... ne casse-moi pas les pieds, d'accord?)
	>	>Promis!
	>	>	`proAff+=1`
	>	>	![[proNonchalant.png]]
	>	>Aucune promesse.
	>	>	![[proAnnoyed.png]]
	>	(... Au plaisir de travailler avec toi.)
	>	[[#awakening]]
	>Non, je rigolais.
	>	![[proAnnoyed.png]]
	>	(Ugh, j'ai failli y croire... ça aurait été *bizarre*.)
	>	![[pro.png]]
	>	(Allez, c'est quoi ton vrai nom?)
	>	[[#nameEntry]]
`else if pnee,pike`
	![[proCynical.png]]
	(On a déjà établi que tu n'es pas mon père.)
	>C'est aussi son nom?
	>	![[proAnnoyed.png]]
	>	(Agh...)
	>	![[proCynical.png]]
	>	(Bon, d'accord. Tu peux le garder, mais ne t'attends pas à ce que je le répète aux autres.)
	>	![[proHidingSomething.png]]
	>	(...)
	>	![[proNonchalant.png]]
	>	(... Au plaisir de travailler avec toi.)
	>	[[#awakening]]
	>Haha, d'accord.
	>	![[pro.png]]
	>	(Allez, c'est quoi ton vrai nom?)
	>	[[#nameEntry]]
`else if pnee,phyllo,phylo,akro,kion,dendro,medi,api,oiko,polema,arb,hedera`
	![[proCynical.png]]
	(Quelle... coïncidence embêtante.)
	![[proNonchalant.png]]
	(... Je suppose que je peux faire avec.)
	(Au plaisir de travailler avec toi.)
	[[#awakening]]
`else if pnee,libra,xylo,trabe,hinoki,fibra,flora,erg,ergasio,chion,moriko`
	![[proNonchalant.png]]
	(Oh. Quelle coïncidence.)
	(...)
	(Enfin bon, au plaisir de travailler avec toi.)
	[[#awakening]]
`else if pnee,chara,frisk,kris,niko,shulk,juniper,joon,red,harrier,lea,ryu,mario`
	`proAff+=1`
	![[proThinking.png]]
	(... J'ai l'impression d'avoir entendu ce nom quelque part...)
	(...)
	![[proNonchalant.png]]
	(Bon, au plaisir de travailler avec toi.)
	[[#awakening]]
`else if pnee,sam`
	![[proMildSurprise.png]]
	(Oooh... vraiment?)
	>Oui.
	>Pourquoi?
	>	![[proHidingSomething.png]]
	>	(Euh... rien, c'est bon.)
	![[proAnnoyed.png]]
	(En même temps, *c'était* un nom plutôt courant...)
	![[proNonchalant.png]]
	(Bon, au plaisir de travailler avec toi.)
	[[#awakening]]
`else`
	[[#nameDone]]

`x`
