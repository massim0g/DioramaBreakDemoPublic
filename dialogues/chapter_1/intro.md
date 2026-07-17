# wakeup
`c, introSetup`

`s, 0.5`Pro?`s`

`c,momKnockOnDoor`

Pro, are you still in there?

`p,3`

![[proMeditating.png]]
......
No.

`c, momWalkIn`

![[salviaAngry.png]]
This is unbelievable!

![[proMeditating.png]]
`c, proDraggedOutOfBed, false``a,0.4`Is it?
![[proMildSurprise.png]]
Ah-!

`a,-1`
![[proNonchalant.png]]
Mom, come on, there's plenty of time.

![[salviaSerious.png]]
It's a quarter past eight!

![[proNonchalant.png]]
Yes.

![[salviaSerious.png]]
You were meant to be there at *seven*! I thought you had left already!

![[pro.png]]
Uh, no, he said eight-thirty.

![[salviaAngry.png]]
He said *absolutely no later than* eight-thirty!

![[proNonchalant.png]]
Yeah. So, like I said, plenty of time left.

![[salviaConcern.png]]
I-
...
I really wished this would be the one day we could count on you to take things seriously.

![[proRollingEyes.png]]
Please, I'm sure the <span style="color:rgb(225, 188, 105)">Patron</span> will pardon less than perfect punctuality. 

![[salviaConcern.png]]
Perhaps.
![[salviaSerious.png]]
But I don't expect they'll enjoy being kept waiting. And I *know* the mayor won't.

![[proCynical.png]]
Well *I* know that the longer I wait, the less time he'll have to lecture me.

![[salviaConcern.png]]
He just wants to get things right.
We all do.

![[proMeditating.png]]
Yeah, yeah.
![[proCynical.png]]
Do you need to supervise while I get dressed?

![[salvia.png]]
...
Make it quick.

`c, proGetsReady`

`x`
# interference
`c,interference`
![[proAnnoyed.png]]
(Agh.)
![[proCynical.png]]
`if turnedInHallway`
	`a,0.7`(Why did I turn...)
`else`
	`face,pro,right``p,0.4`
	`a,0.7`(What was...)

![[]]`a`PRO!

`face,pro,left`
![[proMildSurprise.png]]
(Ah!)
![[proAnnoyed.png]]
Coming! Coming!

`c, proWalksDownstairs`
# downstairs

![[salvia.png]]
Hold it.

`face, pro, up` `p, 0.33`

You're bringing your sword?

![[proMildSurprise.png]]
Oh. Uh...

`c, momWalksToPro`

![[salviaConcern.png]]
...
Are you really planning to run off as soon as you're done?

![[proFacade.png]]
O-of course not.

![[salviaConcern.png]]
...
At least stop by to say goodbye, alright?

![[proRollingEyes.png]]
Mom, c'mon.

![[salviaConcern.png]]
...

`p,2.5`

![[proMildSurprise.png]]
Uh, Mom?

![[salviaConcern.png]]
You know I love you right?
I know it's been difficult-

![[proEmbarrassed.png]]
Mom. Please. I know.

![[salviaConcern.png]]
Ok, ok. Sorry, I just worry sometimes.

![[proBemused.png]]
Sometimes?

![[salviaConcern.png]]
...
You're not afraid?

![[proSkeptical.png]]
Should I be? You're the ones always telling me it'll be fine.

![[salvia.png]]
Oh, you're right, there's nothing to fear.
Still, it's a big change...
...

`p,0.75`

![[pro.png]]
Ahem.

![[salviaSmiling.png]]
Yes, yes. Sorry. Goodbye. I love you.

![[pro.png]]
Love you too.

`c, proWalksOut`
# outside

![[proMeditating.png]]
...
![[pro.png]]
Alright.

`c,proWalksToHall`
`a,-1`
# hallArrival

`c, hallArrival`

![[phylloSurprised.png]]
`a,0.4`!
`c, phylloRunsOff, false`Sir! Sir! He's here!

`a,-1`

![[]]
PRO!

`c, mayorWalksDown`

