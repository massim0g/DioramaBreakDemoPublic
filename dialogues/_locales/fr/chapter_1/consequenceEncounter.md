# warnPro
![[pro.png]]
-ien, allons-y.
>Tu es sur le point de tomber dans une embuscade.
>	`warnedProAboutConsequence`
>	`gameSave`
>	![[proMildSurprise.png]]
>	(Hein? Maintenant?)
>	>Dès que tu franchis la lisière de la forêt, quelque chose t'attaque par derrière. Tiens-toi prêt.
>	>	![[proMildSurprise.png]]
>	>	(...)
>	>	![[pro.png]]
>	>	(... D'accord.)
>	>	![[proHidingSomething.png]]
>	>	(...)
>	>	![[proSkeptical.png]]
>	>	(Comment tu sais ça?)
>	>	>J'ai pas pu te garder en vie. Le monde se réinitialise au dernier passage à une Fixation quand tu meurs.
>	>	>	`proAff-=4`
>	>	>	`resetsKnown`
>	>	>	![[proMildSurprise.png]]
>	>	>	(Qu-)
>	>	>	![[proFrustrated.png]]
>	>	>	Comment ça t'as pas pu me garder en vie!?
>	>	>	![[minimaSurprised.png]]
>	>	>	!
>	>	>	Pro? Qu'est-ce qu'il y a?
>	>	>	![[proFrustrated.png]]
>	>	>	Pas maintenant Minima, je parle à `$player`.
>	>	>	(Est-ce que je vais mourir si je retourne là-bas?)
>	>	>	>T'inquiète, ça n'arrivera plus.
>	>	>	>	Et comment tu le *sais*?
>	>	>	>	>Ben, maintenant on sait que ça arrive.
>	>	>	>	>	`proAff+=2`
>	>	>	>	>Euh...
>	>	>	>	>De la magie.
>	>	>	>	[[#timeTravelIsAnnoying]]
>	>	>	>C'est possible. Pourquoi tu crois que je te préviens?
>	>	>	>	`proAff+=5`
>	>	>	>	[[#timeTravelIsAnnoying]]
>	>	>	>Penses-y un peu. Tant que je suis là, tu ne peux jamais vraiment mourir.
>	>	>	>	`proAff+=2`
>	>	>	>	(Je...)
>	>	>	>	(J'ai du mal à saisir...)
>	>	>	>	(J'imagine que tout baigne dans ce cas? Reste que j'ai l'impression que quelque chose ne tourne pas rond.)
>	>	>	>	[[#minimaCutsInDuringWarningB]]
>	>	>Je peux voir l'avenir parfois.
>	>	>	![[proSkeptical.png]]
>	>	>	(Je... vois.)
>	>	>	![[proCynical.png]]
>	>	>	(Tiens-moi au courant alors, ok?)
>	>	>	[[#minimaCutsInDuringWarningA]]
>	>	>De la magie.
>	>	>	`proAff-=1`
>	>	>	![[proCynical.png]]
>	>	>	(Ouais ouais...)
>	>	>	(Je me demande ce que Minima dirait de ça...)
>	>	>	![[minima.png]]
>	>	>	...?
>	>	>	[[#minimaCutsInDuringWarningA]]
>...

`x`
## timeTravelIsAnnoying
![[proAnnoyed.png]]
(Agh...)
![[proStressed.png]]
(Donc... si tu peux vraiment remonter le temps, ça veut dire que tout baigne?)
![[proAnnoyed.png]]
(Y'a un truc qui me chicote là-dedans.)
[[#minimaCutsInDuringWarningB]]
## minimaCutsInDuringWarningA

![[minima.png]]
Pro? Qu'est-ce qui ne va pas?

![[proNonchalant.png]]
Ça va. C'est rien.
![[proThinking.png]]
(C'est pas comme si elle pouvait rendre ton avertissement plus crédible.)

![[minimaCheeky.png]]
Oh, tu communiais avec ton Mécène? On t'a *dévoilé* quelque chose?

![[proAnnoyed.png]]
Quelque chose dans le genre...

`x`

## minimaCutsInDuringWarningB
![[minimaApprehensive.png]]
... Pro? Tu m'inquiètes un peu.
![[proAnnoyed.png]]
Tout va bien, allons-y.
(C'est pas comme si elle pouvait rendre ton avertissement plus crédible.)
![[minimaConflicted.png]]
... D'accord.

`x`

# ambushStart
![[minimaSurprisedSmile.png]]
Oh! Je vois le rivage!

`c,minimaRunsAhead`

`if warnedProAboutConsequence`
	[[#proWarned]]

`c,ambushStart`
`x`

## ambushStarted

![[proMildSurprise.png]]
(!?)
(Qu'est-ce qui se passe?)

>Je sais pas.
>	![[proSkeptical.png]]
>	(On se fait attaquer?)
>On est en combat.
>	![[proSkeptical.png]]
>	(Contre quoi?)

![[proStressed.png]]
(...)
(D'ici, j'arrive pas à voir ce qu'on affronte.)

>Je vais regarder.
>...

`x`

## ambushCheckedAttack
![[proMildlyStressed.png]]
(Alors?)
>J'arrive pas à voir, non plus.
>	![[proStressed.png]]
>	(Par pitié, fais quelque chose!)
>Je crois pas pouvoir esquiver cette attaque...
>	![[proStressed.png]]
>	(Hein!? Quelle attaque?)
>	![[proFrustrated.png]]
>	(Par pitié, fais quelque chose!)

`x`
## proWarned
![[proHidingSomething.png]]
(... Maintenant?)
>Ouais.
>	![[proDetermined.png]]
>	(Ok.)
>Encore un peu.
>	![[proMildlyStressed.png]]
>	`a,0.4`(Laissons-leur pas le temps-!)
>	`a`

`c,ambushStart`
`x`
## consequenceAppears

`c,ambushEnd`

![[consequenceShouting.png]]
Trêve! Entamons les pourparlers!

`c,cameraSnapsToPro`

![[proMildlyStressed.png]]
...
`p,1`
![[proStressed.png]]
(Pourquoi le temps n'est pas figé?)
## timestop
>Peut-être parce qu'il ne veut pas se battre.
>	![[proAnnoyed.png]]
>	(C'est vraiment comme ça que ça marche? Il vient d'essayer de me tuer!)
>Je sais pas.
>	`proAff-=1`
>	![[proAnnoyed.png]]
>	(C'est pas toi qui le contrôles?)

[[#timestopEnd]]


## timestopEnd
![[proStressed.png]]
(...)
![[proAnnoyed.png]]
(Écoutons ce qu'il a à dire...)

`c,proPutsSwordAway`

![[proDetermined.png]]
Très bien.

`c,cameraSnapsToConsequence`

![[consequence.png]]
...

`c,consequenceWalksToPro`

![[consequenceEyesClosed.png]]
Héros. Je vous demande pardon.
![[consequence.png]]
J'avais l'intention candide de vous neutraliser sans délai
et de vous épargner une fâcheuse échauffourée, à vous et votre compagne.

`if resetsKnown && warnedProAboutConsequence`
	![[proSkeptical.png]]
	(Tu viens pas de dire qu'il m'avait tué? Donc, il ment éhontément?)
	>Ouaip.
	>	`proAff+=0.5`
	>	![[proRollingEyes.png]]
	>	(Ah. Et dire qu'il avait l'air digne de confiance.)
	>Tu es mort sur le coup... mais peut-être qu'il voulait se retenir?
	>	![[proCynical.png]]
	>	(Mouais...)

![[consequenceEyesClosed.png]]
J'ai échoué, par malheur. Mais maintenant que vous prêtez l'oreille, nous parviendrons peut-être
à nous soustraire à la rudesse inéluctable de la violence et à trouver un terrain d'entente.
![[proAnnoyed.png]]
... « Peut-être » vous dites?

![[consequence.png]]
Mes « employeurs », pour ainsi dire, ont résolu de précipiter le cours de vos activités vers sa finalité incessante et définitive.

![[minimaMildlyAnnoyed.png]]
Qui? Pourquoi?

![[consequenceEyesClosed.png]]
Je n'ai pas le loisir de le divulguer.
![[consequence.png]]
Je prends la parole devant vous à cette heure pour vous offrir l'occasion unique d'accepter votre reddition sans conditions.
![[consequenceAnnoyed.png]]
Ne vous y méprenez pas, la présente ne constitue pas une *demande*.
![[consequence.png]]
J'ai épié vos affrontements. Votre aptitude est remarquable, voire inhumaine, ma foi...
...Nonobstant, vous ne ferez pas le poids contre moi.

![[proMocking.png]]
Ah, bon?

![[consequenceEyesClosed.png]]
Si fait.
![[consequence.png]]
`c,consequenceStepsForward, false`
`a,0.3`J'énonce maintenant mes modalités, qui vont comme sui-
`a`

![[minimaShouting.png]]
`flag, consequenceStops`Stop!
Restez où vous êtes.

![[consequenceAnnoyed.png]]
...
![[consequence.png]]
Mes conditions pour vous deux vont comme suit :
Posez les armes. Retournez dans vos communautés. Ne repartez jamais.
Si vous le faites, je vous tuerai.

`p,0.8`

![[proMocking.png]]
Vous êtes sérieux?

![[consequence.png]]
J'offre même de vous y raccompagner...
...et de vous garder sous surveillance à perpétuité.

![[proAnnoyed.png]]
Non, je-
![[proDisdainful.png]]
Vous imaginez quand même pas que je vais gober ça?

![[consequenceEyesClosed.png]]
Je m'en doutais.
Mais je ne perdais rien à le demander.
![[consequence.png]]
Minima?

![[minimaStressed.png]]
L-laissez-moi parler à Pro.

![[consequence.png]]
... Vous avez cinq minutes. N'essayez pas de fuir.

`c,proAndMinimaHuddle`

![[proDisdainful.png]]
Alors, euh, on m'a pas prévenu pour les monstres qui parlent.

![[minimaStressed.png]]
N-non. Je n'ai aucune idée de ce qu'il est.
Mais tu soulèves un bon point. Quel genre d'humain menacerait de tuer quelqu'un?

![[proThinking.png]]
(Hm...)

>Je pourrais en citer quelques-uns...
>	![[proRollingEyes.png]]
>	En fait, historiquement...
>	![[minimaAnnoyed.png]]
>	Ouais d'accord, mais de nos jours ça n'a de sens pour personne. Aucun groupe connu, du moins.
>J'ai rien.
>	![[proCynical.png]]
>	(Utile comme toujours.)
>	Désolé, je saurais pas dire.
>	![[minimaStressed.png]]
>	En plus, ça n'a de sens pour personne. Aucun groupe connu, du moins.

![[minimaMildlyAnnoyed.png]]
Et il est bien trop... posé pour être un quidam illuminé.

![[proConflicted.png]]
Super.
(On fait quoi, alors?)

>Vous devriez vous battre tous les deux.
>	`proAff+=1`
>	![[proMildlyConflicted.png]]
>	`a,0.3`(Vraiment? Elle va faire comment, pour le-)
>	![[minimaMildlyAnnoyed.png]]`a`Je pense qu'on devrait l'affronter.
>	![[proMildSurprise.png]]
>	Hein?
>	[[#minimasPlanVariantB]]
>Minima devrait fuir.
>	`proAff+=1`
>	![[proMildlyConflicted.png]]
>	(O-ouais.)
>	![[pro.png]]
>	Je pense que tu devrais filer d'ici.
>	![[minimaMildlyAnnoyed.png]]
>	Je suis pas d'accord.
>	Il a dit que c'est *toi* qu'il a vu en combat. Il sait pas de quoi mon équipement est capable. Enfin, sûrement pas.
>	Si tu veux en finir vite avec lui, tu ferais mieux de compter sur moi.
>	![[proMildSurprise.png]]
>	Attends, tu veux te battre?
>	![[minimaConflicted.png]]
>	...
>	[[#minimasPlanVariantB]]
>Vous devriez fuir tous les deux.
>	![[proHidingSomething.png]]
>	(...)
>	On devrait essayer de s'enfuir.
>	![[minimaMildlyAnnoyed.png]]
>	Non.
>	[[#minimasPlanVariantA]]
>Tu devrais faire couvrir par Minima pendant que tu fuis.
>	`proAff-=1`
>	![[proBemused.png]]
>	(Ha, quoi? Comment?)
>	![[proAnnoyed.png]]
>	(Laisse tomber. Je vais lui demander directement.)
>	![[pro.png]]
>	À ton avis, on devrait faire quoi?
>	![[minimaConflicted.png]]
>	Hm...
>	[[#minimasPlanVariantA]]

## minimasPlanVariantA
![[minimaConflicted.png]]
Ça n'a pas de sens pour d'aussi fort que ce qu'il prétend de discuter avec nous comme ça.
Ce combat doit être plus risqué pour lui que ce qu'il laisse transparaître si ça se trouve...
`a,0.3`Fais-le parler. Tant qu'il reste au même endroit assez longtemps, je peux-

![[proMildSurprise.png]]`a`Attends, tu veux te battre?

![[minimaLookingAway.png]]
...

![[minimaMildlyAnnoyed.png]]
Il a dit que c'est *toi* qu'il a vu en combat. Il sait pas de quoi mon équipement est capable. Enfin, sûrement pas.
Si tu veux en finir vite avec lui, tu ferais mieux de compter sur moi.

![[minimaBemused.png]]
... Et puis, tu t'imagines céder à une menace pareille? Ce serait la honte!

![[proSoftSmile.png]]
Heh, t'as bien raison.
![[pro.png]]
Alors, j'ai juste à lui parler?

![[minimaMildlyAnnoyed.png]]
Ouais... juste une minute environ. Mets-toi devant moi pour qu'il voie pas ce que je fais.
[[#proConfrontsConsequence]]

## minimasPlanVariantB
![[minimaConflicted.png]]
Ça n'a pas de sens pour d'aussi fort que ce qu'il prétend de discuter avec nous comme ça.
Ce combat doit être plus risqué pour lui que ce qu'il laisse transparaître si ça se trouve...
![[minimaBemused.png]]
... Et puis, tu t'imagines céder à une menace pareille? Ce serait la honte!
![[proSoftSmile.png]]
Heh, t'as bien raison.
![[minimaLecturing.png]]
T'as qu'à le faire parler encore un peu. Tant qu'il reste au même endroit assez longtemps, je peux le cogner. Fort.
![[minimaMildlyAnnoyed.png]]
Mets-toi devant moi pour qu'il voie pas ce que je fais.
[[#proConfrontsConsequence]]

## proConfrontsConsequence
![[proDetermined.png]]
Compris.

`c,proConfrontsConsequence`

![[proDetermined.png]]
Hé!

![[consequence.png]]
Vous avez changé d'avis?

![[proNonchalant.png]]
Peut-être.
![[proMocking.png]]
Votre discours est un peu léger, par contre.
Pourquoi je vous ferais confiance? Je connais même pas votre nom.

`c,minimaReadiesAttack,false`

![[consequence.png]]
Encore une fois, je n'ai pas le loisir de vous dire quoi que ce soit.

![[proRollingEyes.png]]
Vraiment? Rien du tout? J'hésite vraiment là.

![[consequenceQuestioning.png]]
J'estimais qu'entre tous les villages, le vôtre serait à même de comprendre l'importance manifeste de la sécurité opérationnelle.

![[pro.png]]
...

![[consequence.png]]
...
![[consequenceEyesClosed.png]]
Mon nom est Consequence.

![[proRollingEyes.png]]
Ooh, l'épouvante.

![[consequenceAnnoyed.png]]
Cet exercice est futile. Vous pensez que je bluffe.
![[consequenceEyesClosed.png]]
`a,0.2`Il semble-
`a`
`c,minimaAttacksConsequence`
![[consequence.png]]
-qu'une démonstration s'impose.

`c,consequenceFightStart`
`x`
## consequenceHitsPro
![[proHit.png]]
Aïe!

![[proStressed.png]]
(Je crois pas qu'on puisse se permettre de prendre des coups ici!)
(Qu'est-ce qui se passe?)

>Il réagit à tout ce que je fais!
>	(Quoi?)
>	(Il y a sûrement une faille! Il faut tenter le coup!)
>Il est... il est rapide...
>	(Quoi?)
>	(Il y a sûrement une faille! Il faut tenter le coup!)
>Je crois qu'on sera obligés de perdre...
>	`proAff-=3`
>	![[proStressed.png]]
>	(Quoi!?)
>	![[proMildlyStressed.png]]
>	(Baisse pas les bras pas comme ça!!)
>...
>	`proAff-=2`
>	![[proStressed.png]]
>	(`$player`? Ohé!?)

`x`
## midFight

`if consequencePhase1TimedOut`
	![[proStressed.png]]
	(On arrive à peine à le toucher! Qu'est-ce qui se passe?)
	>!Il anticipe tous mes coups!
	>	![[proPanicked.png]]
	>	(Sérieusement!?)
`else`
	![[proHit.png]]
	Aah!
	![[proPanicked.png]]
	Ok, ok! Tu bluffais pas!

`c,proAndConsequenceCircleAroundEachOther`

![[consequence.png]]
Prêt à vous rendre?

`if consequenceHitPhase1`
	![[consequenceDark.png]]
	Ces cartouches fumigènes coûtent *cher*, vous savez.

![[proStressed.png]]
...`var,affinityCheck,12`

>Fuis.
>	[[#runAway]]
>Retourne te battre.`if !consequencePhase1TimedOut`
>	[[#keepFighting]]
>Rends-toi.
>	![[proStressed.png]]
>	(...)
>	![[proUpset.png]]
>	(... Tu penses vraiment qu'on devrait céder?)
>	>Oui. Retournons à Stroma.
>	>	(Pourquoi?)
>	>	>Je crois pas qu'on ait le choix. Tu veux vraiment mourir?
>	>	>	`proAff+=2`
>	>	>	`if proAff > affinityCheck`
>	>	>		![[proUpset.png]]
>	>	>		(Je...)
>	>	>		![[proMildlyConflicted.png]]
>	>	>		(Non.)
>	>	>		(...)
>	>	>		![[proMeditating.png]]
>	>	>		(Ok. On trouvera le moyen de s'en tirer. Je te fais confiance.)
>	>	>		[[#proGivesUp]]
>	>	>	`else`
>	>	>		`p,0.75`
>	>	>		![[proFrustratedSimmering.png]]
>	>	>		(T'en sais quoi, au juste!? C'est pas comme si ça changeait quoi que ce soit pour toi si je meurs!)
>	>	>		![[proAnnoyed.png]]
>	>	>		(Tant pis. C'est pas comme si t'avais aidé dans ce combat.)
>	>	>		![[proFrustratedSimmering.png]]
>	>	>		(Je gère ça moi-même.)
>	>	>		[[#proAttacksConsequence]]
>	>	>Je veux connaître la suite.
>	>	>	`c,interference`
>	>	>	`proAff-=6`
>	>	>	![[proDisdainful.png]]
>	>	>	(Tu veux...)
>	>	>	(...)
>	>	>	![[proMocking.png]]
>	>	>	(C'est vrai...)
>	>	>	(... qu'au fond, t'en as rien à cirer de tout ça.)
>	>	>	![[proAnnoyed.png]]
>	>	>	(...)
>	>	>	![[proFrustratedSimmering.png]]
>	>	>	(Très bien. C'est pas comme si t'avais aidé pendant ce combat.)
>	>	>	(Je gère ça moi-même.)
>	>	>	[[#proAttacksConsequence]]
>	>Non. Fais semblant.
>	>	`proAff+=1`
>	>	![[proUpset.png]]
>	>	(Je... je crois qu'il va le voir venir.)
>	>	>Alors fuis.
>	>	>	[[#runAway]]
>	>	>Alors retourne te battre.`if !consequencePhase1TimedOut`
>	>	>	[[#keepFighting]]
>	>Laisse tomber, fuis.
>	>	[[#runAway]]
>	>Laisse tomber, retourne te battre.`if !consequencePhase1TimedOut`
>	>	[[#keepFighting]]

## runAway
![[proMildSurprise.png]]
`a,0.4`(Quoi? Mais Minim-)

`c,cameraPansToMissingMinima`

`a`![[proCynical.png]](...oublie ça.)
![[proConflicted.png]]
(...)
(Tu crois vraiment qu'on peut le semer?)

>Oui.
>	`if proAff > affinityCheck`
>		![[proMeditating.png]]
>		(D'accord. Je te fais confiance.)
>		[[#proRunsFromConsequence]]
>	`else`
>		`c,interference`
>		![[proAnnoyed.png]]
>		(... Pourquoi? Pourquoi je devrais te faire confiance?)
>		![[proFrustrated.png]]
>		(C'est vrai, c'est parce que t'as envie de connaître la suite.)
>		![[proAnnoyed.png]]
>		(...)
>		(Tant pis.)
>		![[proFrustratedSimmering.png]]
>		(Je gère ça moi-même.)
>		[[#proAttacksConsequence]]
>Je sais pas.
>	`proAff+=1`
>	`if proAff > affinityCheck`
>		![[proSoftSmile.png]]
>		(Ha... bon, on saura pas sans essayer, pas vrai?)
>		![[proConflicted.png]]
>		(... C'est bon, je te fais confiance.)
>		[[#proRunsFromConsequence]]
>	`else`
>		`c,interference`
>		![[proPanicked.png]]
>		(Tu sais pas...? On dirait que tu t'en fiches carrément.)
>		![[proAnnoyed.png]]
>		(Tant pis.)
>		![[proFrustratedSimmering.png]]
>		(Je gère ça moi-même.)
>		[[#proAttacksConsequence]]

### proRunsFromConsequence
`c,proAndConsequenceFaceEachOther`
![[proDetermined.png]]
Hé, ho! « Consequence »!

![[consequenceQuestioning.png]]
...?
![[proSmirk.png]]
Félicitations, tu t'es mérité un tête-à-tête avec ma <span style="color:rgb(225, 188, 105)">technique spéciale</span>!
![[proDetermined.png]]
Prépare-toi à subir toute la puissance de mon Mécène!

`c,proBluffsConsequence,false`

`a,-1`

![[consequenceExerted.png]]
`a,0.5`Ragh-!

`a,-1`
## keepFighting

`if proAff > affinityCheck`
	![[proMeditating.png]]
	(...)
	![[pro.png]]
	(Ok. Je te fais confiance.)
	![[proDetermined.png]]
	(Finissons-en.)
	![[consequenceAnnoyed.png]]
	...!
	`c,proAndConsequenceContinueFighting`
	`x`
`else`
	![[proConflicted.png]]
	(...)
	![[proDisdainful.png]]
	(À quoi bon?)
	(On se fait trucider, là.)
	(C'est parce que ça t'embête de pas pouvoir le battre. C'est ça?)
	>On l'a touché. Il n'est pas invincible.`if consequenceHitPhase1`
	>	![[proStressed.png]]
	>	(...)
	>	![[proAnnoyed.png]]
	>	(Bien!)
	>	![[proFrustratedSimmering.png]]
	>	(T'as intérêt à avoir un plan.)
	>	![[consequenceAnnoyed.png]]
	>	...!
	>	`c,proAndConsequenceContinueFighting`
	>	`x`
	>Non. Je peux le battre.`if !consequenceHitPhase1`
	>	`c,interference`
	>	![[proAnnoyed.png]]
	>	(... Comment? Pourquoi je devrais te croire?)
	>	(...)
	>	(Tant pis. Tu ne sais pas t'y prendre, en fin de compte.)
	>	![[proFrustratedSimmering.png]]
	>	(Je gère ça moi-même.)
	>	[[#proAttacksConsequence]]
	>Euh...
	>	`c,interference`
	>	![[proFrustrated.png]]
	>	(Je le savais!)
	>	![[proAnnoyed.png]]
	>	(Agh, et puis merde! T'as aucune idée de ce que tu fais.)
	>	![[proFrustratedSimmering.png]]
	>	(Je gère ça moi-même.)
	>	[[#proAttacksConsequence]]

## proGivesUp
![[proMildlyStressed.png]]
C'est bon!`proGaveUpToConsequence`

`c,proAndConsequenceFaceEachOther`

![[proStressed.png]]
T'as prouvé ton point. Je... je me rends.

![[consequenceEyesClosed.png]]
Ah. Bien.

`c,consequenceWalksOverToPro`

![[consequence.png]]
Ça va me faciliter la tâche.

`c,consequenceKnocksOutPro`
`a,-1`
## proAttacksConsequence

`c,proAttacksConsequence,false`
`a,-1`

![[proAnnoyed.png]]Ah...
![[proUpset.png]]Pu-

`a,-1`

# minimaTransition
`c,minimaTransition,false`
`a,-1`
# minimaConnection
![[minimaStressed.png]]
`s,0.5`Arrêtez-vous.

![[consequenceQuestioning.png]]
Vous revoila.
![[consequenceEyesClosed.png]]
`s`... Ça ne me surprend pas. Vous ne seriez pas venue ici si vous étiez du genre à fuir.

![[minimaStressed.png]]
Ne faites pas ça!

![[consequenceDark.png]]
...

![[minimaStressed.png]]
S'il vous plaît. Qui êtes-vous? Pourquoi faire ça!? Il doit y avoir quelque chose-

![[consequenceAnnoyed.png]]
Pourquoi me supplier de la sorte? Il a clairement fait comprendre qu'il préférait la mort à la déroute.

`if proGaveUpToConsequence`
	![[minimaMildlyAnnoyed.png]]
	Vraiment? Il m'avait l'air plutôt coopératif.
	![[consequenceAnnoyed.png]]
	... Il bluffait de toute évidence.
`else`
	![[minimaDisappointed.png]]
	Il ne réfléchissait pas.
	![[consequenceEyesClosed.png]]
	Décidément, il n'en avait pas l'habitude.
	![[consequence.png]]
	Sortir seul comme ça... On aurait pu croire qu'éventuellement, quelqu'un aurait essayé de l'en dissuader.
	![[consequenceDark.png]]
	Eh bien, réfléchi ou non, en voilà les conséquences.
![[consequence.png]]
Maintenant posez cette arme et partez.

![[minimaStressed.png]]
Vous n'allez pas juste me tirer dans le dos?

![[consequence.png]]
...
Pro représente un risque réel. Mes options étaient malheureusement limitées en ce qui le concerne.
![[consequenceEyesClosed.png]]
Au demeurant, il y aura toujours des « héros » comme vous qui trouvent une faille et passent entre les mailles de notre filet.
![[consequence.png]]
Nous savons d'expérience que quelqu'un comme vous ne représente pas un danger.

![[minimaMildlyAnnoyed.png]]
...
Pas un danger pour quoi?

![[consequenceDark.png]]
... Rentrez chez vous, Minima.

![[minimaDisappointed.png]]
Je... vous pouvez pas...

`c,minimaFallsToHerKnees`

![[minimaDark.png]]
...vous pouvez pas.

![[consequence.png]]
...

`c,minimaMeditationStart`

![[minimaRanting.png]]
(aaaaaAAAAAAHHHH!! *Putain*!)
![[minimaStressed.png]]
(Il est *juste là*! Je suis même pas capable de sauver quelqu'un qui est *juste*-- *là*!)
![[minimaDark.png]]
(Pourquoi, pourquoi personne m'a dit de devenir plus forte...)
(Pourquoi il n'y a que moi ici qui...)

`c,reachOutChoice`

`x`

## playerConnectsToMinima
`c,minimaConnects`

![[minimaExhausted.png]]
(...?)
(Q-quoi...)
>Bonjour.
>Salut!

(Qu'est-ce qui se passe? C'est qui qui a dit ça?)

>Je suis le Joueur.
>	![[minimaDisappointed.png]]
>	(Le... joueur?)
>	(Oh, le « mécène » de Pro.)
>Je suis le Mécène de Pro.
>Je suis `$player`
>	![[minimaDisappointed.png]]
>	(`$player`...?)
>	`a,0.3`(Où est-ce que j'ai déjà-)
>	`a`(Oh. Le « mécène » de Pro.)

(...)
(...)
(...)

>Allô?
>Tu vas bien?

(...je me suis évanouie?)

>Je te jure que j'existe.
>	![[minimaConflicted.png]]
>	(... Continue de parler.)
>	>Je crois qu'il faut d'abord sauver Pro.
>	>	[[#savePro]]
>	>Tu t'es calmée?
>	>	[[#stillUpset]]
>T'es arrivée à te calmer?
>	![[minimaBemused.png]]
>	(T'essaies de me consoler?)
>	![[minimaDisappointed.png]]
>	(...)
>	[[#stillUpset]]
## stillUpset
![[minimaConflicted.png]]
(... Je suis calme.)

>T'inquiète. On va le sauver.
>Tu n'es pas faible.
>	![[minimaBemused.png]]
>	(Aha. C'est gentil.)
>	![[minimaAnnoyed.png]]
>	(Ça me convainc presque que t'es pas un mécanisme d'adaptation.)
>	![[minimaDisappointed.png]]
>	(Qu'est-ce qui te fait dire ça, d'ailleurs?)
>	>Ta force de caractère.
>	>	![[minimaExhausted.png]]
>	>	(Ah, la force de caractère. Ça va gagner le combat, ça.)
>	>	>On peut encore le sauver.
>	>	>Tu es restée. Si je t'aide à le sauver alors oui, en quelque sorte.
>	>J'ai juste besoin que tu sauves Pro.

# savePro

![[minimaSurprised.png]]
(-!)
(On a encore le temps!? On peut...)
![[minimaMildlyAnnoyed.png]]
(...)
![[minimaDisappointed.png]]
(Tu l'aidais pas *déjà*?)
(Qu'est-ce qui te fait croire que ça se passera différemment pour moi?)

>Tu verras.
>	![[minimaConflicted.png]]
>	(...)
>	![[minimaMildlyAnnoyed.png]]
>	(Montre-moi, alors.)
>Je sais pas. On est dans une emmerde.
>	![[minimaBemused.png]]
>	(Haha.)
>	(Alors tu demandes juste parce qu'il y a personne d'autre?)
>	![[minimaConflicted.png]]
>	(Quelle raison stupide de continuer...)
>	(...)
>	![[minimaMildlyAnnoyed.png]]
>	(Mais bon. Allons-y.)

`hdOverlay`
Prête de tendre la perche par gentillesse, même lorsqu'implorée dans la détresse,
MINIMA rejoint l'équipe!
`hdOverlay`
# minimaMeditationEnd

`c,minimaMeditationEnd`
`x`
## minimaCombatStart
![[minimaSurprisedBlink.gif]]
(Oh!)

`p,1`

(Ouah.)
>!Témoignez de ma puissance!

![[minimaSurprised.png]]
(Ouais, c'est assez convaincant.)
![[minimaConflicted.png]]
(...et ça donne beaucoup plus de crédibilité aux simulationnistes...)
`p,0.33`
![[minimaSurprised.png]]
(Mes relevés atmosphériques sont figés aussi!)
(J-il y a quelque chose à faire avec ça!)

![[minimaMildlyAnnoyed.png]]
(Même si j'ai juste quelques secondes pour examiner ces relevés, je devrais être assez rapide pour l'atteindre!)

`x`

## consequenceHit
![[consequenceHit.png]]
Kh-!
![[consequenceAngry.png]]
...
`consequenceHitByMinima`
`x`
## minimaAttacked
![[minimaStressed.png]]
`if consequenceHitByMinima`
	(Bordel, il est toujours debout...)
`else`
	(Bordel, on arrive même pas à le toucher...)

`hdOverlay`

Ouah! Quelle embrouille!
Rééquilibrons un peu les choses.
`camPan,pro`
Quand une de vos unités est assommée, vous pouvez tenter de la ranimer.
**Attention cependant.** Cela ne peut être fait qu'**une fois par combat** et **annulera toutes vos actions en file et avancera le tour.**
Autrement dit, vos autres unités ne pourront pas agir ce tour-ci.
`c,proHighlight,false`
`if gamepad`
	Essayez d'appuyer sur **A** plusieurs fois avec Pro sélectionné pour le ranimer.`a,-1`
`else`
	Essayez de cliquer plusieurs fois sur Pro pour le ranimer.`a,-1`
`hdOverlay`
`x`
## proWakesUp

`c,consequenceRunsAtMinima,false`

`a,0.25`![[minimaSurprised.png]]Ah!
`a,-1`![[minimaFlinching.png]]Non, non, non, stop, stop! `$player`!

`a,-1`

![[consequenceAngryClenched.png]]
Quoi!? Comment vous faites pour tenir encore debout?

>« Pas de sieste au boulot! »
>	![[proSmirk.png]]
>	Pas de sieste pendant le boulot.
>	![[consequenceAngry.png]]
>	...
>« Tu m'as pas bordé. »
>	![[proSmirk.png]]
>	Tu m'as pas bordé.
>	![[consequenceAngry.png]]
>	...?
>« Parce que t'es nul, crétin! »
>	![[proDetermined.png]]
>	Parce que t'es nul, crétin!
>	![[consequenceAngryClenched.png]]
>	...??
>	![[proAnnoyed.png]]
>	(Bon... au moins, ça fait du bien de le dire.)
>C'est *pas* le moment de sortir une réplique.
>	![[proNonchalant.png]]
>	(Ah...)

![[minimaSurprised.png]]
(Il s'est relevé!)
![[minimaStressed.png]]
(B-bien! Tant qu'on arrive à prévoir le coup... on peut encore gagner.)
`c,combatResumesAfterRevivingPro`
`x`

# consequenceDefeated
![[consequenceHit.png]]
Graah!

`c,consequenceThrowsASmokeBomb`

![[consequenceExerted.png]]
Haah...
Belle bandes de buses atones.
Vous êtes vraiment, mais *complètement* inconscients du type de menace que vous représentez pour ce monde paisible.
...
... J'ai mal fait mes calculs.
Ce sera donc à *elle* de vous le faire comprendre.

`c,consequenceLeapsAway`

![[minimaStressed.png]]
...
![[minimaExhausted.png]]
Oh...

`c,minimaSits`

J'ai frôlé la mort un peu trop souvent aujourd'hui.

`if proBladeShattered`
	`c,proPicksUpSwordFragment`
	![[proUpset.png]]
	Mon épée...
	![[proAnnoyed.png]]
	(Ça va être une *galère* à faire remplacer.)
	>Et à qui la faute?
	>	![[proCynical.png]]
	>	(Je me le demande.)
	>Déso...
	>	![[proMildlyConflicted.png]]
	>	(... T'en fais pas.)
	>	(C'était une situation tendue.)

`c,proWalksOverToMinima`

![[proSmile.png]]
T'as enfin réussi à faire tourner ce machin?
![[proSmirk.png]]
T'étais à ce point déterminée de me sauver?

![[minimaLookingAway.png]]
En fait...

>Y'avait pas qu'elle.
>On est une vraie équipe maintenant!

![[proSkeptical.png]]
(Hein?)

![[minimaSheepish.png]]
Ouais.

![[proSkeptical.png]]
Quoi?

>Minima et moi, on a un lien maintenant.
>Elle m'entend, tu sais.
>Il semblerait que les combats à mort sont propices pour souder des liens.
>	![[proAnnoyed.png]]
>	(De quoi vous parlez tous les d-)
>	![[proMildSurprise.png]]
>	Attends, t'as entendu ça?
>	![[minimaEmbarassed.png]]
>	Ouais.

![[proMildSurprise.png]]
Comment?

![[minimaSheepish.png]]
C'est ce que j'aimerais savoir.

>Peut-être qu'il fallait simplement ouvrir son cœur.
>	![[minimaBemused.png]]
>	« Peut-être » donne certainement le ton dans cette phrase.
>Tendre la perche par gentillesse, même lorsqu'implorés dans la détresse!
>	![[minimaSkeptical.png]]
>	C'est une façon... fleurie de le dire.
>	![[proBemused.png]]
>	Ha! Alors tu voulais bien me sauver.
>	![[minimaBemused.png]]
>	Je suis là pour sauver *tout le monde*. Te fais pas d'idées.
>	![[minimaSmile.png]]
>	Même si dans ton cas, je t'en devais une.
>	![[proSmirk.png]]
>	Heh. Ouais.

![[proSkeptical.png]]
`$player`, ça veut dire que tu peux parler à n'importe qui maintenant?

>Non.
>Je crois pas.

![[proRollingEyes.png]]
Au moins, dorénavant, je serai plus le seul à entendre des voix dans ma tête.

![[minimaBemused.png]]
Hourra...

![[proSkeptical.png]]
Tu as l'air... étonnamment à l'aise avec ça.

![[minimaSurprisedBlink.gif]]
Pourquoi je le serais pas?

>Qu'est-il advenu de tout ton incrédulité?
>	![[minimaBemused.png]]
>	Euh, je crois que j'ai vu assez de preuves pour changer d'avis.
>	![[proNonchalant.png]]
>	C'est juste.
>	![[minimaBemused.png]]
>	Je vais pas me présenter comme une Héroïne élue, par contre.
>	![[proFrustrated.png]]
>	C'est pas juste.
>Ouais Pro, pourquoi elle le serait pas?
>	![[proAnnoyed.png]]
>	Laisse tomber.

![[pro.png]]
...
Alors c'est quoi le plan, maintenant?

![[minimaConflicted.png]]
Eh bien, j'ai *tout plein* de questions.
![[minimaMildlyAnnoyed.png]]
La principale étant, combien de temps tu peux *arrêter le temps*?

>Il n'y a pas vraiment de limite.
>Jusqu'à ce que j'appuie sur le bouton « tour suivant »?

![[minimaBeady.png]]
(...)
![[minimaRanting.png]]
Tu veux dire qu'on aurait pu rester là, à chercher des moyens de le battre aussi longtemps qu'on voulait!?
Et tu fais ça pour Pro aussi? Comment vous avez fait pour perdre?

>Rester assis à réfléchir éternellement? Euh...
>	![[minimaSkeptical.png]]
>	Quoi?
>	>C'est ennuyeux, non?
>	>	![[proRollingEyes.png]]
>	>	Je te fais pas dire...
>	>	![[minimaAnnoyed.png]]
>	>	Et ça vous dérange pas plus que ça?
>	>Je crois pas que Pro aurait tenu.
>	>	![[minimaLookingAway.png]]
>	>	Ah.
>	>	(Ouais, il a pas l'air du genre patient.)
>	>	![[proCynical.png]]
>	>	T'as quelque chose à dire?
>	>	![[minimaEmbarassed.png]]
>	>	E-eh bien,
>	>	 ce serait sûrement *pas* une bonne idée de tester combien de temps quelqu'un peut rester figé avant de craquer...
>J'ai la quasi-certitude que l'issue de ce combat était prédéterminée.
>	![[proCynical.png]]
>	« Quasi-certitude »?
>	![[proAnnoyed.png]]
>	Bah, peu importe, tout s'est bien terminé.
>C'est pas comme si le temps était figé dans *mon* monde.
>	![[minimaSheepish.png]]
>	Ah, je vois. Pardon.
>	![[proMeditating.png]]
>	Personnellement je vois pas en quoi c'est notre problème.
>En fait, je peux remonter le temps si Pro meurt, donc l'approche par tâtons fonctionne bien ici.
>	![[minimaBeady.png]]
>	Quoi!?
>	`if resetsKnown`
>		![[minimaStressed.png]]
>		Attends, c'est déjà arrivé?
>		![[proHidingSomething.png]]
>		Mm...
>		![[minimaSurprised.png]]
>		Ah!
>	`else`
>		![[proMildSurprise.png]]
>		Vraiment?
>		![[minimaStressed.png]]
>		Pour vrai, c'est déjà arrivé?
>		>Non.
>		>	![[minimaAnnoyed.png]]
>		>	D'accord. Oui, je vois. Mais dans ce cas...
>		>Ouais.
>		>	![[minimaSurprised.png]]
>		>	Ah!
>	![[minimaApprehensive.png]]
>	S'il te plaît, de grâce, ne nous tue pas juste pour tester un truc!
>	>T'inquiète, je le ferai pas.
>	>	![[minimaSkeptical.png]]
>	>	... D'accord.
>	>	>!Ce serait une énorme perte de temps.
>	>	>	![[minimaDisappointed.png]]
>	>	>	...
>	>Je peux rien promettre, ces combats sont durs.
>	>	![[minimaStressed.png]]
>	>	Agh.
>	>	![[proHidingSomething.png]]
>	>	...
>	>	![[minimaApprehensive.png]]
>	>	J-je devrais voir ça comme une bonne nouvelle.
>	>	Perdre... un peu de temps... c'est mieux que mourir pour de bon...
>	>	![[minimaAnnoyed.png]]
>	>	Ceci dit, faisons tous les deux de notre mieux pour pas mourir du tout. S'il te plaît.
>	`resetsKnown`


![[minimaMildlyAnnoyed.png]]
`a,0.3`Ok. Question suivante-

`a`![[proAnnoyed.png]]
Stop. Non. J'entrevois déjà le puits sans fond.
Plus de questions comme ça tant que j'ai pas eu la chance de m'allonger.

![[minimaSurprised.png]]
Mais c'est sans précédent! On a des expériences à mener!

![[proCynical.png]]
*Maintenant*? On fait quoi si quelqu'un d'autre nous attaque?

![[minimaSheepish.png]]
Ah, ouais, ça devrait être la priorité...

![[proHidingSomething.png]]
C'était qui ce type?

![[minimaConflicted.png]]
Me regarde pas.
![[minimaLookingAway.png]]
Quoiqu'à bien y penser, j'ai pu noter certains trucs.

![[proSkeptical.png]]
Ah oui?

![[minimaConflicted.png]]
Il *doit* y avoir un lien avec les monstres, pour commencer.

![[pro.png]]
Oui. À cause de son apparence.

![[minima.png]]
Ouais.

>!Ouah.
>	![[minimaSurprised.png]]
>	Oui, c'est très choquant.

![[minimaConflicted.png]]
Personne ne sait ce qui a causé l'apparition de tous ces monstres...
![[minimaDeadpan.png]]
Mais dès que le Héros de la prophétie se pointe le bout du nez, un gars à la peau grise débarque et essaie de le tuer?
![[minimaConflicted.png]]
J'étais longuement été d'avis que les théories proposées sur nos origines ne tenaient pas la route,
mais là, je remets sérieusement en question certaines notions...

`if pnee,sam`
	![[proSmirk.png]]
	Comme quoi? Genre, que le Gouvernement Central était derrière tout ça?
	![[minimaBemused.png]]
	Tu penses à *ce* <span style="color:rgb(225, 188, 105)">Sam</span>-là?
`else`
	![[proSmirk.png]]
	Quoi, genre que <span style="color:rgb(225, 188, 105)">Sam</span> était derrière tout ça?


![[minimaBemused.png]]
 *Ça*, c'est un peu capillotracté comme idée, quand même.

>!Sam?
>	![[minimaSheepish.png]]
>	Ooh...
>	`if pnee,sam`
>		![[proHidingSomething.png]]
>		(Pas moyen de l'éviter plus longtemps...)
>	`else if warringEraHistoryRead`
>		![[proSmirk.png]]
>		Prend le temps d'ouvrir un livre d'histoire, tu veux bien?.
>		>!J'ai essayé! Il y en avait pas sur l'ère des guerres!
>		>	Ça c'est ton problème.
>	`else`
>		![[proSmirk.png]]
>		Ouvre un livre d'histoire.
>	![[minimaConflicted.png]]
>	Sam était... un très mauvais homme.
>	![[proSkeptical.png]]
>	Il y a pas besoin d'infantiliser.
>	![[proCynical.png]]
>	Il est la raison pour laquelle la moitié du continent est inhabitable.
>	Et, euh, les anciens habitants ont pas exactement eu l'opportunité d'émigrer en paix.
>	![[minimaLookingAway.png]]
>	Dans un sens, on pourrait dire qu'ils nous ont tous quitté très très vite et d'un coup.
>	![[proMocking.png]]
>	Oh là, c'est du lourd.
>	![[minimaSheepish.png]]
>	Ouais.

![[minima.png]]
Mais ça ramène au sujet.
![[minimaConflicted.png]]
Qui qu'ils soit, les « employeurs » en question opèrent probablement à partir d'une des régions inhabitées.

![[pro.png]]
... Ouais, peut-être.

![[minimaLookingAway.png]]
À moins qu'ils aient un gigantesque bunker souterrain.
![[proThinking.png]]
... Et si c'était à Tongue?
![[minimaMildlyAnnoyed.png]]
Oh, bonne remarque.

>!Vous pourriez arrêter de tout divulgâcher?
>	![[minimaSheepish.png]]
>	On fait que spéculer là. Libre à toi de contribuer à la conversation.
>	[[#theories]]

![[minimaLecturing.png]]
`$player`, t'as des idées?
## theories
>Euh...
>J'ai rien.

![[minimaAnnoyed.png]]
Bon, je crois qu'il est temps de reconnaître qu'on est sérieusement désavantagés en termes d'information.
![[minimaMildlyAnnoyed.png]]
Ce qui veut dire qu'il ne reste plus qu'une ressource à consulter pour de l'aide...

![[proSkeptical.png]]
C'est quoi?

![[minimaJovial.png]]
La bibliothèque!

![[proCynical.png]]
Ah. Évidemment.

![[minima.png]]
L'Académie de Front regorge de rapports rédigés à l'époque des expéditions dans les régions dévastées par l'<span style="color:rgb(225, 188, 105)">Effondrement</span>.
![[minimaLeaningIn.png]]
C'est probablement notre meilleure chance de trouver un indice sur l'identité de ce type.

![[proRollingEyes.png]]
Oh, la bibliothèque de l'*Académie*.

![[minimaSheepish.png]]
Oui, oui, je sais. On n'est pas tout à fait à côté.
D'ici, on doit pratiquement traverser la moitié du monde.

![[proFacade.png]]
Ah, je suppose qu'on peut faire ça si on a pas d'autre choix.
![[proSmirk.png]]
(Je peux pas *trop* me plaindre.)

![[minimaCheeky.png]]
Là, tu parles!
Ça va être palpitant et rocambolesque!

`c,minimaStepsForward`

![[minimaMildlyAnnoyed.png]]
Monstres mortels, contrées périlleuses et adversaires redoutables nous barreront la route!
![[minimaJovial.png]]
Mais tout ça, nous en viendrons à bout grâce à l'aide de `$player`!
`face,minima,right`
![[minimaSmile.png]]
Et c'est parti! Direction-

`c,demoOutroStart`
`x`
