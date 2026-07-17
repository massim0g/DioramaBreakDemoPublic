# preamble
![[pro.png]]
(Bon, dernière foulée.)
(L'ascenseur qui nous dépose au sol est à l'étage en-dessous.)
![[proCynical.png]]
(Reste qu'à passer outre la capitaine.)
`gameSave`
`x`

# captainEncounter
`c, polemaEncounterStart``encounteredPolema`
![[polema.png]]
...

![[pro.png]]
...

![[polema.png]]
Ça s'est bien passé?

![[pro.png]]
Bien sûr.

![[polemaBemused.png]]
Tu n'as pas l'air différent.

![[proCynical.png]]
Tu ne me regardes même pas.

`c,polemaTurnsAround`

![[polemaBemused.png]]
...
Il y avait quelque chose à voir?

![[proBemused.png]]
T'as jamais vu grand potentiel en moi, hein?
![[proNonchalant.png]]
Bon, je dois répondre à l'appel du destin. Tu me donnes un coup de main avec l'<span style="color:rgb(225, 188, 105)">ascenseur</span>?

![[polemaStern.png]]
T'as bel et bien *quelque chose* qui t'es monté à la tête si tu crois que tu vas sortir d'ici aujourd'hui.

`c,polemaWalksOver,false`

`a,0.5`![[polema.png]]Allez, prends une épée d'entraînement.
On va voir si toute cette histoire en valait la pei-

`a,-1`

![[polemaStern.png]]
Pro...

![[proDisdainful.png]]
`face,pro,up`Si tu voulais pas aider, t'avais qu'à le dire. Je me casse.

![[polemaBemused.png]]
Comment tu comptes faire ça, exactement?
On a besoin d'*au moins* deux personnes fonctionner l'ascenseur.
![[polemaShout.png]]
À moins que tu veuilles mettre en péril notre seule connexion vers le monde extérieur.

![[proConflicted.png]]
Pff. C'est pas comme si vous vous en serviez.

![[polemaStern.png]]
Ça suffit.
Tu n'es pas prêt.

![[proFrustrated.png]]
Et même si c'était vrai, c'est la faute de qui?

![[polemaPain.png]]
Quelle sorte de- !
![[polemaPainedConcern.png]]
...
Pro, t'as jamais *vu* un de ces monstres.
Tu ne feras pas long feu là-bas, surtout pas seul.

![[proDisdainful.png]]
Je ne suis *pas* seul.
![[proAnnoyed.png]]
(D'ailleurs, tu voulais ajouter quelque chose?)
### polema response
>Pourquoi ça lui tient tant à cœur?
>	![[proConflicted.png]]
>	(Oh, c'est parce qu'elle pense que je finirai comme mon père.)
>	[[#not my father]]
>Je trouve ses arguments plutôt convaincants.
>	![[proAnnoyed.png]]
>	(N'importe quoi. Elle a juste peur que je finisse comme mon père.)
>	[[#not my father]]
>Prends l'ascenseur de force! Tu peux la vaincre! [[#fight her]]
>Je sers pas à grand-chose là. [[#third wheel]]
>Dis-lui que les frontières ouvertes sont un droit et que tu ne laissera plus ces restrictions fascisantes brimer ta liberté de mouvement! [[#insult her]]

### third wheel
`playerWhiny+=1``proAff-=1`
![[proCynical.png]]
(T'as qu'à dire quoi que ce soit.)
[[#polema response]]
### fight her
![[proCynical.png]]
(À moins que tu sois sur le point de me donner des super-pouvoirs, je peux vraiment, vraiment pas.)
(T'aurais pas un truc pertinent à ajouter sur la *conversation*?)
[[#polema response]]

### insult her
`proAff-=1`
![[proCynical.png]]
(Quoi? Non.)
>Fais-moi confiance.
>Ok, d'accord.
>	![[proMildlyConflicted.png]]
>	(...)
>	[[#polema response]]

![[proCynical.png]]
(...)
![[proAnnoyed.png]]
Capitaine! Les frontières ouvertes sont un droit et je ne tolérerai pas ces restrictions fascistes sur ma liberté de mouvement!

![[polema.png]]
...
Comme c'est nostalgique.
Je croyais que t'avais dépassé l'âge de faire ce genre de proclamation depuis des années.

![[proEmbarrassed.png]]
(euhhh...)

![[polema.png]]
Il est clair que je n'arrivera pas à te dissuader.
Approche, dans ce cas.

`c, polemaWalksDown`

![[proMildSurprise.png]]
...
(Euh..attends- Quoi?!)
>!Je te l'avais dit.
>	![[proCynical.png]]
>	(...)

`x`
### not my father
![[proCynical.png]]
Arrête de t'inquiéter que je finisse comme mon père.

![[polemaPainedConcern.png]]
...
Aucune chance, même si je sais que je ne peux pas te retenir éternellement.
![[polemaPain.png]]
Je t'en prie, Pro. Il y a encore du temps pour te préparer.
Te laisser emporter par toutes ces- ces chimères, ça va te tuer!

![[proMocking.png]]
Hoh. « Toutes ces chimères »? Tu sais, si t'avais dit un truc pareil hier, j'aurais été le premier à te donner raison.
![[proHidingSomething.png]]
(... dans mon esprit, du moins. Avec bémols.)

![[polemaPain.png]]
J'espérais ne pas avoir à le dire, mais puisque tu es clairement incapable de le comprendre par toi-même...

![[proCynical.png]]
Ça va *aller*. Je mens pas à propos de ce matin. Le Mécène est là, que tu le croies ou non.
![[proSkeptical.png]]
Et il attend, en passant.

![[polemaSkeptical.png]]
Vraiment.
![[polema.png]]
J'avoue que tu sembles plus engagé dans ton rôle que d'habitude.

![[proCynical.png]]
Jouer la comédie est facile quand on ne fait pas semblant.
![[proRollingEyes.png]]
D'ailleurs... on devrait peut-être demander l'avis du maire.
![[proSmirk.png]]
Je me demande ce qu'il penserait de ton manque de foi.

![[polemaStern.png]]
...
Viens, l'ascenseur attend.

`c, polemaWalksDown, false`

`p,0.5`

![[proSkeptical.png]]
`a,0.1``face,pro,down`Quoi? Comme ça, tout bonnement?

`a,-1`

(Hrm.)
## captainEncounterQuestions
>C'était facile. [[#captainEncounterQuestionsA]]
>C'était quoi cette histoire avec ton père?
>	`proAff+=1`
>	![[pro.png]]
>	(Oh, quand j'étais bébé il est mort dans une attaque en allant récupérer le courrier.)
>	>!Récupérer le courrier? Sur le pas de sa porte?
>	>	![[proCynical.png]]
>	>	(... Non. Un des envois de l'extérieur.)
>	>	![[proNonchalant.png]]
>	>	(Le protocole était bien plus laxiste à l'époque, à ce qu'on m'a dit.)
>	>	![[proMildlyConflicted.png]]
>	>	(...)
>	![[proMildlyConflicted.png]]
>	(J'ai jamais vraiment fait mon deuil, je me souviens même pas de lui.)
>	(C'était un coup dur pour maman, mais elle m'a jamais mis ça sur le dos.)
>	![[proCynical.png]]
>	(La capitaine, par contre...)
>Allons-y.

`encounteredPolema`
`x`

### captainEncounterQuestionsA
(Trop facile, ouais.)
[[#captainEncounterQuestions]]

# trainingAreaEntrance
`if combatTutorialFailed`
	[[#returnedAfterFailure]]
`else`
	[[#triedToLeave]]
# triedToLeave
![[proNonchalant.png]]
`if !combatTutorialTriedToLeave`
	(Quoi, t'as oublié quelque chose?)
	>Oui
	>	![[proCynical.png]]
	>	(Tant pis.)
	>Non
	>	![[proAnnoyed.png]]
	>	(Alors allons à l'ascenseur.)
	(Je veux pas lui laisser le temps de changer d'avis.)
	`combatTutorialTriedToLeave`

`walkBack, left`
`x`
# guardsEncounter

`c, guardsEncounterStart`
![[proCynical.png]]
(Hm, la belle bande de bras cassés est réunie.)

![[chionSmiling.png]]
Salut Pro!

![[kion.png]]
Salut.

![[akroSmile.png]]
Yo.

![[pro.png]]
Salut les gars.

`c,proTurnsToPolema`

![[proSkeptical.png]]
T'es si certaine qu'ils en viendront à bout de m'empêcher de partir?
![[proSmirk.png]]
Faut croire qu'on manque réellement d'effectifs.

![[kionExclaimingAngry.png]]
`face,pro,left`Hé! On pourrait te faire la peau n'importe quand!

`c, proPsychsOutKion`

![[proHaughty.png]]
Hmph.

`c, polemaSpeaksUp, false`

![[polemaShout.png]]
CADETS!`a,-1`

![[]]
CAPITAINE!

![[polemaShout.png]]
Malgré mes mises en garde, il semblerait que notre héros tienne à partir sur-le-champ!
Nous allons donc profiter de cette occasion pour effectuer un exercice à lame découverte!

>!C'est tellement gonflant...
>	![[proAnnoyed.png]]
>	(AAAH, je sais!! On y est presque, on y est presque...)
>	[[#tunedOut]]

Il est grand temps, pour certains d'entre vous, de vous familiariser avec le fonctionnement de l'ascenseur principal.
C'est pourquoi je vous ai tous réunis ici pour participer.

![[polema.png]]
Akro, tu gères les commandes.

![[akro.png]]
Reçu.

![[polema.png]]
Kion, tu t'occuppes de surveiller.

![[kionExclaimingSmiling.png]]
Oh! Oui Capitaine!

![[polema.png]]
Je dirigerai.
## tunedOut
![[polemaShout.png]]
À vos postes, tous!

![[chion.png]]
O-oui, Capitaine!

`c, everyoneBoardsElevator, false`

![[proSkeptical.png]]
(Attend, même Chion? Y a quelque chose qui cloche.)

>!Interviens.
>	![[proNonchalant.png]]
>	(Et risquer d'interrompre le départ? Hors de question.)

`a,-1`

## elevatorBoarded
![[polemaShout.png]]
Tout le monde, donnez votre signal!

![[akro.png]]
Prêt.

![[kion.png]]
Prêt!

![[polemaShout.png]]
Confirmation des conditions au sol!

![[kion.png]]
Oui!

`face,kion,down`
`p,1`
`face,kion,up`
`p,1.5`

![[polemaShout.png]]
Cadet?

![[kion.png]]
Oh, pardon, euh... tout est bon!

![[polemaStern.png]]
... Reçu. Les yeux collés sur l'objectif, tout le monde.
`face,kion,down`Puissance réglée à septante pourcent. Entamez la descente!

![[akroOrders.png]]
Reçu!
`face, akro, up`

## elevatorDescent
`c, elevatorDescends, false`

`a,-1`

# elevatorStop

![[polemaShout.png]]
Stop!`a,0.5`

![[akroOrders.png]]
Stop!

`a,-1`

![[proCynical.png]]
(Et voilà...)

`c, polemaApproachesPro`

![[polemaBemused.png]]
Tu pensais que ce serait si facile?

![[proNonchalant.png]]
Non, pas vraiment.
![[proSmirk.png]]
Par contre, j'avais pas réalisé que tu serais capable de duperies aussi élaborées, Capitaine.

![[polemaStern.png]]
Silence.
J'avoue que les autres risquent de se laisser convaincre de te laisser filer vers une mort prématurée...
Alors mieux vaut régler ça tout de suite. Personne ne contestera les résultats d'une réelle épreuve de force.

`c, polemaWalksBack`

![[polemaShout.png]]
Si t'arrives à vaincre chacun d'entre nous en combat, je te laisserai quitter ce village.

![[proCynical.png]]
(Ah.)
Même toi?

![[polemaBemused.png]]
Si tu ne peux même pas gagner contre moi, tu crois vraiment avoir une chance contre une horde de monstres?

![[proHidingSomething.png]]
(...)

>Allez, on peut gagner contre elle!
>	![[proMildlyConflicted.png]]
>	(Tu la sors d'où, toute cette hardiesse? Je suis jamais passé près de la battre par moi-même.)
>	>Quoi? Pourtant, tu as l'air si fort. Ton épée est énorme!
>	>	`proAff+=1`
>	>	![[proBemused.png]] 
>	>	(Aha, merci.)
>	>	(Mais, euh... la sienne est plus grosse.)
>	>	>Oh. Bon, tu sais ce qu'on dit à propos de la taille.
>	>	>	`proAff+=1`
>	>	>	![[proJovial.png]]
>	>	>	(Ha!)
>	>	>	![[proMocking.png]]
>	>	>	(D'accord, montre-moi comment on fait alors.)
>	>	>Zut alors.
>	>	>	![[proBemused.png]]
>	>	>	(Heh, ouais.)
>	>	>	![[proConflicted.png]]
>	>	>	(Cela dit, c'est pas une raison pour la laisser me convaincre de lâcher le morceau sans rien faire.)
>	>J'ai le don pour ce genre de choses.
>	>	`proAff+=1`
>	>	![[proSkeptical.png]]
>	>	(Vraiment...?)
>	>	![[proMeditating.png]]
>	>	(Bon, je te fais confiance là-dessus.)
>	>Elle est vieille.
>	>	![[proCynical.png]]
>	>	(Pas assez pour faire pencher la balance, crois-moi.)
>	>	![[proAnnoyed.png]]
>	>	(Argh, reste que je ne la laisserai m'écraser sans lui tenir tête.)
>Garde la tête haute, je doute qu'on nous impose un défi impossible aussi tôt.
>	`proAff+=1`
>	![[proSkeptical.png]]
>	(Comme c'est... pieux de ta part.)
>	![[pro.png]]
>	(Mais d'accord, je te crois.)
>Elle marque un bon point.
>	![[proCynical.png]]
>	(Ouais, et je suis jamais passé proche de la battre par moi-même.)
>	(Tu me dis qu'on est fichus là?)
>	>Oui.
>	>	`playerClueless+=1``proAff-=1`
>	>	![[proAnnoyed.png]]
>	>	(Argh...)
>	>	![[proFrustratedSimmering.png]]
>	>	(Même si tu dis ça, je vais pas la laisser me convaincre de lâcher le morceau sans me battre.)
>	>Non, je pense qu'on peut gagner.
>	>	![[proCynical.png]]
>	>	(Tu « penses »...?)
>	>	(...)
>	>	![[proMeditating.png]]
>	>	(Bof, c'est mieux que rien.)
>	>Pas du tout, allons lui en coller une.
>	>	`proAff+=2`
>	>	![[proSmirk.png]]
>	>	(Ha!)
>	>	![[pro.png]]
>	>	(D'accord, je me fie à toi dans ce cas.)

![[proDetermined.png]]
Très bien, Capitaine. Je relève le défi.

![[polema.png]]
Les recrues passeront en premier, par ordre d'expérience. Autant en faire une journée d'entraînement.

![[proCynical.png]]
Mm. Ok.
C'est pas comme si ça change quoi que ce soit.

![[akroWrySmile.png]]
Belles paroles.

![[kionExclaimingAngry.png]]
Ouais! Belles paroles!

![[proCynical.png]]
Tais-toi, Kion.
![[proThinking.png]]
(Ok, battre ces gars... devrait pas être trop dur.)
![[proHidingSomething.png]]
(Je suppose qu'Akro pourrait me poser problème; mais ça, ils ont pas besoin de le savoir.)

>!Et les deux autres?
>	![[proBemused.png]]
>	(Haha.)
>	(Ce sont des gamins, qu'est-ce qu'ils vont faire?)
>	![[proMocking.png]]
>	(Chion arrive même pas à tenir sa lance correctement.)
>	![[proHidingSomething.png]]
>	(...notre combat risque de te donner un petit aperçu de ce que la capitaine va me faire à *moi*.)

# chionFightStart
![[polema.png]]
Chion, c'est ton tour.

![[chionSurprised.png]]
Oui!

`c, proAndChionGetInPosition`

![[polema.png]]
Vous combattrez jusqu'à ce que l'un de vous cède.
Et n'en faites pas trop. Je compte pas ramener qui que ce soit sur une civière aujourd'hui.

![[proDetermined.png]]
(C'est parti.)

![[polemaStern.png]]
Attends.
Tu comptais pas utiliser ta vraie lame, toujours?

![[proNonchalant.png]]
Pourquoi pas? Ils utilisent leurs vraies lances.
J'imagine qu'on veut tous en finir vite.

>!T'entends quoi par là, au juste!?
>	![[proRollingEyes.png]]
>	(Oh, du calme, c'est pas comme si je pouvais frapper assez fort pour *tuer* l'un d'eux.)

![[polemaStern.png]]
Équipe une lame d'entraînement.

![[proCynical.png]]
Bon.

`c, proEquipsTrainingBlade`

![[polemaShout.png]]
Combattants, en garde!
Et...
Commencez!

`c,chionFightStart`

`x`
# combatInterface
![[proMildSurprise.png]]
(Ouah!)
(...)
(Tout est figé?)
![[proAnnoyed.png]]
(Hrngh...)
`p,1`
![[proCynical.png]]
(Moi y compris...)
![[proMildSurprise.png]]
(Quand même, c'est incroyable. Pourquoi t'as pas mentionné ça avant?)
![[proCynical.png]]
(... Tu sais comment ça marche, toujours?)

>Oui.
>	`var, heKnows`
>Euh...
>	`var, heKnows, 0`

`hdOverlay`
Test, test?
Ah, bien, ça semble fonctionner.
Pas de souci, nous vous laisserons tranquille dans un instant. Ce système est quelque peu complexe alors nous sommes là pour vous aider à vous y retrouver.
`if heKnows`
	Mais bon, vous avez l'air plutôt sûr de vous, je parie que vous n'aurez pas besoin d'aide du tout!
`c,highlightPro,false`
`if gamepad`
	Pour commencer, pourquoi ne pas sélectionner le cadre aux pieds de Pro avec votre curseur?`a,-1`
`else`
	Pour commencer, pourquoi ne pas faire un clic gauche sur le cadre aux pieds de Pro?`a,-1`
`hdOverlay`

`x`

# combatInterface2
![[proUpset.png]]
(Blargh.)
(Ça finit par donner la nausée, à force de s'arrêter et repartir comme ça.)
`x`
# chionQuip
![[kionExclaimingAngry.png]]
Frappe-le Chion!

![[chion.png]]
J-je...

![[kionExclaimingAngry.png]]
Donne un coup de lance!
`x`
# chionQuip2
![[chionHit.png]]
Aah!

![[proSmile.png]]
(Bien!)
(Je commence à comprendre.)

>!Je me sens un peu mal...
>	![[proSmirk.png]]
>	(C'est la faute de la capitaine. Venge-toi sur elle plus tard.)
>	![[proSmile.png]]
>	(Je pense vraiment qu'on a une chance maintenant!)

`x`

# kionStart
`chionDefeated`
![[chionHit.png]]
Aïe!
Stop! Stop! J'abandonne!

![[polemaShout.png]]
Ça suffit.

`c, combatEnd`

`camPan,arenaCenter`
![[kionExclaimingAngry.png]]
Non! Touche-le au moins une fois! Tu fais quoi!?

![[akro.png]]
Hé. `s,0.5`Il a fait de son mieux, d'accord?`s`

![[kionRestrainedFrustration.png]]
Mmm...

`c, chionWalksOut`

![[chion.png]]
D-désolé.

![[akroSmile.png]]
Te sens pas mal.
On est tous passés par là.

![[chionSmiling.png]]
Vraiment?

![[proSmirk.png]]
Pas vrai! Moi, je suis jamais passé par là!

![[polemaBemused.png]]
Ah bon?

![[proMildSurprise.png]]
Euh-
![[pro.png]]
Kion, on y va?

![[kion.png]]
!

## kionFightStart

`c, kionWalksIn`
`if seen`
	![[kionExclaimingSmiling.png]]
	Tu en redemandes?
	![[proFrustrated.png]]
	Ouais, ouais. Fier de ton petit coup de chance?
	![[proFacade.png]]
	Je vais te démolir Kion. L'épée d'entraînement ne changera rien.
	![[kion.png]]
	Euh... e-essaie toujours.
`else`
	![[kionExclaimingAngry.png]]
	Tu vas le regretter!
	![[proSmirk.png]]
	J'en doute.

![[polemaStern.png]]
Combattants, en garde!
Et...
![[polemaShout.png]]
Commencez!

`c, kionFightStart`
`x`

### kionFightTutorial

`hdOverlay`
`uiHighlight,0,92,133,177`
Gardez un œil sur la barre temporelle quand vous planifiez votre tour.
`uiHighlight,35,99,88,164`
Chaque tour est composé de 6 **étapes**.
`uiHighlight,35,145,88,156`
Les actions que vous et vos ennemis mettez en file prennent un certain nombre d'étapes pour **démarrer**, se **résoudre**, puis **récupérer**.
`uiHighlight,88,145,116,156`
Les actions qui ne se terminent pas à la fin du tour **déborderont** sur le tour suivant.
`uiHighlight,0,92,133,177`
`c,timelineReadOrder,false`
Les actions d'une même étape se résolvent de **haut en bas.** Essayez de lire la progression des événements comme ceci.
L'essentiel à retenir est que **Pro agira toujours en premier dans une étape.**
`var, timelineReadOrderEnd`
`uiHighlight,70,145,81,156`
Portez attention et prévoyez les moments où les attaques se résolvent.
`c,kionHighlight`
Tâchez d'éviter de vous trouver devant Kion quand il sera prêt à attaquer.
`uiHighlight`
`hdOverlay`

`x`
# kionQuip
![[chionSurprised.png]]
Ah! Fais gaffe!

![[kionRestrainedFrustration.png]]
Trop aimable...

`hdOverlay`
Encaisser une attaque causera un « ***Break !*** » à l'unité en question et interrompra ses actions en file.
`uiHighlight,35,145,88,156`
Après un ***Break***, elle sera étourdie pendant un certain nombre d'étapes, en fonction de l'attaque reçue.
Ici, **Coup de bois** inflige **3 de stun**, donc Kion sera maintenant étourdi pendant 3 étapes.
`uiHighlight`
Si vous faites bien attention au rythme des attaques, vous trouverez le moment propice pour frapper votre adversaire en premier!
`hdOverlay`
`x`

# kionQuipTookHit
![[proHit.png]]
Gah!

![[kionExclaimingSmiling.png]]
Haha!

![[proFrustrated.png]]
(Sérieux!?)
(*Fonce pas droit sur lui!*)

>Je sais! Navré!
>Pourquoi tu mets si *longtemps* à réagir?
>	`playerWhiny+=1``proAff-=2`
>	(Les lois de la physique?)

![[proAnnoyed.png]]
(Écoute, il est nul pour couvrir son flanc. *Contourne*-le.)

`x`

# akroStart
`kionDefeated`
![[kionHit.png]]
Aïe!
C'est bon, c'est bon! J'abandonne!

![[proSmirk.png]]
Hein? T'as dit quelque chose?

![[kionExclaimingAngry.png]]
Toi, tu-

![[polemaShout.png]]
Du calme.
Ce match est terminé.

`c,combatEnd`
`camPan,arenaCenter`

![[kionRestrainedFrustration.png]]
...

`c,kionWalksOut`

![[chion.png]]
Ça va?

![[kionExclaimingAngry.png]]
Ça va!

![[akroBemused.png]]
Et voilà.

## akroFightStart

`c,akroWalksIn`

![[akroWrySmile.png]]
Prêt?

![[pro.png]]
... Toujours.

`if seen`
	[[#akroCountdown]]

![[akro.png]]
Je retiendrai pas mes coups. Tu peux utiliser ta vraie épée.

![[proCynical.png]]
T'es si magnanime.
![[proAnnoyed.png]]
(Ugh. Pas possible, le gars.)
![[proCynical.png]]
(Toujours à veiller sur tout le monde.)

>C'est un défaut?
>	(Voyons, comment t'arrives à faire confiance à un gars comme ça?)
>Ouais. Je connais le genre.

(Je suis sûr qu'il veut juste me piquer mon poste.)
![[proRollingEyes.png]]
(Sans compter que je me bats mieux que lui, mais la capitaine n'aurait pas bronché si c'était *lui* qui essayait de partir.)

>!C'est vrai?
>	![[proHidingSomething.png]]
>	(Ouais, clairement. Je le bats, genre, sept fois sur dix. Enfin, six, mais c'est pas comme si on comptabilisait.)

![[proDetermined.png]]
(Bref, il sera pas aussi facile que les autres. Il a la portée et la vitesse pour être une vraie menace.)
`a,0.2`(Déjà, j'arrive pas à égaler sa vitesse initiale avec mon épée-)
![[proMildSurprise.png]]
(Ah, d'ailleurs...)
`c,proEquipsRegularSword`
![[pro.png]]
(Comme je disais, il faut se soucier de sa portée et sa vitesse. Alors fais attention en l'approchant.)

![[proSmirk.png]]
(J'ai peine à gérer le rythme et la distance par moi-même, mais toi, tu devrais être en mesure de prévoir le coup.)

![[akroSurprised.png]]
Au fait, qu'est-ce qu'ils ont tes mouvements aujourd'hui?

![[proSmirk.png]]
Portes attention et tu le découvriras peut-être.

### akroCountdown
![[polemaShout.png]]
Combattants, en garde!
Et...
Commencez!

`c,akroFightStart`

`x`

### akroFightTutorial

`if seen`
	[[#failureTutorial]]

`hdOverlay`
Il est important de faire attention aux portées d'attaque ennemies.
`if gamepad`
	Vous avez peut-être déjà remarqué que consulter la barre temporelle avec **LB** ou sélectionner Pro affiche un **aperçu** des actions à une étape précise.
	Si vous vous déplacez dans une zone dangereuse par erreur, vous pouvez utiliser **LT** pour annuler les actions que vous avez mises en file ce tour-ci.
	`c,akroHighlight,false`
	De plus, vous pouvez appuyer sur **Y** en survolant une unité pour **épingler** un aperçu de toutes ses actions planifiées. Essayez maintenant.`a,-1`
`else`
	Vous avez peut-être déjà remarqué que survoler la barre temporelle ou sélectionner Pro affiche un **aperçu** des actions à une étape précise.
	Si vous vous déplacez dans une zone dangereuse par erreur, vous pouvez utiliser le **Clic Droit** pour annuler les actions que vous avez mises en file ce tour-ci.
	`c,akroHighlight,false`
	De plus, vous pouvez faire un **clic molette** sur une unité (ou appuyer sur **Ctrl** en la survolant) pour **épingler** un aperçu de toutes ses actions planifiées. Essayez maintenant.`a,-1`
`hdOverlay`

`x`

### akroTutorialSpurned
Ou pas, pfff...`a,0.5`
`hdOverlay`
`x`

# akroTookHit
![[proHit.png]]
Aïe!

![[proAnnoyed.png]]
(Allez, c'était tellement prévisible !)
(Juste... ne t'approche pas trop. Essaie de rester hors de portée de sa lance.)

>Ok.
>Pourquoi son attaque s'appelle comme ça ?`if !seen`
>	![[proSkeptical.png]]
>	(S'appelle comment?)
>	>...« L'Attakro d'Akro ».
>	>	`proAff+=0.5`
>	>	![[proMildSurprise.png]]
>	>	(Qu- tu peux voir ça!?)
>	>	![[proLaughing.png]]
>	>	(Hahaha!)
>	>	![[proSmile.png]]
>	>	(Je le taquinais avec ça quand on était gamins.)
>	>	(C'était...)
>	>	![[pro.png]]
>	>	(...il y a des années...)
>	>	![[proMildlyConflicted.png]]
>	>	(Hm.)
>	>Laisse tomber.
>...

`x`

# traineesStart
`akroDefeated`
![[akroPain.png]]
Kh-!
J'abandonne!

`if !tookDamageFromAkro`
	![[polemaPain.png]]
	Pas la moindre égratignure...

`c,combatEnd`
`camPan,arenaCenter`

![[akroQuestioningConcerned.png]]
C'était quoi, cette façon de bouger?
C'est comme si tu savais exactement où j'allais frapper à l'avance.
![[akroPain.png]]
Non. C'est plutôt comme si t'arrives à le voir dès que j'y pense.

![[proSmirk.png]]
Mon ami.
*Voilà* ce que c'est que d'être guidé par le Mécène.

![[polemaBemused.png]]
Je refuse de croire qu'on te donne des instructions aussi précises.
À moins que t'arrives à écarter tout conseil qui ne concerne pas directement le combat.

![[proMildSurprise.png]]
Euh...
![[proFacade.png]]
(C'est pas vrai, hein?)

>Bien sûr que non, tu es très réceptif!
>	`proAff+=1`
>	![[proSmile.png]]
>	(Fiou.)
>Tu pourrais m'écouter davantage.
>	`playerWhiny+=1``proAff-=1`
>	![[proRollingEyes.png]]
>	(Ah bon? On est arrivés jusqu'ici sans problème, non?)
>Bro.
>	![[proEmbarrassed.png]]
>	(Ça alors! T'as qu'à donner de meilleurs conseils!)
>	![[proNonchalant.png]]
>	(Peu importe, on est arrivés jusqu'ici.)

![[pro.png]]
D'accord Capitaine, allons-y.

![[polema.png]]
Pas si vite.
Vous trois, vous combattrez Pro en même temps.

`c,traineesShock`

![[proMildSurprise.png]]
`a,0.3`Quelle arnaque!

![[kionExclaimingSmiling.png]]
Là, tu vas y goûter!

![[chion.png]]
Euh- euh...

![[akroSurprised.png]]
Capitaine, vous êtes sûre-

![[polemaBemused.png]]
`a`Tout à fait sûre.
Les monstres combattent rarement seuls.
Je veux voir comment ce *guidage* compose avec plusieurs adversaires.
Approchez, vous tous.

![[]]
Capitaine!

## traineesFightStart

`c,traineesWalkIn`

`if seen`
	![[akroQuestioningConcerned.png]]
	J'avouerai que j'ai toujours pas l'impression que c'est équitable.
	![[proCynical.png]]
	Peu importe. J'ai compris votre jeu, regardez bien.
	[[#traineesCountdown]]

![[akroSmile.png]]
Désolé qu'on doive te tomber dessus comme ça.

![[kionExclaimingAngry.png]]
Pas moi!!

![[chion.png]]
...

![[proNonchalant.png]]
(Bon, c'est pas si grave. Avec un peu de chance, ils vont juste se piler sur les pieds.)

### traineesCountdown
![[polemaShout.png]]
Combattants, en garde!
Et...
Commencez!

`chionDone=0``chionOut=0`
`kionDone=0``kionOut=0`
`akroDone=0``akroOut=0`
`c,traineesFightStart`

`x`

### traineesFightTutorial

`if seen`
	[[#failureTutorial]]

`hdOverlay`
`c,unblockCamera`
`if gamepad`
	Pour avoir une meilleure vue, vous pouvez déplacer la caméra avec le **stick droit.** Essayez maintenant.
`else`
	Pour avoir une meilleure vue, vous pouvez déplacer la caméra avec les touches **ZQSD**, ou en déplaçant la souris vers le bord de l'écran. Essayez maintenant.
`c,unblockCameraEnd`
`hdOverlay`
`x`

# traineeDone

`if chionDone && !chionOut`
	`chionOut`
	[[#chionOut]]
`else if kionDone && !kionOut`
	`kionOut`
	[[#kionOut]]
`else if akroDone && !akroOut`
	`akroOut`
	[[#akroOut]]
`else if chionOut && kionOut && akroOut`
	[[#polemaStart]]

`x`
## chionOut

![[chionHit.png]]
Aïeee...
J-j'abandonne!

`c, chionWalksOut`

[[#traineeDone]]
## kionOut

![[kionHit.png]]
Argh...
D'accord, j'arrête.

`c, kionWalksOut`

[[#traineeDone]]

## akroOut
![[akroPain.png]]
Ouf-
Ok, ça suffit pour moi.

`c, akroWalksOut`

[[#traineeDone]]

# polemaStart
`traineesDefeated`
![[polemaStern.png]]
...

`c, combatEnd`
`camPan,arenaCenter`

![[pro.png]]
Ouf.
## polemaFightStart

`c,proGetsBackInTutorialPosition`

`if combatTutorialFailed`
	`c,polemaWalksIn`
	![[polemaStern.png]]
	...
	`if !seen`
		[[#polemaFightStartB]]
	![[proHidingSomething.png]]
	...
	[[#polemaCountdown]]

![[proSmirk.png]]
Trop bouche-bée pour siffler la fin?

`c,polemaWalksIn`

### polemaFightStartB

![[polemaStern.png]]
Akro, mon épée.

![[akroQuestioningConcerned.png]]
Ah... oui Capitaine.

![[proMildSurprise.png]]
O-oh. Pas de repos pour les braves...

### polemaCountdown

`c,polemaFightStart`

`x`

### polemaFightTutorial

`if seen`
	[[#failureTutorial]]

`hdOverlay`
`uiHighlight,9,143,127,158`
Certains adversaires redoutables seront capables de **réagir** à vos actions.
`uiHighlight,60,143,92,158`
Les actions qui devaient **démarrer** lors des étapes surlignées de la barre temporelle **changeront** en réponse à vos plans.
`uiHighlight`
Pour toucher juste, vous devrez atteindre votre adversaire **quand il ne peut pas réagir**.
`uiHighlight,35,146,62,155`
Portez attention aux actions qui démarrent tôt sur la barre : celles-ci resteront verrouillées.
`uiHighlight`
`hdOverlay`

`x`

# failureTutorial

`hdOverlay`
`if seen`
	Réfléchissez bien. Restez concentré. Ne faiblissez pas.
	Ça peut sembler impossible pour l'instant, mais vous en rirez un jour.
	Concentrez-vous sur la **barre temporelle**. Faites attention à votre position à chaque **étape**. Vous trouverez une ouverture.
	`if tutorialLostTo == polema`
		N'oubliez pas, vous pouvez librement mettre en file et annuler différents plans pour voir comment votre adversaire va **réagir** avant de vous engager.
	Restez calme. Je suis certain que vous pouvez y arriver.
	`hdOverlay`
	`x`

Eh bien, ce combat est coriace, non ?
`uiHighlight,0,92,133,177`
N'oubliez pas de **bien observer la barre temporelle.** C'est toujours la première chose à regarder.
`c,timelineReadOrder,false`
`unskip`N'oubliez pas, les actions d'une même étape se résolvent de **haut en bas.**
`unskip`**Pro agira toujours en premier dans une étape !**
`var, timelineReadOrderEnd`
`uiHighlight`
`if gamepad`
	Planifiez soigneusement. Essayez de mettre en file différents plans pour voir leur effet sur la barre temporelle. Vous pouvez toujours annuler un plan avec **LT**.
	`c,highlightTimelineAndUnblock`
	Pour y voir plus clair, vous pouvez vous concentrer sur la barre temporelle avec **RB**. Profitez-en bien ! C'est vraiment important ! Vous en aurez probablement souvent besoin !
`else`
	Planifiez soigneusement. Essayez de mettre en file différents plans pour voir leur effet sur la barre temporelle. Vous pouvez toujours annuler un plan avec le **Clic Droit**.
	`c,highlightTimelineAndUnblock`
	Pour y voir plus clair, vous pouvez survoler la barre temporelle avec votre souris. Profitez-en bien ! C'est vraiment important ! Vous en aurez probablement souvent besoin !

`c,unhighlightTimeline`
`hdOverlay`
`x`

# polemaMid
![[polemaPain.png]]
Kh-!

`if seen`
	![[polemaOverexerted.png]]
	Bon... trêve de plaisanteries.
	![[akroQuestioningConcerned.png]]
	...
`else`
	![[akroOrders.png]]
	Ce combat est-
	![[polemaOverexerted.png]]
	Attends.
	Ça va. On continue.
	![[akroSurprised.png]]
	Capitaine, vous-
	![[polemaPain.png]]
	Je n'abandonne *pas*!
	![[akroQuestioningConcerned.png]]
	...

`c,polemaEnterPhase2`
`x`
# polemaDefeated
`polemaDefeated`
![[polemaSeriousHit.png]]
AAH!

`camPan, polema`

![[polemaPain.png]]
Ne...

`c,polemaCollapses`

![[akroSurprised.png]]
`a,0.3`!

![[chionSurprised.png]]Capitaine!

![[kion.png]]...

`a`
`if combatTutorialFailed`
	`c,combatEnd`
	`camPan,arenaCenter`
	[[#polemaCartedAway]]

![[akroOrders.png]]
Bon, vous deux, préparez-vous, on remonte.

![[kion.png]]
O-oui.

`c,combatEnd`
`camPan,arenaCenter`

![[pro.png]]
(...)
>On a réussi!
>	(Euh.)
>	![[proSmile.png]]
>	(Ouais... Ouais!)
>	(On a réussi!)
>	![[pro.png]]
>	(...)
>Content?
>	![[pro.png]]
>	(Je... suppose que oui.)

(...)

# elevatorRises
`c,elevatorRises`

# polemaCartedAway
![[akroQuestioningConcerned.png]]
Vite, le brancard.

![[kion.png]]
J'y vais!

`c,chionAndKionGetTheStretcher`

![[akro.png]]
Vous la tenez?

![[kion.png]]
Oui.

![[chion.png]]
O-oui.

![[akroOrders.png]]
Bon, emmenez-la à l'infirmerie, aussi vite que possible.
Je reste ici pour *monter la garde*.

![[kion.png]]
Ouais, d'accord.

`c,chionAndKionCarryPolemaAway`

![[akroQuestioning.png]]
J'adore ce gamin, mais quelqu'un devrait lui apprendre à être un peu plus méfiant.

`facePlayer,akro``p,0.5`

![[akroBemused.png]]
Bon, on te sort d'ici.

![[proMildSurprise.png]]
`face,pro,akro`
...
Attends, vraiment?
Pourquoi tu es resté alors?

![[akroBemusedOpenMouth.png]]
`if combatTutorialFailed`
	Je veux pas que t'abandonnes l'ascenseur en bas. Il se ferait démolir.
`else`
	Je veux pas que tu laisses ce truc en bas pour qu'il se fasse démolir.

![[akroBemused.png]]
Ou que t'essaies de le renvoyer en haut sans passager.

![[proFacade.png]]
Je ferais pas ça.

![[akroWrySmile.png]]
Ha! Haha! Tu mens comme un gosse.
![[akro.png]]
Allez, on dégage d'ici.

`c,akroAndProWalkToElevator`

# akroConvo

`c,setupAkroConvoFromLoad`

![[akro.png]]
Oh, tu sens ça?
Je crois qu'on vient de passer le <span style="color:rgb(225, 188, 105)">seuil de la Fixation</span>.

![[proConflicted.png]]
Mm...

`if fromLoad`
	>(Ignorer)
	>	[[#elevatorReachesBottom]]
	>(Continuer à écouter)

`p,1.5`

![[proHidingSomething.png]]
...

![[akro.png]]
Quelque chose te tracasse?

![[pro.png]]
... Pourquoi tu m'aides?

![[akroBemusedOpenMouth.png]]
C'est pas comme si j'étais capable de t'arrêter.

![[proHidingSomething.png]]
Ouais, je comprends. C'est juste que... je t'aurais cru plus récalcitrant.

![[akroQuestioningConcerned.png]]
Pourquoi?
Oh, tu crois que je crains les remontrances de la part de la capitaine?
T'inquiète, je sais qu'elle comprendra.
![[akroBemused.png]]
Enfin, elle finira par s'y faire. Elle voulait *vraiment* pas te laisser partir.
![[akroWrySmile.png]]
Tu me fais douter maintenant, haha.

![[proMildSurprise.png]]
Là! C'est en plein ce que je voulais dire.
Tu rigoles, mais je- j'aurais jamais pensé que tu risquerais de contrarier la capitaine pour *moi*.

![[akro.png]]
Pourquoi pas?

![[proConflicted.png]]
Parce que, eh bien...
T'as une dent contre moi?

![[akroQuestioningConcerned.png]]
Ouah, ça sort d'où, ça?

![[proMildlyConflicted.png]]
Je.. je me suis toujours dit que ça valait pas la peine de l'aborder.
Mais bon, maintenant que je quitte, plus besoin de me retenir.

![[akro.png]]
Je crois que tout le monde aimerait que tu prennes les choses plus au sérieux.
Mais là tu donnes l'impression que je te déteste.

`c,proConfrontsAkro,false`

![[proFrustrated.png]]
Comment tu pourrais pas!?
Tu te donnes tellement à fond, tout le monde t'adore, ils pensent évidemment que t'es meilleur que moi.
![[proMildlyConflicted.png]]
Mais c'est à moi que revient le droit d'être le héros, simplement parce que je suis né dans le rôle.

![[akroQuestioning.png]]
Le « droit » d'être?
![[akroWrySmile.png]]
Ha, je croyais que tu faisais semblant d'être nonchalant, mais ça te dépasse réellement à vrai dire.
![[akroQuestioningConcerned.png]]
Tu crois que j'ai envie de me promener dans les bois avec une chance sur dix de me faire tuer?
![[akroBemusedOpenMouth.png]]
Sans parler de la pression.
J'arrive pas à croire que t'aies pas craqué avec tous les reproches qu'on te fait.

![[proMildSurprise.png]]
Oh. M-moi non plus.
![[proSoftSmile.png]]
...
![[proMildlyConflicted.png]]
...
Désolé.

![[akroWrySmile.png]]
Haha.
Bon, j'avoue que j'étais quelque peu vexé quand on a arrêté de traîner ensemble.
Je me disais, en fin de compte, que t'en avais beaucoup sur les épaules.

![[proNonchalant.png]]
Hm. Faut croire que t'es réellement un type sympa...

![[akroSmile.png]]
Peut-être.
![[akro.png]]
...
On dirait qu'on arrive bientôt.

![[proHidingSomething.png]]
Ouais.

![[akro.png]]
...
Pourquoi tiens-tu *tant* à partir? On est vraiment si pénibles que ça?

![[proHidingSomething.png]]
... Je sais pas.
![[proDisdainful.png]]
J'en ai juste marre d'être enfermé.
![[pro.png]]
Là-bas, j'aurai un peu plus l'occasion d'être moi-même.

![[akro.png]]
Au lieu de devoir jouer au héros?

![[proAnnoyed.png]]
Peut-être!
Ou peut-être qu'il est temps d'être un héros- le héros.

![[proCynical.png]]
Je veux juste pas être *leur* héros, tu comprends?

![[akroSmile.png]]
Je comprends.

# elevatorReachesBottom

`c,elevatorReachesBottom`

![[akro.png]]
Bon, j'irai pas plus loin.

![[pro.png]]
Pressé de remonter?

![[akro.png]]
Euh, ouais, un peu.
`face,akro,up`
![[akroQuestioningConcerned.png]]
...

![[pro.png]]
Qu'est-ce qu'il y a?

![[akroQuestioningConcerned.png]]
`face,akro,left`
Désolé, c'est juste que je réalise à quel point je vais mal paraître tu ne reviens pas.
T'es vraiment sûr de toi? Tu pourras pas remonter pendant un moment.
Il n'y aura probablement personne pour surveiller l'ascenseur tant que la capitaine sera pas rétablie.

![[proMeditating.png]]
Oui, je suis sûr...
`a,0.5`![[proJovial.png]]...pas que tu puisses m'arrêter maintenant!
`a,0.2`![[proLaughing.png]]Haha!
`c,proRunsOffTheElevator`

`a`![[akroQuestioningConcerned.png]]
Pfff...
![[akro.png]]
D'accord, bonne chance.

![[proSmile.png]]
À plus!

![[akro.png]]
Ouais, à plus...

`c,elevatorReturnsWithAkro`

![[pro.png]]
(Désolé que t'aies dû subir tout ça.)

>Je suis content que tu aies pu mettre les choses au clair.
>	`proAff+=1`
>	![[proNonchalant.png]]
>	(Ouais, plus ou moins...)
>	![[proJovial.png]]
>	(Maintenant allons-y!)
>T'inquiète. En avant!
>	`proAff+=2`
>	![[proJovial.png]]
>	Oui!
>C'est rien.
>J'écoutais pas.
>	`playerClueless+=1``proAff-=1`
>	![[proNonchalant.png]]
>	(C'est compréhensible.)
>	![[pro.png]]
>	(Allons-y.)
>Peu importe, on est dehors. Donne-moi mon prix.`if pinwheelPrizeMentioned`
>	![[proSkeptical.png]]
>	(Quoi?)
>	![[proCynical.png]]
>	(Oh... pour les virevents?)
>	(Tu te paies ma tête?)
>	>Oui. Haha. Je m'attendais à rien du tout.
>	>	`proAff+=2`
>	>	![[proSmirk.png]]
>	>	(Ah oui?)
>	>Non, je plaisantais pas.
>	>	`playerCaresAboutPinwheels``proAff-=1`
>	>	![[proCynical.png]]
>	>	(Il- il n'y a pas de prix. Désolé.)
>	>	>Oh non...
>	>	>Je m'en souviendrai.
>	>	![[proCynical.png]]
>	>	(Je- écoute, je te revaudrai ça.)
>	>	![[proNonchalant.png]]
>	>	(Je suis sûr qu'il y aura quelque chose d'intéressant par ici.)

`combatTutorialDone`
`inIrisIntro`

`x`

# failure

`c,proWakesUpAfterFailure`

`if combatTutorialFailed`
	![[proCynical.png]]
	(...)
	(Bon... au moins on progresse.)
	(...enfin, je crois.)
	`c, proGetsUpAfterFailure`
	`x`

`combatTutorialFailed`
![[proAnnoyed.png]]
Urgh...
>!Que s'est-il passé?
>	(... On a perdu.)
>	>Pourquoi on est dans ta chambre?
>	>	![[proEmbarrassed.png]]
>	>	(Quelqu'un m'a probablement porté ici après que je me sois évanoui.)
>	>Ça t'arrive souvent?
>	>	![[proCynical.png]]
>	>	(Plus tellement, ces derniers temps.)
>	>	(Merci pour ton guidage, en passant.)

![[salviaConcern.png]]
Pro?

`c,salviaWalksInAfterFailure`

Oh, bien, tu es réveillé. J'avais peur que tu restes inconscient pendant des heures encore.
...

`if saidGoodbyeToMom`
	Après les adieux émouvants que tu m'as faits, je ne savais pas trop à quoi m'attendre.
`else`
	![[salviaSerious.png]]
	Franchement. Foncer se battre contre la capitaine sans dire un mot?

![[proAnnoyed.png]]
Tu as l'air soulagée...

![[salviaConcern.png]]
Eh bien... je suppose que je suis contente de voir que t'es fidèle à toi-même, toujours là à te battre jusqu'à t'écrouler.

`if tutorialLostTo == kion`
	Tu as donné une sacrée frayeur à ce pauvre Kion.
	![[proMildSurprise.png]]
	(Non... non, non, non.)
	![[proPanicked.png]]
	J'ai perdu contre *Kion*.
	![[salviaConcern.png]]
	Eh bien, je ne sais pas exactement ce qui s'est passé entre vous tous.
	Mais le garçon avait l'air carrément ébahi.
	![[proAnnoyed.png]]
	Aaauughh.....
	![[proSad.png]]
	(Pourquoi!? Pourquoi tu me ferais une telle chose?)
	>!Mes excuses!
	>	![[proFrustrated.png]]
	>	(Je te crois pas!!)
	![[salvia.png]]
	Oh, pas besoin de t'en faire.
	Je suis sûre que Kion s'en remettra.
`else if tutorialLostTo == akro`
	Enfin, ça fait combien de fois, au total?
	Je croyais qu'Akro et toi auriez appris à être plus prudents à force.
	![[proAnnoyed.png]]
	Ugh.
	(C'est pour ça que je vais jamais aux entraînements de groupe. Kion va plus jamais la fermer.)
	>!C'est vraiment pour ça que tu vas pas aux entraînements de groupe?
	>	![[proCynical.png]]
	>	(...)
	>Et Akro?
	>	(Lui, il fait juste me narguer en silence.)
	>	![[proCynical.png]]
	>	(Je dirais que c'est « encore pire » mais Kion est *vraiment* agaçant.)
`else if tutorialLostTo == guards`
	Même si ça me semble à peine juste que t'aies eu à combattre les trois garçons en même temps.
	Je présume que la capitaine voulait te donner une bonne leçon.
	![[proAnnoyed.png]]
	Qu'est-ce qu'elle t'a dit, d'ailleurs?
	![[salvia.png]]
	Pas grand-chose. Kion, en revanche... est bavard comme toujours.
`else if tutorialLostTo == polema`
	En fin de compte, c'est pas si surprenant, vu que t'as affronté la capitaine elle-même. Qu'est-ce qui t'as pris?
	![[proHidingSomething.png]]
	Mmm...

![[salvia.png]]
Bref, relève-toi. Passe pas *encore* un après-midi à traîner par terre.

![[proCynical.png]]
Maman.

![[salviaQuestioning.png]]
Quoi? Tu sais, je t'entends quand tu te morfonds à voix haute ici.

![[proFrustrated.png]]
Maman! Un peu de discrétion, s'il te plaît!

![[salvia.png]]
Qu'est-ce que tu... Oh!
Oui, bien sûr. Faudrait pas donner une mauvaise première impression!

>Je crois que c'est un peu tard pour ça.
>	![[proAnnoyed.png]]
>	(Chut.)
>	![[salvia.png]]
>	...hm?
>	![[proHidingSomething.png]]
>	Rien.
>...

Eh bien, si c'est sorti de ton système, tu devrais aller prendre l'air.
Tout le monde doit avoir hâte de te parler après tout.
Je te laisse te préparer.

`c, salviaLeavesAfterFailure`
`c, proGetsUpAfterFailure`
`x`


# returnedAfterFailure

`c,proWalksUpToTrainees`

`if polemaThreatened`
	![[polemaPainedConcern.png]]
	...
	![[proDetermined.png]]
	...
	![[polemaPainedConcern.png]]
	... C'est reparti, alors.
	`c,tutorialReset`

`if seen`
	![[polema.png]]
	Oui?
`else`
	![[polema.png]]
	Ah. Tu t'es finalement relevé.
	Tu veux te joindre à nous?

![[proHidingSomething.png]]
(...)

>T'attends quoi? Défie-la à nouveau.
>	![[proDetermined.png]]
>	On est prêts à recommencer.
>	![[polemaBemused.png]]
>	« Recommencer »?
>	C'était une occasion unique, cadet.
>	![[proStressed.png]]
>	...
>	>Insiste un brin.
>	>	`c,proThreatensPolema`
>	>	`polemaThreatened`
>	>	![[proDetermined.png]]
>	>	...
>	>	![[polemaPain.png]]
>	>	...
>	>	![[akroSurprised.png]]
>	>	Ouah, euh...
>	>	![[chion.png]]
>	>	C-capitaine?
>	>	![[polemaStern.png]]
>	>	...
>	>	![[polemaShout.png]]
>	>	Très bien!
>	>	![[polema.png]]
>	>	On fera ça autant de fois qu'il faudra, alors.
>	>	![[polemaShout.png]]
>	>	Cadets!
>	>	![[]]
>	>	Capitaine!
>	>	![[polemaShout.png]]
>	>	Dégagez le terrain.
>	>	![[]]
>	>	Oui, capitaine!
>	>	`c,tutorialReset`
>	>Laissons tomber pour l'instant.
>	>	![[proHidingSomething.png]]
>	>	`if backedOutOfTutorialRematch`
>	>		... Laisse tomber.
>	>		`c,proBacksOutOfFight`
>	>		`x`
>	>	... D'accord.
>	>	Dans ce cas, j'irai... parler aux autres.
>	>	[[#backedOff]]
>Laissons tomber pour l'instant.
>	![[proHidingSomething.png]]
>	`if backedOutOfTutorialRematch`
>		... Laisse tomber.
>		`c,proBacksOutOfFight`
>		`x`
>	Non... c'est que... je venais pour te dire que je serai occupé.
>	À parler aux autres.
>	[[#backedOff]]

## backedOff
![[polemaSkeptical.png]]
Je vois.
![[polema.png]]
Prends le temps qu'il te faut.
![[proHidingSomething.png]]
Mm.
`backedOutOfTutorialRematch`

`c,proBacksOutOfFight`
`x`
