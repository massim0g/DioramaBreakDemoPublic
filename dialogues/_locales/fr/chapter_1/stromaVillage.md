# inspectables

## pinwheel
`pinwheelsFound+=1`

`if pinwheelsFound == 1`
	![[proNonchalant.png]]
	(Ces virevents servent supposément à mesurer le flux d'Air.)
	(Mais on n'aurait évidemment pas besoin d'une douzaine pour ça.)
	(Les gens les aiment juste comme décorations.)
`else if pinwheelsFound == 2`
	![[pro.png]]
	(... Un autre virevent.)
`else if pinwheelsFound == 3`
	![[proSkeptical.png]]
	(T'aimes vraiment ça, hein?)
`else if pinwheelsFound == 4`
	![[proCynical.png]]
	(Tu fais juste le tour pour les regarder?)
`else if pinwheelsFound == 5`
	![[proAnnoyed.png]]
	(C'est quoi le quatrième, cinquième?)
	>Le cinquième.
	>	![[proBemused.png]]
	>	(Heh. Content de voir que tu comptes aussi.)
	>Le quatrième.
	>	![[proBemused.png]]
	>	(Ha. Je t'ai eu. C'est le cinquième.)
	>	(À quoi bon si tu les comptes même pas correctement?)
	>Je compte pas.
	>	![[proCynical.png]]
	>	(Alors à quoi bon...?)
`else if pinwheelsFound == 6`
	![[pro.png]]
	(Ça fait le sixième maintenant. T'essaies de tous les trouver?)
	>Ouais!
	>Non. Je les trouve juste cool.
	![[proNonchalant.png]]
	(Bon... peu importe. C'est mieux que de rester planté là pendant que les gens te parlent.)
`else if pinwheelsFound == 7`
	![[proNonchalant.png]]
	(Le septième. C'est la moitié.)
`else if pinwheelsFound == 8`
	![[pro.png]]
	(Eh, numéro huit.)
`else if pinwheelsFound == 9`
	![[pro.png]]
	(Le huitième.)
	>!Je crois que t'as mal compté.
	>	![[proSmirk.png]]
	>	(Content de voir que tu portes attention.)
`else if pinwheelsFound == 10`
	![[proDetermined.png]]
	(Le GRAND un-zéro.)
	![[proNonchalant.png]]
	(Encore quelques autres.)
`else if pinwheelsFound == 11`
	![[proNonchalant.png]]
	(Numéro onze.)
	(...)
	(Je trouve rien à dire sur celui-ci.)
`else if pinwheelsFound == 12`
	![[proSkeptical.png]]
	(Hm, je me souvenais pas qu'il y en avait un ici.)
	![[proNonchalant.png]]
	(Il en reste deux, alors.)
`else if pinwheelsFound == 13`
	![[proNonchalant.png]]
	(Il n'en reste qu'un à trouver. Trépidant.)
`else if pinwheelsFound == 14`
	![[proNonchalant.png]]
	(Eeet... on les a tous trouvés.)
	(Bien joué?)
	>Hourra!
	>	![[proNonchalant.png]]
	>	(Géniaaal!)
	>	![[proCynical.png]]
	>	(On peut y aller maintenant?)
	>Je gagne quoi?
	>	![[proThinking.png]]
	>	(Hmm...)
	>	![[proFacade.png]]
	>	(Un truc secret spécial qui sera seulement dévoilé quand on sera sortis du village.)
	>	(Allons le chercher!)
	>	`pinwheelPrizeMentioned`
`x`

## cabinet
![[proCynical.png]]
`if cabinetInspected`
	(Arrête d'essayer de me faire fouiller dans des meubles au hasard.)
`else`
	(Tu comptes faire quoi avec ça? Je vais pas me mettre à fouiller dans les meubles des gens.)`cabinetInspected`
`x`
## prosHouse
### ergsRoom
`if !introDone`
	`x`
![[pro.png]]
(La chambre de grand-papa.)
![[pro.png]]
(Un peu suffocant là-dedans, mais je l'entends jamais se plaindre.)
![[proRollingEyes.png]]
(Sauf quand il se met à m'agaçer.)
`x`

### salviasRoom
`if !introDone`
	`x`
![[pro.png]]
(La chambre de maman.)
>!On y va!
>	`playerClueless+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(Non.)

`x`
### prosKitchenCabinet
![[pro.png]]
(J'ai pas vraiment faim...)
![[proFacade.png]]
(Et si on sortait s'ouvrir l'appétit?)
`x`

## prosNeighbourhood
### salviasGarden
![[proSmirk.png]]
Je te dis, ma mère fait pousser d'excellents légumes, `$player`.
`x`

### salviasTools
![[pro.png]]
(Les outils de ma mère.)
>!Elle jardine?
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Ouaip. *Toutes* les formes de jardinage.)
>	(Le lierre se drape pas parfaitement et élégamment tout seul, tu sais.)
>	![[pro.png]]
>		(En fait, je crois qu'elle tient surtout à faire pousser toute notre nourriture.)

`x`

### prosArmor
![[pro.png]]
(Ma vieille armure. Elle me fait plus depuis des plombes.)
![[proCynical.png]]
(Je détestais porter ce truc, ça limite mes mouvements.)
>!Tu peux pas en avoir une nouvelle?
>	![[proSmirk.png]]
>	(Je « prévois » la faire réajuster depuis un moment.)
>	![[pro.png]]
>	(Personne me presse vraiment, par contre.)
>	(Je me débrouille assez bien aux entraînements,)
>	![[proRollingEyes.png]]
>	(alors c'est probablement au bas de la longue liste de trucs pour lesquels les gens me tombent dessus.)

`x`

### chionAndKionArmor
![[pro.png]]
(On dirait les armures de rechange de Chion et Kion.)
![[proCynical.png]]
(Je crois pas qu'ils avaient réfléchi à leur coup en commandant quatre ensembles identiques.)
(Je suppose qu'Edif ne gère pas ce genre de truc aussi bien que sa femme.)
`x`

### chionAndKionSpears
![[pro.png]]
(Des lances de rechange. Quand la moitié du ménage les utilise, c'est bien d'en avoir quelques-unes en réserve.)
`x`
### prosLaundry
![[proSmirk.png]]
(Mon linge sale t'intéresse?)
`x`
## townCenter
### Pond
![[pro.png]]
(La créature au milieu aurait aidé à façonner le monde.)
![[proCynical.png]]
(Je me souviens plus exactement de sa contribution...)
>!Votre face?
>	...?

`x`
### akrosSpears
![[pro.png]]
(Les lances de rechange d'Akro.)
![[proCynical.png]]
(C'est le seul de sa famille à s'en servir, mais j'imagine qu'il en faut assez pour trois personnes.)
>!Pourquoi autant?
>	![[pro.png]]
>	(Les pointes se cassent assez facilement.)
>	![[proCynical.png]]
>	(Pas étonnant vu qu'on peut juste les fabriquer avec des bouts de métal raclés de l'intérieur de l'arbre.)

`x`

## townHallExterior

### observationDeck
`x`

### townHallLandscaping
![[pro.png]]
(Ce sont les outils qu'on utilise pour l'aménagement autour de la mairie.)
>!L'aménagement a l'air un peu inachevé.
>	![[proSmirk.png]]
>	(Ouais...)
>	(Ils refilent ce boulot à nous, les jeunes.)
>	(Et pour une fois, c'est pas que moi qui ai mieux à faire.)

`x`

### townHallEntrance
`if sprinklerCutsceneDone`
	`x`

![[proCynical.png]]
(Quoi? T'as oublié quelque chose?)
(Allez, on y va. Ils sont sûrement encore en train de ranger là-dedans.)
`x`
## townHallInterior
### mayorsOfficeDoor
`if introDone || dendroOfficeMentioned`
	`x`

![[dendro.png]]
C'est la porte de mon bureau.
N'hésitez pas à passer une fois que vous aurez eu l'occasion de vous familiariser avec le village.
`x`
### stainedGlass
`if introDone`
	`x`

`camPan, stromaStainedGlassMural`

![[pro.png]]
...

![[dendro.png]]
Le vitrail vous intéresse?
Je serais ravi d'en expliquer la signification.

![[proCynical.png]]
(Dis non, s'il te plaît.)

>J'aimerais en entendre parler.
>	![[proAnnoyed.png]]
>	(...)
>	![[proCynical.png]]
>	Faites court.
>	![[dendro.png]]
>	Oui, certainement.
>	![[dendroClearingThroat.png]]
>	Hm hm.
>	![[dendroPreaching.png]]
>	Ce vitrail représente le Vaisseau, symbole de notre <span style="color:rgb(225, 188, 105)">Ministère</span>.
>	La terre et la mer visibles dans la partie inféri-`a,0.3`
>	![[proAnnoyed.png]]
>	`a`Plus court.
>	![[dendroSurprised.png]]
>	...
>	Il- le symbole représente l'univers tel que nous le concevons.
>	![[dendro.png]]
>	La tête d'un être supérieur, voilée, surplombe le paysage ci-bas
>	où se dresse une image de la terre.
>	Et finalement, il y a notre monde, façonné au croisement de ces derniers.
>	`camReset`
>D'accord.
>	`camReset`
>	![[pro.png]]
>	Non, c'est bon.
>	![[dendro.png]]
>	Très bien.

`x`

### townHallBulletinBoard
![[proCynical.png]]
(Le maire voulait que ce rituel reste discret...)
(...mais il a réservé la mairie pendant des heures.)
(Ça rend les choses assez évidentes.)
![[proRollingEyes.png]]
(Puis, de toute façon, ils sont probablement déjà au courant, tous sans exception.)
![[proCynical.png]]
(Les secrets ne font pas long feu dans ce village.)
`x`
### townHallClock
![[pro.png]]
(Hm. Cette horloge ne bouge plus. Elle doit être à court d'<span style="color:rgb(225, 188, 105)">Air</span>.)
![[proNonchalant.png]]
(Je suppose que personne ne ressent le besoin de vérifier l'heure ici.)
`x`

### townHallFood
![[proSkeptical.png]]
Pourquoi est-ce qu'il y a de la nourriture ici?
![[phyllo.png]]
On s'est dit que le Mécène voudrait peut-être... manger?
![[proSkeptical.png]]
?
(Tu as faim?)
>Oui.
>	![[proNonchalant.png]]
>	(Eh bien... moi non.)
>Non.
>	![[proNonchalant.png]]
>	(Bien, moi non plus.)
>Je peux pas manger ça, andouille.
>	`proAff+=0.5`
>	![[proRollingEyes.png]]
>	(C'est ce que je pensais.)
>	![[proSmirk.png]]
>	Le Mécène dit que c'est bête comme idée!
>	![[dendroSurprised.png]]
>	Ah... pardonnez-nous.
>	La nature exacte- la façon dont vous percevez les sens de votre protégé n'avait pas été précisée.
>	![[proSmirk.png]]
>	Je vous pardonne.
>	![[proNonchalant.png]]
>	(De toute façon, j'avais pas faim.)

`x`

## library

## libraryCounter
`if sprinklerCutsceneDone`
	[[#phyllo]]
`else`
	[[#Libra]]

### libraryBackOfComputer
![[proNonchalant.png]]
(Me demande pas comment tous ces fils et tuyaux fonctionnent.)
`x`

### emptyPlanter
![[pro.png]]
(Oh, un bac à plantes vide.)
(Ce qu'il y avait dedans est mort, on dirait.)
![[proThinking.png]]
(Ou juste pas assez joli.)
`x`
### repository
![[pro.png]]
`if !repositoryExplained && !repositoryMentioned`
	(C'est notre copie du <span style="color:rgb(225, 188, 105)">Répertoire</span>.)
`else`
	(C'est notre copie du Répertoire.)
#### repoChoice
>C'est quoi?[[#repoAsk]]`if !repositoryExplained`
>Lis-moi la prophétie.[[#repoProphecy]]`if repositoryExplained`
>Tourne à une page au hasard.
>	![[]]
>	(...)
>	(`$repoLine`)
>	[[#repoChoice]]
>Laisse tomber.

`x`
#### repoAsk
![[proCynical.png]]
(Crois-le ou non, c'est une encyclopédie magique de votre monde. En grand format.)
![[proNonchalant.png]]
(Qui existe depuis la nuit des temps.)
(Phyllo pourra sûrement mieux l'expliquer que moi.)`repositoryMentioned`
[[#repoChoice]]

#### repoProphecy
![[proNonchalant.png]]
(Je doute que tu y trouveras quoi que ce soit que tu ne connaissais pas déjà...)
(Mais bon, d'accord.)
![[pro.png]]
(...)
(La voilà.)
![[]]
Un jour, un individu élu naîtra.
Sa naissance sera marquée d'un signe évident.
Le jour de ses 20 ans, il sera lié à un observateur humain de la Terre.
Cet humain sera le joueur d'un grand jeu.
>!Hm... pour l'instant ce jeu est passable au mieux.
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Désolé de te décevoir.)

![[]]
Ensemble, s'ils font le choix de persévérer, l'élu et ce joueur refaçonneront le monde.
Une fois ce changement réalisé, la connexion du joueur au monde sera coupée.

![[pro.png]]
(C'est tout.)
>C'est tout!?
>	![[proAnnoyed.png]]
>	(Avoue! Par contre, à bien y penser...)
>	![[proNonchalant.png]]
>	(Il y a d'autres sections qui expliquent mieux ce qu'on entend par « observateur humain » ...)
>	(Mais elles sont assez... abstraites? Ça me passe toujours au-dessus de la tête.)
>	![[proThinking.png]]
>	(En plus... il y a aussi la section chiffrée.)
>	![[proCynical.png]]
>	(Le maire dit que c'est juste des détails de procédure.)
>	(Pourtant j'ai soi-disant pas le droit de la lire.)
>	(Vraiment suspect.)
>	`encryptedPropheciesMentioned`
>Tu avais raison, je savais déjà tout ça.
>	![[proNonchalant.png]]
>	(Bon, au moins c'est dit maintenant.)
>Sacrément sec pour une prophétie.
>	![[proSkeptical.png]]
>	(Comment ça? Toutes les prophéties sont comme ça.)
>	![[proRollingEyes.png]]
>	(Il va pleuvoir ici tel jour. La température sera mesurée à exactement tant et tant.)
>	![[proNonchalant.png]]
>	(Comparativement, celle-ci est palpitante.)
>	`normalPropheciesExplained`
>C'était quoi la dernière partie?
>	![[pro.png]]
>	(À propos de ta connexion qui sera coupée?)
>	(On dirait que tu pourras pas rester de manière définitive.)
>	![[proNonchalant.png]]
>	(T'attache pas trop, alors.)


`x`

## mainTrunk
### sprinkler
![[pro.png]]
(C'est le transformateur qu'on doit utiliser pour alimenter l'Asperseur.)
`camPan, stromaFixture`
![[pro.png]]
(L'Air arrive de la <span style="color:rgb(225, 188, 105)">Fixation</span> et se comprime avant d'être envoyé par le tuyau.)

>La « Fixation »?
>	![[proSkeptical.png]]
>	(Tu connais pas?)
>	![[proThinking.png]]
>	(C'est une espèce de fontaine d'Air magique géante. Et ça repousse les monstres, dans un certain rayon.)
>	![[pro.png]]
>	(En fait, c'est à cause de ce truc qu'on a dû se planquer ici en haut, dans les branches.)
>	>!Pourquoi vous l'avez mise là?
>	>	![[proSkeptical.png]]
>	>	(Mise?)
>	>	![[pro.png]]
>	>	(Oh. On ne sait pas les fabriquer. Elles ont toujours été là.)
>	![[pro.png]]
>	(Bref...)
>Je vois.

`camReset`

`if sprinklerExplained`
	![[pro.png]]
	(Pour ce qui est de l'Asperseur lui-même, Mme Kitamura l'a déjà mieux expliqué que moi.)
`else`
	![[pro.png]]
	(Si tu veux savoir comment l'Asperseur fonctionne, Mme Kitamura là-bas pourra mieux l'expliquer que moi.)`sprinklerMentioned`
	>!Ça te dérange pas de t'arrêter pour demander?
	>	`proAff+=0.5`
	>	![[proSmirk.png]]
	>	(Ben, c'est assez cool. Moi aussi je serais curieux.)
	>	![[proNonchalant.png]]
	>	(Et elle est juste là, ça prendra pas longtemps.)

`x`

### centerBranch
`camPan, stromaTrunkCenterLamp`
![[pro.png]]
(On garde cette branche dépouillée de feuilles pour que la lampe qu'on a accrochée là puisse éclairer correctement.)
`camReset`
![[proHidingSomething.png]]
(Aussi pour limiter sa croissance, histoire qu'elle finisse pas par casser le plancher.)
![[pro.png]]
(Dès que des feuilles apparaissent, quelqu'un monte pour les arracher.)
>!Hm.
>	![[proSkeptical.png]]
>	(Quoi?)
>	>Ça semble un peu excessif.
>	>	(Tu préfèrerais vivre sous un abat-jour?)
>	>Rien.

`x`

### playerIsLost
![[proCynical.png]]
(Ok, ça doit bien faire trois fois qu'on passe par ici.)
(T'as besoin d'aide pour t'y retrouver?)

>Oui.
>	![[proAnnoyed.png]]
>	(...)
>	`face,pro,left`
>	![[proCynical.png]]
>	(Le pont vers la sortie est *juste là*.)
>	`camPan,stromaBridgeToTrainingArea`
>	`a,1.5`
>	`camReset`
>	(Allez, on y va.)
>Non.
>	`face,pro,left`
>	![[proCynical.png]]
>	(Mm. D'accord. Je voulais surtout te faire savoir que le pont vers la sortie se trouve juste là.)

`x`

## workshopArea

### workshopEquipment
![[pro.png]]
(Voilà ce qu'on utilise pour fabriquer toutes ces lances et ces outils.)
>!Tu devrais commencer à palper des trucs au hasard et à tout chambarder.
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Heh. Je sais m'en servir, tu sais.)
>	![[proNonchalant.png]]
>	(Mais Oiko s'énerve effectivement quand je déplace des trucs.)
>	![[proSmirk.png]]
>	(Aussi captivant que ce soit...)
>	![[pro.png]]
>	(...on a mieux à faire.)

`x`

### workshopAreaTable
![[pro.png]]
(Rien de tel que boire du jus à l'ombre par une journée chaude.)
![[proNonchalant.png]]
(On croirait pas qu'il ferait si chaud aussi haut.)
(Ça a un rapport avec la façon dont le Grand Arbre fait circuler l'Air.)
>!On est à quelle altitude exactement?
>	![[proThinking.png]]
>	(Oh... environ trois kilomètres je crois.)
>	>Ouah!
>	>	![[proSmirk.png]]
>	>	(Ouais, on y pense pas souvent mais c'est quand même assez cool.)
>	>Je vois.

`x`
### captainsHouse
`if encounteredPolema`
	![[pro.png]]
	(La maison de la capitaine.)
	![[proCynical.png]]
	(Traînons pas ici, j'ai pas envie de la vexer davantage.)
`else`
	![[pro.png]]
	(La maison de la capitaine. La porte est verrouillée, comme d'habitude.)
	>!Capitaine?
	>	![[proCynical.png]]
	>	(Ouais, la capitaine de la garde. La capitaine de « tout le monde ».)
	>	![[proDisdainful.png]]
	>	(Je pourrais t'en dire plus, mais il y a pas moyen de sortir d'ici sans la croiser.)

`x`

## trainingArea
### spareTrainingEquipment
![[pro.png]]
(C'est le matériel de rechange pour les entraînements avec les autres.)
![[proSkeptical.png]]
(Maintenant que j'y pense, ils sont où? Je pensais qu'ils seraient dans le coin.)
>!Qui?
>	![[proNonchalant.png]]
>	(Mes camarades de la garde.)
>	(Pas qu'ils aient quoi que ce soit de spécial, remarque.)
>	(Tous les hommes doivent suivre un entraînement au combat à partir d'environ onze ans.)
>	![[proHidingSomething.png]]
>	(Sauf si t'es bien vu du maire.)

`x`

## architectsHouse
### architectBookshelves
![[pro.png]]
(Hm. Même sans tous les livres d'architecture, c'est une collection impressionnante.)
>!Comme si *tu* t'y connaissais.
>	`playerTeasedProAboutBooks``proAff-=0.5`
>	![[proCynical.png]]
>	(Ha ha.)

`x`

### architectKitchen
![[proNonchalant.png]]
(... C'est une cuisine. Rien de particulier à rajouter.)
>!Pourquoi vous avez pas d'éviers?
>	![[proSkeptical.png]]
>	(Évier...?)
>	>Pour l'eau.
>	>	![[proNonchalant.png]]
>	>	(Ah, un truc d'eau, je vois. On n'a pas besoin de manger et boire tout le temps.)
>	>	>Ta mère a pas un potager?
>	>	>	![[pro.png]]
>	>	>	(Enfin, ça aide quand même de manger quand on est blessé ou fatigué.)
>	>	>Compris.
>	>Laisse tomber.

`x`

### architectUpstairsDoor
![[pro.png]]
(Cette porte mène à l'étage.)
![[proHidingSomething.png]]
(J'ai pas vraiment eu de raison d'y monter dernièrement.)
![[proNonchalant.png]]
(Et j'en ai toujours pas.)
`x`

## mayorsHouse
### apiDoor
![[pro.png]]
(...)
(...si je tends l'oreille, je l'entends tapoter quelque chose de manière intempestive.)
`x`

### mediDoor
![[pro.png]]
(Ça doit être la chambre de Medi.)
(C'est marrant de penser que lui et sa sœur dorment sous cette terrasse derrière la maison.)
![[proRollingEyes.png]]
(Je me demande s'ils entendent les gens piétiner au-dessus.)
`x`
### mayorsRoomDoor
![[pro.png]]
(...)
[Hedera]
`camPan,hedera`
Ah... est-ce que le Mécène s'intéresse... à la chambre de mon mari et moi?
![[proFacade.png]]
`camReset`
Non, j'admirais juste... les plans d'aménagement.
![[proCynical.png]]
(S'il te plaît, donnons pas au maire des raisons de plus de me casser les pieds.)
[Hedera]
`camPan, hedera`
Je vois! Oui, nous sommes très fiers de nos méthodes de construction uniques.
`camReset`
`x`

### mayorsHomeBookshelves
![[pro.png]]
(Hm... j'ai jamais vraiment regardé cette étagère de près.)
(Plein de livres sur le commerce, le gouvernement, le leadership...)
![[proCynical.png]]
(...l'éducation des enfants...)
`x`

### mayorsKitchen
`if seen`
	`x`

![[proRollingEyes.png]]
(Une cuisine étonnamment modeste.)
![[proCynical.png]]
(Ils doivent être trop occupés pour manger régulièrement.)
`x`

## mayorsOffice
### mayorsOfficeChair
![[proHidingSomething.png]]
(Je déteste cette chaise.)
>!Pourquoi?
>	`playerClueless+=1``proAff-=0.5`
>	(Ça devrait être évident.)

`x`

### mayorsBookshelf
![[pro.png]]
(Que des vieux registres et des trucs du genre par ici.)
![[dendro.png]]
Ah, je vous demanderais de faire attention en examinant ces archives.
C'est un peu en désordre, mais c'est de la documentation importante.
![[proCynical.png]]
T'inquiète, je touche à rien.
>!Qu'est-ce qu'il y a dedans?
>	![[proAnnoyed.png]]
>	(...)
>	![[proCynical.png]]
>	Qu'est-ce qu'il y a là-dedans?
>	![[dendro.png]]
>	Oh, divers inventaires, procès-verbaux, registres électoraux, courriers...
>	Tout ce qui concerne les opérations du village.
>	![[proNonchalant.png]]
>	Palpitant...

`x`

### mayorsAssistantDesk
![[proNonchalant.png]]
(Le petit pupitre d'assistant de Phyllo.)
(... C'est quoi, ça?)
![[proMildlyConflicted.png]]
(...)
![[proSmirk.png]]
Haha. C'est pour ton petit discours, ce brouillon?
![[dendroSurprised.png]]
Ah, ça...
![[proSmirk.png]]
« Ô Observateur, nous vous implorons! »
![[dendroStern.png]]
...
![[proMildSurprise.png]]
« S'il vous pwaît, s'il vous pwaît, sauvez-nous! »
![[dendroAngry.png]]
Pro...
![[proJovial.png]]
D'accord, d'accord.
`x`

## artisansHouse
### artisansBackDoor
![[pro.png]]
(Faut passer par un patio pour monter à l'étage.)
(Ça doit être malcommode à la longue, mais c'est pas comme si le village devait composer avec le mauvais temps.)
`x`

### floraScribbles
![[proHaughty.png]]
(Hm...)
`if collectedPaper`
	(La composition est bonne, mais il faudrait revoir l'agencement des couleurs.)
	>!Oh! Prends un crayon!
	>	![[proSkeptical.png]]
	>	(Hein? Pour quoi faire?)
	>	>Pour prendre des notes!
	>	>	![[proCynical.png]]
	>	>	(Je vais pas prendre des notes en *crayon de couleur*.)
	>	>	![[proBemused.png]]
	>	>	(Ni voler à une gamine, d'ailleurs.)
	>	>Laisse tomber.
`else`
	(La composition est bonne, mais il faudrait revoir l'agencement des couleurs.)

`x`
# trainingDummy
`if beatUpTrainingDummy`
	![[pro.png]]
	(Attendons que quelqu'un le répare avant de s'y remettre.)
	`x`

`c, proWalksToTrainingDummy`
![[pro.png]]
(...)
>Tu veux le frapper?
>	(T'es censé me donner des pouvoirs spéciaux, non?)
>	>Bien sûr.
>	>	![[pro.png]]
>	>	(Mm...)
>	>	(Fais voir, alors.)
>	>Moi!?
>	>	![[proCynical.png]]
>	>	(...)
>	>	(Bon, on devrait vérifier alors.)
>	`c,trainingDummyFightStart`
>	`x`
>...
>	![[proMildlyConflicted.png]]
>	(Non, pas le temps.)

`x`

## trainingDummyEnd
![[pro.png]]
(Ok, ok, ça suffit.)`beatUpTrainingDummy`

`c,combatEnd`

![[proCynical.png]]
(Me faire engueuler encore pour avoir cassé ce truc, c'est la dernière chose dont j'ai besoin.)
![[proConflicted.png]]
(...)
(C'était pas si différent de d'habitude.)
![[proNonchalant.png]]
(Tant pis. Allons-y.)
`camReset`
`x`
# fixture
`c,cameraPanToFixture`
![[pro.png]]
(La sortie est juste là, à gauche puis sur ce pont.)

## fixtureChoice
>C'est quoi la grosse vis? [[#fixtureA]]
>Qu'est-ce qu'il y a derrière la grande porte? [[#fixtureB]]
>Allons-y.

`x`

## fixtureA
(C'est la Fixation du village.)

>!Fixation?
>	![[pro.png]]
>	(Ça tient les monstres à distance. Entre autres.)
>	(C'est à cause d'elle qu'on a dû se replier jusqu'ici, dans les branches.)
>	>!Pourquoi vous l'avez mise là?
>	>	![[proSkeptical.png]]
>	>	(Mise?)
>	>	![[pro.png]]
>	>	 (Oh. Vous devez savoir les fabriquer, mais pas nous. Elles ont toujours fait partie du monde pour nous.)
>	>	>!Une *fixation* du paysage?
>	>	>	![[proCynical.png]]
>	>	>	(... Oui. C'est pour ça qu'on les appelle comme ça.)

[[#fixtureChoice]]

## fixtureB
(Des vieux.)
>!... Mais encore?
>	(On loge les personnes âgées là-dedans.)
>	(C'est bien plus sûr à l'intérieur, près de la vis.)

[[#fixtureChoice]]



# edif
`if seen`
	![[proCynical.png]]
	(On dirait qu'il faut faire demi-tour.)
	`walkBack,left`
	`x`
[Edif]
Ah, Pro! T'as fini le rituel!
Comment tu te sens? T'avais besoin de prendre l'air?

![[pro.png]]
Salut Edif. Je me sens, euh, bien. En train de remettre plein de choses en question.
Je fais visiter à mon Mécène.
![[proCynical.png]]
(Apparemment.)
>!Hé! Comment on aurait fait pour parler à tout le monde sinon?
>	(Je les vois tous les jours. Ils s'en remettront.)
>	>!Mais *moi* je les ai jamais rencontrés!
>	>	![[proAnnoyed.png]]
>	>	(Crois-moi, tu t'en remettras.)
>	(Bref,)

![[pro.png]]
On a fait un petit détour, mais ils se disent maintenant prêts à prendre la bonne route.
Alors si je pouvais juste me faufiler...?

[Edif]
Oh, désolé mais le chemin est impraticable .
Une sacrée branche est tombée et a arraché un bon morceau du pont.
Faudra faire le tour, j'ai bien peur.

![[proCynical.png]]
Ah.
(Je me demandais pourquoi il était planté là.)

[Edif]
Oh, t'inquiète pas, Hinoki l'aura réparé en un rien de temps.
Tu m'aides à monter la garde?

![[proCynical.png]]
J'adorerais, mais tu sais, avec la visite et tout je dois m'occuper de plein de trucs.

[Edif]
Oh, oui oui, faudrait pas faire attendre le Mécène, hein?

![[proCynical.png]]
En effet.

[Edif]
Bon, bonne chance!
Et passe nous voir, je suis sûr que Flora voudra tout entendre.

![[pro.png]]
D'accord...
`walkBack,left`
`spokeToEdif`
`x`

# sprinklerCutscene

`c, sprinklerCutsceneStart`

[Trabe]
J'ouvre la valve maintenant!

`c, sprinklerActivation`

[Trabe]
Tout s'est bien passé?

[Hinoki]
`camPan, hinoki, false`
`face,hinoki,left`
Oui. Le chemin est dégagé et j'ai réussi à colmater la brèche.
Il faudra aller paver correctement et réparer la rambarde, mais le pont est praticable pour l'instant.

[Trabe]
`camPan, trabe, false`
Fantastique, ma chérie! Tu as fait un travail merveilleux.

[Hinoki]
`camPan, hinoki, false`
`face,hinoki,right`
Ne me traite pas avec condescendance.

[Trabe]
`camPan, trabe, false`
Ah...
Je vois que tu es fatiguée. Va t'asseoir. L'Ancien Arb et moi, on s'occupe de ranger l'<span style="color:rgb(225, 188, 105)">Asperseur</span>.

[Hinoki]
`camPan, hinoki, false`
`face,hinoki,right`
Oui. Par contre, tu devrais aller prévenir Edif qu'on a fini.`a,0.8`

`c,trabeRunsOff,false`Ah, oui.`a,1.5`

`a,-1`

![[pro.png]]
(La sortie est juste là, à ma gauche puis sur le pont qui va en bas.)

>C'était quoi tout ça?
>	![[pro.png]]
>	(Juste des travaux, apparemment.)
>	(C'est l'architecte du village et son mari, ils gèrent ce genre de trucs.)
>Allons-y.

`sprinklerCutsceneDone`
`x`

# proRoom

## proCloset
`if !introDone`
	![[pro.png]]
	(...)
	![[proMildlyConflicted.png]]
	(Pourquoi je regarde le placard encore? J'ai rien oublié.)
	`x`
### proClosetPostIntro
`if seen`
	`x`
![[proNonchalant.png]]
(C'est là que je range mes fringues.)

>Mets tes vêtements décontractés.
>Mets tes vêtements d'hiver.
>Mets tes vêtements chics.
>Cool.
>	(Ouaip.)
>	`x`

![[proMildSurprise.png]]
(Quoi? Je vais pas me changer, tu `speed,0.5`*regardes*.)

`x`
## proDesk
`if !introDone`
	![[pro.png]]
	(Je me demande si ce bureau me manquera.)
	(...)
	![[proMocking.png]]
	(C'est peu probable.)
	`x`
### proDeskPostIntro
`if seen`
	`x`

![[pro.png]]
`if prosRoomMentioned`
	(C'est mon bureau. Pas grand-chose à rajouter.)
	>C'était quoi que tu devais récupérer?
	>	![[proSkeptical.png]]
	>	(Hein?)
	>	>T'as dit que tu devais récupérer quelque chose dans ta chambre.
	>	>	`proAff+=0.5`
	>	>	![[proMildSurprise.png]]
	>	>	(O-oh, c'est vrai, euh...)
	>	>	(Voyons voir...)
	>	>	![[proConflicted.png]]
	>	>	(...)
	>	>	![[proFacade.png]]
	>	>	(Voilà! Une feuille de papier.)
	>	>	(Pour prendre des notes! Très utile.)
	>	>	`itemCollect, paper`
	>	>	![[pro.png]]
	>	>	(Bon, allons-y maintenant.)`collectedPaper`
	>	>	>!T'as de quoi écrire?
	>	>	>	![[proCynical.png]]
	>	>	>	(Tu penses vraiment à tout...)
	>	>	>	![[proConflicted.png]]
	>	>	>	(...)
	>	>	>	![[proNonchalant.png]]
	>	>	>	(Non. Plus de crayons. Tant pis.)
	>	>	>	(On trouvera bien une solution.)
	>	>Laisse tomber.
	>...
`else`
	(C'est mon bureau. Pas grand-chose à rajouter.)
	(Il y a rien d'utile dans les tiroirs, au cas où tu te poserais la question.)

`x`
## proSwordHolder
`if !introDone`
	`if seen`
		`x`
	![[proConflicted.png]]
	(Je devrais vraiment prendre l'épée avec moi en partant...?)
	![[proConflicted.png]]
	(...)
	![[proDetermined.png]]
	(Oui. Je sors d'ici *aujourd'hui*.)
	`x`
### proSwordHolderPostIntro
`if seen`
	`x`
![[pro.png]]
(J'aime garder mon épée à portée de main.)
(Pour la défense du foyer.)

>!Contre quoi?
>	![[proHidingSomething.png]]
>	(... Des oiseaux, quoi.)
>	>!Tu tues les oiseaux qui rentrent ici?
>	>	![[proEmbarrassed.png]]
>	>	(Ben, un oiseau, une fois.)
>	>	(Et je l'ai pas *tué*, j'ai juste... tapé dessus jusqu'à ce qu'inertie s'ensuive.)
>	>	(...)
>	>	![[proAnnoyed.png]]
>	>	(Écoute, j'allais pas laisser filer l'occasion de m'entraîner sur une vrai cible, quand même.)
>	>	(De toute façon, c'est sa faute d'avoir empiété sur mon territoire.)

`x`
## proBed
`if !introDone`
	![[proBemused.png]]
	(Je devrais vraiment pas...)
	`x`
### proBedPostIntro
`if seen`
	`x`

![[pro.png]]
(Comme on dit.)
(Plein de sommeil, pas besoin de manger.)

>Ça marche pas du tout comme ça.
>	![[proMildSurprise.png]]
>	(Oh, c'est vrai, vous devez faire les deux.)
>	![[proBemused.png]]
>	(Ça doit être pénible.)
>Ça se tient.

`x`

# hinoki
`if interactCount>1`
	[[#hinokiInteract]]

[Hinoki]
Oh, bonjour Pro. Ton rituel s'est bien passé?

![[pro.png]]
Oui, Mme Kitamura.

[Hinoki]
... Tu n'as pas l'air si différent.

![[proCynical.png]]
Mon petit doigt me dit que j'ai pas fini de l'entendre.

[Hinoki]
Oui. Enfin, j'ai aucun doute que ça fera aussi une énorme différence pour certains.

![[pro.png]]
Ça vous rend pas heureuse que le confinement soit levé?

[Hinoki]
Mm. Qu'est-ce que ça change pour moi?
Avec tous ces monstres dehors, ça revient à la même chose.
Mes jours de pèlerinages dangereux sont loin derrière moi, c'est certain.
Tout de même, ce sera agréable de prévenir mes sœurs de ce qui se passe. Elles se sont toujours tellement inquiétées dans leurs lettres.

![[pro.png]]
Mm.

>J'ai des questions!
>	![[proAnnoyed.png]]
>	(...)
>	(Bon, faisons vite.)
>	[[#hinokiInteract]]
>Avançons.
>	![[pro.png]]
>	(Ok.)

`x`

## hinokiQuestionsStart
![[proCynical.png]]
Euh...
Le Mécène veut vous poser des questions.

[Hinoki]
Oh. Je... vois.
...
Eh bien, allez-y.
[[#hinokiQuestions]]

## hinokiInteract
`if !seen`
	[[#hinokiQuestionsStart]]
[Hinoki]
Oui?
## hinokiQuestions

>Comment fonctionne l'Asperseur?[[#hinokiSprinklerStart]]`if sprinklerMentioned && !sprinklerExplained`
>Que faisait-elle il y a un instant?[[#hinokiWork]]`if !sprinklerMentioned`
>Ses sœurs?[[#hinokiSisters]]
>Demande-lui à propos de sa ville natale.[[#hinokiHometown]]`if hinokiHometownMentioned`
>Allons-y.
>	![[pro.png]]
>	Plus de questions. Au revoir, Mme Kitamura.
>	[Hinoki]
>	Au revoir, Pro.
>	`x`

## hinokiWork
![[pro.png]]
Vous travailliez sur quoi, il y a un instant?

[Hinoki]
Ah, une branche est tombée en emportant un morceau du pont qui mène vers la bibliothèque.
Je procédais au déblaiement initial et aux premières réparations.`sprinklerMentioned`

>Avec un tuyau?`if !sprinklerExplained`
>	![[proSkeptical.png]]
>	(Tu sais pas...?)
>	![[proNonchalant.png]]
>	(Non, je vois pourquoi tu saurais pas.)
>	Je crois que le Mécène ne sait pas comment l'Asperseur fonctionne.
>	[[#hinokiSprinkler]]
>Je vois.
>	![[proNonchalant.png]]
>	Je vois.
>	[Hinoki]
>	Bien. Le Mécène avait-il d'autres questions?
>	[[#hinokiQuestions]]

## hinokiSprinklerStart
![[pro.png]]
Le Mécène veut savoir comment l'Asperseur fonctionne.
## hinokiSprinkler
[Hinoki]
Je vois.
Permettez-moi de reprendre depuis le début.
Notre beau village a la chance de posséder un <span style="color:rgb(225, 188, 105)">Modeleur</span> indispensable à sa édification.
`camPan,hoseFocus`
Il suffit de faire passer un courant d'Air assez puissant à travers ce tuyau pour qu'une essence miraculeuse en jaillisse.
`camReset`
À vrai dire, n'importe quel tuyau ou contenant ferait l'affaire, et la partie du dispositif qui compte réellement n'est qu'un embout spécial, en fait.
Bref...
Notre Grand Arbre, au contact de cette substance, subit une croissance soudaine et fulgurante.
Si fulgurante, en fait, que contrairement aux autres Modeleurs,
l'Asperseur est somme tout plutôt inutile pour la construction détaillée.
Mais il répond tout de même aux commandes de l'utilisateur.
Si on lui des instructions claires, il fonctionne assez bien pour la démolition et pour poser des fondations.
Il est certain que les ancêtres de Pro n'auraient jamais pu construire un tel village sans lui.
Oh, ce que je donnerais pour voir la capitale stromale dans toute sa splendeur de naguère... l'arbre entier, dans toute son enveloppe alvéolée...
![[proNonchalant.png]]
Vous rendez ça un peu effrayant.
[Hinoki]
Les ruches sont magnifiques, jeune homme. À la fois structurées et organiques.
Enfin, bref. Je divague. Le Mécène avait-il d'autres questions?`sprinklerExplained`
[[#hinokiQuestions]]

## hinokiSisters
![[pro.png]]
Ils veulent en savoir plus sur vos sœurs.
[Hinoki]
Qu'est-ce qu'ils veulent savoir?
![[proCynical.png]]
C'est pas clair.
[Hinoki]
Mm. J'imagine que c'est assez inhabituel que j'aie de la famille en dehors du village.
Oui, j'ai de la famille à <span style="color:rgb(225, 188, 105)">Kiba</span>. On s'écrit des lettres.
J'y met rien de trop intime. Je ne voulais simplement pas perdre tout contact.
Après, il faut dire que ce bureaucrate guindé qui tient à lire toutes les lettres avant qu'elles soient envoyées y est aussi pour quelque chose.
![[proSmirk.png]]
Heh.
[Hinoki]
Je ne devrais pas me plaindre. On a tous accepté ce confinement après tout.
![[proCynical.png]]
« Tous »?
[Hinoki]
Encore à râler, hein? C'est le comble de te voir te plaindre, toi de tous les gens, alors que c'était pour *ta* sécurité.
![[proAnnoyed.png]]
Oui, oui.
[Hinoki]
À vrai dire, c'était à peine un désagrément.
Ça ne devrait surprendre personne que je n'ai guère envie de retrouver ma ville natale.`hinokiHometownMentioned`
...[[#hinokiQuestions]]

## hinokiHometown
![[proFacade.png]]
(T'essaies de me faire passer pour mal élevé parce que j'ai jamais demandé?)
![[proAnnoyed.png]]
(Hmph...)
![[proNonchalant.png]]
Le Mécène aimerait en savoir plus sur votre ville natale.

[Hinoki]
Kiba? Voyons voir...
Un endroit terriblement étouffant. Chaque jour un nouveau « combat ».
Leur Modeleur leur permet d'entretenir une imposante muraille et eux,
en retour, labourent les vastes étendues de leurs terres.
Qu'ils tirent tous une fierté *incommensurable* à défendre, d'ailleurs.
Franchement, ils auraient bien moins d'ennuis s'ils savaient quand lâcher prise, mais « chaque centimètre est une insulte ». Quelles sottises belliqueuses.
Ce n'était certainement pas un endroit adéquat pour élever un enfant, alors nous voilà.
Ceci dit, j'avoue que la terre ferme me manque parfois.

![[pro.png]]
Vous auriez pas pu aller à Tongue?

[Hinoki]
Voyons, ce terrier infect? Aucune chance, je ne me lasse pas de voir le soleil briller de temps à
 autre.
Alors, d'autres questions?
[[#hinokiQuestions]]

# returnedHome

![[salvia.png]]
!

`c,momWalksToGreetPro`

![[salvia.png]]
Tu es rentré.
![[salviaConcern.png]]
Tu te sens bien? ...toi-même?

![[pro.png]]
Ouais. Ça va. Bien. Le Mécène me parle.
>!Salut!
>	Il dit salut.

![[salviaSmiling.png]]
J-je vois. C'est merveilleux. Je suis contente que tout se soit bien passé.

![[pro.png]]
Ouais.

![[salviaSmiling.png]]
Tu vas partir pour de bon maintenant, alors?

![[proMildSurprise.png]]
O-oui.
![[proHidingSomething.png]]
Ils ont hâte d'y aller.

![[salviaSmiling2.png]]
Ah oui?
Eh bien, il ne faudrait pas faire attendre notre grand Mécène.
Dis-leur que je vous souhaite bonne chance à tous les deux.
Et que tu peux toujours revenir à la maison.

![[proAnnoyed.png]]
Ouais...

![[salviaSerious.png]]
Et rappelle-lui de te faire manger! Et de modérer ton imprudence!

>Ça marche!
>	`proAff+=1`
>	![[proAnnoyed.png]]
>	(Vous me donnez tous envie de disparaître sous terre...)
>	![[pro.png]]
>	Ils disent qu'ils le feront, maman.
>	![[salviaSmiling2.png]]
>	Oh là là!
>	Merci.
>Bon. On peut y aller maintenant?
>	`playerClueless+=1``proAff-=2`
>	![[proHidingSomething.png]]
>	Ils... disent qu'ils le feront.
>	![[salviaSmiling2.png]]
>	Oh là là!
>	Merci.
>Elle le prend plutôt bien, toutes choses considérées.
>	`proAff+=0.5`
>	![[proHidingSomething.png]]
>	(...)
>	(Je sais qu'on précipite un peu les choses...)
>	(Mais tout le monde s'attend à ce que je parte *un jour*.)
>	(Et elle sait qu'elle est la seule personne que je...)
>	![[proAnnoyed.png]]
>	(Aah, laisse tomber. On doit y aller. Je déteste parler de ça.)
>	![[proCynical.png]]
>	Ils- ils disent qu'ils le feront, maman. Me garder au pas et tout.
>	![[salviaSmiling2.png]]
>	Oh là là!
>	Merci.
>...
>	`proAff+=0.5`
>	![[proAnnoyed.png]]
>	Maman.
>	![[salviaSmiling2.png]]
>	Bon, bon.

![[salvia.png]]
...
![[salviaSmiling.png]]
Eh bien, je serai dans la cuisine si tu as encore besoin de moi.

`c, salviaWalksToKitchen`

`spokeToMom`
`x`


# salviaInteract
![[proHidingSomething.png]]
(Laissons-lui un peu d'espace...)

`x`


# oiko
`if seen`
	![[proCynical.png]]
	(Elle est clairement pas d'humeur à me parler.)
	`x`

![[pro.png]]
Hé, Oiko.

[Oiko]
Hein?
`face, oiko, down`
Oh. Je suis un peu occupée là. C'est quoi?

![[pro.png]]
Ça t'intéresse pas d'entendre parler de, tu sais...

[Oiko]
Quoi, t'es venu frimer? J'en ai rien à cirer.
Tu peux enfin faire ton boulot, alors va le faire.

![[proConflicted.png]]
Je... ok, ouais, c'est déjà dans les plans.

[Oiko]
Merci.
`face, oiko, up`
`p,1`
`face,pro,down`
![[proHidingSomething.png]]
(...)
>!C'est quoi son problème?
>	![[proCynical.png]]
>	(Les filles sont comme ça, c'est tout.)
>	(Il y a quelque temps, elles se sont mis en tête de pas me laisser prendre la grosse tête, ou une truc dans le genre.)
>	>Ça me plaît pas du tout!
>	>	`proAff+=0.5`
>	>	![[proSmirk.png]]
>	>	(Heh. Merci. Mais je crois pas que ce serait dans notre intérêt de leur en parler.)
>	>	![[proNonchalant.png]]
>	>	(Je peux même pas dire que je leur en veux tant que ça...)
>	>Ça se comprend.
>	>	`playerSidedWithGirls``proAff-=0.5`
>	>	![[proCynical.png]]
>	>	(Ah bon?)
>	>	(...)
>	>	![[proHidingSomething.png]]
>	>	(... Bon, je peux pas dire que je leur en veux *tant* que ça...)
>	>Je vois.
>	>	![[proHidingSomething.png]]
>	>	(Je peux pas dire que je leur en veux *tant* que ça...)
>	![[proCynical.png]]
>	(Mais ça les tuerait de me lâcher un peu la grappe à ce stade?)
>	(Enfin, on dit *tous* des âneries quand on est gosse, non?)

`spokeToOiko`
`x`
# erg
`if seen`
	[Erg]
	Hé!
	[[#ergInteract]]

[Erg]
Hé! Tiens, qui voilà qui fait le tour.
Grand jour aujourd'hui. Comment tu gères?

![[pro.png]]
Bien. Plus ou moins. Ça s'est avéré, euh, plus réel que ce à quoi je m'attendais.

[Erg]
Oh?

![[pro.png]]
Ouais, il y a définitivement *quelque chose* qui écoute.
(C'est mon grand-père, au passage.)

[Erg]
Ooh! Eh ben, j'en tombe presque des nues!

![[proLaughing.png]]
Ha ha!
![[proSmirk.png]]
Ouais, qui aurait pu le voir venir?

[Erg]
T'as dit quoi au maire?

![[proSmile.png]]
Oh, pas grand-chose. Je crois que ça comptait pas vraiment, il était tellement... prêt à tout gober.

[Erg]
Ha! Ça a dû lui changer un peu! J'aurais adoré voir ça.
Mais toi alors, t'as la voix du Mécène en toi maintenant? Ça fait quoi?

![[proMildlyConflicted.png]]
Je m'habitue encore. Les gens avaient raison, je me sens pas si différent que ça.
![[proHidingSomething.png]]
Je... sais pas si je me serais rué jusqu'ici par moi-même, par contre.

[Erg]
T'avais pas envie de voir le vieux de ton vieux?

![[proSmirk.png]]
Inquiet pour moi?

[Erg]
Bien sûr que oui.
Et ta mère aura jamais fini de s'en faire, surtout si tu files comme ça.

`if spokeToMom`
	![[pro.png]]
	T'inquiète, on s'est parlé.
	[Erg]
	Ah. Bien, bien.
`else`
	![[proHidingSomething.png]]
	Ouais. Je lui parlerai.
	[Erg]
	C'est bien, mon garçon.

Et tu peux me parler à moi aussi. Quand tu veux.

![[pro.png]]
Mm.

## ergInteract
[Erg]
Tu voulais dire quelque chose?
## ergQuestions

>C'est quoi ce bâtiment?[[#ergWorkshopExplainer]]
>Allons-y.
>	![[pro.png]]
>	Faut que j'y aille.
>	[Erg]
>	D'accord.
>	`if !swordReminded`
>		Dis à ton nouvel ami que vous pouvez toujours faire un tour ici si vous avez besoin de forge.
>		`swordReminded`

`x`
## ergWorkshopExplainer

![[proNonchalant.png]]
Le Mécène veut en savoir plus sur ton travail.

[Erg]
Ah, très sensé.
On fabrique tous les outils du village ici même, dans cet atelier. Épées, râteaux, lampes, et tout le reste.
>!On?
>	![[pro.png]]
>	(Oiko l'aide.)
>	(C'est la fille des architectes.)
>	[Erg]
>	Tu me suis toujours?
>	![[proNonchalant.png]]
>	Hm? Oh, ouais.

[Erg]
Les bons matériaux sont durs à trouver ici en haut, alors on finit par devoir faire travailler notre imagination. Dur à faire livrer aussi.
Mais y'a plein de bon bois.

![[proSmirk.png]]
T'es plutôt doué pour travailler le bois en bonnes grandes grilles avec la bonne bacaisse des grands bois verts.

[Erg]
Tu l'as dit.

[[#ergQuestions]]

# Xylo
![[proNonchalant.png]]
(C'est le père de Phyllo.)
(On dirait qu'il arrive pas à décider dans quel ordre ranger ces livres.)

`x`

# Libra
`if spokeToLibra`
	`x`

![[pro.png]]
Salut Libra.

[Libra]
Hm?
`face,libra,left`
Oh! Pro!
Ça fait plaisir de te voir ici! Tu dois être en train de faire visiter!
Dis-moi, dis-moi, ça fait quoi?

![[proCynical.png]]
Euh. Rien de spécial, en fait. Pas tellement différent de la normale.

[Libra]
Mm? Tu dois bien ressentir le Mécène d'une façon ou d'une *autre*?

![[proCynical.png]]
Ouais. Je les entends parler.

[Libra]
Ouaah! Communion directe, fascinant!
Ils te donnent des ordres?

![[proRollingEyes.png]]
En quelque sorte, oui.
>!Même pas!
>	![[proSmirk.png]]
>	(Ouais, parce que tu peux juste *espérer* me les faire faire.)

[Libra]
Alors c'est un peu donnant-donnant, hein?
Ça me rappelle un livre que j'ai lu autrefois!

![[proCynical.png]]
(Quelle surprise.)

[Libra]
Il racontait l'histoire de deux êtres sensibles, soit un homme greffé à un ver.
Partageant le même corps, aucun des deux n'arrivait à totalement contrôler l'autre,
et ils étaient forcés de coopérer pour poursuivre leurs objectifs communs.
D'un certain point de vue, c'est une situation assez romantique.

![[proSkeptical.png]]
Euh-hein...
... Tu viens de traiter le Mécène de ver?

[Libra]
Haha! Bonne question!

`p,2`

Tu voulais emprunter un livre?

![[proCynical.png]]
Euh, on fait juste un tour pour l'instant.

[Libra]
Aha! « On »! Bien sûr!
Attention quand même, certains pourraient se faire de fausses idées si tu parles de toi comme ça.

![[proAnnoyed.png]]
O-oui.

>!Quelles fausses idées?
>	![[proCynical.png]]
>	(Euh... tu sais, je suis pas de la royauté.)
>	(Même si je vois comment tu aurais pu avoir cette impression.)

`spokeToLibra`
`x`

# phyllo
`if spokeToPhyllo`
	[[#phylloInteract]]

![[phyllo.png]]
`spokeToPhyllo`
Salut, Pro.

![[pro.png]]
Salut salut.

![[phyllo.png]]
Je suis surpris de te voir ici. Vu le temps qu'il a fallu au maire et moi pour ranger, je pensais que tu serais parti depuis longtemps.

![[proSkeptical.png]]
Tu me prends pour qui?
![[phyllo.png]]
...
![[pro.png]]
...
![[proCynical.png]]
Ok, en fait le Mécène veut la grande visite, ou quelque chose comme ça.
Ils m'ont juste fait courir partout.
![[phylloSurprised.png]]
Oh! Je vois.
Eh bien, s'ils ont des questions sur la bibliothèque, c'est pour ça que je suis là.
![[pro.png]]
(T'en as?)
>Ouais.
>	![[proCynical.png]]
>	(Bon, on est là. Autant en finir.)
>	[[#phylloQuestions]]
>Non.
>	![[pro.png]]
>	On n'a pas de questions pour l'instant.
>	![[phyllo.png]]
>	D'accord. Je suis là si vous avez besoin.
>	`x`

## phylloInteract
![[phyllo.png]]
Des questions?
## phylloQuestions
>C'est quoi la sélection?[[#phylloSelection]]
>C'est quoi cette machine avec les tubes?[[#phylloComputer]]
>C'est quoi le « Répertoire Originel »?[[#phylloRepository]]`if repositoryMentioned`
>Où est la dame qui était là tout à l'heure?[[#phylloAskAboutLibra]]`if spokeToLibra`
>Plus de questions.
>	![[pro.png]]
>	Plus de questions.
>	![[phyllo.png]]
>	D'accord. N'hésitez pas à regarder autour de vous.
>	`x`

## phylloSelection
![[pro.png]]
On a quoi comme livres?
![[phyllo.png]]
Eh bien, comme bon nombre de bibliothèques de nos jours,
c'est surtout des trucs que les gens ont jugé bon de sauver pendant l'<span style="color:rgb(225, 188, 105)">Effondrement</span>.
Donc surtout du non-romanesque, avec plein de livres de référence simples et pratiques. On garde les plus précieux au fond.
![[phylloConcerned.png]]
C'est dommage qu'on n'ait qu'un seul exemplaire du <span style="color:rgb(225, 188, 105)">Répertoire Originel</span> à exposer.`repositoryMentioned`
Les gens pensaient sûrement que les matériaux seraient faciles à trouver et ont donné la priorité à d'autres livres.
Mais de nos jours, c'est assez difficile de rassembler tout le nécessaire pour faire des copies.
![[phyllo.png]]
Sinon, côté fiction, on n'a vraiment qu'une seule étagère.
C'est pas une super sélection, j'admets, mais Moriko a l'air de s'en contenter.
Les étagères restantes sont organisées selon-`a,0.3`
`a`![[proCynical.png]]
Bon, bon.
Je crois qu'on a compris.
![[phylloSurprised.png]]
Ah, oui. Tu peux toujours consulter le dépliant-guide.
D'autres questions?
[[#phylloQuestions]]

## phylloComputer
![[pro.png]]
Ils veulent en savoir plus sur l'ordinateur.
![[phylloSurprised.png]]
Ah! J'ai lu des trucs là-dessus.
Apparemment les ordinateurs des êtres supérieurs exploitent une force mystérieuse qui n'existe qu'à leur niveau de réalité.
![[phylloConcerned.png]]
`face,phyllo,up`
Pendant ce temps, nos ordinateurs ne peuvent fonctionner qu'à l'<span style="color:rgb(225, 188, 105)">Air</span>, alors ils risquent de trouver les nôtres assez bizarres.
![[phyllo.png]]
Malgré cela, et même si celui-ci est un ancien modèle, son horloge tourne à plus de quatre cent kilohertz; très respectable.
Du moins, c'est suffisant pour les besoins de la bibliothèque.
![[phylloConcerned.png]]
`face,phyllo,left`
Bien que j'entende dire que les modèles les plus avancés de l'<span style="color:rgb(225, 188, 105)">Académie de Front</span> peuvent contenir autant de puissance dans quelque chose qui tient sur un bureau.
![[phylloSurprised.png]]
Et le Mécène a probablement accès à des ordinateurs des dizaines, peut-être des centaines de fois plus rapides.
![[phylloConcerned.png]]
C'est étrange quand même, le Répertoire Originel ne précise jamais de chiffres exacts en matière d'informatique.`repositoryMentioned`
![[proSkeptical.png]]
(Tu sais pourquoi?)
>Probablement pour pas que vous vous sentiez inadéquats.
>	![[proCynical.png]]
>	(Qu'est-ce que c'est censé...)
>	(Tu sais quoi, j'en ai rien à faire.)
>	[[#phylloComputerEnd]]
>Je ne le dirai jamais...
>Non.

![[proCynical.png]]
(Très bien. J'en ai vraiment rien à faire.)
#### phylloComputerEnd
![[phyllo.png]]
Bref, d'autres questions?
[[#phylloQuestions]]
## phylloRepository
![[proCynical.png]]
(S'il y a quelqu'un pour l'expliquer...)
![[pro.png]]
Tu peux expliquer le Répertoire au Mécène?
![[phyllo.png]]
Bien sûr! Laissez-moi réfléchir...
Le Répertoire Originel est une encyclopédie magique du monde du Mécène et des <span style="color:rgb(225, 188, 105)">Créateurs</span>.
On dit que c'est le premier <span style="color:rgb(225, 188, 105)">Modeleur</span>, un objet impossible à reproduire venu d'au-delà de ce monde, doté de pouvoirs magiques.
![[phylloConcerned.png]]
Cela dit, on débat encore pour déterminer si le Répertoire compte comme un « vrai » Modeleur.
Il ne semble pas vraiment avoir d'applications concrètes en construction, comme les autres.
Et dans son cas précis, il n'est pas *tout à fait* juste de dire qu'il est « impossible à reproduire ».
![[phyllo.png]]
On *peut* en faire des copies via un court rituel qui implique d'assembler les bons matériaux près d'une copie existante.
Curieusement, les copies faites ainsi ne gardent aucune usure, effacement, ni... modification.
On peut toujours produire la même version originale exacte du contenu.
Même en partant d'une copie dont, disons, la moitié des pages a été arrachée.
![[phylloSurprised.png]]
Ce qui devrait être impossible! L'information perdue est perdue après tout. Mais je suppose que c'est ça qui le rend magique.
Oh, et aussi le fait qu'il est vaaachement plus grand à l'intérieur qu'il n'y paraît.
![[phyllo.png]]
On pourrait probablement remplir plusieurs dizaines d'étagères si tout était imprimé en livres normaux.
![[phylloConcerned.png]]
Et même là, il y a clairement des choses qui manquent.
Alors même si on a passé des siècles à disséquer ces passages et à lire entre les lignes...
il y a encore énormément de choses du monde du Mécène qui nous échappent.
![[phylloSurprised.png]]
La complexité et le volume d'information sont indéniablement d'un ordre supérieur.
![[proRollingEyes.png]]
Oui, qu'ils soient loués. (Vous êtes tous très impressionnants.)
>!Merci!

![[phyllo.png]]
Bref, voilà le résumé. Vous pouvez aller lire l'exemplaire exposé sur le lutrin là-bas si vous voulez en savoir plus.
D'autres questions?
`repositoryExplained`
[[#phylloQuestions]]

## phylloAskAboutLibra
![[pro.png]]
(Sa mère?)
![[proRollingEyes.png]]
(Xylo non plus est pas là...)
![[pro.png]]
Où sont tes parents?
![[phyllo.png]]
Oh. Ils travaillent au fond, comme d'habitude.
![[proCynical.png]]
Ils sont sacrément souvent là-dedans.
![[phylloConcerned.png]]
Mm. Ouais. Et toujours pas de frères ou sœurs pour m'aider ici.
![[proBemused.png]]
Hein?
![[phylloSurprised.png]]
Euh, oublie ce que j'ai dit.
Le Mécène voulait savoir quoi d'autre?

[[#phylloQuestions]]
# moriko
`if interactCount>1`
	[[#morikoInteract]]

![[proNonchalant.png]]
Salut Moriko.

[Moriko]
Ah. Euh. Salut.
C'est le Mécène qui t'a dit de me parler?

![[proNonchalant.png]]
En gros.

[Moriko]
Oh ouah. C'est trop cool.
Je... qu'est-ce qu'ils voulaient dire?

## morikoResponse

>Tiens, une fille qui te déteste pas.[[#morikoHate]]`if spokeToOiko || spokeToHedera`
>J'ai quelque chose à demander.
>	![[pro.png]]
>	(Ouais?)
>	[[#morikoQuestions]]
>J'ai rien à dire.
>	![[pro.png]]
>	Oh. Rien, apparemment. Désolé.
>	[Moriko]
>	Oh! Non! J-je suis désolée, j'aurais pas dû présumer.
>	![[proNonchalant.png]]
>	C'est rien.
>	Je vais continuer à regarder autour.
>	[Moriko]
>	D'accord.
>	`x`

## morikoQuestions
>Demander à propos d'elle.[[#morikoAbout]]
>Demander son opinion de toi.[[#morikoOpinion]]
>Demander son opinion de moi.[[#morikoOpinionPatron]]
>Plus de questions.`if morikoAsked`
>	![[proNonchalant.png]]
>	Plus de questions.
>	[Moriko]
>	D-d'accord. Je vais retourner à ce que je faisais alors. Salut Pro.
>	![[proNonchalant.png]]
>	Salut.
>	`x`
## morikoHate
![[proAnnoyed.png]]
`playerClueless+=1``proAff-=0.5`
(Sois pas bizarre.)
[Moriko]
...?
[[#morikoResponse]]

## morikoAbout
![[pro.png]]
Ils veulent en savoir plus sur toi.
[Moriko]
Oh, bien sûr. Euh.
Je sais pas trop quoi dire.
Tu peux pas juste leur dire?
![[proCynical.png]]
Si, mais t'es juste là.
[Moriko]
O-oh, t'as raison. Pardon.
J-je m'appelle Moriko Kitamura. Je suis la plus jeune de trois enfants, et ma mère est l'architecte du village.
Euh... j'aime lire et dessiner?
![[proSkeptical.png]]
C'est une question?
[Moriko]
Ben, mes parents trouvent pas ça très utile. Genre, vraiment pas en fait.
Alors je sais pas trop. Ma mère me fournit du matériel, mais je crois qu'elle aimerait que mes dessins soient plus... techniques.
J'aime surtout dessiner les personnages que je lis dans les livres.

>!C'est un beau passe-temps.
>	`proAff+=0.5`
>	![[proSkeptical.png]]
>	(Tu le penses vraiment?)
>	![[proNonchalant.png]]
>	(Un peu d'encouragements, ça peut pas faire de mal.)
>	Le Mécène dit que c'est un beau passe-temps.
>	[Moriko]
>	Aha. M-merci.
>	Mais oui. Juste un passe-temps.
>C'est nul comme passe-temps.
>	`proAff+=0.5`
>	![[proAnnoyed.png]]
>	(Je vais pas dire ça.)
>	![[proCynical.png]]
>	(Mais je suis d'accord, c'est un peu bizarre.)

[Moriko]
...
Parfois j'ai l'impression que je devrais vouloir en faire plus, mais... je veux pas. Enfin, je veux dire.
C'est juste pour le plaisir. Mais c'est probablement du gaspillage si ça aide personne.
Je sais pas. C'est bête. J'aurais pas dû embêter votre Mécène avec ça. Pardon.
![[proNonchalant.png]]
`a,0.3`C'est-
`a`[Moriko]
Non, vraiment. C'est idiot.
Demande-moi autre chose.`morikoAsked`
[[#morikoQuestions]]

## morikoOpinion
![[proCynical.png]]
(Urgh.)
![[pro.png]]
Le Mécène veut savoir ce que tu penses de moi.
[Moriko]
Oh. Euh. Si je suis honnête...
![[proCynical.png]]
T'es pas obligée.
[Moriko]
N-non, non, je trouve que c'est super ce que tu fais, vraiment.
Enfin, je crois que tout le monde est du même avis, même si, genre,
ça met ma sœur hors d'elle-même que tu reçoives un traitement de faveur.
![[proRollingEyes.png]]
Tu m'étonnes.
[Moriko]
Mais mon frère dit toujours que t'as beaucoup sur les épaules.
![[proCynical.png]]
Ah bon?
[Moriko]
Ouais. Alors je crois que je comprends ce que tu vis.
Les gens disent que ton attitude est pas à la hauteur de ton rang ou je sais pas quoi,
mais je vois que t'y mets du tien.
Et moi, je pourrais jamais sortir et risquer ma vie comme tu vas le faire.
Alors j'apprécie vraiment, et tout.
![[pro.png]]
Oh. Eh bien, merci.
![[proHidingSomething.png]]
(Ce serait encore mieux si ça ne venait pas d'une enfant, mais il y a au moins *quelqu'un* de reconnaissant.)
[Moriko]
D-de rien.
`p,1`
Il y avait autre chose?
[[#morikoQuestions]]

## morikoOpinionPatron
![[pro.png]]
Le Mécène veut savoir ce que tu penses d'eux.
[Moriko]
Ah, d'accord. Je les connais pas très bien, mais je suis sûre qu'ils sont géniaux!
Et je suis vraiment contente qu'ils soient venus résoudre le problème des monstres et tout ça.
Je... je me suis aussi dit que ce serait amusant de toujours avoir quelqu'un à qui parler.
![[proSmirk.png]]
Vraiment?
[Moriko]
Oh, pas que je puisse pas... c'est juste, le village est si petit, tu vois?
![[proJovial.png]]
Tu m'étonnes.
[Moriko]
Haha, ouais.
...
[[#morikoQuestions]]

## morikoInteract
![[pro.png]]
(Elle arrête pas de me jeter des coups d'œil, mais on dirait qu'elle veut plus parler.)
`x`

# medi
`if interactCount>1`
	![[pro.png]]
	(Laissons-le tranquille.)
	`x`
[Medi]
Pro! Bonjour.
![[pro.png]]
Salut, Medi.
[Medi]
Tu as déjà fini le rituel? Je t'ai vu passer en courant tout à l'heure.
Père a dû être sacrement échauffé de te voir arriver si tard!
![[proRollingEyes.png]]
Ouais. Merci de me le rappeler.
[Medi]
Oh. Euh. Je ne voulais pas...
![[proNonchalant.png]]
C'est rien, je te taquine.
[Medi]
A-ah. Bien sûr.
Je suis soulagé de voir que le lien ne t'a pas trop affecté.
![[pro.png]]
Mm.
(D'ailleurs, pourquoi tu me fais parler à Medi?)

>Je fais juste le tour.
>	![[proCynical.png]]
>	(Alors est-ce qu'on *doit* se lancer dans une longue conversation?)
>	>Qu'est-ce qui va pas avec Medi?
>	>	[[#mediWhatsWrong]]
>	>Non, on peut y aller.
>	>	[[#mediLeave]]
>Qu'est-ce qui va pas avec le fait de parler à Medi?
>	[[#mediWhatsWrong]]
>Aucune raison, on peut y aller.
>	[[#mediLeave]]

## mediWhatsWrong
![[proHidingSomething.png]]
(Hrm. J'ai pas de problème avec *lui* à proprement parler.)
![[proCynical.png]]
(Mais tout ce que je lui dis a une fâcheuse tendance à remonter jusqu'à son père.)
>Je veux juste lui poser des questions.
>	![[proAnnoyed.png]]
>	(Bon, faisons vite.)
>	![[pro.png]]
>	Le Mécène veut te poser des questions.
>	[Medi]
>	Ouah! Tu es déjà aussi acclimaté à eux?
>	Bien sûr, demandez ce que vous voulez.
>	[[#mediQuestions]]
>Bon, on peut y aller.
>	[[#mediLeave]]

## mediQuestions
>Qui est-il?[[#mediAbout]]
>Il lit quoi?[[#mediBook]]
>Plus de questions.[[#mediLeaveAfterQuestions]]`if askedMedi`

## mediAbout
![[pro.png]]
Le Mécène veut en savoir plus sur toi.
[Medi]
Quel honneur! Voyons voir...
Je suis le premier fils du maire de ce village, bien que j'aie une sœur aînée.
Et... même si ça peut sembler un brin présomptueux de ma part, vu que nous vivons dans une démocratie après tout...
Le jour viendra sûrement où je serai amené à prendre la place de mon père, comme il l'a fait avec le sien, d'ailleurs.
Alors j'essaie de passer la majeure partie de mon temps à me préparer. C'est une grande responsabilité.
Cela dit, ce n'est pas comme si je me sentais injustement accablé. L'art de gouverner m'intéresse depuis toujours.
...à tel point qu'il m'arrive parfois de me demander à quoi ressemblerait un poste encore plus élevé.
Mais c'est juste un peu de rêverie, tout ça. En vrai, je voudrais pas imaginer le genre de fardeau qui accompagne une telle responsabilité. 
Mon père a l'air déjà assez stressé avec ses seules fonctions!
![[proSmirk.png]]
On est d'accord là-dessus.
>!Pourquoi il est si sûr de devenir maire? Et sa sœur?
>	![[pro.png]]
>	Le Mécène veut savoir pourquoi ta sœur ne pourrait pas être maire.
>	[Medi]
>	Api!?
>	Hm hm.
>	Au bout du compte, on veut tous ce qu'il y a de mieux pour le village.
>	Si elle s'avère la plus apte, alors, naturellement, elle sera élue.

Alors, il y avait autre chose?`askedMedi`
[[#mediQuestions]]
## mediBook
![[pro.png]]
Tu lis quoi?
[Medi]
Oh, c'est un livre sur l'étiquette de cour.
Plutôt sec dans la plupart des passages, mais les dialogues sont divertissants.
![[proNonchalant.png]]
C'est genre un manuel d'instructions?
[Medi]
En un sens, oui.
J'admets qu'en toute vraisemblance, ces conseils ne me serviront jamais.
Mais parfois, c'est amusant de se projeter dans un environnement plus impitoyable.
![[proSkeptical.png]]
Vraiment? Ça a l'air stressant.
[Medi]
Eh bien, ça reste une chimère. Je ne pense pas que de tels endroits existent encore à notre époque.
Peut-être dans un siècle ou plus, lorsqu'on aura chassé tous les monstres et qu'on aura assisté au retour d'États dignes de ce nom.
Mais même moi j'aurai succombé de vieillesse d'ici là...

>!Quel âge a ce gosse?
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Heh.)
>	Le Mécène trouve que c'est assez sombre pour quelqu'un de ton âge.
>	[Medi]
>	J-je suis assez grand!
>	Et j'ai des responsabilités! Père dit qu'il est bon de ne pas se détourner de ce genre de pensées.
>	Mais peut-être que je me suis un peu laissé emporter...

Quoi qu'il en soit, j'espère avoir répondu à votre satisfaction, Observateur. Il y avait autre chose?`askedMedi`

[[#mediQuestions]]

## mediLeaveAfterQuestions
![[pro.png]]
Plus de questions. Je te laisse tranquille, maintenant.
[Medi]
Oui, bonne chance pour la suite.
C'est... c'était agréable de te parler après tout ce temps, Pro.
![[pro.png]]
`proAff+=0.5`
Oh. Euh, c'était agréable de te parler aussi.
Salut.
[Medi]
Au revoir.
`x`

## mediLeave
![[pro.png]]
(Cool.)
![[proNonchalant.png]]
Bon, je vois que t'es plongé dans ton livre, et j'ai un *tas* de trucs à régler, alors je te laisse.
[Medi]
Ah. Oui, bien sûr.
Bonne chance.
![[proNonchalant.png]]
À plus.
`x`

# hederaMeeting
[Hedera]
Ah!
`c,hederaWalksToPro`
Bienvenue, bienvenue.
Nous sommes honorés de votre visite.
N'hésitez pas à explorer notre foyer comme bon vous semble.
![[proSkeptical.png]]
Euh. Quel accueil chaleureux.
[Hedera]
Je m'efforce de n'offrir à votre Mécène que la plus douce hospitalité.
Comme nous tous devrions.
![[proNonchalant.png]]
Ah.
[Hedera]
`face,hedera,left`
Api!
Nous avons un invité!

`c, apiComesOut`

[Api]
Quoi- mère, tu l'as laissé *entrer*?

`camPan,hedera,false,16`
[Hedera]
Api! Un peu civisme!

`camPan,api,false,16`
[Api]
Non! Je m'en fiche de ce que tu dis, je vais pas ramper et me prosterner devant *lui*!

`camPan,hedera,false,16`
[Hedera]
C'est-!
Le savoir-vivre, Api! Le savoir-vivre!

`camPan,api,true,16`
[Api]
Pff!

`c, apiLeaves`

[Hedera]
`face,hedera,right`
Veuillez l'excuser.
Elle s'accorche encore à certains idéaux puérils.

![[proFacade.png]]
C-c'est rien.

>!Qu'est-ce que tu lui as fait?
>	![[proMildSurprise.png]]
>	(J'ai, euh...)
>	(J'ai peut-être manqué un peu d'humilité par le passé. À propos de mon boulot, tu vois.)
>	![[proHidingSomething.png]]
>	(À ma déchrge, j'avais, genre, 12 ans.)
>	![[proAnnoyed.png]]
>	(Ce que les gens peuvent nous reprocher...)
>	>!Tu t'es jamais excusé?
>	>	`playerSidedWithGirls``proAff-=0.5`
>	>	![[proCynical.png]]
>	>	(Euh... l'occasion m'est un peu passée sous le nez.)
>	>	![[proEmbarrassed.png]]
>	>	(À ma décharge, j'avais... juste un peu plus que 12 ans...)
>	>	![[proAnnoyed.png]]
>	>	(Écoute, à partir, d'un certain moment, elle a simplement décidé que je n'aurais jamais la cote à ses yeux.)

![[pro.png]]
Bref, Mme Demos, je crois que le Mécène aimerait jeter un œil.
![[proCynical.png]]
(T'as l'air d'aimer ça.)

[Hedera]
Je vous en prie.

`c,hederaWalksBack`
`spokeToHedera`
`x`

# hederaInteract
![[proMildlyConflicted.png]]
`if !hederaCreepy`
	(Je... veux pas vraiment parler à Hedera.)
	>!Pourquoi pas?
	>	![[proDisdainful.png]]
	>	(Elle me file la chair de poule! Comme si son regard me transperçait le crâne quand elle fixe quelque chose...)
	>	`hederaCreepy`
`else`
	(...)
`x`

# edifAndTrabe
`face,pro,right`
`if seen`
	![[pro.png]]
	(On va pas les déranger pendant qu'ils travaillent.)
	`walkBack, left`
	`x`

[Edif]
`camPan, edif`
Ah, Pro!
`if spokeToEdif`
	Content de te revoir!

[Trabe]
`camPan, trabe`
`face,trabe,left`
Oh, oui, bonjour.
Désolée de pas avoir pu t'accueillir, comme tu peux voir on est un peu débordés ici.

![[proNonchalant.png]]
T'inquiète pas. Vraiment.

[Trabe]
Quelle malchance que ça arrive le jour de ton grand jour, hein?
J'imagine que tu dois faire le tour?

![[proAnnoyed.png]]
On dirait bien.

[Trabe]
Eh bien, crois-moi, j'adorerais discuter, mais on doit élaborer notre plan pour réparer cette rambarde rapidement.
On veut pas que quelqu'un, euh, fasse un plongeon accidentel.
Pourquoi tu repasserais pas demain?

![[proNonchalant.png]]
... D'accord.

`face,trabe,right`
`camReset`
`walkBack,left`

`x`


# arb
## arbInterrupt
`if spokeToArb`
	`x`
[Arb]
Hm hm.

`c, proWalksToArb`
## arbInteract
[Arb]
...
C'est fait?
![[pro.png]]
Oui, Ancien.
[Arb]
Bien.
Je m'adresserai directement au Mécène alors.
...
Bienvenue dans notre beau village.
J'espère que sa splendeur vous parvient bien, là-haut. Profitez-en à votre guise.
Cependant, les pièces qui se trouvent de l'autre côté de ces portes sont interdites aux étrangers, comme elles le sont depuis des générations.
Nous y abritons nos plus vulnérables, nos blessés et nos anciens.
Et bien que nous ne doutions pas de vos bonnes intentions, les accidents surviennent rapidement.
Nous vous saurions gré de retenir votre curiosité jusqu'à ce que vous et votre protégé ayez prouvé la stabilité de votre lien.
>Compris.
>Mais je veux voir!!
>	`playerWhiny+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(Désolé, mais j'ai pas envie d'aller ranger mon épée juste pour me faire dévisager par des retraités.)
>	`var, lying`
>C'est une tentative assez transparente de me détourner de la pile de ressources.
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Heh.)
>	(Ouais, nos entrepôts sont par là aussi.)
>	(Crois-moi cependant, y'a rien qui vaut la peine d'être volé.)
>	`var, lying`
>« Ancien »? Étonnamment respectueux.
>	![[proAnnoyed.png]]
>	(J'ai appris à la dure qu'il fallait pas plaisanter avec lui.)
>	![[proSmirk.png]]
>	(Mais c'est pas comme s'il a besoin que je dise autre chose. J'ai qu'à hocher la tête et décrocher pendant qu'il parle.)
>	[Arb]
>	Mon garçon?
>	![[proMildSurprise.png]]
>	A-ah, oui, Ancien.
>	`var, lying`

![[pro.png]]
Le Mécène comprend.

[Arb]
`if lying`
	...
	Le passage s'ouvrira en temps voulu. Merci de votre compréhension.
`else`
	C'est bien. Merci.

Je dois maintenant aller remettre l'Asperseur en lieu sûr. Je vous souhaite le meilleur.

`c, arbLeaves`

`spokeToArb`

`x`

# fibra
[Fibra]
Mm?
Oh, Pro, entre, entre!

`c, proWalksToFibra`

![[proSoftSmile.png]]
Salut Fibra.
[Fibra]
Oh, regarde-toi avec ton épée et tout! La cape te va bien.
![[proMildlyEmbarassed.png]]
M-merci.
[Fibra]
Mm, mais ces chaussures ne te vont plus trop, non?
Rappelle-moi de t'en faire des nouvelles quand le prochain envoi arrivera.
![[proHidingSomething.png]]
Oh. D'accord.
[Fibra]
Qu'est-ce qu'il y a?
Oh! Que dis-je? Tu seras parti d'ici là, non?
![[proMildSurprise.png]]
Euh- ben... ouais.
![[proFacade.png]]
Faudrait pas faire attendre le Mécène.
[Fibra]
Oui, bien sûr.
Oh là là... c'est dur de croire qu'ils sont enfin là...
Ah! Alors, tu es ici au nom du Mécène? Si tu cherches Edif, il parait qu'il est dehors en train de réparer le pont.
![[proCynical.png]]
Non, je suis juste en train de... parler à tout le monde, j'imagine.
[Fibra]
Oho! On dirait que t'en as déjà marre, hein?
Je te retiendrai pas longtemps alors.
![[proMeditating.png]]
Merci.
[Fibra]
Je parie que t'auras ta dose de questions à la fête de demain de toute façon.
![[proFacade.png]]
O-Ouais.
`x`

## fibraInteract
![[pro.png]]
(Tu voulais lui demander quelque chose?)
## fibraQuestions

>Pourquoi il y a si peu d'enfants dans votre village?[[#fibraKids]]
>C'est quoi tout cet équipement?[[#fibraEquipment]]`if !fibraEquipmentAsked`
>Non, rien.
>	`x`

## fibraKids
![[proSkeptical.png]]
(C'est une question pour elle?)
![[pro.png]]
(Ça peut pas faire de mal de demander.)
![[pro.png]]
Le Mécène se demande pourquoi le village a si peu d'enfants.
[Fibra]
Aha, ma fille est juste tellement adorable, n'est-ce pas?
![[proNonchalant.png]]
Peut-être.
[Fibra]
Oui!
Eh bien, pour répondre à votre question... hm...
Je saurais pas vraiment dire!
Disons qu'on manque pas de bras. Même si la capitaine serait peut-être pas d'accord.

>Mais avec autant de couples, ça... arrive pas tout seul?
>	![[proSkeptical.png]]
>	(... Non? Pourquoi ça arriverait?)
>	>Des accidents?
>	>	![[proSkeptical.png]]
>	>	(On peut accidentellement choisir d'avoir un enfant?)
>	>	![[proMildSurprise.png]]
>	>	(Oh! C'est vrai! C'est le cas pour vous!)
>	>	![[proNonchalant.png]]
>	>	(Pardon. Ça fait un moment qu'on a vu ce passage du manuel.)
>	>	>!C'est tellement injuste.
>	>	>	![[proCynical.png]]
>	>	>	(Tu veux échanger?)
>	>	![[proNonchalant.png]]
>	>	(Bref.)
>	>	(Tu voulais lui demander autre chose?)
>	>	[[#fibraQuestions]]
>	>Laisse tomber.
>Vous voulez pas plus d'enfants?
>	![[pro.png]]
>	Tu crois que les gens veulent plus d'enfants?
>	[Fibra]
>	Eh bien, peut-être.
>	En ce qui nous concerne, trois c'est déjà pas mal!
>	Et ce serait pas très juste envers les autres si Edif et moi on en avait beaucoup plus.
>	On finirait par manquer d'espace.
>	![[pro.png]]
>	Ouais...
>	![[proSkeptical.png]]
>	On est quand même pas *si* à l'étroit.
>	[Fibra]
>	Non... mais je dirais que ce genre de choses a tendance à partir en vrille plus vite que ce qu'on pourrait croire.
>	![[proMildlyConflicted.png]]
>	Hm.
>D'accord.

![[proNonchalant.png]]
(Passons à autre chose.)
(Tu voulais lui demander autre chose?)
[[#fibraQuestions]]


## fibraEquipmentAsk
![[pro.png]]
Le Mécène est curieux au sujet de tes outils.
`var askedDirectly`
## fibraEquipment
`if fibraEquipmentAsked`
	![[pro.png]]
	(Les outils de Fibra.)
	![[proNonchalant.png]]
	(Elle pourrait probablement en parler pendant des heures, alors regardons pas de trop près.)
	`x`
[Fibra]
`if !askedDirectly`
	`camPan, fibra`
Ah! Intéressé par la marchandise, hein?
C'est ce que j'utilise pour fabriquer des choses pour le village.
Des vêtements, des bibelots, des bricoles, tout le bric-à-brac.
Avec vous, les jeunes, et toute votre croissance, le travail manque pas!
![[pro.png]]
Merci pour ça.
[Fibra]
Oh, pas de quoi. Sans les récoltes de ta mère je pourrais à peine faire la moitié de ce que je fais.
Bien qu'encore, je trouve ça éternellement stimulant comme défi de devoir me débrouiller avec les moyens du bord.
![[proNonchalant.png]]
(Elle a l'air un peu nostalgique...)

`fibraEquipmentAsked`

`if askedDirectly`
	![[proNonchalant.png]]
	(Bref.)
	(Tu voulais demander autre chose?)
	[[#fibraQuestions]]
`else`
	`camReset`
	`x`
# flora
`if spokeToFlora`
	![[pro.png]]
	(On dirait qu'elle a perdu l'envie de parler, alors elle me regarde même pas.)
	![[proMeditating.png]]
	(Comme c'est enviable.)
	`x`

![[proFacade.png]]
Hé Flora!
[Flora]
Bonjour!
Maman a dit que tu peux entendre le Mécène maintenant.
![[proSmile.png]]
Exactement! Tu voulais leur dire quelque chose?
[Flora]
Non!
Merci!

`c, floraRunsAway`

![[pro.png]]
...
(Au moins quelqu'un me comprend.)

`spokeToFlora`

`x`

# dendroIntro
![[dendro.png]]
`facePlayer, dendro`
Hm?
Ah, bienvenue, bienvenue.
Vous avez eu l'occasion de regarder autour?
![[proCynical.png]]
Mm.
![[dendro.png]]
Et comment va la connexion? Vous êtes tous les deux bien acclimatés?
>Ça se passe super bien!
>	![[proNonchalant.png]]
>	Ils ont, à tout le moins, l'air de bien s'amuser.
>	![[dendroSurprised.png]]
>	Je... vois. Eh bien, tant mieux.
>Je prends le pli.
>	`playerClueless+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(Le pli de quoi? De me faire courir comme un larbin?)
>	![[dendroStern.png]]
>	Quelque chose ne va pas?
>	![[proFacade.png]]
>	Tout le contraire! Le Mécène a apparemment adoré la visite!
>	![[dendroStern.png]]
>	Hmph. À votre place, je ne délaisserais pas si cavalièrement mes derniers jours de quiétude.
>	![[proCynical.png]]
>	Oui, la quiétude. C'est clairement ce qui me vient à l'esprit quand je traine avec vous.
>	![[dendroOhReally.png]]
>	Aujourd'hui, du moins, le Mécène t'a guidé ici. Quiétude ou non, tu gagnerais à y voir quelque chose.
>	![[proAnnoyed.png]]
>	Vous diriez pas ça si vous les connaissiez comme moi...
>	![[dendroOhReally.png]]
>	Oho, peut-être bien, peut-être bien.
>Non, il arrête pas de rétorquer et de me dire quoi faire!
>	`playerWhiny+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(Tu sais qu'il peut pas t'entendre, hein?)
>	![[proFacade.png]]
>	Ça se passe super bien!
>	![[dendroOhReally.png]]
>	Mm. Je suppose que je devrai vous croire sur parole.
>	>!Ça! En plein ce genre de truc!
>	>	![[proNonchalant.png]]
>	>	(On dirait que tu vas juste devoir t'« acclimater ».)

![[dendro.png]]
Quoi qu'il en soit, si vous êtes venu avec des questions alors n'hésitez pas.
Je suis là pour aider.
![[proCynical.png]]
Je vous ferai signe.
`x`

# dendro
![[pro.png]]
(Tu veux lui demander quoi?)

## dendroQuestions
>Pourquoi il est si dur avec toi?[[#dendroMean]]`if !judgedDendro`
>Pourquoi t'es si désinvolte avec lui?[[#dendroNotMean]]`if !judgedDendro`
>Il travaille sur quoi?[[#dendroWork]]
>Vous me vénérez? C'est pas clair.[[#dendroWorship]]
>Pourquoi le village n'a pas de toilettes? On dirait une grave défaillance institutionnelle.[[#dendroToilets]]
>Qu'est-ce qu'il y a dans les prophéties chiffrées?[[#dendroProphecies]]`if encryptedPropheciesMentioned`
>Plus de questions.
>	`x`

## dendroMean
`proAff+=0.5`
![[proLaughing.png]]
Ha!
![[dendroSurprised.png]]
Mm?
![[proSmirk.png]]
Oui, pourquoi *êtes*-vous si dur avec moi?
![[dendroAngry.png]]
...
![[dendroClearingThroat.png]]
...
![[dendro.png]]
On ne peut qu'espérer faire au mieux avec ce qu'on a.
![[dendroStern.png]]
N'en parlons plus.
Il y avait autre chose?`judgedDendro`
![[pro.png]]
(Oui?)
[[#dendroQuestions]]

## dendroNotMean
`proAff-=2`
![[proHidingSomething.png]]
Tch.
![[dendro.png]]
Qu'y a-t-il?
![[proCynical.png]]
Pourquoi faut-il que vous preniez *tout* tellement au sérieux *tout le temps*?
![[dendroStern.png]]
Je l'ai dit mille fois. C'est le destin du monde, Pro.
Être laxiste dans nos efforts serait irresponsable de notre part.
![[proCynical.png]]
Même si ça nous rend misérables?
![[dendroStern.png]]
Si c'est le prix à payer... oui, nous le considérerons à tous les coups.
Mais enfin, t'es pas misérable. Une éducation convenable n'est guère si torturante.
![[proCynical.png]]
(Et voilà.)`judgedDendro`
>!Pardon.
>	`proAff+=3`
>	![[proMildSurprise.png]]
>	(Oh. T'en fais pas, c'est pas comme si t'y étais pour quelque chose.)
>	![[proCynical.png]]
>	(Enfin, pas directement.)
>	![[pro.png]]
>	(Bref, tu avais autre chose à demander?)
>	[[#dendroQuestions]]

`playerSidedWithDendro`
[[#dendroQuestions]]

## dendroWork
![[pro.png]]
Le Mécène veut savoir sur quoi vous travaillez.
![[dendro.png]]
Oh, en ce moment, eh bien...
Je rédige diverses lettres, annonces officielles, ce genre de choses.
Maintenant que nous rendons votre existence publique, il est important que les dirigeants des autres colonies soient informés.
![[dendroClearingThroat.png]]
Cela dit, le maire du <span style="color:rgb(225, 188, 105)">Village de Kiba</span> devrait déjà être au courant.
![[proMildSurprise.png]]
Hein?
![[dendro.png]]
Oui, le message a été envoyé il y a quelques semaines.
J'ai jugé bon de prévenir quelqu'un tôt plutôt que tard, en cas d'urgence, et c'est un homme de confiance.
![[proCynical.png]]
Vingt ans à garder un secret et vous avez eu envie de jacasser juste avant le rituel?
![[dendroClearingThroat.png]]
Allons, allons. Personne n'aurait été en mesure d'agir sur cette information à temps.
L'assurance que cela procure vaut largement le risque de fuite.
![[proCynical.png]]
Assurance contre quoi?
![[dendroStern.png]]
Nous ne pouvons être certains d'être les seuls à avoir accès aux connaissances restreintes du <span style="color:rgb(225, 188, 105)">Répertoire</span>.`repositoryMentioned`
Ni qu'il n'y ait eu *aucune* fuite ces deux dernières décennies.
S'il y en avait eu avec cette information et l'intention d'agir contre vous,
ce que le village préparait aurait été bien trop évident.
Avoir la possibilité de fuir vers Kiba semblait souhaitable dans bien des cas. C'est aussi pour ça que j'ai fait faire ce badge.
![[proRollingEyes.png]]
Ça me semble paranoïaque.
![[dendro.png]]
Peut-être. Mais on n'est jamais trop prudent quand le monde est en jeu.
C'est un peu dérisoire maintenant. Avec le Mécène à vos côtés, vous serez certainement bien moins en danger.
![[proCynical.png]]
Euh, oui.
>!Merci de croire en moi!
>	![[proCynical.png]]
>	Le Mécène dit merci.
>	![[dendroSurprised.png]]
>	Ah. Je...les en prie?

![[pro.png]]
(T'avais autre chose à demander?)
[[#dendroQuestions]]

## dendroWorship
![[proThinking.png]]
(Ah... plus ou moins? Les détails m'ont toujours un peu embrouillé.)
![[pro.png]]
Le Mécène veut savoir si on les vénère ou non.
![[dendroSurprised.png]]
Bonté divine, ignorer même cela...
![[dendroClearingThroat.png]]
Ah- hm, je m'excuse, je ne voulais pas sous-entendre que vous étiez négligent en quoi que ce soit, Observateur.
![[dendro.png]]
Permettez-moi d'expliquer alors.
Tout d'abord, la nôtre n'est pas une foi aveugle.
Les preuves que nous ont accordées les <span style="color:rgb(225, 188, 105)">Créateurs</span> d'une voie tracée pour ce monde sont indiscutables.
![[dendroClearingThroat.png]]
À savoir si cette voie était souhaitable... n'a jamais fait consensus.
![[dendro.png]]
Mais la confiance en ce plan a été, en quelque sorte, le pilier central de notre organisation et de ses alliés.
![[dendroClearingThroat.png]]
Et le demeure, pour ce qu'il en reste.
![[dendro.png]]
Tout cela pour dire que nous respectons et faisons confiance à votre rôle dans ce processus.
Y compris la nature de votre esprit pensant en tant que...
substrat, pour ainsi dire, de l'instanciation de notre monde dans la réalité supérieure.
Nous ressentons de la gratitude pour tout cela.
Mais sans plus.
Nous ne sommes pas, disons, sous l'illusion que vous ou les Créateurs êtes libres de voir et d'agir sans contrainte.
![[dendroClearingThroat.png]]
Bien que pour être tout à fait franc, la nature *exacte* de ces contraintes,
et vos... positions respectives, métaphysiquement parlant...
Même aujourd'hui, il reste beaucoup d'ambiguïté là-dessus...

>Je comprends. Je peux expliquer.
>	![[proAnnoyed.png]]
>	Mmm...
>	![[dendroSurprised.png]]
>	Ah- à en juger par l'expression de Pro, vous avez commencé à expliquer, mais de grâce, n'en faites pas une obligation.
>	![[dendro.png]]
>	Sous votre tutelle, il aura largement le temps d'en arriver à une compréhension profonde et directe de tout cela.
>	![[dendroStern.png]]
>	Et ce sera plus simple pour tout le monde qu'il l'explique alors lui-même, plutôt que par procuration.
>	![[proNonchalant.png]]
>	Absolument.
>Je comprends pas vraiment.
>	![[proNonchalant.png]]
>	(On est tous dans le même bateau alors.)
>...


![[pro.png]]
(Tu avais autre chose à demander?)
[[#dendroQuestions]]

## dendroToilets
![[pro.png]]
...
C'est quoi des toilettes?
![[dendro.png]]
Hm?
Ah, attendez, je vois.
Observateur, nous ne produisons pas de déchets comme vous.
Le peu que nous excrétons est entièrement évacué par notre respiration.

>C'est pas juste!
>	![[proSkeptical.png]]
>	(C'est vraiment si gênant que ça?)
>Quel malheur. Vous ne connaîtrez jamais les joies d'un bon déchargement.
>	![[proCynical.png]]
>	(Euh... je crois qu'on s'en sort.)

![[pro.png]]
(Bref, tu avais autre chose à demander?)
[[#dendroQuestions]]

## dendroProphecies
`proAff+=0.5`
![[proSmirk.png]]
Le Mécène veut savoir ce qu'il y a dans les prophéties chiffrées.
![[dendroOhReally.png]]
Bien essayé.
![[proFrustrated.png]]
Oh allez, je mens pas.
![[dendro.png]]
Il n'y a rien là-dedans que ton Mécène ne saurait déjà.
S'ils souhaitent te le révéler, libre à eux de le faire directement.
>!Mais... c'est quoi?
>	![[proCynical.png]]
>	Ils ne savent pas de quoi vous parlez.
>	![[dendro.png]]
>	Ah. Eh bien.
>	Je comprends le problème, mais sans moyen de valider les véritables intentions du Mécène, j'ai les mains liées.
>	Acceptez mes excuses.

![[proHidingSomething.png]]
Hmph.
[[#dendroQuestions]]
