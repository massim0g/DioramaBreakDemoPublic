# firstImpressions
//this dialogue is deprecated, unused
`c,proWalksAlongForestPath,false`
![[proThinking.png]]
(I wonder what the people outside are like.)
![[pro.png]]
(I've never really had the chance to give a first impression.)
>!What about me?
>	`proAff+=1`
>	![[proNonchalant.png]]
>	(Oh. I guess that counts.)
>	![[proRollingEyes.png]]
>	(I think you can see why I'd want to be a bit more prepared though.)
>What do you mean?
>	`proAff+=1`
>	![[proNonchalant.png]]
>	(Well, because everyone in the village has known me since I was a baby.)

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
>	>That was scary!
>	>	![[proStressed.png]]
>	>	(Let's just handle it...)
>	>...
>	>	![[proMocking.png]]
>	>	(What are *you* so scared of...?)
>	>	(...)
>	>	![[proAnnoyed.png]]
>	>	(Haah...)
>	>	![[proStressed.png]]
>	>	(Let's just handle it.)
>	`x`

![[proFearful.png]]
(...)
![[proAnnoyed.png]]
(Haah...)
![[proStressed.png]]
(Ok. We can handle this, no problem...)
>Yup, looks easy.
>	![[proStressed.png]]
>	(Great. Just kill it quick.)
>Scared?
>	![[proAnnoyed.png]]
>	(No!)
>	![[proStressed.png]]
>	(It- it's alone, how dangerous could it be?)

`x`
## firstMonsterHit
![[proHit.png]]
Gh-
![[proFearful.png]]
(It's... ok, I'm ok.)
`tookDamageFromFirstMonster`
`x`

## firstMonsterDefeated
![[proMildSurprise.png]]
Alright!
![[proNonchalant.png]]
(That wasn't bad at all! I don't get what they were worried about.)
![[proThinking.png]]
(I guess having the power to stop time doesn't hurt.)
>!And my impeccable strategic guidance?
>	![[proBemused.png]]
>	(Uh, sure.)

`if tookDamageFromFirstMonster`
	![[proMildlyConflicted.png]]
	(Still, we should be more careful not to take hits.)
	(The <span style="color:rgb(225, 188, 105)">Air</span> here is... thin. I don't feel like I can recover as easily...)
`else`
	![[proConflicted.png]]
	(... Good thing we didn't take any hits. The <span style="color:rgb(225, 188, 105)">Air</span> here is... thin.)
	(I don't feel like I can recover as easily...)

`firstMonsterDefeated`
`inIrisIntro=2`
`camReset`
`x`

# deepShrine
![[minimaSurprisedSmile.png]]
Oh! There it is!

`c,minimaWalksToFixture`

![[minimaSmile.png]]
This <span style="color:rgb(225, 188, 105)">Fixture</span> only covers a small area but we should be safe from monsters here.

![[pro.png]]
Cool.
>!Is that like the one that protects your village?
>	(Yeah. Smaller though.)

`x`
## deepShrineChest
`if seen`
	![[pro.png]]
	(There's nothing left here that fits me.)
	`x`

![[pro.png]]
What's in this chest?

![[minima.png]]
The mailmen keep them stocked with supplies and equipment.
![[minimaSmile.png]]
Check it out, maybe you'll find something in your size.

![[proSkeptical.png]]
They don't mind us taking stuff?

![[minimaLecturing.png]]
Nah, that's what it's there for.
And it's not like there's anyone besides us and them passing through here anyway.

`p,1.5`

![[proRollingEyes.png]]
(Doesn't look like there's much to take anyway...)

`itemCollect,normalBoots`
`gameSave`
`x`

# craft
`if irisVestFixed&&irisBootsFixed`
	![[pro.png]]
	(I think we've taken everything usable here.)
	`x`

`if !seen`
	![[proCynical.png]]
	Hm. There's some old equipment but it doesn't seem very usable.
	`s,0.5`Who's just been dumping their trash in here?`s`
	![[minimaLeaningIn.png]]
	Nah, that looks totally fixable.
	![[minimaSmile.png]]
	If you pick up enough useful materials from the forest I can probably repair this stuff.
	>!Can she?
	>	![[proSkeptical.png]]
	>	... Really?
	>	![[minimaEmbarassed.png]]
	>	Well... it was covered in the survivalist course I took at least.
	>	![[proThinking.png]]
	>	Ah...
	>	![[proMildlyEmbarassed.png]]
	>	(Probably should've paid more attention when Fibra was teaching this sort of stuff...)
	>	![[proFacade.png]]
	>	Alright, no harm in trying then.
	>	![[minimaSmile.png]]
	>	Cool!
	[[#craftCost]] 
## craftChoice
![[minimaSmile.png]]
So, what'll it be?
>Fix the vest.`if !irisVestFixed`
>	![[pro.png]]
>	Fix the vest, please.
>	![[minimaCheeky.png]]
>	You got it!
>	`c,fixVest`
>	`if craftFailed`
>		[[#craftFail]]
>Fix the pair of boots.`if !irisBootsFixed`
>	![[pro.png]]
>	Fix the boots.
>	![[minimaCheeky.png]]
>	You got it!
>	`c,fixBoots`
>	`if craftFailed`
>		[[#craftFail]]
>Fix both.`if !irisVestFixed && !irisBootsFixed`
>	![[pro.png]]
>	Can you fix both?
>	![[minimaCheeky.png]]
>	Sure!
>	`c,fixVestAndBoots`
>	`if craftFailed`
>		[[#craftFail]]
>How much stuff do we need again?`if !irisVestFixed || !irisBootsFixed`
>	[[#craftCost]]
>Nevermind.

`x`
## craftCost
![[minimaLookingAway.png]]
Let's see...
`if !irisBootsFixed`
	The boots will need, let's say, **2** pieces of **corneal wood** and **3** lengths of **string**.
`if !irisVestFixed`
	The vest will probably need **1** piece of **corneal wood** and **6** lengths of **string**.

[[#craftChoice]]

## craftFail
![[minimaLookingAway.png]]
Mm... is that all you have?
![[minimaMildlyAnnoyed.png]]
I don't think this is gonna be enough.
![[minimaSheepish.png]]
Sorry.
![[proNonchalant.png]]
No worries.
(Guess we've gotta hike around a bit more if we want that.)
`x`

# returnedToElevator
![[pro.png]]
...
![[minima.png]]
...
So...?
![[pro.png]]
There should be someone posted up top watching for visitors.
![[proNonchalant.png]]
We just gotta wait for them to send the elevator down.
![[minima.png]]
Alright.
`c,elevatorWait`
![[proCynical.png]]
Ok. It's been long enough.
I don't think we're getting up there today.
![[minimaSheepish.png]]
Aw, bummer.
Sorry to have made you trek back here.
![[proHidingSomething.png]]
Don't worry about it, really.
![[proDisdainful.png]]
...what's taking them so long?
>!This kind of work is hard, you know!
>	![[proCynical.png]]
>	(Uh huh. I'm sure you know all about it.)

`x`

# opinionOfPlayer
`c,restTalkStart`
![[minimaLookingAway.png]]
So... what's it like.
![[pro.png]]
What's what like?
![[minimaBemused.png]]
Talking to "god"?
![[proAnnoyed.png]]
They're not *god*.
![[proCynical.png]]
And I thought you said the whole idea was insane.
![[minimaBemused.png]]
Yeah, and? I'm still curious.
![[proHidingSomething.png]]
Pfft...
...

//since 4.5 affinity points can be gained in the consequence encounter alone, checks are reduced here
//The levels here are: You are cheating, very positive, lukewarm, negative
`if proAff>=21`
	![[pro.png]]
	It's pretty nice actually.
	![[proThinking.png]]
	Feels like... they always know what to say.
	![[proConflicted.png]]
	Like, exactly what to say.
	Hm.
	Come to think of it, it's kinda weird.
	![[minima.png]]
	Is it?
	![[proDisdainful.png]]
	Yeah, like they're trying *too* hard to get on my good side, y'know?
	![[minimaSheepish.png]]
	Uh... not really.
	![[proDisdainful.png]]
	One sec.
	(What's up with that?)
	>I don't know what you're talking about.
	>	![[proSkeptical.png]]
	>	(...)
	>	![[proNonchalant.png]]
	>	(Ah, whatever, I'm probably overthinking it.)
	>	![[minima.png]]
	>	So...
	>	![[pro.png]]
	>	Oh, uh, nevermind. They're fun, they give good advice.
	>	No complaints, really.
	>	![[minima.png]]
	>	Gotcha...
	>Ok fine, I looked up a guide on how to get you to like me.
	>	`proAff-=8`
	>	![[proBemused.png]]
	>	(Haha, wh- what? That's a thing?)
	>	(I- I don't know if I should be flattered or...)
	>	>I'll stop...
	>	>	`proAff+=2`
	>	>	![[proBemused.png]]
	>	>	(Oh, no, don't stop on my behalf, I don't mind.)
	>	>	(Despite how pathetic it is.)
	>	>...
	>	>	![[proMocking.png]]
	>	>	(Are you gonna keep using it?)
	>	>	(I don't really mind, but that's super pathetic.)
	>	![[minimaBemused.png]]
	>	Uh, Pro? Did you get in a fight or something?
	>	![[proMocking.png]]
	>	Kinda. Get this, `$player` is apparently using a guide on how to get me to like them.
	>	![[minimaBemused.png]]
	>	Ha. What?
	>	![[proMocking.png]]
	>	Yeah, that's what *I* said.
	>	![[minimaBemused.png]]
	>	No, I mean...
	>	You're saying your "patron" is desperate to get you to like them?
	>	![[proMildSurprise.png]]
	>	Uh...
	>	![[minimaBemused.png]]
	>	Maybe I *did* have the wrong idea about what this was.
	>	![[proMildlyEmbarassed.png]]
	>	Well, you see-
	>	![[minimaSmile.png]]
	>	No, no. I get it. Making real friends is tough.
	>	![[proFrustrated.png]]
	>	Can we talk about something else?
	>	![[minimaJovial.png]]
	>	Sure, sure.
`else if proAff>8`
	![[pro.png]]
	It's pretty nice actually.
	![[proHidingSomething.png]]
	Growing up, I always worried the Patron would be like all the other stuffy adults in my life.
	![[proSmile.png]]
	But honestly, they're pretty fun to talk to.
	>!Aw, thanks.
	![[minimaBemused.png]]
	So, the voice in your head just always tells you what you wanna hear?
	![[proThinking.png]]
	No, not always.
	![[pro.png]]
	But they're not really *annoying* about it, y'know.
	![[minimaSkeptical.png]]
	Maybe? I don't really know what you find annoying.
	![[proThinking.png]]
	Um...
	![[proAnnoyed.png]]
	I guess I'm just sick of people telling me what's supposedly good for me.
	![[minimaSheepish.png]]
	Oh. Yeah, that *would* be a reasonable reaction to being raised by a bunch of crazies.
	![[proCynical.png]]
	Uh... yeah.
`else if proAff>2.5`
	![[proNonchalant.png]]
	It's fine.
	`$player` is kinda boring to be honest.
	>!Hey!
	>	![[proMocking.png]]
	>	(What? You are.)
	![[proRollingEyes.png]]
	They got me this far though, so I can't complain *too* much.
	>!Too much?
	>	![[proCynical.png]]
	>	Well...
	>	[[#playerComplaints]]
	[[#lukewarmEnd]]
`else`
	![[proHidingSomething.png]]
	I don't know.
	I shouldn't really complain, they got me this far.
	But `$player` kind of sucks.`var, playerSucks`
	>What!? How?
	>	[[#playerComplaints]]
	>Yeah...
	>	`proAff+=0.5`
	>	![[proConflicted.png]]
	>	(What, now you feel bad?)
	>	[[#doneComplaining]]

`c,restStart`
`x`
## lukewarmEnd
![[proNonchalant.png]]
So yeah, overall it's been so-so.
![[minimaSurprised.png]]
Huh. What a surprisingly grounded take.
![[proMocking.png]]
Sorry to disappoint.
`c,restStart`
`x`
## playerComplaints

`if playerCalledProSubhuman`
	`var, complained`
	![[proDisdainful.png]]
	(You literally called me "subhuman" when we first met.)

`if playerCaresAboutPinwheels`
	`var, complained`
	![[proCynical.png]]
	(You have a weird obsession with pinwheels...)

`if playerSidedWithGirls`
	`var, complained`
	![[proMocking.png]]
	(You sided with Api and Oiko, of all things.)

`if playerTeasedProAboutBooks`
	`var, complained`
	![[proHidingSomething.png]]
	(You teased me about the books that one time.)
	>!In the mayor's house? That was a joke.
	>	![[proConflicted.png]]
	>	(Yeah, whatever.)

`if playerSidedWithDendro`
	`var, complained`
	![[proAnnoyed.png]]
	(You seem to think the mayor is sooo great...)
	>!He's clearly just doing his best.
	>	`proAff-=2`
	>	![[proConflicted.png]]
	>	(Uh huh.)

`if playerWhiny>=2`
	`var, complained`
	![[proCynical.png]]
	(You're... kinda whiny.)

`if playerClueless>=2`
	`var, complained`
	![[proCynical.png]]
	(You say really tactless things sometimes.)

`if !complained`
	`if playerSucks`
		![[proCynical.png]]
		(... I don't know how. You just do.)
		[[#doneComplaining]]
	`else`
		![[proThinking.png]]
		(...) 
		(... Actually I can't really think of anything to complain about.)
		![[pro.png]]
		(I guess you're not *that* bad.)
		>!Gee, thanks.
		>	![[proSmirk.png]]
		>	(You're welcome.)
		[[#lukewarmEnd]]
`else`
	`if playerSucks`
		![[proHidingSomething.png]]
		(...)
		>Is that it?
		>	![[proDisdainful.png]]
		>	(Yeah.)
		>I'm sorry.
		>	`proAff+=0.5`
		>	![[proConflicted.png]]
		>	(...)
		[[#doneComplaining]]
	`else`
		![[proNonchalant.png]]
		(But hey, like I said, no big deal.)
		[[#lukewarmEnd]]

## doneComplaining
![[minimaApprehensive.png]]
Um. Sorry if that was too rude. I didn't realize you felt that strongly-
![[proMildSurprise.png]]
Oh. No, it's fine.
![[proBemused.png]]
I'm not upset at *you* or anything.
![[minimaSmile.png]]
Oh, whew, ok.
Wanna talk about something else?
![[proMeditating.png]]
Sure.
`c,restStart`
`x`

# swearing
//stewards cut-to functionality unfinished
`c,restTalkStart`
![[minima.png]]
Y'know, I don't think I've heard you swear even once.
![[proSkeptical.png]]
What? Pretty sure I've said, like, damn, crap, ass...
![[minimaBemused.png]]
Haha ok, but that hardly counts, does it?
![[proMildSurprise.png]]
It... doesn't?
![[minimaLeaningIn.png]]
Wait, do you not know any harder swears!?
![[proMildlyEmbarassed.png]]
Er...
![[minimaLaughing.png]]
Haha, that's so funny!
![[minimaBemused.png]]
Your village really *is* good at opsec.
![[minimaCheeky.png]]
`a,0.3`No, *real* swears are stuff like f-
`c,cutToStewards`
`steward,r,neutral`
Hey! How's it going?
...
`steward,r,giveUp,neutral`
Oh, wondering why I had to get your attention?
`steward,r,annoyed`
No reason, just felt like it!
`steward,r,neutral`
Have you been having fun?
`steward,r,cheery`
>Yeah!
>	That's great! Isn't it great to play such a great game with such a great, wholesome age rating?
>I guess?
>	Haha, is it not great to play such a great game with such a great, wholesome age rating?
>No.
>	What? Not enjoying playing such a great game with such a great, wholesome age rating?
>I don't think pulling me aside like this every time will work.
>	Then you'd be surprised!

`steward,r,neutral`
...
`steward,r,distracted,neutral`
Ok, I think they're done.
`steward,r,cheery`
Nice talking!
`c,cutFromStewards`

![[proSmirk.png]]
...uh-huh?
![[minimaMildlyAnnoyed.png]]
Come on, you think I'm messing with you?
![[proBemused.png]]
You had me going for a second, but a special word you can put basically anywhere?
Including in the middle of other words?
I think you're just trying to trick me into making a fool of myself. 
![[minimaDeadpan.png]]
I didn't say you could do it *tastefully*.
![[proBemused.png]]
Ha, right.
`$player`, back me up here.
>She's telling the truth.
>	![[proRollingEyes.png]]
>	That so?
>	![[proMocking.png]]
>	Guess you're both in on this.
>	Pick a better lie next time, you two.
>	![[minimaAnnoyed.png]]
>	...
>You're right, that would make you sound like a \*\*\*\*\*\*.
>	![[proAnnoyed.png]]
>	Agh.
>	![[minimaBemused.png]]
>	Pfft.
>	![[proCynical.png]]
>	What was that beeping noise? Don't do that again.

`c,restStart`
`x`