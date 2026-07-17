# startEncounter
`c,startEncounter`

![[proMildSurprise.png]]
(What was that?)

`c,proWalksBehindRock`

![[proSkeptical.png]]
(What is she waving around?)
(Some kind of fan?)
`camPan, minima, true, 30`
(Whatever it is, it doesn't seem to be helping.)`a,1`
`camPan, pro, true, 30`
`a`(...)
### helpChoice
>Get in there and help her!
>	![[proDeterminedSmile.png]]
>	(Don't have to tell me twice!)
>Keep watching. [[#keepWatching]]
>Get out of here, it's too dangerous.
>	![[proMocking.png]]
>	(... You sound like the captain.)
>	(If you're so concerned...)
>	![[proDeterminedSmile.png]]
>	(...then I'm sure you won't mind helping out!)

`c,proJumpsIn`

`x`

## keepWatching
`p,2`
(I don't think she has a lot of time left.)
[[#helpChoice]]

## postCombat
`camPan, pro`
![[proNonchalant.png]]
Whew.
`c,proLooksAround`
![[pro.png]]
You still there? I think it's safe to come out now.

`c,minimaEmerges`

![[minimaConflicted.png]]
H-hey.

`p,2.5`

![[pro.png]]
Are... you alright?

![[minimaDisappointed.png]]
Oh. Yeah.
![[minimaAnnoyed.png]]
Sorry, coming down from the rush...

`c,minimaWalksNextToPro`

![[minima.png]]
Thanks for saving me.
Are you with the <span style="color:rgb(225, 188, 105)">mailmen</span>?

![[proBemused.png]]
Er, no.
![[pro.png]]
I'm from Stroma Village.

![[minimaSurprised.png]]
Oh! Really? I should've guessed from the clothing.
You guys... do patrols?

![[proThinking.png]]
Not really. I'm...
![[proMeditating.png]]
(Alright, first first impression...)

>Play it up.
>	(...)
>	![[proSmirk.png]]
>	(... Sure, why not.)
>	![[proHaughty.png]]
>	... I am the Hero of Prophecy, as of this morning bonded with my Patron, `$player`, and embarked on my Quest.
>	![[minimaSurprisedBlink.gif]]
>	...
>	![[proVeryHaughty.png]]
>	Ah, your shock is understandable.
>	Yes, my birth was kept secret from the world for my safety.
>	![[proDetermined.png]]
>	But with the Patron here, I am free to bare all!
>	![[minimaApprehensive.png]]
>	So... let me get this straight.
>Keep it simple.
>	![[pro.png]]
>	I'm the Hero of Prophecy.
>	![[minimaSurprisedBlink.gif]]
>	...
>	Excuse me?
>	![[proMeditating.png]]
>	I've been living in the village, but I bonded with my Patron, `$player`, this morning.
>	![[proNonchalant.png]]
>	So, um... here I am.
>	![[minimaApprehensive.png]]
>	... Let me get this straight, then.

You're saying that you, alone, are the reason Stroma has been on lockdown for twenty years?
![[minimaDisappointed.png]]
You guys didn't, say, discover something that needed to be kept secret?
Some weapon against the monsters?

![[proSkeptical.png]]
No?
![[proSmirk.png]]
Unless my body counts.

![[minimaAnnoyed.png]]
R-right. So, your whole village told you- er, raised you as the Hero.
As-in, the mythic Hero of prophecy with a direct line to a higher being from the great beyond.

![[pro.png]]
Indeed...

![[minimaLecturing.png]]
That's insane.

![[proMildSurprise.png]]
Well, uh...

>!She has a point.
>	![[proCynical.png]]
>	(...)
>It's ok, I believe you.
>	![[proCynical.png]]
>	(Gee, thanks.)

![[minimaAnnoyed.png]]
`s,0.5`Augh, everyone was right, of course it was going to be some crazy cult crap.`s,1`

![[proCynical.png]]
I can still hear you.
![[proAnnoyed.png]]
(So much for this first impression.)
![[proSkeptical.png]]
Did you not see me beat all those monsters?

![[minimaLecturing.png]]
Being an, admittedly, terrific fighter does not make you god's chosen.
![[minimaBemused.png]]
And proclaiming that so dramatically doesn't help your credibility.
Have you actually read the prophecies?

![[proDisdainful.png]]
Y-yeah.
![[proHidingSomething.png]]
Or... most of them.

![[minimaBemused.png]]
Amazing...
Well, then you're surely aware they're really not all that romantic.
![[minimaLecturing.png]]
They read like an instruction manual more than anything.
![[minimaLookingAway.png]]
At least the parts that aren't just long lists of future meteorological data.

![[proCynical.png]]
`if normalPropheciesExplained`
	Yeah, yeah. I did know about those.
`else`
	Yeah, yeah. I did know about those.
	>!What?
	>	![[proCynical.png]]
	>	(There to "verify predictive accuracy", supposedly.)

![[minimaBemused.png]]
Did you just not feel like doing due diligence?
There's nothing in the prophecies about the Hero not being allowed to read them.

![[proDisdainful.png]]
There is in the encrypted section.
![[proRollingEyes.png]]
(Allegedly.)

![[minimaMildlyAnnoyed.png]]
... You guys cracked the encrypted prophecies? That's... doubtful.

![[pro.png]]
We didn't *crack* them.
![[proRollingEyes.png]]
The key... appeared when I was born.

![[minimaSkeptical.png]]
"Appeared"?

![[proEmbarrassed.png]]
It's a little embarrassing...
![[proAnnoyed.png]]
Look, there was an obvious sign, and that's how people knew I was the Hero.

![[minimaBemused.png]]
Or so you've been told.

![[proAnnoyed.png]]
Ok, I really really get where you're coming from.
![[proCynical.png]]
But this morning has pretty decisively put a lot of these doubts to rest for me.

![[minimaCheeky.png]]
Oh that's right, you "bonded". Let me guess, you can *feel their presence*?

![[proAnnoyed.png]]
(Damn it.)
![[proCynical.png]]
No, it's... a lot more than that. Look, you've read the prophecy.

![[minimaCheeky.png]]
Oh, so you're claiming you can talk to them? Even better.
What's their name?
![[proHidingSomething.png]]
...`$player`.
![[minimaBemused.png]]
Oh. Ha.
>!What? What!?
>	![[proCynical.png]]
>	(Don't ask me, man.)

![[minimaBemused.png]]
Well, I hope you can see why none of this is very convincing.

![[proRollingEyes.png]]
Yeah, fine.
`c,proStartsLeaving`
![[pro.png]]
See ya around then. Good luck with whatever it is you were doing out here.

![[minimaSurprisedBlink.gif]]
Ah, um, actually I was on my way to Stroma.

![[pro.png]]
`face,pro,down`
Great, it's just down that path.
`face,pro,right`
![[proMocking.png]]
Quick warning though-
I don't think they'll be checking for visitors for a little while, so you might have to camp out.
![[proRollingEyes.png]]
Try to be... surreptitious.

`c,proWalksAway,false`

`p,1`

![[minimaApprehensive.png]]
`a,1`...

`a,-1`

![[minimaLookingAway.png]]
On second thought, it's probably worth asking you some more questions.
I know a safe place to camp.

![[pro.png]]
`a`Great.
>!You're ok with this?
>	![[proSkeptical.png]]
>	(I'm not just gonna leave her to die.)
>	![[proRollingEyes.png]]
>	(...as long as she's showing at least some self-preservation instinct.)

`a,-1`
## firstEncounterDone
`a,-1`
`x`
# afterNextCombat
//triggered after the first monster encounter you beat after meeting minima
`c,minimaWalksToPro`
`face,pro,minima`
`face,minima,pro`
![[minimaLeaningIn.png]]
Looking closely, your reflexes are... almost unbelievable.
![[minima.png]]
How are you pulling that off?

![[proSmirk.png]]
Told you, I'm the Hero.

![[minimaBemused.png]]
Come on man, that's not an explanation.

![[proThinking.png]]
...
![[proSkeptical.png]]
I can't say I blame you much in this case, but do you grill everyone who saves your life like this?

![[minimaEmbarassed.png]]
Ah, um...
Yeah... kinda.

![[proBemused.png]]
"Yeah"? So this isn't the first time?

![[minimaSheepish.png]]
... I forget how much people outside the <span style="color:rgb(225, 188, 105)">Academy</span> seem to dislike it.`minimaMentionedFront`

![[proSkeptical.png]]
Saving your life?

![[minimaMildlyAnnoyed.png]]
No, being sane.

![[proVeryHaughty.png]]
Saving you was insane, gotcha.
>!Kinda.
>	`proAff+=1`
>	![[proSmirk.png]]
>	(Selling yourself a little short there.)

`minimaCommentedOnCombat`
`x`
# aboutMinima
`c,restTalkStart`
//another campfire convo
![[pro.png]]
You mentioned you were from <span style="color:rgb(225, 188, 105)">Front Academy</span>? What are you doing all the way out here?

![[minimaLookingAway.png]]
It's pronounced *frʌnt*. And, well...
![[minimaMildlyAnnoyed.png]]
Do you ever feel like everyone's just kinda... given up? On dealing with the monsters for good?

![[proSkeptical.png]]
No?

![[minimaSheepish.png]]
Right, I guess *you* wouldn't.
![[minimaLecturing.png]]
I suppose I was at least right about Stroma being the only place that was trying to *do* something.
![[minimaLookingAway.png]]
Anyway, to answer your question, I heard a rumor that the village would be opening up around this time.

![[proCynical.png]]
(So much for opsec...)

![[minima.png]]
And, for everyone's sake, I thought it was worth the risk to come see what was up.

![[proSkeptical.png]]
Alone?

![[minima.png]]
The mailmen escorted me most of the way.
![[minimaConflicted.png]]
But once we got to <span style="color:rgb(225, 188, 105)">Lacrima</span> they said they weren't planning another delivery for weeks, and I was so close...

![[pro.png]]
(Wow.)
>!She's more of an adventurer than you!
>	![[proRollingEyes.png]]
>	(And even more "suicidal", at least *I* trained from birth for this.)
>Ok, what's the deal with these "mailmen"?
>	![[proNonchalant.png]]
>	(They deliver mail. Do you not have mail?)

![[minimaAnnoyed.png]]
Going it alone... what a stupid, pointless risk.

![[proMildlyEmbarassed.png]]
Um...

![[minimaExhausted.png]]
I think having gotten so far without incident might've messed up my expectations.
Ugh.

![[proFacade.png]]
Well, one has to take risks to achieve their goals.

![[minimaRanting.png]]
I *know* that!
But you only get so many dice rolls and I can't *help* anyone if I'm *dead*!!

`p,2.5`

![[minimaLookingAway.png]]
... Sorry. Let's talk about something else.

![[proMildSurprise.png]] //todo: don't really have a great expression here, need a sort of neutral "avoiding the subject" expression
Sure.
`c,restStart`
`x`

# names
//first campfire convo, not optional (as part of the tutorial)
`c,restTalkStart`
![[minimaSmile.png]]
So... thanks again for the rescue, um...
![[minima.png]]
What's your name?

![[pro.png]]
Pro.

![[minimaSmile.png]]
Pro. Nice to meet you. Or lucky, at least.
![[minimaSurprised.png]]
... Wait. "Pro". As in, "pro"-tagonist?

![[proHidingSomething.png]]
Er...
No comment.

![[minimaLaughing.png]]
Hahaha! No way!
That's incredible! That's fantastic!

![[proAnnoyed.png]]
Alright, alright.
It's been "nice" meeting you too... uh...

![[minimaSurprisedSmile.png]]
Oh!

`c,minimaGetsUpToTwirl`

![[minimaCheeky.png]]
Genius engineer! Lovable spellcaster!
Your friendly local...

`c,minimaTwirl`

![[minimaPose.png]]
Minima!

`p,0.7`

![[proMildSurprise.png]]
...
>Damn, you've gotta work on your intro.
>	`proAff+=1`
>	![[proBemused.png]]
>	(It'll be difficult to top that.)
>	(Very difficult.)
>I think I still liked your intro better.
>	`proAff+=2`
>	![[proBemused.png]]
>	(Yeah, I figure this one only appeals to...)
>	(...particular tastes.)
>...

`c,minimaStopsPosing`

![[minimaSmile.png]]
Now who's shocked speechless? Haha.

![[proBemused.png]]
I wasn't looking for competition, y'know.

![[minimaLaughing.png]]
Ha!

`minimaIntroduced`
`c,restStart`
`x`
# spellcaster 
//second campfire convo, technically optional but *very* hard to miss
`c,restTalkStart`
![[proBemused.png]]
You called yourself a "spellcaster"?

![[minimaJovial.png]]
Yup! Peep the staff, buddy!

![[proMocking.png]]
The giant fan?

![[minimaSmile.png]]
It's called an <span style="color:rgb(225, 188, 105)">anemomater</span>.

![[pro.png]]
Never heard of that.
>!Shouldn't it be anemo-*meter*?
>	![[proThinking.png]]
>	(Good point.)
>	![[proSkeptical.png]]
>	Shouldn't it be anemo-*meter*?
>	![[minimaSmile.png]]
>	No, anemometers measure Air, this thing affects it.

![[minimaCheeky.png]]
Normally you wouldn't see these outside of a weather lab, but I managed to put together a portable version!

![[proSkeptical.png]]
And this makes it magical?

![[minimaBemused.png]]
Magic isn't real, dummy!
![[minimaCheeky.png]]
But this thing sure looks magical in action!
![[minimaLeaningIn.png]]
Empty space isn't as flat as you'd imagine, Air can get trapped in "denser" pockets.
![[minimaSmile.png]]
This device can smooth out nearby regions temporarily and set off some powerful chain reactions.

![[proSkeptical.png]]
Didn't seem to be doing much when you were swinging it around earlier.

![[minimaEmbarassed.png]]
Well... it worked fine in the lab.
![[minimaSheepish.png]]
Though I get how that sounds.
Outside conditions have just been a bit *too* chaotic.
![[minimaLookingAway.png]]
Not that I wasn't expecting as much but... I need more practice.
![[minimaSheepish.png]]
I can't exactly carry around a supercomputer on my back,
so the software relies a lot on manual adjustments.

![[proNonchalant.png]]
This all sounds incredibly overwrought.

![[minimaBemused.png]]
... We can't all be trained in swordfighting from birth.

![[proSmirk.png]]
Not with that attitude.
`c,restStart`
`x`

# anemomaterAndTimeStop
`c,restTalkStart`

![[pro.png]]
How come you're suddenly able to actually use that thing so well?

![[minima.png]]
What? The anemomater?
Time stop, duh.

![[proCynical.png]]
Well, yeah, but it's not like the time stop makes me any better at swinging my sword. 

![[minimaLookingAway.png]]
Oh. Hm... how should I explain it...
![[minima.png]]
Imagine you had to play an instrument off of a piece of sheet music,
but notes you had to start playing kept changing every few milliseconds.
![[minimaLecturing.png]]
By the time you'd read them and started playing, the piece you were supposed to play changed.
But if you had time to read the music before it changed, it wouldn't be much different from playing normally.
![[minimaConflicted.png]]
`a,0.4`Though, you'd still have to remember what to play, you wouldn't keep looking at-
![[minimaSheepish.png]]
`a`I think I'm butchering this analogy.
![[minima.png]]
Anyway, that's all to say, time stop keeps the "sheet music", that is, my atmospheric readout, fixed.
That makes working out exactly what I need to do to trigger the reaction I want ahead of time a lot easier.

![[proThinking.png]]
I see...

`c,restStart`

`x`

# triedToLeaveEarly
`if seen`
	![[pro.png]]
	(Come on, I want to hear what her deal is.)
	`c,walkBackToRestArea`
	`x`
![[minimaSurprised.png]]
Hey, are we leaving already?
![[minimaSmile.png]]
C'mon, sit down, we've barely had a chance to talk.
![[proRollingEyes.png]]
(Mm... I do wanna hear what her deal is.)
![[pro.png]]
Yeah, alright.
`c,walkBackToRestArea`
`x`