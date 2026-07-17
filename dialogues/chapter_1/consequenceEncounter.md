# warnPro
![[pro.png]]
-lright, let's get going.
>You're about to be ambushed.
>	`warnedProAboutConsequence`
>	`gameSave`
>	![[proMildSurprise.png]]
>	(Huh? Now?)
>	>As soon as you cross the forest's edge something attacks you from behind. Be ready for it.
>	>	![[proMildSurprise.png]]
>	>	(...)
>	>	![[pro.png]]
>	>	(... Ok.)
>	>	![[proHidingSomething.png]]
>	>	(...)
>	>	![[proSkeptical.png]]
>	>	(How do you know this?)
>	>	>I couldn't keep you alive. The world gets reset to the last time we visited a Fixture when you die.
>	>	>	`proAff-=4`
>	>	>	`resetsKnown`
>	>	>	![[proMildSurprise.png]]
>	>	>	(Wh-)
>	>	>	![[proFrustrated.png]]
>	>	>	What do you mean you couldn't keep me alive!?
>	>	>	![[minimaSurprised.png]]
>	>	>	!
>	>	>	Pro? What?
>	>	>	![[proFrustrated.png]]
>	>	>	Not now Minima, talking to `$player`.
>	>	>	(Am I going to die if go out there again?)
>	>	>	>Don't worry, it won't happen again.
>	>	>	>	And how do you know *that*?
>	>	>	>	>Well, now we know it's coming.
>	>	>	>	>	`proAff+=2`
>	>	>	>	>Uh...
>	>	>	>	>Magic.
>	>	>	>	[[#timeTravelIsAnnoying]]
>	>	>	>You might. Why do you think I'm warning you?
>	>	>	>	`proAff+=5`
>	>	>	>	[[#timeTravelIsAnnoying]]
>	>	>	>If you think about it you can't ever really die as long as I'm around.
>	>	>	>	`proAff+=2`
>	>	>	>	(I...)
>	>	>	>	(This is really hard to wrap my head around...)
>	>	>	>	(It's probably fine then? Something about that doesn't seem right.)
>	>	>	>	[[#minimaCutsInDuringWarningB]]
>	>	>I can see the future sometimes.
>	>	>	![[proSkeptical.png]]
>	>	>	(I... see.)
>	>	>	![[proCynical.png]]
>	>	>	(Just keep me posted then, ok?)
>	>	>	[[#minimaCutsInDuringWarningA]]
>	>	>Magic.
>	>	>	`proAff-=1`
>	>	>	![[proCynical.png]]
>	>	>	(Uh huh...)
>	>	>	(I wonder what Minima would have to say about that...)
>	>	>	![[minima.png]]
>	>	>	...?
>	>	>	[[#minimaCutsInDuringWarningA]]
>...

`x`
## timeTravelIsAnnoying
![[proAnnoyed.png]]
(Agh...)
![[proStressed.png]]
(Well... if you really can turn back time, then it's probably fine?)
![[proAnnoyed.png]]
(Something about that doesn't sit right with me.)
[[#minimaCutsInDuringWarningB]]
## minimaCutsInDuringWarningA

![[minima.png]]
Pro? Is something wrong?

![[proNonchalant.png]]
Nothing, it's fine.
![[proThinking.png]]
(Not like she'll give your warning any merit.)

![[minimaCheeky.png]]
Oh, were you communing with your Patron? Was something *revealed* to you?

![[proAnnoyed.png]]
Something like that...

`x`

## minimaCutsInDuringWarningB
![[minimaApprehensive.png]]
... Pro? You're kinda worrying me.
![[proAnnoyed.png]]
Everything's fine, let's go.
(Not like she'll give your warning any merit.)
![[minimaConflicted.png]]
... Alright.

`x`

# ambushStart
![[minimaSurprisedSmile.png]]
Oh! I see the shoreline!

`c,minimaRunsAhead`

`if warnedProAboutConsequence`
	[[#proWarned]]

`c,ambushStart`
`x`

## ambushStarted

![[proMildSurprise.png]]
(!?)
(What's going on?)

>I don't know.
>	![[proSkeptical.png]]
>	(Are we under attack?)
>We're in combat.
>	![[proSkeptical.png]]
>	(With what?)

![[proStressed.png]]
(...)
(I can't see what we're fighting in this position.)

>I'll take a look.
>...

`x`

## ambushCheckedAttack
![[proMildlyStressed.png]]
(Well?)
>I can't see it either.
>	![[proStressed.png]]
>	(Well, figure something out!)
>I don't think I can dodge this attack...
>	![[proStressed.png]]
>	(Huh!? Attack?)
>	![[proFrustrated.png]]
>	(Figure something out!)

`x`
## proWarned
![[proHidingSomething.png]]
(... Now?)
>Yeah.
>	![[proDetermined.png]]
>	(Ok.)
>Just a little more.
>	![[proMildlyStressed.png]]
>	`a,0.4`(Let's not give them the chance-!)
>	`a`

`c,ambushStart`
`x`
## consequenceAppears

`c,ambushEnd`

![[consequenceShouting.png]]
Stop! Parley!

`c,cameraSnapsToPro`

![[proMildlyStressed.png]]
...
`p,1`
![[proStressed.png]]
(Why isn't time stopping?)
## timestop
>Maybe because he doesn't want to fight.
>	![[proAnnoyed.png]]
>	(Is that really how it works? He just tried to kill me!)
>I don't know.
>	`proAff-=1`
>	![[proAnnoyed.png]]
>	(You can't control it?)

[[#timestopEnd]]


## timestopEnd
![[proStressed.png]]
(...)
![[proAnnoyed.png]]
(Let's hear what he has to say, I guess...)

`c,proPutsSwordAway`

![[proDetermined.png]]
Alright.

`c,cameraSnapsToConsequence`

![[consequence.png]]
...

`c,consequenceWalksToPro`

![[consequenceEyesClosed.png]]
Hero. Forgive me.
![[consequence.png]]
I had merely hoped to incapacitate you swiftly, that you and your companion might be spared a dangerous fight.

`if resetsKnown && warnedProAboutConsequence`
	![[proSkeptical.png]]
	(Didn't you say he killed me? Is he just lying through his teeth?)
	>Yeah.
	>	`proAff+=0.5`
	>	![[proRollingEyes.png]]
	>	(Ah. And he seemed so trustworthy.)
	>You died on impact... but maybe he meant to hold back?
	>	![[proCynical.png]]
	>	(Right...)

![[consequenceEyesClosed.png]]
I failed, regrettably. But you are listening now, so we may yet avoid violence.
![[proAnnoyed.png]]
... May?

![[consequence.png]]
My "employers", so to speak, have an interest in putting an immediate and permanent halt to your activities.

![[minimaMildlyAnnoyed.png]]
Who? Why?

![[consequenceEyesClosed.png]]
I am not at liberty to disclose that.
![[consequence.png]]
I speak to you now only to offer you a chance at unconditional surrender.
![[consequenceAnnoyed.png]]
To be clear, I am not making a *request*.
![[consequence.png]]
I have been observing your fights. Your skills are impressive, inhumanly so...
...but nevertheless, you stand no chance against me.

![[proMocking.png]]
Is that so?

![[consequenceEyesClosed.png]]
Yes.
![[consequence.png]]
`c,consequenceStepsForward, false`
`a,0.3`Now, my terms are as foll-
`a`

![[minimaShouting.png]]
`flag, consequenceStops`Stop!
Stay right there.

![[consequenceAnnoyed.png]]
...
![[consequence.png]]
My terms are as follows, for the both of you:
Drop your weapons. Return to your settlements. Never leave again.
If you do, I will kill you.

`p,0.8`

![[proMocking.png]]
What?

![[consequence.png]]
I am prepared to escort you back...
...and to keep you under indefinite surveillance.

![[proAnnoyed.png]]
No, I-
![[proDisdainful.png]]
You really think I'll just buy that?

![[consequenceEyesClosed.png]]
Not particularly.
But there was little to lose in asking.
![[consequence.png]]
Minima?

![[minimaStressed.png]]
L-let me talk to Pro.

![[consequence.png]]
... You have five minutes. Do not attempt to flee.

`c,proAndMinimaHuddle`

![[proDisdainful.png]]
So, uh, did I miss the memo on there being talking monsters?

![[minimaStressed.png]]
N-no. I have no idea what he is.
But you make a good point, what kind of human would threaten to kill someone?

![[proThinking.png]]
(Hm...)

>I could name a few...
>	![[proRollingEyes.png]]
>	I mean, historically...
>	![[minimaAnnoyed.png]]
>	Well, yeah, but nowadays it doesn't make sense for anyone. Any known group, at least.
>I got nothing.
>	![[proCynical.png]]
>	(Helpful as always.)
>	Sorry, I wouldn't know.
>	![[minimaStressed.png]]
>	Yeah, it doesn't make sense for anyone. Any known group, at least.

![[minimaMildlyAnnoyed.png]]
And he's too... put together to just be some random lunatic.

![[proConflicted.png]]
Great.
(So what do we do?)

>You should both fight.
>	`proAff+=1`
>	![[proMildlyConflicted.png]]
>	`a,0.3`(Really? How is she gonna-)
>	![[minimaMildlyAnnoyed.png]]`a`I think we should fight him.
>	![[proMildSurprise.png]]
>	Huh?
>	[[#minimasPlanVariantB]]
>Minima should run.
>	`proAff+=1`
>	![[proMildlyConflicted.png]]
>	(Y-yeah.)
>	![[pro.png]]
>	I think you should get out of here.
>	![[minimaMildlyAnnoyed.png]]
>	I disagree.
>	He said he saw *you* fight. He has no idea what my equipment is capable of. Probably.
>	I'm your best shot at finishing this quickly.
>	![[proMildSurprise.png]]
>	Hold on, you want to fight?
>	![[minimaConflicted.png]]
>	...
>	[[#minimasPlanVariantB]]
>You should both run.
>	![[proHidingSomething.png]]
>	(...)
>	We should try making a break for it.
>	![[minimaMildlyAnnoyed.png]]
>	No.
>	[[#minimasPlanVariantA]]
>You should have Minima hold him off while you run.
>	`proAff-=1`
>	![[proBemused.png]]
>	(Ha, what? How?)
>	![[proAnnoyed.png]]
>	(Forget it. I'll just ask her.)
>	![[pro.png]]
>	What do you think we should do?
>	![[minimaConflicted.png]]
>	Hm...
>	[[#minimasPlanVariantA]]

## minimasPlanVariantA
![[minimaConflicted.png]]
If he's as strong as he's claiming, it doesn't make sense for him to be talking to us like this. 
He must think fighting is more of a risk to him than he's letting on...
`a,0.3`Keep him talking. As long as he's standing in one spot for long enough I can-

![[proMildSurprise.png]]`a`Hold on, you want to fight?

![[minimaLookingAway.png]]
...

![[minimaMildlyAnnoyed.png]]
He said he saw *you* fight. He has no idea what my equipment is capable of. Probably.
I'm your best shot at finishing this quickly.

![[minimaBemused.png]]
... Plus, how embarrassing would it be to cave to a threat like *that*?

![[proSoftSmile.png]]
Heh, you got that right.
![[pro.png]]
So, just talk to him?

![[minimaMildlyAnnoyed.png]]
Yeah... just for a minute or so. Stand in front of me so it's hard to see what I'm doing.
[[#proConfrontsConsequence]]

## minimasPlanVariantB
![[minimaConflicted.png]]
If he's as strong as he's claiming, it doesn't make sense for him to be talking to us like this. 
He must think fighting is more of a risk to him than he's letting on...
![[minimaBemused.png]]
...besides, how embarrassing would it be to cave to a threat like *that*?
![[proSoftSmile.png]]
Heh, you got that right.
![[minimaLecturing.png]]
Just keep him talking. As long as he's standing in one spot for long enough I can hit him hard.
![[minimaMildlyAnnoyed.png]]
Stand in front of me so it's hard to see what I'm doing.
[[#proConfrontsConsequence]]

## proConfrontsConsequence
![[proDetermined.png]]
Got it.

`c,proConfrontsConsequence`

![[proDetermined.png]]
Hey!

![[consequence.png]]
Changed your mind?

![[proNonchalant.png]]
Maybe.
![[proMocking.png]]
Your pitch seems a little under-baked though.
Why should I trust anything you say? I don't even know your name.

`c,minimaReadiesAttack,false`

![[consequence.png]]
Again, I am not free to tell you anything.

![[proRollingEyes.png]]
Really? Nothing at all? I'm really on the fence here man.

![[consequenceQuestioning.png]]
I was under the impression that your village, of all places, understood the importance of operational security.

![[pro.png]]
...

![[consequence.png]]
...
![[consequenceEyesClosed.png]]
My name is Consequence.

![[proRollingEyes.png]]
Ooh, terrifying.

![[consequenceAnnoyed.png]]
This is pointless. You think I'm bluffing.
![[consequenceEyesClosed.png]]
`a,0.2`It seems-
`a`
`c,minimaAttacksConsequence`
![[consequence.png]]
-a demonstration is in order.

`c,consequenceFightStart`
`x`
## consequenceHitsPro
![[proHit.png]]
Ow!

![[proStressed.png]]
(I don't think we can afford to take hits here!)
(What's going on?)

>He's reacting to everything I do!
>	(What?)
>	(There has to be an opening, keep trying!)
>He's... he's fast...
>	(What?)
>	(There has to be an opening, keep trying!)
>I think this might be a forced loss...
>	`proAff-=3`
>	![[proStressed.png]]
>	(What!?)
>	![[proMildlyStressed.png]]
>	(Don't just give up!!)
>...
>	`proAff-=2`
>	![[proStressed.png]]
>	(`$player`? Hello!?)

`x`
## midFight

`if consequencePhase1TimedOut`
	![[proStressed.png]]
	(We're barely touching him! What's happening?)
	>!He's predicting all my moves!
	>	![[proPanicked.png]]
	>	(Seriously!?)
`else`
	![[proHit.png]]
	Aah!
	![[proFearful.png]]
	Ok, ok! You weren't bluffing!

`c,proAndConsequenceCircleAroundEachOther`

![[consequence.png]]
Ready to surrender?

`if consequenceHitPhase1`
	![[consequenceDark.png]]
	Those smoke cartridges are *expensive*, you know.

![[proStressed.png]]
...`var,affinityCheck,12`

>Run.
>	[[#runAway]]
>Keep fighting.`if !consequencePhase1TimedOut`
>	[[#keepFighting]]
>Surrender.
>	![[proStressed.png]]
>	(...)
>	![[proUpset.png]]
>	(... You really think we should give in?)
>	>Yes. Let's go back to Stroma.
>	>	(Why?)
>	>	>I don't think we have a choice. Do you really want to die?
>	>	>	`proAff+=2`
>	>	>	`if proAff > affinityCheck`
>	>	>		![[proUpset.png]]
>	>	>		(I...)
>	>	>		![[proMildlyConflicted.png]]
>	>	>		(I don't.)
>	>	>		(...)
>	>	>		![[proMeditating.png]]
>	>	>		(Ok. We'll figure something out. I trust you.)
>	>	>		[[#proGivesUp]]
>	>	>	`else`
>	>	>		`p,0.75`
>	>	>		![[proFrustratedSimmering.png]]
>	>	>		(What do you know!? It's not like it'll matter at all to you if I die!)
>	>	>		![[proAnnoyed.png]]
>	>	>		(Screw this. It's not like you've helped at all in this fight.)
>	>	>		![[proFrustratedSimmering.png]]
>	>	>		(I'll handle this myself.)
>	>	>		[[#proAttacksConsequence]]
>	>	>I want to see what happens.
>	>	>	`c,interference`
>	>	>	`proAff-=6`
>	>	>	![[proDisdainful.png]]
>	>	>	(You want to...)
>	>	>	(...)
>	>	>	![[proMocking.png]]
>	>	>	(That's right.)
>	>	>	(You wouldn't really care about any of this.)
>	>	>	![[proAnnoyed.png]]
>	>	>	(...)
>	>	>	![[proFrustratedSimmering.png]]
>	>	>	(Fine. It's not like you've helped at all in this fight.)
>	>	>	(I'll handle this myself.)
>	>	>	[[#proAttacksConsequence]]
>	>No. Fake it, I mean.
>	>	`proAff+=1`
>	>	![[proUpset.png]]
>	>	(I... I think he'll see that coming a mile away.)
>	>	>Then run.
>	>	>	[[#runAway]]
>	>	>Then keep fighting.`if !consequencePhase1TimedOut`
>	>	>	[[#keepFighting]]
>	>Nevermind, run.
>	>	[[#runAway]]
>	>Nevermind, keep fighting.`if !consequencePhase1TimedOut`
>	>	[[#keepFighting]]

## runAway
![[proMildSurprise.png]]
`a,0.4`(What? But what about-)

`c,cameraPansToMissingMinima`

`a`![[proCynical.png]](...nevermind.)
![[proConflicted.png]]
(...)
(Do you really think we can outrun him?)

>Yes.
>	`if proAff > affinityCheck`
>		![[proMeditating.png]]
>		(Alright. I trust you.)
>		[[#proRunsFromConsequence]]
>	`else`
>		`c,interference`
>		![[proAnnoyed.png]]
>		(... Why? Why should I trust that?)
>		![[proFrustrated.png]]
>		(Do you just want to see what happens?)
>		![[proAnnoyed.png]]
>		(...)
>		(Screw that.)
>		![[proFrustratedSimmering.png]]
>		(I'll handle this myself.)
>		[[#proAttacksConsequence]]
>I don't know.
>	`proAff+=1`
>	`if proAff > affinityCheck`
>		![[proSoftSmile.png]]
>		(Ha... well, we won't know until we try, right?)
>		![[proConflicted.png]]
>		(... It's ok, I trust you.)
>		[[#proRunsFromConsequence]]
>	`else`
>		`c,interference`
>		![[proFearful.png]]
>		(You don't...? It's like you don't even care.)
>		![[proAnnoyed.png]]
>		(Screw that then.)
>		![[proFrustratedSimmering.png]]
>		(I'll handle this myself.)
>		[[#proAttacksConsequence]]

### proRunsFromConsequence
`c,proAndConsequenceFaceEachOther`
![[proDetermined.png]]
Hey "Consequence"!

![[consequenceQuestioning.png]]
...?
![[proSmirk.png]]
Congrats, looks like I'll have to use my <span style="color:rgb(225, 188, 105)">special technique</span>!
![[proDeterminedSmile.png]]
Get ready to face my Patron's true power!

`c,proBluffsConsequence,false`

`a,-1`

![[consequenceExerted.png]]
`a,0.5`Damn it-!

`a,-1`
## keepFighting

`if proAff > affinityCheck`
	![[proMeditating.png]]
	(...)
	![[pro.png]]
	(Ok. I trust you.)
	![[proDetermined.png]]
	(Let's finish this.)
	![[consequenceAnnoyed.png]]
	...!
	`c,proAndConsequenceContinueFighting`
	`x`
`else`
	![[proConflicted.png]]
	(...)
	![[proDisdainful.png]]
	(Why should I?)
	(He's trouncing us.)
	(Are you just mad you can't beat him?)
	>We've hit him. He's not untouchable.`if consequenceHitPhase1`
	>	![[proStressed.png]]
	>	(...)
	>	![[proAnnoyed.png]]
	>	(Fine!)
	>	![[proFrustratedSimmering.png]]
	>	(You'd better have a plan though.)
	>	![[consequenceAnnoyed.png]]
	>	...!
	>	`c,proAndConsequenceContinueFighting`
	>	`x`
	>No. I can beat him.`if !consequenceHitPhase1`
	>	`c,interference`
	>	![[proAnnoyed.png]]
	>	(... How? Why should I trust that?)
	>	(...)
	>	(Screw this. You have no idea what you're doing.)
	>	![[proFrustratedSimmering.png]]
	>	(I'll handle this myself.)
	>	[[#proAttacksConsequence]]
	>Err...
	>	`c,interference`
	>	![[proFrustrated.png]]
	>	(I knew it!)
	>	![[proAnnoyed.png]]
	>	(Agh, screw this, you have no idea what you're doing.)
	>	![[proFrustratedSimmering.png]]
	>	(I'll handle this myself.)
	>	[[#proAttacksConsequence]]

## proGivesUp
![[proMildlyStressed.png]]
Alright!`proGaveUpToConsequence`

`c,proAndConsequenceFaceEachOther`

![[proStressed.png]]
You've proven your point. I... I surrender.

![[consequenceEyesClosed.png]]
Ah. Good.

`c,consequenceWalksOverToPro`

![[consequence.png]]
That makes this much easier.

`c,consequenceKnocksOutPro`
`a,-1`
## proAttacksConsequence

`c,proAttacksConsequence,false`
`a,-1`

![[proAnnoyed.png]]Aw...
![[proUpset.png]]Man-

`a,-1`

# minimaTransition
`c,minimaTransition,false`
`a,-1`
# minimaConnection
![[minimaStressed.png]]
`s,0.5`Stop.

![[consequenceQuestioning.png]]
You're back.
![[consequenceEyesClosed.png]]
`s`... I'm not surprised. You would not be here in the first place if you were someone who'd flee.

![[minimaStressed.png]]
Don't do it!

![[consequenceDark.png]]
...

![[minimaStressed.png]]
Please. Who are you? Why do this!? There has to be something-

![[consequenceAnnoyed.png]]
Why beg like this? He's made it clear that he would rather die than give up.

`if proGaveUpToConsequence`
	![[minimaMildlyAnnoyed.png]]
	Really? He seemed pretty cooperative to me.
	![[consequenceAnnoyed.png]]
	... That was an obvious bluff.
`else`
	![[minimaDisappointed.png]]
	He wasn't thinking.
	![[consequenceEyesClosed.png]]
	Yes, he doesn't seem to be in the habit.
	![[consequence.png]]
	Coming out here alone... you'd think someone would have tried to warn him off it.
	![[consequenceDark.png]]
	Well, thought-through or not, these are the consequences.
![[consequence.png]]
Now drop that weapon and leave.

![[minimaStressed.png]]
You won't just shoot me in the back?

![[consequence.png]]
...
Pro is a real threat. My options are sadly limited, in his case.
![[consequenceEyesClosed.png]]
But there will always be "heroes" like you, who find some loophole, slip through our net.
![[consequence.png]]
Experience has shown that you are not a danger.

![[minimaMildlyAnnoyed.png]]
...
Not a danger to what?

![[consequenceDark.png]]
... Go home, Minima.

![[minimaDisappointed.png]]
I... you can't...

`c,minimaFallsToHerKnees`

![[minimaDark.png]]
...you can't.

![[consequence.png]]
...

`c,minimaMeditationStart`

![[minimaRanting.png]]
(aaaaaAAAAAAHHHH!! *Fuck!*)
![[minimaStressed.png]]
(He's *right there*! I can't even save someone who's *right*-- *there*!)
![[minimaDark.png]]
(Why, why didn't anyone ever tell me to get stronger...)
(Why am I the only one here...)

`c,reachOutChoice`

`x`

## playerConnectsToMinima
`c,minimaConnects`

![[minimaExhausted.png]]
(...?)
(W-wuh...)
>Hello.
>Hi!

(What's happening? Who said that?)

>I'm the Player.
>	![[minimaDisappointed.png]]
>	(The... player?)
>	(Oh, Pro's "patron".)
>I'm Pro's Patron.
>I'm `$player`.
>	![[minimaDisappointed.png]]
>	(`$player`...?)
>	`a,0.3`(Where have I-)
>	`a`(Oh. Pro's "patron".)

(...)
(...)
(...)

>Hello?
>Are you alright?

(...did I pass out?)

>I swear I'm real.
>	![[minimaConflicted.png]]
>	(... Keep talking.)
>	>I think we need to save Pro first.
>	>	[[#savePro]]
>	>Have you calmed down?
>	>	[[#stillUpset]]
>Have you calmed down?
>	![[minimaBemused.png]]
>	(Are you trying to console me?)
>	![[minimaDisappointed.png]]
>	(...)
>	[[#stillUpset]]
## stillUpset
![[minimaConflicted.png]]
(... I'm calm.)

>Don't worry. We'll save him.
>You're not weak.
>	![[minimaBemused.png]]
>	(Aha. How nice of you.)
>	![[minimaAnnoyed.png]]
>	(Really convincing me that you're not just some coping mechanism.)
>	![[minimaDisappointed.png]]
>	(What makes you say that, anyway?)
>	>Your character.
>	>	![[minimaExhausted.png]]
>	>	(Ah, character. That'll win the fight.)
>	>	>We can still save him.
>	>	>You stayed. If I help you save him then yeah, kind of.
>	>I just need you to save Pro.

# savePro

![[minimaSurprised.png]]
(-!)
(There's still time!? We can...)
![[minimaMildlyAnnoyed.png]]
(...)
![[minimaDisappointed.png]]
(Wasn't *he* getting your help?)
(What makes you think it'll go differently for me?)

>You'll see.
>	![[minimaConflicted.png]]
>	(...)
>	![[minimaMildlyAnnoyed.png]]
>	(Show me, then.)
>I don't know. It's a pinch.
>	![[minimaBemused.png]]
>	(Haha.)
>	(So you're just asking because there's no one else?)
>	![[minimaConflicted.png]]
>	(What a stupid reason to keep going...)
>	(...)
>	![[minimaMildlyAnnoyed.png]]
>	(Fine, let's do this.)

`hdOverlay`
Through wish to aid and desperate plea...
MINIMA joins the party!
`hdOverlay`
# minimaMeditationEnd

`c,minimaMeditationEnd`
`x`
## minimaCombatStart
![[minimaSurprisedBlink.gif]]
(Oh!)

`p,1`

(Wow.)
>!Behold my power!

![[minimaSurprised.png]]
(Yeah, this is pretty convincing.)
![[minimaConflicted.png]]
(...and grants a lot of credibility to the simulationists...)
`p,0.33`
![[minimaSurprised.png]]
(My atmospheric readout is frozen too!)
(I- I can work with this!)

![[minimaMildlyAnnoyed.png]]
(Even with just a few seconds to look at these readings, I can be fast enough to catch him off-guard!)

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
	(Crap, he's still standing...)
`else`
	(Crap, we couldn't even hit him...)

`hdOverlay`

Wow! What a pinch!
Let's tip the scales a little.
`camPan,pro`
When one of your units is knocked out, you can attempt to revive them.
**Careful though.** This can only be done **once per fight** and will **cancel all your queued actions and advance the turn.**
That is to say, your other units won't be able to act this turn.
`c,proHighlight,false`
`if gamepad`
	Try pressing **A** repeatedly while Pro is selected to revive him.`a,-1`
`else`
	Try clicking repeatedly on Pro to revive him.`a,-1`
`hdOverlay`
`x`
## proWakesUp

`c,consequenceRunsAtMinima,false`

`a,0.25`![[minimaSurprised.png]]Ah!
`a,-1`![[minimaFlinching.png]]No, no, no, stop, stop! `$player`!

`a,-1`

![[consequenceAngryClenched.png]]
What!? How are you awake?

>"Can't stay asleep on the job!"
>	![[proSmirk.png]]
>	I can't just stay asleep on the job.
>	![[consequenceAngry.png]]
>	...
>"You didn't tuck me in."
>	![[proSmirk.png]]
>	You didn't tuck me in.
>	![[consequenceAngry.png]]
>	...?
>"Because you suck, dumbass!"
>	![[proDetermined.png]]
>	Because you suck, dumbass!
>	![[consequenceAngryClenched.png]]
>	...??
>	![[proAnnoyed.png]]
>	(Well... at least that felt good to say.)
>Do *not* spout a one-liner.
>	![[proNonchalant.png]]
>	(Aw...)

![[minimaSurprised.png]]
(He's up!)
![[minimaStressed.png]]
(A-alright! As long as we plan things carefully... we can win.)
`c,combatResumesAfterRevivingPro`
`x`

# consequenceDefeated
![[consequenceHit.png]]
Graah!

`c,consequenceThrowsASmokeBomb`

![[consequenceExerted.png]]
Haah...
You fools.
You have no idea, *none*, of how you threaten this world's peace.
...
... I've miscalculated.
*She'll* have to make you understand.

`c,consequenceLeapsAway`

![[minimaStressed.png]]
...
![[minimaExhausted.png]]
Oh man.

`c,minimaSits`

That's a lot of near-death experiences for one day.

`if proBladeShattered`
	`c,proPicksUpSwordFragment`
	![[proUpset.png]]
	My sword...
	![[proAnnoyed.png]]
	(This is gonna be a *pain* to get replaced.)
	>And whose fault is that?
	>	![[proCynical.png]]
	>	(I seriously wonder.)
	>Sorry...
	>	![[proMildlyConflicted.png]]
	>	(... Don't worry about it.)
	>	(It was a tough spot.)

`c,proWalksOverToMinima`

![[proSmile.png]]
Finally figured that thing out?
![[proSmirk.png]]
Wanted to save me that badly?

![[minimaLookingAway.png]]
Actually...

>She wasn't the only one.
>We're a real party now!

![[proSkeptical.png]]
(Huh?)

![[minimaSheepish.png]]
Yeah.

![[proSkeptical.png]]
What?

>I bonded with Minima.
>She can hear me, dummy.
>Turns out battles to the death are real bonding experiences.
>	![[proAnnoyed.png]]
>	(What the heck are you two talking-)
>	![[proMildSurprise.png]]
>	Wait, you heard that?
>	![[minimaEmbarassed.png]]
>	Yeah.

![[proMildSurprise.png]]
How?

![[minimaSheepish.png]]
That's what I'd like to know.

>Perhaps you merely had to open your heart.
>	![[minimaBemused.png]]
>	"Perhaps" is doing a lot of work in that sentence.
>Through wish to aid and desperate plea!
>	![[minimaSkeptical.png]]
>	That's a... flowery way of putting it.
>	![[proBemused.png]]
>	Ha! You did want to save me.
>	![[minimaBemused.png]]
>	I'm out to save *everyone*. Don't get the wrong idea.
>	![[minimaSmile.png]]
>	Though in your case I did have a favor to return.
>	![[proSmirk.png]]
>	Heh. Yeah.

![[proSkeptical.png]]
`$player`, does this mean you can just talk to anyone now?

>No.
>I don't think so.

![[proRollingEyes.png]]
Oh well. At least now I'm not the only one with voices in my head.

![[minimaBemused.png]]
Hooray...

![[proSkeptical.png]]
You seem... oddly ok with this.

![[minimaSurprisedBlink.gif]]
Why wouldn't I be?

>What happened to all that skepticism, Minima?
>	![[minimaBemused.png]]
>	Uh, I think I've seen enough evidence to change my mind.
>	![[proNonchalant.png]]
>	Fair.
>	![[minimaBemused.png]]
>	Not gonna go around introducing myself as a chosen Hero though.
>	![[proFrustrated.png]]
>	Not fair.
>Yeah Pro, why wouldn't she be?
>	![[proAnnoyed.png]]
>	Never mind then.

![[pro.png]]
...
So what's the plan from here?

![[minimaConflicted.png]]
Well, I've got a *lot* of questions.
![[minimaMildlyAnnoyed.png]]
Chief of which, how long can you *stop time* for?

>There isn't really a limit.
>Until I press the "next turn" button?

![[minimaBeady.png]]
(...)
![[minimaRanting.png]]
You mean we could've sat there thinking of ways to beat him for as long as we wanted!?
And you were doing this for Pro too? How the hell did you guys lose?

>Sitting and thinking forever? Er...
>	![[minimaSkeptical.png]]
>	What?
>	>Sounds boring.
>	>	![[proRollingEyes.png]]
>	>	Admittedly...
>	>	![[minimaAnnoyed.png]]
>	>	Does this not matter much to either of you?
>	>I don't think Pro would have been ok with that.
>	>	![[minimaLookingAway.png]]
>	>	Ah.
>	>	(Yeah, he doesn't seem like the patient type.)
>	>	![[proCynical.png]]
>	>	Got something to say?
>	>	![[minimaEmbarassed.png]]
>	>	W-well, 
>	>	it probably *isn't* a great idea to test how long someone can stay frozen like that before losing it...
>Pretty sure the outcome of that fight was predetermined.
>	![[proCynical.png]]
>	"Pretty sure?"
>	![[proAnnoyed.png]]
>	Ah, whatever, it all worked out.
>It's not like time is frozen in *my* world.
>	![[minimaSheepish.png]]
>	Ah, I see. Sorry.
>	![[proMeditating.png]]
>	Personally I don't see why that's our problem.
>I actually get to rewind time if Pro dies so trial and error is optimal.
>	![[minimaBeady.png]]
>	What!?
>	`if resetsKnown`
>		![[minimaStressed.png]]
>		Wait, has that ever happened?
>		![[proHidingSomething.png]]
>		Mm...
>		![[minimaSurprised.png]]
>		Ah!
>	`else`
>		![[proMildSurprise.png]]
>		Wait, really?
>		![[minimaStressed.png]]
>		Hold on, has that ever happened?
>		>No.
>		>	![[minimaAnnoyed.png]]
>		>	Ok, ok. But...
>		>Yeah.
>		>	![[minimaSurprised.png]]
>		>	Ah!
>	![[minimaApprehensive.png]]
>	Please, please don't kill us just to test something!
>	>Don't worry, I won't.
>	>	![[minimaSkeptical.png]]
>	>	... Ok.
>	>	>!It would be a huge waste of my time.
>	>	>	![[minimaDisappointed.png]]
>	>	>	...
>	>No promises, these fights are tough.
>	>	![[minimaStressed.png]]
>	>	Agh.
>	>	![[proHidingSomething.png]]
>	>	...
>	>	![[minimaApprehensive.png]]
>	>	I-I guess I should treat this as good news.
>	>	Losing... some time... is better than dying forever...
>	>	![[minimaAnnoyed.png]]
>	>	Still, let's both do our best not to die at all. Please.
>	`resetsKnown`


![[minimaMildlyAnnoyed.png]]
`a,0.3`Ok. Next question-

`a`![[proAnnoyed.png]]
Stop. No. I know a rabbit hole when I see one.
No more questions like that until I've had a chance to lie down.

![[minimaSurprised.png]]
But this is historic! We've got experiments to run!

![[proCynical.png]]
*Now*? What are we gonna do if someone else comes after us?

![[minimaSheepish.png]]
Ah, yeah, that should take priority...

![[proHidingSomething.png]]
Who was that guy?

![[minimaConflicted.png]]
Don't look at me.
![[minimaLookingAway.png]]
Or, actually, there were a few things I picked up on.

![[proSkeptical.png]]
Yeah?

![[minimaConflicted.png]]
There *has* to be some connection to the monsters, for one.

![[pro.png]]
Right. Because of the way he looks.

![[minima.png]]
Yeah.

>!Wow.
>	![[minimaSurprised.png]]
>	Yes, it's very shocking.

![[minimaConflicted.png]]
Nobody knows what caused all these monsters to start appearing...
![[minimaDeadpan.png]]
But as soon as the Hero of prophecy shows up, some elf-looking guy pops up and tries to kill him?
![[minimaConflicted.png]]
I didn't think man-made origin theories had much of a leg to stand on but I'm seriously reconsidering...

`if pnee,sam`
	![[proSmirk.png]]
	What, that the Central Government was behind it?
	![[minimaBemused.png]]
	You mean *that* <span style="color:rgb(225, 188, 105)">Sam</span>?
`else`
	![[proSmirk.png]]
	What, like that <span style="color:rgb(225, 188, 105)">Sam</span> was behind it?


![[minimaBemused.png]]
Well *that's* still a stretch.

>!Sam?
>	![[minimaSheepish.png]]
>	Ooh...
>	`if pnee,sam`
>		![[proHidingSomething.png]]
>		(Guess there's no avoiding it...)
>	`else if warringEraHistoryRead`
>		![[proSmirk.png]]
>		Pick up a history book, man.
>		>!I tried! There weren't any on the warring era!
>		>	Sounds like a you problem.
>	`else`
>		![[proSmirk.png]]
>		Pick up a history book, man.
>	![[minimaConflicted.png]]
>	Sam was... a very bad man.
>	![[proSkeptical.png]]
>	What are they, a toddler?
>	![[proCynical.png]]
>	He's the reason half the continent is uninhabitable.
>	And, uh, the previous inhabitants didn't exactly get a chance to peacefully emigrate.
>	![[minimaLookingAway.png]]
>	Well, one could say they all moved on very very quickly all at once.
>	![[proMocking.png]]
>	Woah-ho, dark.
>	![[minimaSheepish.png]]
>	Yeah.

![[minima.png]]
But that does relate back.
![[minimaConflicted.png]]
Whoever that was, their "employers" are probably operating out of one of the uninhabited regions.

![[pro.png]]
... Yeah, maybe.

![[minimaLookingAway.png]]
Unless they've got some giant underground bunker.
![[proThinking.png]]
... What if they're in Tongue?
![[minimaMildlyAnnoyed.png]]
Oh, good point.

>!Can you guys stop spoiling stuff?
>	![[minimaSheepish.png]]
>	We're just speculating right now. You're welcome to join in.
>	[[#theories]]

![[minimaLecturing.png]]
`$player`, do you have any ideas?
## theories
>Uh...
>I got nothing.

![[minimaAnnoyed.png]]
Ok, I think the only obvious thing here is that we're at a serious informational disadvantage.
![[minimaMildlyAnnoyed.png]]
Which means there's only one thing that can help us...

![[proSkeptical.png]]
What?

![[minimaJovial.png]]
The library!

![[proCynical.png]]
Ah. Of course.

![[minima.png]]
Front Academy has a bunch of reports from when they were doing expeditions into the regions ruined by the <span style="color:rgb(225, 188, 105)">Collapse</span>.
![[minimaLeaningIn.png]]
Those are probably our best shot at finding a clue to that guy's identity.

![[proRollingEyes.png]]
Oh, the *Academy* library.

![[minimaSheepish.png]]
Yeah, I know, it's a long trip.
From here, we basically have to cross half the world.

![[proFacade.png]]
Ah, well, if we have to.
![[proSmirk.png]]
(Guess I can't complain *too* much.)

![[minimaCheeky.png]]
That's the spirit!
This'll be fun!

`c,minimaStepsForward`

![[minimaMildlyAnnoyed.png]]
Deadly monsters, treacherous terrain, and fearsome foes await!
![[minimaJovial.png]]
But with `$player`'s help, this'll be easy!
`face,minima,right`
![[minimaSmile.png]]
Let's go! Time to set out for-

`c,demoOutroStart`
`x`