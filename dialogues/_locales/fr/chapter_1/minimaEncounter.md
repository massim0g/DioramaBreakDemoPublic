# startEncounter
`c,startEncounter`

![[proMildSurprise.png]]
(C'était quoi ça?)

`c,proWalksBehindRock`

![[proSkeptical.png]]
(Qu'est-ce qu'elle agite?)
(Une sorte de ventilateur?)
`camPan, minima, true, 30`
(Quoi que ce soit, ça n'a pas l'air de l'aider.)`a,1`
`camPan, pro, true, 30`
`a`(...)
### helpChoice
>Vas-y, aide-la!
>	![[proDeterminedSmile.png]]
>	(Je me ferai pas prier, non plus!)
>Continue à observer. [[#keepWatching]]
>File d'ici, c'est trop dangereux.
>	![[proMocking.png]]
>	(... Tu parles comme la capitaine.)
>	(Si ça t'inquiète tant que ça...)
>	![[proDeterminedSmile.png]]
>	(...je suis sûr que ça te dérangera pas de filer un coup de main!)

`c,proJumpsIn`

`x`

## keepWatching
`p,2`
(Je crois qu'elle n'a plus beaucoup de temps.)
[[#helpChoice]]

## postCombat
`camPan, pro`
![[proNonchalant.png]]
Ouf.
`c,proLooksAround`
![[pro.png]]
T'es toujours là? Je crois qu'il n'y a plus de danger, tu peux sortir.

`c,minimaEmerges`

![[minimaConflicted.png]]
S-salut.

`p,2.5`

![[pro.png]]
Tu vas... bien?

![[minimaDisappointed.png]]
Oh. Ouais.
![[minimaAnnoyed.png]]
Désolée, le stress retombe...

`c,minimaWalksNextToPro`

![[minima.png]]
Merci de m'avoir sauvée.
T'es avec les <span style="color:rgb(225, 188, 105)">facteurs</span>?

![[proBemused.png]]
Euh, non.
![[pro.png]]
Je viens du village de Stroma.

![[minimaSurprised.png]]
Oh! Vraiment? J'aurais dû deviner vu les vêtements.
Vous faites... des patrouilles?

![[proThinking.png]]
Pas vraiment. Je suis...
![[proMeditating.png]]
(Bon, première première impression...)

>...nappée de sauce, sur nid de salade avec breuvage et dessert. //Alt: Rajoute-en.
>	(...)
>	![[proSmirk.png]]
>	(... Ouais, pourquoi pas.)
>	![[proHaughty.png]]
>	...Je suis celui qui est né sous l'épithète du Héros de la Prophétie.
>	Lié par l'esprit depuis ce matin-même à mon Mécène, `$player`, 
>	j'ai quitté le village et pris le route en direction vers mon destin.
>	![[minimaSurprisedBlink.gif]]
>	...
>	![[proVeryHaughty.png]]
>	Ah, ta stupéfaction est compréhensible.
>	Oui, ma naissance fut gardée secrète pour ma sécurité.
>	![[proDetermined.png]]
>	Mais avec le Mécène ici, je suis libre de tout révéler!
>	![[minimaApprehensive.png]]
>	Alors... laisse-moi récapituler.
>Fais simple.
>	![[pro.png]]
>	Je suis le Héros de la Prophétie.
>	![[minimaSurprisedBlink.gif]]
>	...
>	Pardon?
>	![[proMeditating.png]]
>	J'ai vécu dans le village, mais je me suis lié à mon Mécène, `$player`, ce matin.
>	![[proNonchalant.png]]
>	Donc, euh... me voilà.
>	![[minimaApprehensive.png]]
>	... Laisse-moi récapituler, alors.

T'es en train de dire que c'est toi, et uniquement toi, la raison pour laquelle Stroma est en confinement depuis vingt ans?
![[minimaDisappointed.png]]
Et que tout ce temps-là, ce n'était pas parce que vous aviez découvert quelque chose qu'il fallait garder secret?
Pas d'arme ultime contre les monstres, ou quelque chose du genre?

![[proSkeptical.png]]
Non?
![[proSmirk.png]]
Sauf si mon corps fait partie de cette définition.

![[minimaAnnoyed.png]]
D-d'accord. Donc, tout ton village t'a dit- euh, t'a élevé comme le Héros.
Genre, le Héros mythique de la prophétie avec une ligne directe vers un être supérieur du grand au-delà.

![[pro.png]]
En effet...

![[minimaLecturing.png]]
C'est de la folie.

![[proMildSurprise.png]]
Bon, euh...

>!Elle a pas tort.
>	![[proCynical.png]]
>	(...)
>Ça va aller, je te crois.
>	![[proCynical.png]]
>	(Oh, merci beaucoup.)

![[minimaAnnoyed.png]]
`s,0.5`Augh, ils avaient tous raison; bien évidemment que ça allait être un truc de secte cinglée.`s,1`

![[proCynical.png]]
Je t'entends toujours.
![[proAnnoyed.png]]
(Adieu la première impression.)
![[proSkeptical.png]]
Tu m'as pas vu battre tous ces monstres?

![[minimaLecturing.png]]
Être un combattant formidable ne fait pas de toi l'élu de dieu.
![[minimaBemused.png]]
Et proclamer ça de façon aussi grandiloquente n'ajoute pas à ta crédibilité.
Tu as vraiment lu les prophéties?

![[proDisdainful.png]]
O-ouais.
![[proHidingSomething.png]]
La plupart, du moins.

![[minimaBemused.png]]
Incroyable...
Eh bien, alors tu sais sûrement qu'elles sont pas si romanesques que ça.
![[minimaLecturing.png]]
On dirait plutôt un manuel d'instructions qu'autre chose.
![[minimaLookingAway.png]]
Du moins les parties qui ne se résument pas à des listes interminables de données météorologiques futures.

![[proCynical.png]]
`if normalPropheciesExplained`
	Ouais, ouais. Je le savais.
`else`
	Ouais, ouais. Je le savais.
	>!Quoi?
	>	![[proCynical.png]]
	>	(C'est là pour « valider la précision des prévisions », soi-disant.)

![[minimaBemused.png]]
T'as juste pas eu envie de faire preuve de rigueur?
Il n'y a rien dans les prophéties qui interdise au Héros de les lire.

![[proDisdainful.png]]
Si, dans la section chiffrée.
![[proRollingEyes.png]]
(Enfin, c'est ce qu'on m'a raconté.)

![[minimaMildlyAnnoyed.png]]
... Vous avez décrypté les prophéties chiffrées? Ça semble... peu probable.

![[pro.png]]
On ne les a pas *décryptées*.
![[proRollingEyes.png]]
La clé... est apparue quand je suis né.

![[minimaSkeptical.png]]
« Apparue »?

![[proEmbarrassed.png]]
C'est un peu gênant, à vrai dire...
![[proAnnoyed.png]]
Bref, un signe clair est apparu, et c'est comme ça que les gens ont su que j'étais le Héros.

![[minimaBemused.png]]
Ou, du moins, c'est ce qu'on t'a raconté.

![[proAnnoyed.png]]
D'accord, je comprends entièrement où tu veux en venir.
![[proCynical.png]]
Mais ce qui s'est produit ce matin a élucidé une bonne partie des doutes qui me travaillent depuis le temps.

![[minimaCheeky.png]]
Oh c'est vrai, tu t'es « lié ». Laisse-moi deviner, tu *sens leur présence*?

![[proAnnoyed.png]]
(Zut.)
![[proCynical.png]]
Non, c'est... bien plus que ça. Écoute, tu as lu la prophétie.

![[minimaCheeky.png]]
Oh, alors tu prétends leur parler? C'est encore mieux.
Comment ils s'appellent?
![[proHidingSomething.png]]
...`$player`.
![[minimaBemused.png]]
Oh. Ha.
>!Quoi? Quoi!?
>	![[proCynical.png]]
>	(Me demande pas.)

![[minimaBemused.png]]
Bon, j'espère que tu comprends pourquoi rien de tout ça n'est très convaincant.

![[proRollingEyes.png]]
Ouais, ok.
`c,proStartsLeaving`
![[pro.png]]
À un de ces quatre, alors. Bonne chance avec ce que tu faisais là.

![[minimaSurprisedBlink.gif]]
Ah, euh, en fait j'étais en route pour Stroma.

![[pro.png]]
`face,pro,down`
Super, il y a qu'à suivre ce chemin jusqu'au bout.
`face,pro,right`
![[proMocking.png]]
D'ailleurs, je devrais peut-être te faire savoir....
Je crois pas qu'ils s'attendent à avoir des visiteurs de sitôt,
alors tu finiras peut-être par devoir guetter l'entrée jusqu'à ce que quelqu'un descende.
![[proRollingEyes.png]]
Essaie d'être... discrète.

`c,proWalksAway,false`

`p,1`

![[minimaApprehensive.png]]
`a,1`...

`a,-1`

![[minimaLookingAway.png]]
En y repensant, ça vaut probablement le coup de te poser quelques questions de plus.
Je connais un endroit sûr pour camper.

![[pro.png]]
`a`Super.
>!Ça te va?
>	![[proSkeptical.png]]
>	(Je vais pas la laisser pour compte ici.)
>	![[proRollingEyes.png]]
>	(...du moment qu'elle arrive à rassembler un minimum d'instinct de survie quand viendra le temps.)

`a,-1`
## firstEncounterDone
`a,-1`
`x`
# afterNextCombat
`c,minimaWalksToPro`
`face,pro,minima`
`face,minima,pro`
![[minimaLeaningIn.png]]
Plus j'observe, et plus tes réflexes me paraissent... presque incroyables.
![[minima.png]]
Comment t'arrives à faire tout ça?

![[proSmirk.png]]
Je te l'ai dit, je suis le Héros.

![[minimaBemused.png]]
Allez, c'est pas une explication.

![[proThinking.png]]
...
![[proSkeptical.png]]
Je peux pas trop t'en vouloir dans ce cas, mais tu passes toujours au crible ceux qui te sauvent la vie comme ça?

![[minimaEmbarassed.png]]
Ah, euh...
Ouais... un peu.

![[proBemused.png]]
« Ouais »? Alors c'est pas la première fois?

![[minimaSheepish.png]]
... J'oublie à quel point les gens ont pas l'air d'aimer dès qu'on met le pied hors de l'<span style="color:rgb(225, 188, 105)">Académie</span>.`minimaMentionedFront`

![[proSkeptical.png]]
De se faire sauver la vie?

![[minimaMildlyAnnoyed.png]]
Non, d'être sensé.

![[proVeryHaughty.png]]
Te sauver c'était insensé. Je note.
>!Un peu, quand même.
>	`proAff+=1`
>	![[proSmirk.png]]
>	(Tu te sous-estimes un peu là.)

`minimaCommentedOnCombat`
`x`
# aboutMinima
`c,restTalkStart`
![[pro.png]]
Tu as dit que t'es arrivée ici de l'<span style="color:rgb(225, 188, 105)">Académie du Front</span>? Qu'est-ce que t'es venue faire si loin?

![[minimaLookingAway.png]]
Je te ferai savoir que ça s'appelle l'Académie *de* Front. Et, ben en fait...
![[minimaMildlyAnnoyed.png]]
As-tu parfois l'impression que tout le monde a... baissé les bras en quelque sorte?
Qu'ils ont abandonné l'idée de régler le problème des monstres pour de bon?

![[proSkeptical.png]]
Non?

![[minimaSheepish.png]]
Bon, j'imagine que *toi*, tu seras pas porté à le voir ainsi.
![[minimaLecturing.png]]
	Il semble qu'en fin de compte, j'avais au moins raison sur le fait qu'il n'y a que Stroma qui essaie de *faire* quelque chose pour aider.
![[minimaLookingAway.png]]
Bref, pour répondre à ta question, j'ai entendu une rumeur comme quoi le village allait s'ouvrir aux alentours de cette période.

![[proCynical.png]]
(Adieu la confidentialité...)

![[minima.png]]
Et, pour le bien du plus grand nombre, j'ai pensé que ça valait le risque de venir voir ce qui se passait.

![[proSkeptical.png]]
Par toi-même?

![[minima.png]]
Les facteurs m'ont escortée pendant la majeure partie du trajet.
![[minimaConflicted.png]]
Mais une fois arrivés à <span style="color:rgb(225, 188, 105)">Lacrima</span>, ils ont dit qu'ils ne prévoyaient pas de livraison avant des semaines, et j'étais si près...

![[pro.png]]
(Ouah.)
>!Elle est plus aventurière que toi!
>	![[proRollingEyes.png]]
>	(Et encore plus « suicidaire », au moins *moi*, je me suis entraîné depuis la naissance pour ça.)
>Ok, c'est quoi cette histoire de « facteurs »?
>	![[proNonchalant.png]]
>	(Ils livrent le courrier. T'as pas de courrier dans ton monde?)

![[minimaAnnoyed.png]]
Y aller seule... quel risque badaud et futile.

![[proMildlyEmbarassed.png]]
Euh...

![[minimaExhausted.png]]
Je crois que d'être arrivée si loin sans fracas a un peu faussé mes attentes.
Ugh.

![[proFacade.png]]
Eh bien, qui ne risque rien, n'a rien.

![[minimaRanting.png]]
Je le *sais*, ça!
Mais on n'a qu'un nombre limité de chances et je peux pas *aider* qui que ce soit si j'y *reste*!!

`p,2.5`

![[minimaLookingAway.png]]
... Pardon. Parlons d'autre chose.

![[proMildSurprise.png]]
D'accord.
`c,restStart`
`x`

# names
`c,restTalkStart`
![[minimaSmile.png]]
Alors... merci encore pour le sauvetage, euh...
![[minima.png]]
Comment tu t'appelles?

![[pro.png]]
Pro.

![[minimaSmile.png]]
Pro. Enchantée. Ou chanceuse, du moins.
![[minimaSurprised.png]]
... Attends. « Pro ». Genre, « pro »-tagoniste?

![[proHidingSomething.png]]
Euh...
Sans commentaire.

![[minimaLaughing.png]]
Hahaha! Non mais c'est pas vrai!
C'est incroyable! C'est fantastique!

![[proAnnoyed.png]]
Bon, bon.
« Enchanté » de te faire ta connaissance, aussi... euh...

![[minimaSurprisedSmile.png]]
Oh!

`c,minimaGetsUpToTwirl`

![[minimaCheeky.png]]
Ingénieure de génie! Jeteuse de sorts sans équivoque!
Votre sympathique...

`c,minimaTwirl`

![[minimaPose.png]]
Minima!

`p,0.7`

![[proMildSurprise.png]]
...
>Ouah, va falloir que tu retravailles ton intro.
>	`proAff+=1`
>	![[proBemused.png]]
>	(Difficile de faire mieux.)
>	(Très difficile.)
>Je crois que j'ai préféré ta présentation à toi.
>	`proAff+=2`
>	![[proBemused.png]]
>	(Ouais, celle-ci ne plaît qu'à...)
>	(...des goûts particuliers.)
>...

`c,minimaStopsPosing`

![[minimaSmile.png]]
C'est à qui le tour, d'être stupéfait, hein? Haha.

![[proBemused.png]]
C'était pas une compétition, tu sais.

![[minimaLaughing.png]]
Ha!

`minimaIntroduced`
`c,restStart`
`x`
# spellcaster
`c,restTalkStart`
![[proBemused.png]]
T'as dit que t'étais une « jeteuse de sorts »?

![[minimaJovial.png]]
Ouaip! Mate le bâton!

![[proMocking.png]]
Le gros ventilateur?

![[minimaSmile.png]]
Ça s'appelle un <span style="color:rgb(225, 188, 105)">anémomateur</span>.

![[pro.png]]
Jamais entendu parler.
>!Ça devrait pas être anémo-*mètre*?
>	![[proThinking.png]]
>	(Bonne question.)
>	![[proSkeptical.png]]
>	Ça devrait pas être anémo-*mètre*?
>	![[minimaSmile.png]]
>	Non, un anémomètre mesure l'Air; ce truc l'affecte.

![[minimaCheeky.png]]
En principe, ils sont pas censés se trouver en dehors d'un labo météo, mais j'ai réussi à assembler une version portable!

![[proSkeptical.png]]
Et ça le rend magique?

![[minimaBemused.png]]
La magie n'existe pas, banane!
![[minimaCheeky.png]]
Mais ce truc a vraiment l'air magique quand il est en action!
![[minimaLeaningIn.png]]
Malgré ce qu'on pourrait croire, un espace vide n'est pas si plat que ça, 
et l'Air finit parfois piégé dans des poches plus « denses ».
![[minimaSmile.png]]
Cet appareil trace brièvement un point d'équilibre avec les régions voisines, déclenchant de puissantes réactions en chaîne.

![[proSkeptical.png]]
Ça n'avait pas l'air de faire grand-chose quand tu le brandissais tout à l'heure.

![[minimaEmbarassed.png]]
Ben... ça fonctionnait bien au labo.
![[minimaSheepish.png]]
Même si je comprends quelle impression ça donne.
Les conditions extérieures ont été un peu *trop* chaotiques.
![[minimaLookingAway.png]]
C'est pas que je m'y attendais pas mais... j'ai besoin de plus de pratique.
![[minimaSheepish.png]]
Je peux pas exactement transporter un supercalculateur sur mon dos,
alors le logiciel dépend beaucoup d'ajustements manuels.

![[proNonchalant.png]]
Tout ça a l'air tout à fait trop compliqué.

![[minimaBemused.png]]
... On est pas tous voués à être entraînés au maniement de l'épée depuis la naissance.

![[proSmirk.png]]
Pas avec cette attitude.
`c,restStart`
`x`

# anemomaterAndTimeStop
`c,restTalkStart`

![[pro.png]]
Comment ça se fait que t'arrives soudainement à utiliser ce truc aussi bien?

![[minima.png]]
Quoi? L'anémomateur?
C'est grâce à l'arrêt du temps. C'est évident, non?

![[proCynical.png]]
Oui, bon, mais c'est pas comme si le temps qui fige me rendait meilleur à l'épée.

![[minimaLookingAway.png]]
Oh. Hm... comment je pourrais expliquer...
![[minima.png]]
Imagine que tu devais jouer d'un instrument en suivant une partition,
mais que les notes que tu devais jouer changent toutes les quelques millisecondes.
![[minimaLecturing.png]]
Le temps que tu les lises et commences à jouer, le morceau que t'étais censé jouer a déjà changé.
Par contre, si t'avais assez de temps pour lire la partition avant qu'elle change,
ce serait pas si différent que de jouer normalement.
![[minimaConflicted.png]]
`a,0.4`Cependant, tu dois quand même te rappeler quoi jouer et ce, en tout temps; 
ce faisant, tu voudras pas passer tout ton temps à regard-
![[minimaSheepish.png]]
`a`Je crois que je suis en train de massacrer cette analogie.
![[minima.png]]
Bref, tout ça pour dire que l'arrêt du temps fige la « partition », c'est-à-dire mes relevés atmosphériques.
Ça facilite énormément le fait de calculer exactement ce que je dois faire pour déclencher la réaction voulue à l'avance.

![[proThinking.png]]
Je vois...

`c,restStart`

`x`

# triedToLeaveEarly
`if seen`
	![[pro.png]]
	(Allez, je veux savoir ce qu'elle fait là.)
	`c,walkBackToRestArea`
	`x`
![[minimaSurprised.png]]
Hé, on part déjà?
![[minimaSmile.png]]
Allez, viens t'asseoir. On a à peine eu le temps de parler.
![[proRollingEyes.png]]
(Mm... j'aimerais quand même savoir ce qu'elle fait là.)
![[pro.png]]
Ouais, d'accord.
`c,walkBackToRestArea`
`x`