![[dendro.png]]
Did something happen!? Has your Patron spoken to you?

![[proMildSurprise.png]]
Uh... no? Not that I can tell.

![[dendroAngry.png]]
Then what in the world took you!?

![[pro.png]]
Oh, I think it was the nerves.
![[proSmirk.png]]
I was just paralyzed at the thought of disappointing you.

![[dendroStern.png]]
Enough foolery.
Even if you cannot hear them, your Patron is certainly watching us by now.

![[proBemused.png]]
Oh? Can you already *feel their presence*?

![[dendroStern.png]]
Bah, wipe that grin off your face. You're about to feel their presence enough for the both of us.
Now come, stand on the altar.

`c, proAndMayorGetIntoPosition, false``a,5.66`

`a`![[dendro.png]]Phyllo, the notes.

![[phyllo.png]]
Yes sir.

`c, phylloHandsOverScript`

![[proSkeptical.png]]
Why's he here? Didn't you say this was supposed to be kept private? 

![[dendroAngry.png]]
Because I couldn't very well handle preparations *alone*!
Now turn around, sit, and shut your mouth.

![[pro.png]]
Turn around?
`face,pro,down``p,1.2`
So I can look at the empty seats?

![[dendroAngry.png]]
Just sit.

![[proRollingEyes.png]]
...
`c, proSits`
![[dendroClearingThroat.png]]
Ahem!
![[dendroPreaching.png]]
We are here today to seal the bond between the <span style="color:rgb(225, 188, 105)">Hero</span> and his Patron.
Hearken, High Observer!
You, who sees and hears this world, and through the glass sustains it... bring forth its promised transformation!
Through your aid, we shall be freed from our predicament.
`p,1`
Hero!

![[pro.png]]
Yes.

![[dendroPreaching.png]]
They are here, and we have waited long enough!
Close your eyes and concentrate!
Reach out, and seal the bond!

`c, proMeditates`

