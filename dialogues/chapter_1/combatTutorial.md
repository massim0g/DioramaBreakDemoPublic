# preamble
![[pro.png]]
(Alright, home stretch.)
(The elevator to the ground is one floor down.)
![[proCynical.png]]
(We just need to get past the captain.)
`gameSave`
`x`

# captainEncounter
`c, polemaEncounterStart``encounteredPolema`
![[polema.png]]
...

![[pro.png]]
...

![[polema.png]]
Did it go well?

![[pro.png]]
You know it.

![[polemaBemused.png]]
You don't seem any different.

![[proCynical.png]]
You aren't even looking at me.

`c,polemaTurnsAround`

![[polemaBemused.png]]
...
Was there something to see?

![[proBemused.png]]
You never could see much in me, huh?
![[proNonchalant.png]]
Anyway, destiny calls. Wanna help me with the <span style="color:rgb(225, 188, 105)">elevator</span>?

![[polemaStern.png]]
*Something* has gotten in your head if you think you're getting out of here today.

`c,polemaWalksOver,false`

`a,0.5`![[polema.png]]Come, grab a training sword. 
We'll see if all this hassle has been worth anyth-

`a,-1`

![[polemaStern.png]]
Pro...

![[proDisdainful.png]]
`face,pro,up`If you didn't want to help you should've just said so. I'm leaving. 

![[polemaBemused.png]]
And how, exactly?
Operating the elevator is at *least* a two-man job.
![[polemaShout.png]]
Unless you want to jeopardize our only connection with the outside.

![[proConflicted.png]]
Feh. Not like you're using it.

![[polemaStern.png]]
Enough.
You're not ready.

![[proFrustrated.png]]
Even if that were true, whose fault would that be?

![[polemaPain.png]]
You-!
![[polemaPainedConcern.png]]
...
Pro, you've never even *seen* one of those monsters.
You don't stand a chance out there, especially not alone.

