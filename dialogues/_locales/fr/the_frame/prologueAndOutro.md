# start
`c,prologueStart`
`steward,r,presenting,neutral`
Bienvenue à la démo de Diorama Break!

`steward,l,reassuring`
Nous vous remercions sincèrement de vous être joint à nous aujourd'hui.

`steward,r,cheery`
Sérieux!
`steward,r,cheeky`
`a,0.5`Personnellement, je ne me verrais pas perdre mon temps à-

`steward,l,irked``a`
Hum.
`steward,l,neutral`
Soyez assurés que, malgré son état incomplet, nous n'avons ménagé aucune dépense pour que cette expérience en vaille la peine.

`steward,r,annoyed`
Oh oui, *dépense* est bel et bien le mot juste.
`steward,r,distracted`
`s,0.5`Il a intérêt à marcher, ce Kickstarter...`s`

`steward,l,neutral`
Bien.
`steward,l,presenting`
Devant vous se dresse le Diorama.

`steward,r,presenting`
Derrière la vitre se trouve un monde miniature d'aventure et de secrets.
`steward,r,cheery,presenting`
Insufflé de vie à l'intersection de votre tête et de l'écran!

`steward,l,presenting,neutral`
Dans ce jeu, vous, cher joueur assis devant nous, guiderez un héros à travers un voyage qui changera son monde.

