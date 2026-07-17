# firstImpressions
`c,proWalksAlongForestPath,false`
![[proThinking.png]]
(Je me demande comment sont les gens à l'extérieur.)
![[pro.png]]
(J'ai jamais vraiment eu l'occasion de faire une première impression.)
>!Et moi?
>	`proAff+=1`
>	![[proNonchalant.png]]
>	(Oh. Bon, on va dire que ça compte.)
>	![[proRollingEyes.png]]
>	(J'aimerais être un peu mieux préparé pour cette éventualité, t'en conviendras.)
>Comment ça?
>	`proAff+=1`
>	![[proNonchalant.png]]
>	(Ben, parce que tout le monde au village me connaît depuis que je suis bébé.)

`var,doneTalking``a,-1`
`x`

# firstMonsterEncounter
`c,monsterReveal`
`x`
## firstMonsterEncounterStarted
![[proPanicked.png]]
(AH!!)
>!AAH!!
>	![[proPanickedHeadTurnSpeedLines.png]]
>	(AAAH!!!)
>	![[proFearful.png]]
>	(AAaah...)
>	![[proAnnoyed.png]]
>	(...)
>	>J'ai eu peur!
>	>	![[proStressed.png]]
>	>	(On s'en occupe, c'est tout...)
>	>...
>	>	![[proMocking.png]]
>	>	(De quoi t'as peur, *toi*...?)
>	>	(...)
>	>	![[proAnnoyed.png]]
>	>	(Haah...)
>	>	![[proStressed.png]]
>	>	(On s'en occupe, c'est tout.)
>	`x`

![[proFearful.png]]
(...)
![[proAnnoyed.png]]
(Haah...)
![[proStressed.png]]
(Bon. On peut gérer, pas de soucis...)
>Oui, ça a l'air facile.
>	![[proStressed.png]]
>	(Super. Tue-le vite.)
>Tu as peur?
>	![[proAnnoyed.png]]
>	(Non!)
>	![[proStressed.png]]
>	(Il- il est seul, c'est pas si dangereux que ça, non?)

`x`
## firstMonsterHit
![[proHit.png]]
Gh-
![[proFearful.png]]
(C'est... ok, ça va.)
`tookDamageFromFirstMonster`
`x`

## firstMonsterDefeated
![[proMildSurprise.png]]
Bien!
![[proNonchalant.png]]
(C'était pas si éprouvant que ça! Ils craignent quoi les autres, au juste?)
![[proThinking.png]]
(Faut admettre que le pouvoir d'arrêter le temps y est pour quelque chose.)
>!Et pas mon impeccable guidage stratégique?
>	![[proBemused.png]]
>	(Euh, si tu veux.)

`if tookDamageFromFirstMonster`
	![[proMildlyConflicted.png]]
	(Quand même, on devrait faire plus attention à pas prendre de coups.)
	(L'<span style="color:rgb(225, 188, 105)">Air</span> ici est... faible. J'ai pas l'impression de pouvoir récupérer aussi facilement...)
`else`
	![[proConflicted.png]]
	(... Heureusement qu'on a pas pris de coups. L'<span style="color:rgb(225, 188, 105)">Air</span> ici est... faible.)
	(J'ai pas l'impression de pouvoir récupérer aussi facilement...)

`firstMonsterDefeated`
`inIrisIntro=2`
`camReset`
`x`

# deepShrine
![[minimaSurprisedSmile.png]]
Oh! La voilà!

`c,minimaWalksToFixture`

![[minimaSmile.png]]
Cette <span style="color:rgb(225, 188, 105)">Fixation</span> ne protège qu'une petite zone, mais on devrait être à l'abri des monstres ici.

![[pro.png]]
Cool.
>!C'est comme celle qui protège ton village?
>	(Ouais. Plus petite par contre.)

`x`
## deepShrineChest
`if seen`
	![[pro.png]]
	(Il reste plus rien ici à ma taille.)
	`x`

![[pro.png]]
Il y a quoi dans ce coffre?

![[minima.png]]
Les facteurs les gardent approvisionnés en fournitures et équipement.
![[minimaSmile.png]]
Jette un œil, tu trouveras peut-être quelque chose à ta taille.

![[proSkeptical.png]]
Ça les dérange pas qu'on prenne des trucs?

![[minimaLecturing.png]]
Non, c'est fait pour ça.
De toute façon, y'a qu'eux et nous qui passent par ici, et personne d'autre.

`p,1.5`

![[proRollingEyes.png]]
(On dirait qu'il y a pas grand-chose à prendre dans tous les cas..)

`itemCollect,normalBoots`
`gameSave`
`x`

# craft
`if irisVestFixed&&irisBootsFixed`
	![[pro.png]]
	(Je crois qu'on a pris tout ce qu'il pourrait y avoir d'utile ici.)
	`x`

`if !seen`
	![[proCynical.png]]
	Hm. Il y a du vieil équipement, mais ça a pas l'air très utilisable.
	`s,0.5`Qui est-ce qui balance ses déchets ici?`s`
	![[minimaLeaningIn.png]]
	Non, ça a l'air tout à fait réparable.
	![[minimaSmile.png]]
	Si tu ramasses assez de matériaux utiles dans la forêt, je peux probablement remettre tout ça en état.
	>!Elle peut faire ça?
	>	![[proSkeptical.png]]
	>	... Vraiment?
	>	![[minimaEmbarassed.png]]
	>	Ben... c'était au programme du cours de survie que j'ai suivi du moins.
	>	![[proThinking.png]]
	>	Ah...
	>	![[proMildlyEmbarassed.png]]
	>	(J'aurais probablement dû mieux écouter quand Fibra enseignait ce genre de trucs...)
	>	![[proFacade.png]]
	>	Bon, on risque rien à essayer.
	>	![[minimaSmile.png]]
	>	Cool!
	[[#craftCost]]
## craftChoice
![[minimaSmile.png]]
Alors, qu'est-ce que ce sera?
>Réparer le gilet.`if !irisVestFixed`
>	![[pro.png]]
>	Répare le gilet, s'il te plaît.
>	![[minimaCheeky.png]]
>	C'est parti!
>	`c,fixVest`
>	`if craftFailed`
>		[[#craftFail]]
>Réparer les bottes.`if !irisBootsFixed`
>	![[pro.png]]
>	Répare les bottes.
>	![[minimaCheeky.png]]
>	C'est parti!
>	`c,fixBoots`
>	`if craftFailed`
>		[[#craftFail]]
>Réparer les deux.`if !irisVestFixed && !irisBootsFixed`
>	![[pro.png]]
>	Tu peux réparer les deux?
>	![[minimaCheeky.png]]
>	Bien sûr!
>	`c,fixVestAndBoots`
>	`if craftFailed`
>		[[#craftFail]]
>Il faut combien de matériaux déjà?`if !irisVestFixed || !irisBootsFixed`
>	[[#craftCost]]
>Laisse tomber.

`x`
## craftCost
![[minimaLookingAway.png]]
Voyons voir...
`if !irisBootsFixed`
	Pour les bottes, il faudra, disons, **2** morceaux de **bois cornéen** et **3** longueurs de **ficelle**.
`if !irisVestFixed`
	Pour le gilet, il faudra **1** morceau de **bois cornéen** et **6** longueurs de **ficelle**.

[[#craftChoice]]

## craftFail
![[minimaLookingAway.png]]
Mm... c'est tout ce que t'as?
![[minimaMildlyAnnoyed.png]]
Je crois que ça suffira pas.
![[minimaSheepish.png]]
Désolée.
![[proNonchalant.png]]
C'est bon, t'inquiète.
(Il va falloir explorer un peu plus avant de faire ça.)
`x`

# returnedToElevator
![[pro.png]]
...
![[minima.png]]
...
Alors...?
![[pro.png]]
Normalement. il devrait y avoir un guet en haut pour repérer les visiteurs.
![[proNonchalant.png]]
On a juste à attendre qu'ils envoient l'ascenseur.
![[minima.png]]
D'accord.
`c,elevatorWait`
![[proCynical.png]]
Ok. Ça fait assez longtemps.
Je crois pas qu'on va pouvoir monter aujourd'hui.
![[minimaSheepish.png]]
Oh, dommage.
Désolée de t'avoir fait revenir ici pour rien.
![[proHidingSomething.png]]
T'en fais pas, c'est rien.
![[proDisdainful.png]]
...pourquoi ils mettent autant de temps?
>!Ce genre de travail, c'est dur, tu sais!
>	![[proCynical.png]]
>	(Ouais ouais. Je suis sûr que tu t'y connais.)

`x`

# opinionOfPlayer
`c,restTalkStart`
![[minimaLookingAway.png]]
Alors... c'est comment?
![[pro.png]]
Comment quoi?
![[minimaBemused.png]]
De parler à « dieu »?
![[proAnnoyed.png]]
C'est pas *dieu*.
![[proCynical.png]]
D'ailleurs, tu disais pas que tu trouvais l'idée complètement folle?
![[minimaBemused.png]]
Ouais, et? Ça m'intéresse quand même.
![[proHidingSomething.png]]
Pfft...
...

`if proAff>=21`
	![[pro.png]]
	C'est plutôt agréable en fait.
	![[proThinking.png]]
	On dirait... qu'ils savent toujours quoi dire.
	![[proConflicted.png]]
	Genre, exactement quoi dire.
	Hm.
	Maintenant que j'y pense, c'est un peu bizarre.
	![[minima.png]]
	Ah bon?
	![[proDisdainful.png]]
	Ouais, comme s'ils mettaient *trop* d'efforts pour se faire bien voir, tu vois le genre?
	![[minimaSheepish.png]]
	Euh... pas vraiment.
	![[proDisdainful.png]]
	Donne-moi un instant.
	(C'est quoi le problème?)
	>Je vois pas de quoi tu parles.
	>	![[proSkeptical.png]]
	>	(...)
	>	![[proNonchalant.png]]
	>	(Bah, peu importe. Si ça se trouve, je réfléchis peut-être trop à tout ceci.)
	>	![[minima.png]]
	>	Alors...
	>	![[pro.png]]
	>	Oh, euh, rien. Ils sont sympas, ils donnent de bons conseils.
	>	Rien à redire, vraiment.
	>	![[minima.png]]
	>	D'accord...
	>Bon d'accord, j'ai consulté un guide qui explique comment m'y prendre pour que tu m'apprécies.
	>	`proAff-=8`
	>	![[proBemused.png]]
	>	(Haha, qu- quoi? Ça existe, un truc pareil?)
	>	(Je- je sais pas si je devrais être flatté ou...)
	>	>Je vais arrêter...
	>	>	`proAff+=2`
	>	>	![[proBemused.png]]
	>	>	(Oh, non, arrête pas pour moi, ça me dérange pas.)
	>	>	(Même si c'est plutôt naze.)
	>	>...
	>	>	![[proMocking.png]]
	>	>	(Tu vas continuer à l'utiliser?)
	>	>	(Ça me dérange pas vraiment, mais c'est hyper pathétique.)
	>	![[minimaBemused.png]]
	>	Euh, Pro? Tu viens de t'engueuler avec quelqu'un, ou quoi?
	>	![[proMocking.png]]
	>	Dans un sens. Figure-toi que `$player` utilise apparemment un guide pour rester dans mes bonnes grâces.
	>	![[minimaBemused.png]]
	>	Ha. Quoi?
	>	![[proMocking.png]]
	>	Ouais, c'était *ma* réaction, aussi.
	>	![[minimaBemused.png]]
	>	Non, je veux dire...
	>	Ton « mécène » veut désespérément que tu l'apprécies?
	>	![[proMildSurprise.png]]
	>	Euh...
	>	![[minimaBemused.png]]
	>	C'est peut-être *moi* qui se fais une mauvaise idée de la chose.
	>	![[proMildlyEmbarassed.png]]
	>	Eh bien, tu vois-
	>	![[minimaSmile.png]]
	>	Non, non. Je comprends tout à fait. Se faire de vrais amis, c'est dur.
	>	![[proFrustrated.png]]
	>	On peut parler d'autre chose?
	>	![[minimaJovial.png]]
	>	Bien sûr, bien sûr.
`else if proAff>8`
	![[pro.png]]
	C'est plutôt agréable en fait.
	![[proHidingSomething.png]]
	Toute mon enfance, je craignais que le Mécène soit aussi coincé que les autres adultes dans ma vie.
	![[proSmile.png]]
	Mais honnêtement, c'est plutôt sympa de leur parler.
	>!Oh, merci.
	![[minimaBemused.png]]
	Alors, la voix dans ta tête te dit essentiellement ce que t'as envie d'entendre?
	![[proThinking.png]]
	Non, pas toujours.
	![[pro.png]]
	Mais ils m'*embêtent* pas vraiment avec ça, tu vois.
	![[minimaSkeptical.png]]
	Peut-être? J'ai pas fait l'inventaire des trucs que tu trouves agaçants.
	![[proThinking.png]]
	Euh...
	![[proAnnoyed.png]]
	J'en ai juste marre des gens qui me disent ce qui est soi-disant bon pour moi.
	![[minimaSheepish.png]]
	Oh. Ouais, ce *serait* une réaction compréhensible quand on a été élevé par des cinglés.
	![[proCynical.png]]
	Euh... ouais.
`else if proAff>2.5`
	![[proNonchalant.png]]
	Ça va.
	`$player` est un peu ennuyeux pour être honnête.
	>!Hé!
	>	![[proMocking.png]]
	>	(Quoi? C'est vrai.)
	![[proRollingEyes.png]]
	Après, je dois avouer que je me suis quand même rendu jusqu'ici grâce à eux, alors je vais pas *trop* me plaindre.
	>!Pas trop?
	>	![[proCynical.png]]
	>	Eh bien...
	>	[[#playerComplaints]]
	[[#lukewarmEnd]]
`else`
	![[proHidingSomething.png]]
	Je sais pas.
	Je devrais pas me plaindre, ils m'ont amené jusqu'ici.
	Mais `$player` craint un peu.`var, playerSucks`
	>Quoi!? Comment ça?
	>	[[#playerComplaints]]
	>Ouais...
	>	`proAff+=0.5`
	>	![[proConflicted.png]]
	>	(Quoi, c'est maintenant que tu culpabilises?)
	>	[[#doneComplaining]]

`c,restStart`
`x`
## lukewarmEnd
![[proNonchalant.png]]
Donc ouais, dans l'ensemble c'est moyen.
![[minimaSurprised.png]]
Tiens. Un avis étonnamment terre-à-terre.
![[proMocking.png]]
Désolé de décevoir.
`c,restStart`
`x`
## playerComplaints

`if playerCalledProSubhuman`
	`var, complained`
	![[proDisdainful.png]]
	(Tu m'as littéralement traité de « sous-humain » quand on s'est rencontrés.)

`if playerCaresAboutPinwheels`
	`var, complained`
	![[proCynical.png]]
	(T'as une drôle d'obsession avec les virevents...)

`if playerSidedWithGirls`
	`var, complained`
	![[proMocking.png]]
	(T'as pris le parti d'Api et Oiko, franchement.)

`if playerTeasedProAboutBooks`
	`var, complained`
	![[proHidingSomething.png]]
	(Tu m'as nargué à propos des livres l'autre fois.)
	>!Chez le maire? C'était une blague.
	>	![[proConflicted.png]]
	>	(Ouais, peu importe.)

`if playerSidedWithDendro`
	`var, complained`
	![[proAnnoyed.png]]
	(Tu as l'air de penser que le maire est teeellement génial...)
	>!Il fait clairement de son mieux.
	>	`proAff-=2`
	>	![[proConflicted.png]]
	>	(Ouais ouais.)

`if playerWhiny>=2`
	`var, complained`
	![[proCynical.png]]
	(Tu es... un brin pleurnicheur.)

`if playerClueless>=2`
	`var, complained`
	![[proCynical.png]]
	(Tu dis des trucs vraiment maladroits parfois.)

`if !complained`
	`if playerSucks`
		![[proCynical.png]]
		(... Je sais pas comment. C'est comme ça.)
		[[#doneComplaining]]
	`else`
		![[proThinking.png]]
		(...)
		(... En fait, je trouve rien à reprocher.)
		![[pro.png]]
		(Bon, t'es peut-être pas ce qu'il y a *de pire*)
		>!Trop aimable.
		>	![[proSmirk.png]]
		>	(De rien.)
		[[#lukewarmEnd]]
`else`
	`if playerSucks`
		![[proHidingSomething.png]]
		(...)
		>C'est tout?
		>	![[proDisdainful.png]]
		>	(Ouais.)
		>Pardon.
		>	`proAff+=0.5`
		>	![[proConflicted.png]]
		>	(...)
		[[#doneComplaining]]
	`else`
		![[proNonchalant.png]]
		(Mais bon, comme j'ai dit, c'est pas grave.)
		[[#lukewarmEnd]]

## doneComplaining
![[minimaApprehensive.png]]
Euh. Désolée si c'était trop direct. Je savais pas que tu prenais aussi mal les-
![[proMildSurprise.png]]
Oh. Non, c'est bon.
![[proBemused.png]]
C'est pas contre *toi* que je m'énerve.
![[minimaSmile.png]]
Oh, ouf, d'accord.
Tu veux parler d'autre chose?
![[proMeditating.png]]
Oui.
`c,restStart`
`x`

# swearing
//stewards cut-to functionality unfinished
`c,restTalkStart`
![[minima.png]]
Tu sais, je crois pas t'avoir entendu jurer une seule fois.
![[proSkeptical.png]]
Quoi? Je suis plutôt sûr d'avoir dit, genre, merde, crotte, cul...
![[minimaBemused.png]]
Haha ok, mais ça compte à peine, si?
![[proMildSurprise.png]]
Ça... compte pas?
![[minimaLeaningIn.png]]
Attends, tu connais pas de jurons plus crus!?
![[proMildlyEmbarassed.png]]
Euh...
![[minimaLaughing.png]]
Haha, c'est trop drôle!
![[minimaBemused.png]]
Ton village est vraiment *doué* en opsec.
![[minimaCheeky.png]]
`a,0.3`Non, les *vrais* jurons c'est des trucs comme put-
`c,cutToStewards`
`steward,r,neutral`
Hé! Comment ça va?
...
`steward,r,giveUp,neutral`
Oh, vous vous demandez pourquoi j'ai dû attirer votre attention?
`steward,r,annoyed`
Aucune raison, c'était juste comme ça!
`steward,r,neutral`
Vous vous amusez bien?
`steward,r,cheery`
>Ouais!
>	C'est super! N'est-ce pas super de jouer à un jeu aussi super avec une classification d'âge aussi super et familiale?
>Je suppose?
>	Haha, n'est-ce pas super de jouer à un jeu aussi super avec une classification d'âge aussi super et familiale?
>Non.
>	Quoi? Vous n'appréciez pas de jouer à un jeu aussi super avec une classification d'âge aussi super et familiale?
>Je doute que m'interpeller comme ça à chaque fois va fonctionner.
>	Vous seriez surpris!

`steward,r,neutral`
...
`steward,r,distracted,neutral`
Ok, je crois qu'ils ont terminé.
`steward,r,cheery`
C'était sympa de discuter!
`c,cutFromStewards`

![[proSmirk.png]]
...ah bon?
![[minimaMildlyAnnoyed.png]]
Allez, tu penses que je te fais marcher?
![[proBemused.png]]
T'as failli m'avoir, mais un mot spécial qu'on peut mettre à peu près n'importe où?
Y compris au milieu d'autres mots?
Je pense que t'essaies juste de me piéger pour que j'aie l'air ridicule.
![[minimaDeadpan.png]]
J'ai pas dit qu'on pouvait le faire avec *élégance*.
![[proBemused.png]]
Ha, bien sûr.
`$player`, aide-moi ici.
>Elle dit la vérité.
>	![[proRollingEyes.png]]
>	Ah bon?
>	![[proMocking.png]]
>	Vous êtes de mèche, je suppose.
>	Trouvez un meilleur mensonge la prochaine fois, vous deux.
>	![[minimaAnnoyed.png]]
>	...
>T'as raison, ça te ferait passer pour un \*\*\*\*\*\*.
>	![[proAnnoyed.png]]
>	Argh.
>	![[minimaBemused.png]]
>	Pfft.
>	![[proCynical.png]]
>	C'était quoi ce bruit de bip? Refais plus jamais ça.

`c,restStart`
`x`