![[proDisdainful.png]]
I'm *not* alone.
![[proAnnoyed.png]]
(Speaking of. Anything to say?)
### polema response
>Why does she care so much?
>	![[proConflicted.png]]
>	(Oh, it's because she thinks I'll turn out like my dad.)
>	[[#not my father]]
>I think she makes some compelling points.
>	![[proAnnoyed.png]]
>	(Bull. She's just worried that I'll turn out like my dad.)
>	[[#not my father]]
>Seize the elevator by force! You can take her! [[#fight her]]
>I'm feeling a bit like a third wheel. [[#third wheel]]
>Tell her open borders are a right and you won't stand for any more fascistic restrictions on your freedom of movement! [[#insult her]]

### third wheel
`playerWhiny+=1``proAff-=1`
![[proCynical.png]]
(Then say something.)
[[#polema response]]
### fight her
![[proCynical.png]]
(Unless you're about to give me superpowers I really, really can't.)
(Was hoping you'd have something to say about the *conversation*?)
[[#polema response]]

### insult her
`proAff-=1`
![[proCynical.png]]
(What? No.)
>Trust me, bro.
>Ok fine.
>	![[proMildlyConflicted.png]]
>	(...)
>	[[#polema response]]

![[proCynical.png]]
(...)
![[proAnnoyed.png]]
Captain! Open borders are a right and I won't stand for any further fascistic restrictions on my freedom of movement!

![[polema.png]]
...
How nostalgic.
I thought you grew out of making proclamations like that years ago.

![[proEmbarrassed.png]]
(uuugh...)

![[polema.png]]
Clearly you can't be talked out of this.
Come, then.

`c, polemaWalksDown`

![[proMildSurprise.png]]
...
(What the hell?)
>!Told you.
>	![[proCynical.png]]
>	(...)

`x`
### not my father
![[proCynical.png]]
Stop worrying that I'll turn out like my dad.

![[polemaPainedConcern.png]]
...
I won't. Even if I can't deny you forever. 
![[polemaPain.png]]
But please, Pro. There's still time to prepare. 
Getting swept away in the- the fantasy of it all, it's going to get you killed!

![[proMocking.png]]
Hoh. The "fantasy of it all"? Y'know, if you'd said something like that yesterday I'd have been the first to agree.
![[proHidingSomething.png]]
(Well, internally. Partially.)

![[polemaPain.png]]
I had hoped to leave it unspoken, but since you clearly can't figure it out for yourself..

![[proCynical.png]]
I'll be *fine*. I'm not lying about this morning. The Patron's here, believe it or not.
![[proSkeptical.png]]
And waiting, I might add.

![[polemaSkeptical.png]]
Really.
![[polema.png]]
I will admit, you seem more committed to the bit than usual.

![[proCynical.png]]
Acting's easy when you're not acting.
![[proRollingEyes.png]]
On that point... maybe we should get the mayor to weigh in on this.
![[proSmirk.png]]
I wonder what he'd make of your lack of faith.

![[polemaStern.png]]
...
Come, the elevator's waiting.

`c, polemaWalksDown, false`

`p,0.5`

![[proSkeptical.png]]
`a,0.1``face,pro,down`What? Just like that?

`a,-1`

(Hrm.)
## captainEncounterQuestions
>That was easy. [[#captainEncounterQuestionsA]]
>What was that about your father?
>	`proAff+=1`
>	![[pro.png]]
>	(Oh, when I was just a baby he died in an attack while collecting the mail.)
>	>!Collecting the mail? On his front porch?
>	>	![[proCynical.png]]
>	>	(... No. One of the shipments from outside.)
>	>	![[proNonchalant.png]]
>	>	(Protocol was a lot more lax back then, or so I'm told.)
>	>	![[proMildlyConflicted.png]]
>	>	(...)
>	![[proMildlyConflicted.png]]
>	(Never really grieved for him, I don't even remember the man.)
>	(It sucked for Mom, but she never made it my problem.)
>	![[proCynical.png]]
>	(The Captain, on the other hand...)
>Let's go.

`encounteredPolema`
`x`

### captainEncounterQuestionsA
(Too easy, yeah.)
[[#captainEncounterQuestions]]

# trainingAreaEntrance
`if combatTutorialFailed`
	[[#returnedAfterFailure]]
`else`
	[[#triedToLeave]]
# triedToLeave
![[proNonchalant.png]]
`if !combatTutorialTriedToLeave`
	(What, forgot something?)
	>Yes
	>	![[proCynical.png]]
	>	(Well too bad.)
	>No
	>	![[proAnnoyed.png]]
	>	(Then let's get to the elevator.)
	(I don't want to give her any time to change her mind.)
	`combatTutorialTriedToLeave`

`walkBack, left`
`x`
# guardsEncounter

`c, guardsEncounterStart`
![[proCynical.png]]
(Hm. The clown squad's all here.)

![[chionSmiling.png]]
Hi Pro!

![[kion.png]]
Hi.

![[akroSmile.png]]
Yo.

![[pro.png]]
Hey guys.

`c,proTurnsToPolema`

![[proSkeptical.png]]
These guys are why you were so confident I couldn't sneak out?
![[proSmirk.png]]
We really are understaffed.

![[kionExclaimingAngry.png]]
`face,pro,left`Hey! We could beat you anytime!

`c, proPsychsOutKion`

![[proHaughty.png]]
Hmph.

`c, polemaSpeaksUp, false`

![[polemaShout.png]]
CADETS!`a,-1`

![[]]
CAPTAIN!

![[polemaShout.png]]
Despite my cautions, it seems our hero is intent on leaving at once!
As such, we will be taking this opportunity to perform a live-fire exercise!

>!This is so boring...
>	![[proAnnoyed.png]]
>	(AAAH, I know!! Almost there, almost there...)
>	[[#tunedOut]]

For some of you, it is well past time you acquainted yourselves with the operation of the main elevator.  
Therefore, I have gathered you all here to participate.

![[polema.png]]
Akro, you man the controls.

![[akro.png]]
Roger.

![[polema.png]]
Kion, you're on observer duty.

![[kionExclaimingSmiling.png]]
Oh! Yes Captain!

![[polema.png]]
I will direct.
## tunedOut
![[polemaShout.png]]
All hands, to your stations!

![[chion.png]]
Y-yes, Captain!

`c, everyoneBoardsElevator, false`

![[proSkeptical.png]]
(Wait, even Chion? Something's up.)

>!Say something.
>	![[proNonchalant.png]]
>	(And risk interrupting the departure? Nuh-uh.)

`a,-1`

## elevatorBoarded
![[polemaShout.png]]
All hands, sound off!

![[akro.png]]
Ready.

![[kion.png]]
Ready!

![[polemaShout.png]]
Confirm ground conditions!

![[kion.png]]
Yes!

`face,kion,down`
`p,1`
`face,kion,up`
`p,1.5`

![[polemaShout.png]]
Cadet?

![[kion.png]]
Oh, sorry, uh... all clear!

![[polemaStern.png]]
... Roger. Maintain observation.
`face,kion,down`Seventy-percent power, begin descent!

![[akroOrders.png]]
Roger!
`face, akro, up`

## elevatorDescent
`c, elevatorDescends, false`

`a,-1`

# elevatorStop

![[polemaShout.png]]
All stop!`a,0.5`

![[akroOrders.png]]
All stop!

`a,-1`

![[proCynical.png]]
(Here it comes...)

`c, polemaApproachesPro`

![[polemaBemused.png]]
Thought it would be that easy?

![[proNonchalant.png]]
No, not really.
![[proSmirk.png]]
Didn't realize you were capable of such elaborate deceptions though, Captain.

![[polemaStern.png]]
Quiet.
I'll admit, the others could indeed be talked into letting you walk into an early grave...
So it's best we nip that in the bud. No one will argue with the results of a proper test of strength.

`c, polemaWalksBack`

![[polemaShout.png]]
Defeat each one of us in open combat, and I will allow you to leave this village.

![[proCynical.png]]
(Ah.)
Even you?

![[polemaBemused.png]]
If you can't even win against me, do you really think you stand a chance against a horde of monsters?

![[proHidingSomething.png]]
(...)

>Come on, we can take her!
>	![[proMildlyConflicted.png]]
>	(What makes you so sure? I've never even come close to beating her on my own.)
>	>What? But you seem so strong. Your sword is huge!
>	>	`proAff+=1`
>	>	![[proBemused.png]] 
>	>	(Aha, thanks.)
>	>	(But, uh... hers is bigger.)
>	>	>Oh. Well, you know what they say about size.
>	>	>	`proAff+=1`
>	>	>	![[proJovial.png]]
>	>	>	(Ha!)
>	>	>	![[proMocking.png]]
>	>	>	(Alright, show me how it's done then.)
>	>	>Oh no.
>	>	>	![[proBemused.png]]
>	>	>	(Heh, yeah.)
>	>	>	![[proConflicted.png]]
>	>	>	(Still, that's hardly a reason to just let her bully me into backing down without a fight.)
>	>I am very good at this sort of thing.
>	>	`proAff+=1`
>	>	![[proSkeptical.png]]
>	>	(Really...?)
>	>	![[proMeditating.png]]
>	>	(Alright, I'll trust you on that.)
>	>She's old.
>	>	![[proCynical.png]]
>	>	(Not old enough for it to matter, trust me.)
>	>	![[proAnnoyed.png]]
>	>	(Argh, even so, I'm not just gonna let her bully me into backing down without a fight.)
>Chin up, I doubt we'll be given an impossible challenge this early on.
>	`proAff+=1`
>	![[proSkeptical.png]]
>	(How... faithful of you.)
>	![[pro.png]]
>	(But alright, I'll believe you.)
>She makes a good point. 
>	![[proCynical.png]]
>	(Yeah, and I've never even come close to beating her on my own.)
>	(Are you telling me we're just screwed here?)
>	>Yes.
>	>	`playerClueless+=1``proAff-=1`
>	>	![[proAnnoyed.png]]
>	>	(Argh...)
>	>	![[proFrustratedSimmering.png]]
>	>	(Even if you say that, I'm not just gonna let her bully me into backing down without a fight.)
>	>No, I think we can win.
>	>	![[proCynical.png]]
>	>	(You "think"...?)
>	>	(...)
>	>	![[proMeditating.png]]
>	>	(Whatever, it's better than nothing.)
>	>Not at all, let's kick her ass.
>	>	`proAff+=2`
>	>	![[proSmirk.png]]
>	>	(Ha!)
>	>	![[pro.png]]
>	>	(Alright, I'm trusting you here.)

![[proDetermined.png]]
Fine, Captain. I'll take you on.

![[polema.png]]
The trainees will go first, in order of experience. Might as well make a training day of this.

![[proCynical.png]]
Mm. Ok.
Not like it'll make a difference.

![[akroWrySmile.png]]
Tough words.

![[kionExclaimingAngry.png]]
Yeah! Tough words!

![[proCynical.png]]
Shut up, Kion.
![[proThinking.png]]
(Ok, beating these guys... shouldn't be too tough.)
![[proHidingSomething.png]]
(I guess Akro might give me some trouble, but it's not like anyone needs to know that.)

>!What about the other two?
>	![[proBemused.png]]
>	(Haha.)
>	(They're kids, what are they gonna do?)
>	![[proMocking.png]]
>	(Chion can't even hold his spear properly.)
>	![[proHidingSomething.png]]
>	(...our fight will probably give you an idea of what the captain'll do to *me*.)

# chionFightStart
![[polema.png]]
Chion, you're up.

![[chionSurprised.png]]
Yes!

`c, proAndChionGetInPosition`

![[polema.png]]
You will fight until one of you yields.
And don't push it. I'm not interested in carrying anyone back unconscious today.

![[proDetermined.png]]
(Here goes.)

![[polemaStern.png]]
Wait.
You weren't planning on using your real blade, were you?

![[proNonchalant.png]]
Why not? They're using their real spears.
I assume we all want this over with quickly.

>!What is that supposed to mean!?
>	![[proRollingEyes.png]]
>	(Oh relax, it's not like I can hit hard enough to *kill* any of them.)

![[polemaStern.png]]
Put a training blade on.

![[proCynical.png]]
Fine.

`c, proEquipsTrainingBlade`

![[polemaShout.png]]
Fighters, ready!
And...
Begin!

`c,chionFightStart`

`x`
# combatInterface
![[proMildSurprise.png]]
(Woah!)
(...)
(Everything's frozen?)
![[proAnnoyed.png]]
(Hrngh...)
`p,1`
![[proCynical.png]]
(Including me...)
![[proMildSurprise.png]]
(Still, this is incredible. Why didn't you mention this before?)
![[proCynical.png]]
(... You do know how this works right?)

>Yes.
>	`var, heKnows`
>Uh...
>	`var, heKnows, 0`

`hdOverlay`
Test, test?
Ah, good, it seems to be working.
Don't worry, we'll get out of your hair soon. This system is a little tricky so we're just here to help you get acquainted.
`if heKnows`
	But hey, you seem pretty confident already, I bet you won't need help at all!
`c,highlightPro,false`
`if gamepad`
	Anyway, why don't you start by selecting Pro's base with your cursor?`a,-1`
`else`
	Anyway, why don't you start by left-clicking on Pro's base?`a,-1`
`hdOverlay`

`x`

# combatInterface2
![[proUpset.png]]
(Blurgh.)
(Stopping and starting like that is nauseating.)
`x`
# chionQuip
![[kionExclaimingAngry.png]]
Hit him Chion!

![[chion.png]]
I-I...

![[kionExclaimingAngry.png]]
Just take a stab!
`x`
# chionQuip2
![[chionHit.png]]
Aah!

![[proSmile.png]]
(Alright!)
(Getting the hang of this.)

>!I feel kinda bad...
>	![[proSmirk.png]]
>	(Blame the captain. And then take it out on her later.)
>	![[proSmile.png]]
>	(I really think we've got a good chance now!)

`x`

# kionStart
`chionDefeated`
![[chionHit.png]]
Ow!
Stop! Stop! I yield!

![[polemaShout.png]]
That's enough.

`c, combatEnd`

`camPan,arenaCenter`
![[kionExclaimingAngry.png]]
No! At least get one hit in! What are you doing!?

![[akro.png]]
Hey. `s,0.5`He did his best, ok?`s`

![[kionRestrainedFrustration.png]]
Mmm...

`c, chionWalksOut`

![[chion.png]]
S-sorry.

![[akroSmile.png]]
Don't feel bad, buddy.
We've all been there.

![[chionSmiling.png]]
Really?

![[proSmirk.png]]
He's lying! I've never been there!

![[polemaBemused.png]]
Oh?

![[proMildSurprise.png]]
Uh-
![[pro.png]]
Kion, we doing this?

![[kion.png]]
!

## kionFightStart

`c, kionWalksIn`
`if seen`
	![[kionExclaimingSmiling.png]]
	Back for more?
	![[proFrustrated.png]]
	Yeah, yeah. Proud of your crappy little fluke?
	![[proFacade.png]]
	I'm gonna wreck you Kion. The training sword won't make any difference.
	![[kion.png]]
	Um... j-just try it.
`else`
	![[kionExclaimingAngry.png]]
	You're gonna pay!
	![[proSmirk.png]]
	Doubt it.

![[polemaStern.png]]
Fighters, ready!
And...
![[polemaShout.png]]
Begin!

`c, kionFightStart`
`x`

### kionFightTutorial

`hdOverlay`
`uiHighlight,0,92,133,177`
Keep an eye on the timeline when planning your turn.
`uiHighlight,35,99,88,164`
Each turn consists of 6 **steps**.
`uiHighlight,35,145,88,156`
Actions you and your enemies queue up can take one or multiple steps to **start up**, **resolve**, then **cool down**.
`uiHighlight,88,145,116,156`
Actions that don't finish by the end of the turn will **spill over** into the next turn.
`uiHighlight,0,92,133,177`
`c,timelineReadOrder,false`
Actions within the same step resolve from **top-to-bottom.** Try reading the progression of events like this.
The main thing to remember is that **Pro will always move first within the same step.**
`var, timelineReadOrderEnd`
`uiHighlight,70,145,81,156`
Pay close attention to when attacks resolve.
`c,kionHighlight`
You'll want to avoid standing in front of where Kion will be when he attacks.
`uiHighlight`
`hdOverlay`

`x`
# kionQuip
![[chionSurprised.png]]
Ah! Watch out!

![[kionRestrainedFrustration.png]]
Gee! Thanks...

`hdOverlay`
Taking an attack will cause a unit to "***Break!***", interrupting their queued actions.
`uiHighlight,35,145,88,156`
After a ***Break***, they'll be stunned for a number of steps, depending on the attack they were hit with.
In this case, **Wooden Swing** deals **3 hitstun**, so Kion is now stunned for 3 steps.
`uiHighlight`
Pay close attention to attack timings, and you're sure to find the opportunity to hit your opponent first!
`hdOverlay`
`x`

# kionQuipTookHit
![[proHit.png]]
Gah!

![[kionExclaimingSmiling.png]]
Haha!

![[proFrustrated.png]]
(Seriously!?)
(*Don't walk straight at him!*)

>I know! I'm sorry!
>Why does it take *you* so long to react?
>	`playerWhiny+=1``proAff-=2`
>	(Physics?)

![[proAnnoyed.png]]
(Look, he sucks at covering his flank. Just *go around*.)

`x`

# akroStart
`kionDefeated`
![[kionHit.png]]
Ow!
Ok, ok! I yield!

![[proSmirk.png]]
Huh? What was that?

![[kionExclaimingAngry.png]]
You-

![[polemaShout.png]]
Cool it.
This match is over.

`c,combatEnd`
`camPan,arenaCenter`

![[kionRestrainedFrustration.png]]
...

`c,kionWalksOut`

![[chion.png]]
Are you ok?

![[kionExclaimingAngry.png]]
I'm fine!

![[akroBemused.png]]
And that's that.

## akroFightStart

`c,akroWalksIn`

![[akroWrySmile.png]]
Ready?

![[pro.png]]
... Always.

`if seen`
	[[#akroCountdown]]

![[akro.png]]
I won't be holding back. You can use your real sword.

![[proCynical.png]]
Generous of you.
![[proAnnoyed.png]]
(Ugh. This guy.)
![[proCynical.png]]
(Always looking out for everyone.)

>Is that a bad thing?
>	(Please. How do you even trust a guy like that?)
>Yeah. I know the type.

(I swear he's just gunning for my job.)
![[proRollingEyes.png]]
(I'm even a better fighter, but the Captain wouldn't have batted an eye if *he* was the one leaving.)

>!Is that true?
>	![[proHidingSomething.png]]
>	(Yeah-huh. I win against him, like, seven times out of ten. Well, six. But who's counting?)

![[proDetermined.png]]
(Anyway, he's not gonna be as easy as the others. He's got the range and speed to pose an actual threat.)
`a,0.2`(I can't match his initial speed with my sword-) 
![[proMildSurprise.png]]
(Ah, speaking of...)
`c,proEquipsRegularSword`
![[pro.png]]
(As I was saying, his range and speed are a threat, so be careful as you approach.)

![[proSmirk.png]]
(It's tricky for me to get the spacing and timing down on my own, but you should be able to plan it out no problem.)

![[akroSurprised.png]]
By the way, what's with your movements today?

![[proSmirk.png]]
Pay attention and maybe you'll find out.

### akroCountdown
![[polemaShout.png]]
Fighters, ready!
And...
Begin!

`c,akroFightStart`

`x`

### akroFightTutorial

`if seen`
	[[#failureTutorial]]

`hdOverlay`
It's important to pay attention to enemy attack ranges.
`if gamepad`
	You may have already noticed that viewing the timeline with **LB** or selecting Pro will show a **preview** of actions on a specific step.
	If you accidentally move into danger, you can use **LT** to undo any actions you've queued this turn.
	`c,akroHighlight,false`
	Additionally, you can press **Y** while hovering over a unit to **pin** a preview of all their planned actions. Try it now.`a,-1`
`else`
	You may have already noticed that hovering the mouse over the timeline or selecting Pro will show a **preview** of actions on a specific step.
	If you accidentally move into danger, you can use the **Right Mouse Button** to undo any actions you've queued this turn.
	`c,akroHighlight,false`
	Additionally, you can **middle-click** a unit (or press **Ctrl** while hovering over them) to **pin** a preview of all their planned actions. Try it now.`a,-1`
`hdOverlay`

`x`

### akroTutorialSpurned
Or don't, geez...`a,0.5`
`hdOverlay`
`x`

# akroTookHit
![[proHit.png]]
Ow!

![[proAnnoyed.png]]
(C'mon, I saw that coming a mile away!)
(Just... don't get too close. Try to stay out of reach of his spear.)

>Ok.
>Why is his attack called that?`if !seen`
>	![[proSkeptical.png]]
>	(Called what?)
>	>..."Akro's Attackro".
>	>	`proAff+=0.5`
>	>	![[proMildSurprise.png]]
>	>	(Wh- you can tell!?)
>	>	![[proLaughing.png]]
>	>	(Hahaha!)
>	>	![[proSmile.png]]
>	>	(I used to tease him with that when we were kids.)
>	>	(Man, that was...)
>	>	![[pro.png]]
>	>	(...years ago...)
>	>	![[proMildlyConflicted.png]]
>	>	(Hm.)
>	>Nevermind.
>...

`x`

# traineesStart
`akroDefeated`
![[akroPain.png]]
Kh-!
I yield!

`if !tookDamageFromAkro`
	![[polemaPain.png]]
	Not a scratch...

`c,combatEnd`
`camPan,arenaCenter`

![[akroQuestioningConcerned.png]]
What was that movement?
It's as if you knew exactly where I'd thrust ahead of time.
![[akroPain.png]]
No, more like, you could see it as soon as I'd thought it.

![[proSmirk.png]]
My friend.
*This* is what it means to be guided by the Patron.

![[polemaBemused.png]]
I refuse to believe you're being given instructions that precise.
Unless you've been ignoring any advice unrelated to fighting.

![[proMildSurprise.png]]
Er...
![[proFacade.png]]
(That's not true, right?)

>Of course not, you've been very receptive!
>	`proAff+=1`
>	![[proSmile.png]]
>	(Whew.)
>You could stand to listen to me more.
>	`playerWhiny+=1``proAff-=1`
>	![[proRollingEyes.png]]
>	(Is that so? We've gotten this far just fine, haven't we?)
>Bro.
>	![[proEmbarrassed.png]]
>	(Well! Maybe you should give better advice!)
>	![[proNonchalant.png]]
>	(Whatever, we've gotten this far.)

![[pro.png]]
Ok Captain, let's do this.

![[polema.png]]
Not so fast.
The three of you will fight Pro all at once.

`c,traineesShock`

![[proMildSurprise.png]]
`a,0.3`What a sham!

![[kionExclaimingSmiling.png]]
You're really in for it now!

![[chion.png]]
Um- um...

![[akroSurprised.png]]
Captain, are you sure-

![[polemaBemused.png]]
`a`I am quite sure.
Monsters seldom fight alone.
I want to see how well this *guidance* fares against multiple opponents.
All of you, get up here.

![[]]
Captain!

## traineesFightStart

`c,traineesWalkIn`

`if seen`
	![[akroQuestioningConcerned.png]]
	I'll admit, this still doesn't seem fair.
	![[proCynical.png]]
	Whatever. I've got you guys figured out, just watch.
	[[#traineesCountdown]]

![[akroSmile.png]]
I'm sorry to gang up on you like this.

![[kionExclaimingAngry.png]]
I'm not!!

![[chion.png]]
...

![[proNonchalant.png]]
(Well, it's not so bad. With any luck they'll just get in each other's way.)

### traineesCountdown
![[polemaShout.png]]
Fighters, ready!
And...
Begin!

//set flags
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
	If you need to get a better view, you can move the camera around with the **right-stick.** Try it now.
`else`
	If you need to get a better view, you can move the camera around with the **WASD** keys, or by moving the mouse to the edge of the screen. Try it now.
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
Oww...
I-I yield!

`c, chionWalksOut`

[[#traineeDone]]
## kionOut

![[kionHit.png]]
Argh... 
Ok, I'm out.

`c, kionWalksOut`

[[#traineeDone]]

## akroOut
![[akroPain.png]]
Ack-
Ok, that's enough for me.

`c, akroWalksOut`

[[#traineeDone]]

# polemaStart
`traineesDefeated`
![[polemaStern.png]]
...

`c, combatEnd`
`camPan,arenaCenter`

![[pro.png]]
Whew.
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
Too impressed to call it?

`c,polemaWalksIn`

### polemaFightStartB

![[polemaStern.png]]
Akro, my sword.

![[akroQuestioningConcerned.png]]
Ah... yes captain.

![[proMildSurprise.png]]
W-whoa. No rest for the valiant...

### polemaCountdown

`c,polemaFightStart`

`x`

### polemaFightTutorial

`if seen`
	[[#failureTutorial]]

`hdOverlay`
`uiHighlight,9,143,127,158`
Certain powerful opponents will be able to **react** to you.
`uiHighlight,60,143,92,158`
Actions that **start** within this highlighted area on the timeline will **change** in response to your plans.
`uiHighlight`
//They'll also be able to queue up actions immediately after a **Break**.
To find your mark, you'll have to catch your opponent **when they can't react**.
`uiHighlight,35,146,62,155`
Pay attention to actions that start early, those will remain locked in.
`uiHighlight`
`hdOverlay`

`x`

# failureTutorial

`hdOverlay`
`if seen`
	Think it through. Stay focused. Don't falter.
	It might seem impossible now, but you'll look back on this and laugh.
	Focus on the **timeline**. Pay attention to your position at every **step**. You'll find an opening.
	`if tutorialLostTo == polema`
		Remember, you can freely queue up and undo different plans to see how your opponent will **react** before you commit to anything.
	Remain calm. I'm certain you can make it through.
	`hdOverlay`
	`x`

Dang, this fight is tough, isn't it?
`uiHighlight,0,92,133,177`
Remember to **pay close attention to the timeline.** You should always be looking at it before anything else.
`c,timelineReadOrder,false`
`unskip`Remember, actions within the same step resolve from **top-to-bottom.**
`unskip`**Pro will always move first within the same step!**
`var, timelineReadOrderEnd`
`uiHighlight`
`if gamepad`
	Plan things out carefully. Try queuing up different plans to see how they look on the timeline. You can always undo a plan with **LT**.
	`c,highlightTimelineAndUnblock`
	If you need a more detailed look, you can focus on the timeline with **RB**. Take full advantage of this! It's really important! You'll probably need to do it a lot!
`else`
	Plan things out carefully. Try queuing up different plans to see how they look on the timeline. You can always undo a plan with the **Right Mouse Button**.
	`c,highlightTimelineAndUnblock`
	If you need a more detailed look, you can hover on the timeline with your mouse. Take full advantage of this! It's really important! You'll probably need to do it a lot!

`c,unhighlightTimeline`
`hdOverlay`
`x`

# polemaMid
![[polemaPain.png]]
Kh-!

`if seen`
	![[polemaOverexerted.png]]
	Alright... let's get serious.
	![[akroQuestioningConcerned.png]]
	...
`else`
	![[akroOrders.png]]
	Alright that's-
	![[polemaOverexerted.png]]
	Wait.
	I'm fine. Keep going.
	![[akroSurprised.png]]
	Captain, you-
	![[polemaPain.png]]
	I do *not* yield!
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
Don't...

`c,polemaCollapses`

![[akroSurprised.png]]
`a,0.3`!

![[chionSurprised.png]]Captain!

![[kion.png]]...//todo: need a surprised expression

`a`
`if combatTutorialFailed`
	`c,combatEnd`
	`camPan,arenaCenter`
	[[#polemaCartedAway]]

![[akroOrders.png]]
Alright, both of you, get ready, we're headed back up.

![[kion.png]]
R-right.

`c,combatEnd`
`camPan,arenaCenter`

![[pro.png]]
(...)
>We did it!
>	(Uh.)
>	![[proSmile.png]]
>	(Yeah. Yeah!)
>	(We did!)
>	![[pro.png]]
>	(...)
>Happy?
>	![[pro.png]]
>	(I... suppose so.)

(...)

// ![[proCynical.png]]
// `a,0.1`(So what happens n-)
// `c, paxDemoOutro, false`
// `x`

# elevatorRises
`c,elevatorRises`

# polemaCartedAway
![[akroQuestioningConcerned.png]]
Quick, get the stretcher.

![[kion.png]]
On it!

`c,chionAndKionGetTheStretcher`

![[akro.png]]
Got her?

![[kion.png]]
Yup.

![[chion.png]]
Y-yes.

![[akroOrders.png]]
Alright, bring her to the infirmary, quick as you can.
I'll stay here and *keep watch*.

![[kion.png]]
Yeah. Ok.

`c,chionAndKionCarryPolemaAway`

![[akroQuestioning.png]]
Love that kid, but someone needs to teach him to be a little more skeptical.

`facePlayer,akro``p,0.5`

![[akroBemused.png]]
Alright, let's get you out of here.

![[proMildSurprise.png]]
`face,pro,akro`
...
Wait, really? 
Why did you bother staying behind then?

![[akroBemusedOpenMouth.png]]
`if combatTutorialFailed`
	I don't want you to leave the elevator down below to get trashed.
`else`
	I don't want you to leave this thing down below to get trashed.

![[akroBemused.png]]
Or try to send it up without anyone on board.

![[proFacade.png]]
I wouldn't.

![[akroWrySmile.png]]
Ha! Haha! You lie like a kid.
![[akro.png]]
Alright, let's get out of here.

`c,akroAndProWalkToElevator`

// ![[akro.png]]
// Ok, all clear. Let's move.

// `c,elevatorDescends`

# akroConvo

`c,setupAkroConvoFromLoad`//only if loading from save, sets up cutscene

![[akro.png]]
Oh, feel that?
I think we just passed the <span style="color:rgb(225, 188, 105)">Fixture's boundary</span>.

![[proConflicted.png]]
Mm...

`if fromLoad`
	>(Tune out)
	>	[[#elevatorReachesBottom]]
	>(Keep listening)

`p,1.5`

![[proHidingSomething.png]]
...

![[akro.png]]
Something bothering you?

![[pro.png]]
... Why are you helping me?

![[akroBemusedOpenMouth.png]]
It's not like I could've stopped you.

![[proHidingSomething.png]]
Yeah, I get that. It's just... I was expecting more resistance.

![[akroQuestioningConcerned.png]]
Why?
Oh, you thought I'd be scared of getting in trouble with the captain?
Don't worry, I know she'll understand.
![[akroBemused.png]]
Well, eventually. She *really* didn't want to let you go.
![[akroWrySmile.png]]
You've got me second-guessing this now, haha.

![[proMildSurprise.png]]
See? Right there.
You're laughing about it, but I- I never thought you'd risk upsetting the captain for *me*.

![[akro.png]]
Why not?

![[proConflicted.png]]
Because, well...
You don't like me?

![[akroQuestioningConcerned.png]]
Woah, where'd this come from?

![[proMildlyConflicted.png]]
I... always thought bringing it up would be petty.
But whatever, I'm leaving. We don't need to hold back.

![[akro.png]]
I think everyone wishes you would take things more seriously.
But you're making it sound like I hate your guts.

`c,proConfrontsAkro,false`

![[proFrustrated.png]]
How couldn't you!?
You're such a tryhard, everyone loves you, they obviously think you're better than me.
![[proMildlyConflicted.png]]
But I'm the one who gets to be the hero. Just because I was born into it.

![[akroQuestioning.png]]
"Gets" to be?
![[akroWrySmile.png]]
Ha, man, it's true, you're not just hiding it, it really doesn't faze you at all.
![[akroQuestioningConcerned.png]]
You think I want to take a walk in the woods with a one in ten chance of killing me?
![[akroBemusedOpenMouth.png]]
Not to mention the pressure.
I can't believe you haven't had a nervous breakdown from all the grief everyone gives you.

![[proMildSurprise.png]]
Oh. M-me neither.
![[proSoftSmile.png]]
...
![[proMildlyConflicted.png]]
...
Sorry.

![[akroWrySmile.png]]
Haha.
I guess I was a little upset that you stopped wanting to hang out.
I just figured you had a lot on your plate.

![[proNonchalant.png]]
Huh. Man... you really are just that nice...

![[akroSmile.png]]
Maybe.
![[akro.png]]
...
Looks like we're almost there.

![[proHidingSomething.png]]
Yeah.

![[akro.png]]
...
Why *do* you want to leave so badly? Are we really that grating?

![[proHidingSomething.png]]
... I don't know.
![[proDisdainful.png]]
I'm just sick of being boxed in.
![[pro.png]]
Out there I'll have some room to be myself.

![[akro.png]]
Instead of having to play the hero?

![[proAnnoyed.png]]
Maybe!
Or maybe I'll be a hero- the hero.

![[proCynical.png]]
I just don't want to be *their* hero, y'know?

![[akroSmile.png]]
I see.

# elevatorReachesBottom

`c,elevatorReachesBottom`

![[akro.png]]
Alright, that's as far as I go.

![[pro.png]]
Itching to get back up?

![[akro.png]]
Uh, yeah, kinda.
`face,akro,up`
![[akroQuestioningConcerned.png]]
...

![[pro.png]]
What's up?

![[akroQuestioningConcerned.png]]
`face,akro,left`
Sorry, it's just hitting me how bad this is gonna look on me if you don't come back.
You're really sure about this? You won't be able to come back up for a while.
There probably won't be anyone watching the elevator until the captain is back on her feet.

![[proMeditating.png]]
Yes, I'm sure... 
`a,0.5`![[proJovial.png]]...not that you could stop me now!
`a,0.2`![[proLaughing.png]]Haha!
`c,proRunsOffTheElevator`

`a`![[akroQuestioningConcerned.png]]
Geez...
![[akro.png]]
Ok, good luck out there.

![[proSmile.png]]
See ya!

![[akro.png]]
Yeah, see ya...

`c,elevatorReturnsWithAkro`

![[pro.png]]
(Sorry you had to sit through that.)

>I'm glad you were able to work through things.
>	`proAff+=1`
>	![[proNonchalant.png]]
>	(Yeah, somewhat...)
>	![[proJovial.png]]
>	(Now let's go!)
>No worries. Onwards!
>	`proAff+=2`
>	![[proJovial.png]]
>	Yeah!
>It's fine.
>I wasn't listening.
>	`playerClueless+=1``proAff-=1`
>	![[proNonchalant.png]]
>	(Fair enough.)
>	![[pro.png]]
>	(Let's go.)
>Doesn't matter, we're out. Give me my prize.`if pinwheelPrizeMentioned`
>	![[proSkeptical.png]]
>	(What?)
>	![[proCynical.png]]
>	(Oh... for the pinwheels?)
>	(Are you kidding?)
>	>Yes. Haha. I wasn't expecting anything at all.
>	>	`proAff+=2`
>	>	![[proSmirk.png]]
>	>	(Uh huh?)
>	>I am not kidding.
>	>	`playerCaresAboutPinwheels``proAff-=1`
>	>	![[proCynical.png]]
>	>	(There's- there's no prize man. I'm sorry.)
>	>	>Aw...
>	>	>I will remember this.
>	>	![[proCynical.png]]
>	>	(I- look, I'll make it up to you.)
>	>	![[proNonchalant.png]]
>	>	(I'm sure there'll be something interesting out here.)

`combatTutorialDone`
`inIrisIntro`

`x`

# failure

`c,proWakesUpAfterFailure`

`if combatTutorialFailed`
	![[proCynical.png]]
	(...)
	(Well... at least we're making progress.)
	(...I think.)
	`c, proGetsUpAfterFailure`
	`x`

`combatTutorialFailed`
![[proAnnoyed.png]]
Urgh...
>!What happened?
>	(... We lost.)
>	>Why are we in your room?
>	>	![[proEmbarrassed.png]]
>	>	(Someone probably carried me here after I passed out.)
>	>Does this happen often to you?
>	>	![[proCynical.png]]
>	>	(It hasn't been, lately.)
>	>	(Thanks for the guidance, by the way.)

![[salviaConcern.png]]
Pro? 

`c,salviaWalksInAfterFailure`

Oh good, you're awake. I was worried you'd be out for hours.
...

`if saidGoodbyeToMom`
	After you gave me that big goodbye I didn't quite know what to expect.
`else`
	![[salviaSerious.png]]
	Honestly. Running off to fight the captain without saying a word?

![[proAnnoyed.png]]
You seem relieved...

![[salviaConcern.png]]
Well... I suppose I am happy to see you're still yourself. Still fighting 'til you're limp.

`if tutorialLostTo == kion`
	You gave poor Kion the fright of his life.
	![[proMildSurprise.png]]
	(No... no, no, no.)
	![[proPanicked.png]]
	I lost to *Kion*.
	![[salviaConcern.png]]
	Well I don't know exactly what happened between you all.
	But the boy seemed downright thunderstruck.
	![[proAnnoyed.png]]
	Aaauughh.....
	![[proSad.png]]
	(Why!? Why would you do this me?)
	>!I'm sorry!
	>	![[proFrustrated.png]]
	>	(I don't believe you!!)
	![[salvia.png]]
	Oh, no need to be so worried.
	I'm sure Kion will be fine.
`else if tutorialLostTo == akro`
	I mean, how many times does this make?
	I'd have thought you and Akro would learn to be more careful by now.
	![[proAnnoyed.png]]
	Ugh.
	(This is why I never go to group practice. Kion's never gonna shut up about this.)
	>!That's really why you don't go to group practice?
	>	![[proCynical.png]]
	>	(...)
	>What about Akro?
	>	(He just silently lords it over me.)
	>	![[proCynical.png]]
	>	(I'd say it's "even worse" but Kion is *really* annoying.)
`else if tutorialLostTo == guards`
	Though it hardly seems fair to me that you were made to fight all three of those boys at once.
	I suppose the captain wanted to teach you a proper lesson.
	![[proAnnoyed.png]]
	How much did she tell you?
	![[salvia.png]]
	Not much. Kion, on the other hand... talkative as always.
`else if tutorialLostTo == polema`
	I suppose it's no surprise though, trying to fight the captain herself. What were you thinking?
	![[proHidingSomething.png]]
	Mmm...

![[salvia.png]]
Anyway, pick yourself up already. Don't spend *another* afternoon moping on the floor.

![[proCynical.png]]
Mom.

![[salviaQuestioning.png]]
What? You know, I can hear it when you whinge out loud in here.

![[proFrustrated.png]]
Mom! A little discretion, please?

![[salvia.png]]
What do you... Oh!
Yes, of course. Wouldn't want to give a bad first impression!

>I think that ship has sailed.
>	![[proAnnoyed.png]]
>	(Quiet.)
>	![[salvia.png]]
>	...hm?
>	![[proHidingSomething.png]]
>	Nothing.
>...

Well then, if you've got it all out of your system you should go out for a bit.
Everyone must be excited to speak with you after all.
I'll let you sort yourself out.

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
	... Again, then.
	`c,tutorialReset`

`if seen`
	![[polema.png]]
	Yes?
`else`
	![[polema.png]]
	Ah. You're finally up.
	Care to join in?

![[proHidingSomething.png]]
(...)

>What are you waiting for? Challenge her again.
>	![[proDetermined.png]]
>	We're ready to go again.
>	![[polemaBemused.png]]
>	"Go again"?
>	That was a one-time opportunity, cadet.
>	![[proStressed.png]]
>	...
>	>Force the issue.
>	>	`c,proThreatensPolema`
>	>	`polemaThreatened`
>	>	![[proDetermined.png]]
>	>	...
>	>	![[polemaPain.png]]
>	>	...
>	>	![[akroSurprised.png]]
>	>	Woah, uh...
>	>	![[chion.png]]
>	>	C-captain?
>	>	![[polemaStern.png]]
>	>	...
>	>	![[polemaShout.png]]
>	>	Alright!
>	>	![[polema.png]]
>	>	We'll do this as many times as it takes, then.
>	>	![[polemaShout.png]]
>	>	Cadets!
>	>	![[]]
>	>	Captain!
>	>	![[polemaShout.png]]
>	>	Clear the floor.
>	>	![[]]
>	>	Yes, captain!
>	>	`c,tutorialReset` //jumps to last failed fight
>	>Let's back off for now.
>	>	![[proHidingSomething.png]]
>	>	`if backedOutOfTutorialRematch`
>	>		... Nevermind then.
>	>		`c,proBacksOutOfFight`
>	>		`x`
>	>	... Fine.
>	>	Then... I should go. Talk to everyone.
>	>	[[#backedOff]]
>Let's back off for now.
>	![[proHidingSomething.png]]
>	`if backedOutOfTutorialRematch`
>		... Nevermind.
>		`c,proBacksOutOfFight`
>		`x`
>	No... just... came to let you know I'll be busy.
>	Talking to the others.
>	[[#backedOff]]

## backedOff
![[polemaSkeptical.png]]
I see.
![[polema.png]]
Take the time you need.
![[proHidingSomething.png]]
Mm.
`backedOutOfTutorialRematch`

`c,proBacksOutOfFight`
`x`