>Ça a l'air bien!
>Ça a l'air nul.
>	`steward,r,annoyed,neutral`
>	...
>	Libre à vous de partir alors.
>	Fermez la démo! Allez : Alt+F4! Tout de suite!
>	...
>	`steward,r,cheeky`
>	Ha! Vous n'oserez pas.
>	`steward,l,irked,neutral`
>	...
>	Poursuivons.
>Cool. Mais pourquoi ce jeu s'appelle Diorama *Break*?
>	`steward,r,cheery`
>	Oh oui!
>	`steward,r,presenting,neutral`
>	`auto,0.2`C'est quoi le truc? On va prendre un marteau et casser ce tr-
>	`auto``steward,l,sternRight,neutral`On ne touche à rien.
>	`steward,l,stern`
>	Les seules « ruptures » qui auront lieu ici seront d'ordre métaphorique.
>	`steward,l,irked,neutral`
>	Maintenant, comme je disais...
>Bien. On peut passer directement à ça?
>	`steward,r,giveUp`
>	Ah, eh bien, il y avait quelques trucs à expliquer...
>	`steward,r,cheery,neutral`
>	Mais bon, je suis sûre que vous arriverez à vous en tirer!
>	Allez-y!
>	`steward,l,irked`
>	Ah... très bien alors.
>	[[#connectionStart]]

`steward,l,neutral`
Chaque instrument de la nature du Diorama est équipé d'un assistant pour guider et interpréter la volonté de l'utilisateur.
En l'occurrence, il s'agit de nous.
`steward,l,bowing`
Mais ne vous en faites pas, on ne vous embêtera pas trop.

`steward,r,presenting,neutral`
Oui, on se fera très discrets.
`steward,r,cheeky`
Vous pourrez alors semer la pagaille comme bon vous semble.

>Compris.
>	`steward,r,cheery`
>	Bonne attitude!
>	`steward,l,neutral`
>	Oui.
>Vous avez dit « un assistant », mais vous êtes deux?
>	`steward,l,neutral,irked`
>	Ah, oui, eh bien, ces outils viennent normalement par paires, mais le Diorama est un peu plus... intégré.
>	`steward,l,neutral`
>	Mais nul besoin de vous soucier de ce genre de détail.
>	`steward,r,cheery`
>	Ouais, tout ça c'est des trucs pour... mods, disons.

`steward,l,reassuring`
Nous sommes presque prêts, mais certains contrôles méritent d'être expliqués.
`steward,l,presenting,neutral`
Prenez ce dialogue, par exemple.
`if gamepad`
	Saviez-vous que vous pouvez utiliser **X** ou **B** pour avancer le dialogue plus vite? Essayez maintenant`speed, 0.1`. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .`speed`
`else`
	Saviez-vous que vous pouvez utiliser le **Clic Droit** ou **Shift** pour avancer le dialogue plus vite? Essayez maintenant`speed, 0.1`. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .`speed`

`steward,r,cheery`
Très bien!
`steward,r,neutral,presenting`
Voici un autre truc intéressant :
`steward,r,presenting`
Parfois, vous aurez la possibilité d'**intervenir** pendant le dialogue!
`steward,r,neutral`
`if gamepad`
	Guettez l'indicateur, puis appuyez sur **Y**.
	>!Comme ça?
	>	`steward,r,cheery`
	>	Oui, parfait!
	>	[[#interjectionDone]]
`else`
	Guettez l'indicateur, puis appuyez sur **Ctrl** ou le **Clic Molette**.
	>!Comme ça?
	>	`steward,r,cheery`
	>	Oui, Parfait!
	>	[[#interjectionDone]]

...
`steward,r,annoyed`
J'ai *dit*, repérez l'indicateur.

>!Oh, j'ai compris.
>	`steward,r,neutral`
>	Merveilleux.
>	[[#interjectionDone]]

...
`if gamepad`
	`unskip`**Touche Y**. *Cet*. *Indicateur*. --->
	>!Compris!
	>	`unskip`
	>	Jamais deux sans trois, hein?
	>	[[#interjectionDone]]
`else`
	`unskip`**Ctrl** ou **Clic Molette**. *Cet*. *Indicateur*. --->
	>!Compris!
	>	`unskip`
	>	Jamais deux sans trois, hein?
	>	[[#interjectionDone]]

`unskip``steward,r,giveUp`
Bon, tant pis. J'abandonne.

`steward,l,bowing`
Allons, allons.
`steward,l,reassuring`
Je suis certain que vous apprendrez à saisir ces occasions quand ça comptera.
## interjectionDone
`steward,l,neutral`
Bien, votre aventure va bientôt commencer.
`steward,l,neutral`
Prenez le temps de gérer les affaires pressantes et de préparer votre espace de jeu.

>Tout est prêt.

Excellent.
# connectionStart
`steward,l,neutral`
Nous allons maintenant vous connecter au Diorama.

`if gamepad`
	Dans un instant, accrochez fermement votre manette. Détendez-vous, inspirez profondément, puis expirez en enfonçant les deux sticks analogiques.
`else`
	Dans un instant, placez vos deux mains au-dessus du clavier. Détendez-vous, inspirez profondément, puis expirez en appuyant longuement sur la barre d'espace.

`c, meditationStart`

`x`

## forgotToBreathe
`c,meditationFailed`
`steward,l,neutral`
`steward,r,distracted,neutral`
Hé, réveillez-vous!
`steward,r,giveUp`
Ça va? Vous ne répondiez plus pendant un moment.
C'était impossible de savoir si vous respiriez correctement...
`steward,r,neutral`
`if gamepad`
	Rappelez-vous, quand l'écran devient noir : accrochez les sticks fermement avec les pouces. Inspirez profondément, puis appuyez et *maintenez*.
`else`
	Rappelez-vous, quand l'écran devient noir : les mains au-dessus de la barre d'espace. Inspirez profondément, puis appuyez et *maintenez*.

`c,meditationStart`
`x`
## connectionFailed
`c, meditationFailed`
`steward,r,neutral`
`steward,l,irked,neutral`
Connexion échouée...

`steward,r,neutral`
`if gamepad`
	Rappelez-vous, quand l'écran devient noir : accrochez les sticks fermement avec les pouces. Inspirez profondément, puis appuyez et *maintenez*.
`else`
	Rappelez-vous, quand l'écran devient noir : les mains au-dessus de la barre d'espace. Inspirez profondément, puis appuyez et *maintenez*.
`steward,r,giveUp,neutral`
*Et ne touchez à rien d'autre.*

`c,meditationStart`
`x`
## connectionComplete

`c,dioramaEntry, false`
`steward,r,neutral`
`steward,l,neutral`
`auto,2`Connexion établie!

`auto,1.75``steward,r,cheery`Bonne chance!

`steward,l,neutral`Et rappelez-vous, ce que vous donnez vous sera rendu.
`speed,0.1``auto,0.25`Nous nous reparlerons bientôt.

`x`

# loaded
`steward,l,neutral`
`steward,r,neutral`
`if demoCompleted`
	[[#loadPostDemo]]
`else`
	[[#loadMidDemo]]
## loadPostDemo
`steward,r,presenting,neutral`
Oh! Vous êtes de retour.
`if !demoContinued`
	`steward,r,cheeky`
	Vous succombez à l'envie de savoir s'il y en a plus?
	`steward,r,giveUp`
	La réponse est... pas vraiment.
	À ce compte, nous pourrions toujours vous renvoyer au début.
	Ou bien vous faire reprendre là où vous en étiez...
	[[#returnedAfterCompletion]]
Envie de continuer? Ou de recommencer?
>Continuer.
>	`steward,r,cheery`
>	C'est parti!
>	[[#continue]]
>Recommencer.
>	[[#reset]]
## loadMidDemo
Bon retour!
`if !seen`
	`steward,r,presenting,giveUp`
	C'est étonnant, nous avions prévu que la plupart des gens arriveraient à terminer cette démo en une seule session.
	`steward,r,neutral`
	Mais je comprends, le monde extérieur est chargé.
	`steward,r,giveUp`
	Et les accidents arrivent aussi...
`steward,l,neutral`
Préférez-vous reprendre là où vous en étiez, ou tout recommencer?
>Continuer.
>	`steward,r,cheery`
>	C'est parti!
>	[[#continue]]
>Recommencer.
>	[[#reset]]
## continue
`steward,r,neutral`
Prêts à y aller. Et vous?
>!Pas d'exercice de respiration?
>	`steward,r,cheery`
>	Aha!
>	`steward,l,reassuring`
>	Nous avons constaté qu'après l'harmonisation initiale, ces exercices ont des rendements décroissants.
>	`steward,r,neutral`
>	Mais libre à vous d'en refaire un si vous voulez!
>	...
>	`steward,r,presenting,neutral`
>	Bon, enfin prêts?

3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`

## reset
`steward,l,bowing`
Très bien.
`steward,l,neutral`
Sachez que, hormis vos paramètres système, cela réinitialisera entièrement cette démo.
Nous devrons alors faire connaissance avec vous une fois de plus, nous aussi.
Souhaitez-vous quand même aller de l'avant?
>Oui.
>	Compris.
>	Au revoir, alors.
>	`steward,r,cheery`
>	À la prochaine!
>	`steward,r,neutral`
>	3...2...1...
>	`c,demoReset,false`
>	`x`
>Non, laissez tomber.
>	`steward,r,neutral`
>	D'accord, nous vous ferons simplement reprendre là où vous en étiez.
>	[[#continue]]

# outro
`steward, l, neutral`
`steward, r, cheery, neutral`
Et... c'est tout pour cette démo!

>Quoi? Non!
>	`steward,r,giveUp`
>	Eh oui. C'est malheureusement tout ce que nous pouvons offrir sans financement supplémentaire.
>	[[#funding]]
>Ohh...
>	`steward,r,giveUp`
>	Oui, c'est bien triste.
>	Mais c'est tout ce que nous pouvons offrir sans financement supplémentaire.
>	[[#funding]]
>Dieu merci.
>	`steward,r,annoyed`
>	Hein? Vous avez quelque chose à dire?
>	`steward,l,irked,neutral`
>	Allons, allons.
>	`steward,l,neutral`
>	Nos développeurs seraient ravis de recevoir toute critique constructive.
>	`steward,l,presenting,neutral`
>	Cependant, pardonnez ma curiosité, mais si cette démo ne vous a pas plu, pourquoi y avoir passé autant de temps?
>	>Je plaisantais.
>	>	`steward,r,cheery`
>	>	Ouf! Ravie de l'entendre!
>	>	`steward,r,distracted`
>	>	Ce boulot est déjà assez dur comme ça...
>	>Quelqu'un d'autre me l'a demandé.
>	>	`steward,l,bowing`
>	>	Ah, eh bien, nous espérons au moins avoir servi à vous aider à mieux les comprendre, ne serait-ce qu'un peu.
>	>	S'il vous plaît, transmettez-leur nos remerciements.
>	>C'est mon travail.
>	>	`steward,l,irked,neutral`
>	>	A-ah, je vois. Eh bien, sachez que nous apprécions profondément le temps que vous avez consacré...
>	>	`steward,l,neutral`
>	>	...et toute publicité qui pourrait en découler.
>	>	`steward,r,cheery`
>	>	On prend ce qu'on peut!
>	>	`steward,r,neutral`
>	>	Si jamais ça pouvait éventuellement finir par être pertinent avec votre métier : dioramabreak.com/presskit
>	`steward,l,neutral`
>	Bien, nous ne prendrons pas plus de votre temps.
>	`steward,r,cheery`
>	Merci d'avoir joué!
>	[[#moreContentChoice]]
>	`x`
>Ok, je comprends.
>	`steward,r,neutral`
>	Oui, c'est tout ce que nous pouvons offrir sans financement supplémentaire.
>	[[#funding]]
>Mais qu'arrivera-t-il à Pro et Minima!?
>	`steward,r,presenting,giveUp`
>	Hm, pas grand-chose sans financement supplémentaire.
>	`steward,r,giveUp`
>	Cette démo a déjà coûté assez cher à produire...
>	[[#funding]]

## funding

`if ksCheck=="pre"`
	`steward,r,neutral`
	D'ailleurs, en parlant de ça...
	`steward,r,cheery`
	Nous lançons un Kickstarter le 28!
	[[#ksChoice]]
`else if ksCheck=="ongoing"`
	`steward,r,neutral`
	D'ailleurs, en parlant de ça...
	`steward,r,cheery`
	Nous avons un Kickstarter en cours *en ce moment même*!
	[[#ksChoice]]
`else`
	`steward,r,giveUp`
	Dommage que vous ayez raté le Kickstarter.
	`steward,r,cheery,neutral`
	Mais ne vous inquiétez pas, tout va bien pour nous!
	`steward,r,giveUp,neutral`
	Du moins, j'espère. On n'a pas de wifi ici.
	`steward,r,presenting`
	Mais *vous* pouvez tout lire en ligne! dioramabreak.com!
	`steward,l,neutral`
	Oui, si vous avez apprécié votre moment aujourd'hui, tout engagement serait apprécié.
	Mais ne vous perdez pas dans les méandres des distractions de l'internet. 
	Une recommandation sincère faite à un ami, c'est qu'il y a de plus précieux pour nous.
	`steward,r,cheeky`
	...sauf, peut-être, un late pledge sur notre page Kickstarter.
	`steward,l,irked`
	Hum.
	`steward,l,neutral`
	Ne vous méprenez pas :
	`steward,l,reassuring`
	Par-dessus tout, nous vous sommes extrêmement reconnaissants d'avoir pris le temps de jouer à cette démo jusqu'au bout.
	[[#signOff]]

## ksChoice
>Je sais.
>	`steward,r,cheeky`
>	C'est à croire que rien ne vous échappe!
>	`steward,l,sternRight`
>	Oui, nous sommes ravis d'apprendre que vous étiez déjà au courant.
>	`steward,l,bowing`
>	Nous vous remercions de votre intérêt.
>	`steward,r,cheery`
>	N'oubliez pas d'en parler à vos amis! dioramabreak.com!
>	`steward,l,reassuring`
>	Bien sûr.
>	Une recommandation sincère faite à un ami; c'est ce qu'il y a de plus précieux pour nous.
>	Mais par-dessus tout, nous vous sommes extrêmement reconnaissants d'avoir pris le temps de jouer à cette démo jusqu'au bout.
>Oh, dites-m'en plus.
>	`steward,l,neutral`
>	La campagne se déroulera du 28 avril au 29 mai 2026.
>	`steward,l,presenting`
>	Un certain nombre de récompenses en édition limitée seront disponibles, y compris la chance de contribuer des designs pour la version intégrale du jeu.
>	`steward,r,cheery,presenting`
>	Allez voir ça! dioramabreak.com!
>	`steward,l,neutral`
>	En fin de compte, toute contribution que vous déciderez de faire sera essentielle pour nous aider à réaliser le plein potentiel de ce projet.
>	`steward,l,reassuring`
>	Même si vous ne pouvez pas faire de don, une recommandation sincère à un ami ferait déjà beaucoup de chemin.
>	`steward,r,cheery`
>	Oui, et plus ledit ami est riche, mieux c'est!
>	`steward,l,irked`
>	Hum.
>	`steward,l,neutral`
>	Ne vous méprenez pas :
>	`steward,l,reassuring`
>	Par-dessus tout, nous vous sommes extrêmement reconnaissants d'avoir pris le temps de jouer à cette démo jusqu'au bout.
>Ça ne m'intéresse pas.
>	`steward,r,annoyed`
>	`a,0.2`Oh vrai-
>	`steward,l,irked``a`Alors nul besoin d'insister.
>	`steward,l,neutral`
>	Reste que si vous avez passé un bon moment aujourd'hui, nous vous invitons à passer le mot auprès des autres; cela nous aiderait grandement.
>	`steward,l,reassuring`
>	Une recommandation sincère à un ami ferait certainement beaucoup de chemin.
>	`steward,r,presenting`
>	Ou si vous n'avez pas aimé, pourquoi ne pas faire une recommandation fourbe à un ennemi juré?
>	`steward,l,sternRight`
>	Quoi qu'il en soit...
>	`steward,l,reassuring`
>	Nous vous sommes, par-dessus tout, extrêmement reconnaissants d'avoir pris le temps de jouer à cette démo jusqu'au bout.

## signOff
`steward,r,cheery`
C'est tout alors!
À bientôt!
`steward,r,annoyed`
...enfin j'espère.
## moreContentChoice

>Au revoir!
>	`x`
>C'est vraiment tout? Il n'y a plus rien, après?
>	[[#moreContent]]
## moreContent

`steward,r,distracted`
Eh bien... pas vraiment...
`steward,r,giveUp`
Mais si insistez pour continuer à courir partout, nous pouvons toujours vous renvoyer au début.
Sinon, vous faire reprendre là où vous en étiez.
## returnedAfterCompletion
`steward,r,neutral`
Qu'avez-vous décidé?
>Remettez-moi dedans.
>	`steward,r,cheery`
>	Bien sûr.
>	`steward,r,neutral`
>	Mais il va falloir me laisser parler un moment.
>	>Compris.
>	>Que voulez-vous dire? Comment?
>	>	`steward,r,presenting,neutral`
>	>	Héhé.
>	>	Qui pensez-vous a choisi vos options de dialogue depuis le début?
>	>	>Oh, je vois.
>	>	>Moi...?
>	>	>	`steward,r,cheeky`
>	>	>	Oh vraiment?
>	>	>	>Oh, effectivement, bien sûr que c'était vous. Vous êtes tellement cool, intelligent et travailleur.
>	>	>	>	`steward,l,irked`
>	>	>	>	Hum.
>	>	>	>	`steward,r,cheery`
>	>	>	>	Héhé!
>	`steward,r,cheery`
>	Continuons alors.
>	`steward,r,neutral`
>	3...2...1...
>	`gameLoad`
>	`x`
>Recommencer.
>	`steward,l,neutral`
>	Très bien.
>	Sachez que, hormis vos paramètres, cela réinitialisera entièrement cette démo.
>	Nous devrons alors faire connaissance avec vous une fois de plus, nous aussi..
>	Souhaitez-vous quand même aller de l'avant?
>	>Oui.
>	>	`steward,l,bowing`
>	>	Compris.
>	>	`steward,l,neutral`
>	>	Au revoir, alors.
>	>	`steward,r,cheery`
>	>	À la prochaine!
>	>	`steward,r,neutral`
>	>	3...2...1...
>	>	`c,demoReset,false`
>	>	`x`
>	>Non, tant pis.
>	>	`steward,l,bowing`
>	>	Compris.
>	>	`steward,l,reassuring`
>	>	À la prochaine fois, alors.
>	>	`steward,r,cheery`
>	>	Au revoir!
>	>	`x`
## demoContinues
`c,demoContinues`
![[minimaSmile.png]]
-th !

>Attendez!

![[minimaSurprised.png]]
?

>Il faut faire demi-tour. Vous ne pouvez pas quitter la forêt.

![[minimaSkeptical.png]]
Pourquoi...?

>Faites-moi confiance, on pourra partir à l'aventure plus tard, mais ne quittez pas la forêt pour l'instant.

`if !proBladeShattered`
	![[minimaSkeptical.png]]
	Mais-
	![[proMeditating.png]]
	D'accord.
	![[minimaSurprised.png]]
	Quoi?
	![[pro.png]]
	Il doit y avoir une bonne raison, non?
	>Oui! Il y a clairement une bonne raison!
	![[proCynical.png]]
	Je... ne posais pas la question, mais d'accord.
	![[pro.png]]
	Je te fais confiance.
	![[minimaSheepish.png]]
	B-bon, d'accord. On doit attendre combien de temps ?
	>Difficile à dire. Ça dépend du calendrier de sortie.
	![[minimaMildlyAnnoyed.png]]
	Quoi?
	>Oubliez ça.
	![[minimaSkeptical.png]]
	???
	![[proAnnoyed.png]]
	Allez, viens.
	![[proRollingEyes.png]]
	Je voulais faire une pause de toute façon.
	![[minimaAnnoyed.png]]
	B-bon. C'est pas comme s'il n'y avait pas un autre camp juste devant mais... d'accord, on fait demi-tour.
`else`
	![[proCynical.png]]
	Ça ne m'inspire pas du tout confiance.
	Après... je devrais probablement aller faire réparer mon épée.
	![[minima.png]]
	Ah, bonne idée.
	À ce rythme, je finirai par voir ce pour quoi je suis venue!
	J'avoue que ça m'intrigue quand même.
	![[pro.png]]
	C'est rien de spécial, je t'assure.

`c, demoContinued`
`x`
# paxDemo
`c,prologueStart`
`steward,l,neutral`
`steward,r,presenting,neutral`
Salut!
`steward,l,neutral`
Bienvenue dans la démo de Diorama Break.
`steward,r,cheery,neutral`
Oui, plus précisément, la version hyper exclusive Ne-nous-jugez-pas-c'est-pas-fini en playtest!
`steward,l,reassuring`
Merci de passer un moment avec nous.
`steward,r,cheery`
Pour de vrai!
`steward,r,cheeky`
`a,0.1``speed,1`Personnellement, je ne pourrais pas m'imaginer consacrer autant de mon temps juste pour jouer à un tas de jeux inachev-`speed`
`steward,l,irked`Hum.
`a``steward,r,cheery`Aha. Je veux dire, euh, qu'est-ce qui a attiré votre regard, au fait?
>J'essaie tout ce qui est ici!
>	`steward,r,giveUp`
>	Mm. Je me sens un peu mal d'apparaître à un événement étudiant.
>	On a quand même eu bien plus de temps et d'argent à dépenser.
>	`steward,r,distracted`
>	Tellement d'argent dépensé...
>	`steward,l,reassuring`
>	Allons, allons. Il y aura certainement quelque chose de valeur à trouver dans chaque jeu ici.
>J'ai aimé l'illustration du poster.
>	Merci beaucoup! Nos artistes sont très talentueux, oui.
>	`steward,r,cheeky`
>	Comme en témoigne la présente compagnie.
>	`steward,l,neutral`
>	Cependant, nous devons avertir...
>	`steward,r,giveUp,neutral`
>	Ah, oui.
>	`steward,r,neutral`
>	Comme vous l'avez peut-être remarqué, votre expérience réelle aujourd'hui sera un peu plus... stylisée.
>	J'espère que ça vous convient.
>	>C'est super! J'adore le pixel art!
>	>Ça me va, je comprends le concept.
>	>	`steward,r,cheery`
>	>	Merveilleux!
>	>Oh.
>	>	`steward,l,irked,neutral`
>	>	Nous- vous invitons néanmoins à continuer.
>	>	`steward,l,reassuring`
>	>	Vous pourriez être agréablement surpris.
>J'ai vu quelqu'un d'autre jouer.
>	`steward,r,giveUp`
>	Oh, première impression gâchée alors.
>	`steward,r,cheery,neutral`
>	Autant avancer vite!
>	`steward,l,neutral`
>	Oui.
>J'ai vu le teaser en ligne et je voulais essayer!
>	`steward,r,cheery,neutral`
>	Oh wow, un superfan par ici!
>	`steward,r,cheeky`
>	Je suis un peu nerveuse...
>Un des devs m'a demandé de l'essayer.
>	`steward,r,giveUp`
>	Aïe, quelle gêne.
>	`steward,r,presenting,neutral`
>	À bien y penser, vous avez la chance de vous y lancer à l'aveugle. Palpitant!

`steward,l,neutral`
Bien.
`steward,l,presenting`
Devant nous se dresse le Diorama.

`steward,r,presenting`
Un monde rempli d'aventure, de mystère et de tragédie!
Insufflé de vie dans l'insterstice qui règne entre votre esprit et l'écran!

`steward,l,presenting,neutral`
Vous guiderez un habitant choisi à travers une épopée qui changera ledit monde.

>Ça a l'air bien!
>Ça a l'air nul.
>	`steward,r,annoyed,neutral`
>	Libre à vous de partir alors. Levez-vous et partez! Tout de suite!
>	...
>	`steward,r,cheeky`
>	Ha! Vous n'y arrivez pas.
>	Essayez de bluffer quelqu'un de votre taille la prochaine fois!
>	`steward,r,giveUp,neutral`
>	Euh, métatextuellement parlant, enfin.
>	`steward,l,irked,neutral`
>	...
>	Poursuivons.
>« Changer »? Ce jeu ne s'appelle pas Diorama *Break*?
>	`steward,r,cheery`
>	Oh oui!
>	`steward,r,presenting,neutral`
>	`auto,0.1`C'est quoi le truc, d'ailleurs? On va prendre un marteau et casser ce tr-
>	`auto``steward,l,sternRight,neutral`On ne touche à rien.
>	`steward,l,stern`
>	Les seules « ruptures » qui auront lieu ici seront d'ordre métaphorique.
>	`steward,l,irked,neutral`
>	Maintenant, comme je disais...

`steward,l,neutral`
Nous servirons, en retour, de guides et d'intendants pour *vous* appuyer dans cette entreprise.
`steward,l,bowing`
Ne vous en faites pas cependant, vous ne sentirez guère notre présence.

`steward,r,presenting,neutral`
Oui, on sera très discrets.
`steward,r,cheeky`
Vous pourrez alors semer la pagaille comme bon vous semble.

`steward,l,reassuring`
Naturellement. Cependant, certains contrôles méritent une explication.
`steward,l,presenting,neutral`
Prenez ce dialogue, par exemple. De toute évidence, vous maîtrisez les commandes de base...
Mais saviez-vous que vous pouvez utiliser le Clic droit ou Shift pour avancer le dialogue plus vite? Essayez maintenant`speed, 0.1`. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .`speed`

`steward,r,cheery`
Bien joué!
`steward,r,neutral,presenting`
Voici un autre truc intéressant :
`steward,r,presenting`
Parfois, vous aurez la possibilité d'intervenir pendant le dialogue!
`steward,r,neutral`
Repérez l'indicateur, puis appuyez sur le clic molette.

>!Comme ça?
>	`steward,r,cheery`
>	Oui! Bien joué!
>	[[#interjectionDonePax]]

...
`steward,r,annoyed`
J'ai *dit*, guettez l'indicateur.

>!Oh, j'ai compris.
>	`steward,r,neutral`
>	Merveilleux.
>	[[#interjectionDonePax]]

...
`unskip`Clic molette. *Cet*. *Indicateur*. --->

>!Compris!
>	`unskip`
>	Jamais deux sans trois, hein?
>	[[#interjectionDonePax]]

`unskip``steward,r,giveUp`
Bon, tant pis. J'abandonne.

`steward,l,bowing`
Allons, allons.
`steward,l,reassuring`
Je suis certain que vous apprendrez à saisir ces occasions quand ça comptera.

## interjectionDonePax

`steward,l,neutral`
Bien, votre aventure va bientôt commencer.
`steward,l,presenting`
Mais d'abord, votre esprit et votre corps doivent être correctement harmonisés.
`steward,l,neutral`
Je comprends que c'est plus compliqué dans un environnement achalandé, mais tâchez néanmoins de focaliser votre attention et d'ignorer toute distraction.

>Tout est prêt.

Excellent.
Nous allons maintenant vous connecter au monde à l'intérieur du Diorama.

`steward,r,neutral`
Dans un instant, placez vos deux mains au-dessus de la barre d'espace. Détendez-vous, inspirez profondément, puis maintenez-la enfoncée en expirant.

`c, meditationStart`

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