![[proMeditating.png]]
(Deep breath in... deep breath out...)
`c, proConnects`
(...)
(I hope I can fake this well enough that he'll let me leave after this...)
>Hello.
>You should show more respect.
>Skip.

`a,0.4`(?)
![[pro.png]](Who said-)

`c, proOpensEyes`

`a`
![[proMildSurprise.png]]
(Whoa.)
(What is this?)

>*Hello.*
>	(!?)
>	(There's no way.)
>I don't know.
>	(??)
>Skip.
>	[[#skip]]
# dad
(Dad?)
>No.
>No, you moron.
>	`proAff+=1`
>Yes.
>	`var,pretendedToBeDad,1,temp`
>	![[proSkeptical.png]]
>	(Wait, really?)
>	>No.
>	>	`proAff+=1`
>	>Yes!
>	>	(You sound awfully... nondescript.)
>	>	>Dying will do that.
>	>	>	![[proAnnoyed.png]]
>	>	>	(Alright, cut it out.)
>	>	>	(I know who you are.)
>	>	>	![[proCynical.png]]
>	>	>	(Oh Patron, my Patron...)
>	>	>	[[#bond1a]]
>	>	>Ok, got me. I am not your father.

![[proSmile.png]]
(Haha, I know.)
# bond1
![[proNonchalant.png]]
(Oh Patron, my Patron.)
## bond1a

`p,1.5`

![[proMildlyConflicted.png]]
(...)
(I'll be honest, I wasn't expecting this.)
>You don't seem particularly surprised.
>	`proAff+=1`
>	![[pro.png]]
>	(Well I *have* technically been trained from birth for this.)
>	![[proNonchalant.png]]
>	(That, and I feel half-asleep.)
>	(So I might just be dreaming all this. Again.)
>	>!You've dreamt of me before?
>	>	![[proHidingSomething.png]]
>	>	(... Nightmared, maybe.)
>What's a Patron?
>	![[proMildSurprise.png]]
>	(Oh, er...)
>	(What would *you* call yourself?)
>	>I'm the Player.
>	>	![[proSkeptical.png]]
>	>	("Player"?)
>	>	![[proRollingEyes.png]]
>	>	(Oh, right. That is what the prophecy calls you.)
>	>	![[pro.png]]
>	>	(I think people just didn't like calling you that.)
>	>	![[proNonchalant.png]]
>	>	(Makes you sound like a gambler.)
>	>	![[proCynical.png]]
>	>	(Or worse...)
>	>I'm a human.
>	>	![[proNonchalant.png]]
>	>	(My, how egalitarian of you.)
>	>	>Thanks!
>	>	>	`proAff+=1`
>	>	>	![[proSmirk.png]]
>	>	>	(You're welcome.)
>	>	>	![[pro.png]]
>	>	>	(But this might get confusing.)
>	>	>I'm just telling it like it is.
>	>	>	`proAff+=1`
>	>	>	![[proSoftSmile.png]]
>	>	>	(I see.)
>	>	>	![[pro.png]]
>	>	>	(Still, this might get confusing.)
>	>	>Uh, no. You, of course, are subhuman.
>	>	>	`playerCalledProSubhuman``proAff-=2`
>	>	>	![[proMocking.png]]
>	>	>	(...)
>	>	>	(I think I'll just stick to the terms I'm used to.)
>	>I'm God.
>	>	`var,calledSelfGod,1,temp`
>	>	![[proBemused.png]]
>	>	(... You really want me to call you that?)

(Do you have a name?)
# nameEntry

`c, startNameEntry`
`x`
# nameDone
![[proNonchalant.png]]
('<span style="color:rgb(225, 188, 105)">`$player`</span>'...)
(That's very, uh... interesting.)

>Thanks!
>	`proAff+=1`
>	![[proBemused.png]]
>	(Don't mention it.)
>	![[proSoftSmile.png]]
>	(...)
>	(My name's Pro.)
>Oh, and what's with *your* name?
>	![[proMildSurprise.png]]
>	(!)
>	![[proEmbarrassed.png]]
>	(See Mom, I knew-)
>	![[proAnnoyed.png]]
>	(...)
>	(Let's not dwell on it.)
>	>!I want to know!
>	>	(I'm sure it'll come up. Later.)
>	![[proSkeptical.png]]
>	(... Wait, you know my name? How long have you been watching me?)
>	>Since you woke up.
>	>	![[proEmbarrassed.png]]
>	>	(Ah.)
>	>	![[proAnnoyed.png]]
>	>	(Well, I hope you had fun peeping on me...)
>	>	[[#awakening]]
>	>Let's not dwell on it.
>	>	`proAff+=1`
>	>	![[proSmirk.png]]
>	>	(Ha.)


![[proSoftSmile.png]]
(Looking forward to working with you...)
[[#awakening]]

# skip
![[pro.png]]
(Skip?)
>Yes.
>	![[proSkeptical.png]]
>	(What does that mean?)
>	>I just want to play the game!
>	>	![[proFrustrated.png]]
>	>	(Oh, I see, it's all just a *game* to you, huh?)
>	>	>Yes!
>	>	>	![[proSmirk.png]]
>	>	>	(Haha, I know.)
>	>	>	[[#bond1]]
>	>	>Wait, no, I'm sorry.
>	>	>	![[proSmirk.png]]
>	>	>	(Haha, don't worry, I don't actually care. I've just always wanted to say that.)
>	>	>	[[#bond1]]
>	>Nothing, never mind.
>No.
>	![[proSkeptical.png]]
>	(Wait, can you hear me?)
>	>Yes.
>	>No.

![[pro.png]]
(You *can* hear me...)
[[#dad]]

# awakening
`c, proStopsMeditating`

![[dendro.png]]
You're awake.
Is it done? How are you feeling?

![[proVeryHaughty.png]]
...
Wonderful, Mayor.
I've consummated my union with my Patron. I am now their perfect instrument in this world.

![[dendroSurprised.png]]
Ah. I-I see...

![[proSmirk.png]]
At least according to this latest voice inside my head.
Felt a bit crowded already but this one really rounds out the choir.

![[phyllo.png]]
`face,phyllo,left``s,0.5`haha.`s`
`face,phyllo,right``c,mayorSlamsPodium`

![[dendroAngry.png]]
The bonding, Pro! Was it or was it not a success!?

![[proMeditating.png]]
(You still there?)
>Yes.
>No.

![[pro.png]]
Yeah, I can hear them.

![[dendroOhReally.png]]
... You seem *remarkably* unperturbed.

![[proNonchalant.png]]
What can I say? You've trained me so well.

![[dendro.png]]
Yes, well, nevertheless, would your Patron mind a... cursory examination?

>Not at all!
>	![[proHaughty.png]]
>	They are extremely eager to get on with things and won't have you wasting their time.
>	>!That's not what I said!
>	>	`proAff+=1`
>	>	![[proSmirk.png]]
>	>	(Ah, whoops.)
>I would.
>	`proAff+=1`
>	![[proHaughty.png]]
>	They are eager to get on with things.

![[dendroOhReally.png]]
How convenient for you.
![[dendroClearingThroat.png]]
Moving on then... ehm...

![[phyllo.png]]
Motor control?

![[dendro.png]]
Ah yes. 
If all went according to prophecy, the Patron should now be able to merge their will seamlessly with your own.

![[proCynical.png]]
Right. The creepy part where they get to puppet me around.

![[dendroStern.png]]
Don't be crass.
![[dendroOhReally.png]]
Their guidance will feel quite natural, as if you had willed the movements yourself.

![[proAnnoyed.png]]
How comforting...
`c,proStandsUp`
`x`

# loadIntoIntro
`c,loadIntoIntro`
`x`

# phyllo
![[proCynical.png]]
Hey.
![[phyllo.png]]
Hey...
![[proSkeptical.png]]
(Why am I talking to Phyllo?)
>I have questions!
>Do you have something against Phyllo?
>	![[proCynical.png]]
>	(I just want to get out of here, man.)
>No reason.

![[phylloSurprised.png]]
Did- did the Patron need something from me?
![[proCynical.png]]
Nope. Like I said, very eager to get on with things.
![[phyllo.png]]
Ah. Well, if they ever need anything, you can come find me at the library after we're done cleaning up here.
![[proCynical.png]]
Noted.
`x`
# noMovement
![[dendroSurprised.png]]
Were you waiting for permission?

![[proMildSurprise.png]]
I... just don't feel like moving?

![[dendro.png]]
Hm. Well, this was not unforeseen.
Let me see... Ah. Here.
![[dendroClearingThroat.png]]
Ahem.
![[dendroPreaching.png]]
ON THE SUBJECT OF COMMANDING MOVEMENT, IT IS FORETOLD:
"THE PLAYER CAN USE WASD OR THE ARROW KEYS!"

![[proNonchalant.png]]
(Whatever that means.)

![[dendroPreaching.png]]
THUS SPEAKS PROPHECY!
`x`
# dendro

`if !insigniaReceived`
	[[#dendroInsignia]]

![[dendro.png]]
Yes...?

![[pro.png]]
Oh, uh... I just felt the urge to get your attention.

![[dendro.png]]
Fascinating.
Perhaps the Patron has a question for me?

>I do.
>	![[proHidingSomething.png]]
>	They do.
>	But, uh, they don't want to get into it right now.
>	![[dendroSurprised.png]]
>	I see. They must want to get their bearings first.
>	![[dendro.png]]
>	Very well, my office is always open.
>I don't.
>	![[pro.png]]
>	They don't.
>	![[dendroSurprised.png]]
>	Ah.
>	![[proSmile.png]]
>	(Wow, he seems genuinely let down.)

`x`

## dendroInsignia
![[dendro.png]]
Here, before I forget...
`itemCollect,stromalInsignia``insigniaReceived`
...that badge will serve to prove your status among the right people once you leave the village.
You won't be needing it for a while, but you should hold onto it just in case.
![[proNonchalant.png]]
"For a while". Yup.
![[proThinking.png]]
...
![[proSkeptical.png]]
...in case of what?
And who would even know about this? Wasn't the whole point of the <span style="color:rgb(225, 188, 105)">lockdown</span> to keep outsiders in the dark?
![[dendroClearingThroat.png]]
...
We can discuss that later, in my office.`dendroOfficeMentioned`
![[proNonchalant.png]]
... Ok.
![[dendro.png]]
It's the door on the left, just over there.
![[proCynical.png]]
I know.
![[dendroStern.png]]
My! How surprising, given how seldom you stop by.
![[proFrustrated.png]]
...
`x`
# leaving
`if !insigniaReceived`
	`if seen`
		![[proNonchalant.png]]
		(Let's see what he has to give me.)
	`else`
		![[dendroSurprised.png]]
		Ah, before you leave...
		![[dendro.png]]
		Come here, I have something to give you.
		![[proSkeptical.png]]
		...?
	`walkBack,up`
	`x`

![[dendro.png]]
Ready to leave?

>Yes.
>	![[pro.png]]
>	Seems like it.
>	![[dendro.png]]
>	Yes, the Patron must want to take a look around.
>	It will give you time to acclimate. By all means then, explore the village at your leisure.
>	I'll be in my office.
>	![[proCynical.png]]
>	Not gonna follow me around?
>	![[dendro.png]]
>	As I'm sure you can tell from the proceedings, the <span style="color:rgb(225, 188, 105)">prophecies</span> were clear about keeping pomp to a minimum.
>	![[dendroOhReally.png]]
>	No grand processions, I'm afraid.
>	![[dendro.png]]
>	But I'm sure the others will all want to speak with you.
>	![[proCynical.png]]
>	Right.
>	![[pro.png]]
>	Well, bye, then.
>	![[dendroStern.png]]
>	Good luck!
>	`c,proWalksIntoLobby`
>No.
>	`if !seen`
>		![[proAnnoyed.png]]
>		`a,0.4`(*Agh*-)
>		`a`(I *want* to leave, but it's like my mind's screaming not to...)
>		(Would you stop that!?)
>		![[dendro.png]]
>		Pro?
>		![[proCynical.png]]
>		Uh, no, not leaving quite yet.
>	`else`
>		![[proCynical.png]]
>		Not yet.
>		![[dendro.png]]
>		Take all the time you need.
>	`walkBack,up`

`x`
# eavesdrop
`if introDone`
	`x`

![[pro.png]]
(...)
(I can hear them talking...)
(Let's take a peek...)

![[phylloConcerned.png]]
Mayor...
Will we be ok?

![[dendro.png]]
Our creators know what they're doing.
![[dendroClearingThroat.png]]
Despite appearances.

![[phylloConcerned.png]]
How can you be so confident?
We didn't even get to do the tests...

![[dendro.png]]
Those were just for our satisfaction. Tested or not, the prophecies are infallible.
...
Rest easy. 
As long as the Patron cares enough to see their role in this through then nothing can stand in the Hero's way.
Competent or not.

![[proCynical.png]]
(... Thanks for the vote of confidence.)

![[phylloConcerned.png]]
"As long as"?

![[dendroStern.png]]
...
Best not to dwell on that.
![[dendro.png]]
Come, help me clean up.

![[phylloConcerned.png]]
... Yes sir.

`x`

# exitingTownHall
`c,exitedTownHall`
![[proNonchalant.png]]
(Ok.)
(You were sent to get rid of all the <span style="color:rgb(225, 188, 105)">monsters</span>, right? Great. I'll bet you want to get started on that.)
(The way to the village exit's on my left.)
(Go down those stairs, then up towards the tree trunk.)

## exitingTownHallChoice
>Got it.
>	`proAff+=1`
>	`x`
>I don't know what kind of monsters you're talking about.[[#exitingTownHallA]]
>Actually, I thought this was a farming-sim sort of deal.[[#exitingTownHallB]]
>Why are you in such a rush to leave?[[#exitingTownHallC]]

### exitingTownHallA
![[proMildSurprise.png]]
(Well, uh...)
![[proFacade.png]]
(What better way to learn than to get out there and find one?)
![[pro.png]]
(Let's go do that.)
[[#exitingTownHallChoice]]

### exitingTownHallB
![[proSkeptical.png]]
(...)
(... What's that?)

>Oh, y'know, we hang around, farm crops, develop the town, maybe date some of the villagers. I guess fight monsters on the side too.
>	![[proMildSurprise.png]]
>	Oh.
>	(No. You- you have been *misinformed*.)
>	![[proEmbarrassed.png]]
>	(We don't need any more farming, financing, or... fornicating.)
>	![[proAnnoyed.png]]
>	(And urban development is bottlenecked by monsters.)
>	(*Just* monsters.)
>	![[proCynical.png]]
>	(So if you want to help with *that*, let's go deal with *those*.)
>	(Far away from here.)
>	[[#exitingTownHallChoice]]
>Nevermind.
>	![[proFacade.png]]
>	(Ok. Let's go then.)
>	[[#exitingTownHallChoice]]


### exitingTownHallC
![[proAnnoyed.png]]
(Because if we are not *leaving* then we are *staying* and before you know it that's our status quo.)
![[proCynical.png]]
(And even if you just want a quick look around,)
(I didn't wait 20 years for this moment just to serve as a glorified tour guide.)
![[proConflicted.png]]
(Besides...)
![[proHidingSomething.png]]
(There's nothing to do here and no one worth talking to.)

>Ok. Let's go then.
>	`proAff+=1`
>	![[pro.png]]
>	(Remember: Down those stairs, up towards the tree trunk, then take the stairs on the left.)
>I still want to look around.
>	![[proAnnoyed.png]]
>	Urgh...
>	(If you *have to*.)
>	![[proCynical.png]]
>	(Trust me though, you won't last an hour.)
>What about your mother?
>	`proAff+=2`
>	![[proHidingSomething.png]]
>	(... She'll be fine.)
>	![[proMildlyConflicted.png]]
>	(...)
>	![[proThinking.png]]
>	(Ah, y'know what, that reminds me...)
>	![[pro.png]]
>	(I think I left some stuff in my room.)`prosRoomMentioned`
>	![[proNonchalant.png]]
>	(So we *should* drop by before we go.)
>How else am I supposed to learn about your cool backstory?
>	![[proAnnoyed.png]]
>	You don't need to-
>	![[proCynical.png]]
>	(I don't see how that would help you do what you came here to do.)
>	>Good rapport is important.
>	>	`proAff+=1`
>	>	![[proHidingSomething.png]]
>	>	Mm...
>	>Maybe I just want to spite you.
>	>	`proAff-=0.5`
>	>	![[proAnnoyed.png]]
>	>	Urgh...


`x`

# wentLeft
![[proCynical.png]]
(Er, I said *my* left.)

>Oops, sorry!
>	(Are you facing me...?)
>I want to explore.
>	![[proAnnoyed.png]]
>	(Fine, let's get it over with.)

`x`

# runTutorial
![[proCynical.png]]
(Are we, uh, just gonna walk the whole time?)

>It's important to pace yourself.
>	![[proAnnoyed.png]]
>	(I can handle a little running...)
>How do I make you run?
>	![[proMocking.png]]
>	(What do you-)
>	![[proThinking.png]]
>	(Oh. Wait. The mayor did mention something about this...)
>	`if gamepad`
>		(... something about an **X**? I don't really remember.)
>	`else`
>		(... something **shift**y? I don't really remember.)

`x`
# name
//player name easter eggs
`if pnee,god,dieu,deus,g-d`
	`if calledSelfGod`
		![[proDisdainful.png]]
		(Alright, come on man.)
		(I know you're not a god.)
		![[proBemused.png]]
		(If you're that desperate though I can think of you as a weird little fairy on my shoulder or something.)
		![[proMocking.png]]
		(I'd still need your name though.)
		[[#nameEntry]]
	`else`
		`var,calledSelfGod,1,temp`
		![[proBemused.png]]
		(... You really want me to call you that?)
		(C'mon, what's your real name?)
		[[#nameEntry]]
`else if pnee,pro`
	![[proAnnoyed.png]]
	(No, I'm asking what *your* name is.)
	>Yeah. That's my name.
	>	![[proCynical.png]]
	>	(That's... a pretty shocking coincidence.)
	>	![[proMildlyConflicted.png]]
	>	(...)
	>	![[proNonchalant.png]]
	>	(Alright, fine.)
	>	![[proThinking.png]]
	>	(I had it first though. So I'm just gonna call you... P.)`player=P`
	>	>Ok.
	>	>No!
	>	>	![[proBemused.png]]
	>	>	(Seems fair enough to me.)
	>	>	(Unless you want me to call you something else?)
	>	>	>Fine.
	>	>	>	[[#nameEntry]]
	>	>	>Nevermind, P is ok.
	>	>	>	![[proSmirk.png]]
	>	>	>	Great!
	>	![[proNonchalant.png]]
	>	(... Looking forward to working with you.)
	>	[[#awakening]]
	>Oh, right.
	>	[[#nameEntry]]
`else if pnee,minima`
	`hdOverlay,true`
	Sorry buddy, that one's taken.
	Nice try though.
	`hdOverlay`
	[[#nameEntry]]
`else if pnee,salvia`
	![[proCynical.png]]
	`if pretendedToBeDad`
		(First my dad and now this?)
	`else`
		(... Really?)
	>What? That's my name.
	>	![[proAnnoyed.png]]
	>	(... And my mother's.)
	>	(Good grief...)
	>	![[proCynical.png]]
	>	(Just... don't be a nag, alright?)
	>	>Sure thing!
	>	>	`proAff+=1`
	>	>	![[proNonchalant.png]]
	>	>No promises.
	>	>	![[proAnnoyed.png]]
	>	(... Looking forward to working with you.)
	>	[[#awakening]]
	>Nah, I'm just messing with you.
	>	![[proAnnoyed.png]]
	>	(Ugh, almost got to me there... that would've been *weird*.)
	>	![[pro.png]]
	>	(C'mon, what's your real name?)
	>	[[#nameEntry]]
`else if pnee,pike`
	![[proCynical.png]]
	(I thought we established this. You're not my dad.)
	>Is that his name too?
	>	![[proAnnoyed.png]]
	>	(Agh...)
	>	![[proCynical.png]]
	>	(Fine. You can have it. But don't expect me to tell any of the others.)
	>	![[proHidingSomething.png]]
	>	(...)
	>	![[proNonchalant.png]]
	>	(... Looking forward to working with you.)
	>	[[#awakening]]
	>Haha, alright.
	>	![[pro.png]]
	>	(C'mon, what's your real name?)
	>	[[#nameEntry]]
`else if pnee,phyllo,phylo,akro,kion,dendro,medi,api,oiko,polema,arb,hedera`
	![[proCynical.png]]
	(That's... kind of an annoying coincidence.)
	![[proNonchalant.png]]
	(... I guess I can live with it though.)
	(Looking forward to working with you.)
	[[#awakening]]
`else if pnee,libra,xylo,trabe,hinoki,fibra,flora,erg,ergasio,chion,moriko`
	![[proNonchalant.png]]
	(Oh. Funny coincidence.)
	(...)
	(Well, looking forward to working with you.)
	[[#awakening]]
`else if pnee,chara,frisk,kris,niko,shulk,juniper,joon,red,harrier,lea,ryu,mario`
	`proAff+=1`
	![[proThinking.png]]
	(... Feels like I've heard that name somewhere before...)
	(...)
	![[proNonchalant.png]]
	(Well, looking forward to working with you.)
	[[#awakening]]
`else if pnee,sam`
	![[proMildSurprise.png]]
	(Oooh... really?)
	>Yes.
	>Why?
	>	![[proHidingSomething.png]]
	>	(Er... nothing, it's fine.)
	![[proAnnoyed.png]]
	(I guess it *was* a pretty common name...)
	![[proNonchalant.png]]
	(Well, looking forward to working with you.)
	[[#awakening]]
`else`
	[[#nameDone]]

`x`


















