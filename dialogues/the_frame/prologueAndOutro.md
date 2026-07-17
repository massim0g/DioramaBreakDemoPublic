# start
`c,prologueStart`
`steward,r,presenting,neutral`
Welcome to the Diorama Break demo!

`steward,l,reassuring`
You have our sincerest thanks for joining us here today.

`steward,r,cheery`
For real!
`steward,r,cheeky`
`a,0.5`Personally, I could never imagine myself wasting my time on-

`steward,l,irked``a`
Ahem.
`steward,l,neutral`
Rest assured, incomplete as it is, we have spared no expense in making this a worthwhile experience.

`steward,r,annoyed`
Oh yes, *expense* is right.
`steward,r,distracted`
`s,0.5`That Kickstarter better pull through for us...`s`

`steward,l,neutral`
Now then.
`steward,l,presenting`
Before you stands the Diorama.

`steward,r,presenting`
Behind the glass lies a mini-scale world of adventure and secrets.
`steward,r,cheery,presenting`
Brought to life at the intersection of your mind and the screen!

`steward,l,presenting,neutral`
In this game, you, dear player sat before us, will guide a hero within on a journey to change his world.

>Sounds good!
>Sounds lame.
>	`steward,r,annoyed,neutral`
>	...
>	Feel free to leave then.
>	Just close the demo! Alt+F4! Right now!
>	...
>	`steward,r,cheeky`
>	Ha! Won't do it.
>	`steward,l,irked,neutral`
>	...
>	Moving on.
>Cool. But why is this game called Diorama *Break*?
>	`steward,r,cheery`
>	Oh yeah!
>	`steward,r,presenting,neutral`
>	`auto,0.2`What's up with that? Are we gonna take a hammer to this thi-
>	`auto``steward,l,sternRight,neutral`No touching.
>	`steward,l,stern`
>	All "breaking" is to remain purely metaphorical.
>	`steward,l,irked,neutral`
>	Now, as I was saying...
>Great. Can we skip straight to that?
>	`steward,r,giveUp`
>	Ah, well, there was some stuff to explain...
>	`steward,r,cheery,neutral`
>	But hey, I'm sure you'll figure it out!
>	Take it away!
>	`steward,l,irked`
>	Ah... very well then.
>	[[#connectionStart]]

`steward,l,neutral`
All instruments of the Diorama's nature come equipped with an assistant to guide and interpret the user's will.
In this case, that would be us.
`steward,l,bowing`
But do not fret, we won't pester you too much.

`steward,r,presenting,neutral`
Yes, we'll be very light-touch.
`steward,r,cheeky`
You'll get to mess things up however you want.

>Got it.
>	`steward,r,cheery`
>	Good attitude!
>	`steward,l,neutral`
>	Yes.
>You said "an assistant", but there are two of you?
>	`steward,l,neutral,irked`
>	Ah, yes, well, these tools normally come in pairs, but the Diorama is more... integrated.
>	`steward,l,neutral`
>	But you need not concern yourself with such details.
>	`steward,r,cheery`
>	Yup, that's all stuff for... mods, let's say.

`steward,l,reassuring`
We're almost ready now, but some controls still warrant explanation.
`steward,l,presenting,neutral`
Take this dialogue, for example.
`if gamepad`
	Were you aware that you may use **X** or **B** to advance dialogue faster? Please try that now`speed, 0.1`. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .`speed`
`else`
	Were you aware that you may use **Right Click** or **Shift** to advance dialogue faster? Please try that now`speed, 0.1`. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .`speed`

`steward,r,cheery`
Well done!
`steward,r,neutral,presenting`
Here's another fun fact:
`steward,r,presenting`
Sometimes, you'll be given the option to **interject** during dialogue!
`steward,r,neutral`
`if gamepad`
	Watch for the prompt and then press **Y**.
	>!Like this?
	>	`steward,r,cheery`
	>	Yup! Good job!
	>	[[#interjectionDone]]
`else`
	Watch for the prompt and then press **Ctrl** or the **Middle Mouse Button**.
	>!Like this?
	>	`steward,r,cheery`
	>	Yup! Good job!
	>	[[#interjectionDone]]

...
`steward,r,annoyed`
I *said*, watch for the prompt.

>!Oh, I got it.
>	`steward,r,neutral`
>	Wonderful.
>	[[#interjectionDone]]

...
`if gamepad`
	`unskip`**Y Button**. *This*. *Prompt*. --->
	>!Got it!
	>	`unskip`
	>	Third time's the charm, huh?
	>	[[#interjectionDone]]
`else`
	`unskip`**Ctrl** or **Middle Mouse Button**. *This*. *Prompt*. --->
	>!Got it!
	>	`unskip`
	>	Third time's the charm, huh?
	>	[[#interjectionDone]]

`unskip``steward,r,giveUp`
Ok, be that way. I give up.

`steward,l,bowing`
Now, now.
`steward,l,reassuring`
I am certain you will learn to seize these chances when it counts.
## interjectionDone
`steward,l,neutral`
Now then, your journey will begin shortly.
`steward,l,neutral`
Take the time to handle anything urgent and prepare your play area.

>I'm ready.

Excellent.
# connectionStart
`steward,l,neutral`
We will now connect you to the Diorama.

`if gamepad`
	In a moment, grip your controller firmly. Relax, take a deep breath in, then exhale while pressing down both analog sticks.
`else`
	In a moment, move both hands above your keyboard. Relax, take a deep breath in, then exhale while pressing down the spacebar.

`c, meditationStart`

`x`

## forgotToBreathe
`c,meditationFailed`
`steward,l,neutral`
`steward,r,distracted,neutral`
Hey, wake up!
`steward,r,giveUp`
You ok? You stopped interacting for a while there.
Couldn't tell if you were breathing properly...
`steward,r,neutral`
`if gamepad`
	Remember, when the screen goes black: Grip the thumbsticks firmly, deep breath in, then press down and *hold*.
`else`
	Remember, when the screen goes black: Hands above the spacebar, deep breath in, then press down and *hold*.

`c,meditationStart`
`x`
## connectionFailed
`c, meditationFailed`
`steward,r,neutral`
`steward,l,irked,neutral`
Connection failed...

`steward,r,neutral`
`if gamepad`
	Remember, when the screen goes black: Grip the thumbsticks firmly, deep breath in, then press down and *hold*.
`else`
	Remember, when the screen goes black: Hands above the spacebar, deep breath in, then press down and *hold*.
`steward,r,giveUp,neutral`
*And don't touch anything else.*

`c,meditationStart`
`x`
## connectionComplete

`c,dioramaEntry, false`
`steward,r,neutral`
`steward,l,neutral`
`auto,2`Connection established!

`auto,1.75``steward,r,cheery`Good luck!

`steward,l,neutral`And remember, what you give will be returned. 
`speed,0.1``auto,0.25`We will speak again soon.

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
Oh! You're back.
`if !demoContinued`
	`steward,r,cheeky`
	Desperate to see if there was anything else?
	`steward,r,giveUp`
	The answer is... not really.
	I suppose we could send you back to the beginning.
	Or we could just put you back in where you last saved...
	[[#returnedAfterCompletion]]
Want to keep going? Or start over?
>Continue.
>	`steward,r,cheery`
>	You got it!
>	[[#continue]]
>Start over.
>	[[#reset]]
## loadMidDemo
Welcome back!
`if !seen`
	`steward,r,presenting,giveUp`
	I'm surprised, we were expecting most people to be able to finish this demo in one sitting.
	`steward,r,neutral`
	I get it though, busy world out there.
	`steward,r,giveUp`
	And accidents happen too...
`steward,l,neutral`
Would you prefer to continue from where you left off, or start over completely?
>Continue.
>	`steward,r,cheery`
>	You got it!
>	[[#continue]]
>Start over.
>	[[#reset]]
## continue
`steward,r,neutral`
Ready?
>!No breathing exercise?
>	`steward,r,cheery`
>	Aha!
>	`steward,l,reassuring`
>	We've found that after the initial attunement, such exercises have diminishing returns.
>	`steward,r,neutral`
>	You can if you want to though!
>	...
>	`steward,r,presenting,neutral`
>	Alright, ready?

3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`

## reset
`steward,l,bowing`
Very well.
`steward,l,neutral`
Know that, besides your system settings, this will fully reset this demo.
Even we will not pretend to recognize you.
Are you certain you wish to proceed?
>Yes.
>	Understood.
>	Goodbye, then.
>	`steward,r,cheery`
>	See ya around!
>	`steward,r,neutral`
>	3...2...1...
>	`c,demoReset,false`
>	`x`
>No, nevermind.
>	`steward,r,neutral`
>	Alright, we'll just put you back where you were then.
>	[[#continue]]

# outro
`steward, l, neutral`
`steward, r, cheery, neutral`
And... that's all for this demo!

>What? No!
>	`steward,r,giveUp`
>	Oh yes. I'm afraid that's all we can muster if we don't get any more funding.
>	[[#funding]]
>Aw...
>	`steward,r,giveUp`
>	Yes, it's very sad.
>	But that's all we can muster if don't get any more funding.
>	[[#funding]]
>Thank goodness.
>	`steward,r,annoyed`
>	Ah? Got something to say?
>	`steward,l,irked,neutral`
>	Now, now.
>	`steward,l,neutral`
>	Our developers would be happy to receive any constructive criticism you might have.
>	`steward,l,presenting,neutral`
>	Though, forgive my asking, but if this demo was not to your liking, why spend so much time with it?
>	>I was just kidding.
>	>	`steward,r,cheery`
>	>	Whew! Good to hear!
>	>	`steward,r,distracted`
>	>	This job's hard enough as it is...
>	>Someone else asked me to.
>	>	`steward,l,bowing`
>	>	Ah, well, we hope to have at least served to help you understand them better, if only a little.
>	>	Please, be sure to give them our thanks.
>	>It's my job.
>	>	`steward,l,irked,neutral`
>	>	A-ah, I see. Well, please know that we deeply appreciate the time you've spent...
>	>	`steward,l,neutral`
>	>	...and any publicity that may come of it.
>	>	`steward,r,cheery`
>	>	Beggars can't be choosers after all.
>	>	`steward,r,neutral`
>	>	But if it was at least interesting enough to make something of it: dioramabreak.com/presskit
>	`steward,l,neutral`
>	Now then, we won't take any more of your time.
>	`steward,r,cheery`
>	Thanks for playing!
>	[[#moreContentChoice]]
>	`x`
>Ok, I understand.
>	`steward,r,neutral`
>	Yes, that's all we can muster if don't get any more funding.
>	[[#funding]]
>But what will happen to Pro and Minima!?
>	`steward,r,presenting,giveUp`
>	Hm, not much if we don't get any more funding.
>	`steward,r,giveUp`
>	This demo was expensive enough to make as it is...
>	[[#funding]]

## funding
// `steward,r,cheery`
// But now's not the time to worry about that!
// `steward,r,giveUp`
// We're still in beta after all.
// `steward,l,neutral,irked`
// Ah, yes, speaking of.
// `steward,l,neutral`
// We've prepared a short survey for the players of this beta.
// If you have the time, we would greatly appreciate hearing your thoughts.
// You may access it from the title menu, or at dioramabreak.com/feedback.
// [[#signOff]]

`if ksCheck=="pre"`
	`steward,r,neutral`
	Speaking of which...
	`steward,r,cheery`
	We'll be launching a Kickstarter on the 28th! How exciting!
	[[#ksChoice]]
`else if ksCheck=="ongoing"`
	`steward,r,neutral`
	Speaking of which...
	`steward,r,cheery`
	We're running a Kickstarter for the full game *right now*!
	[[#ksChoice]]
`else`
	`steward,r,giveUp`
	Too bad you missed the Kickstarter.
	`steward,r,cheery,neutral`
	Don't worry though, we're doing fine!
	`steward,r,giveUp,neutral`
	At least, I hope we are. We don't get wifi in here.
	`steward,r,presenting`
	But *you* can read all about it online! dioramabreak.com!
	`steward,l,neutral`
	Yes, if you enjoyed your time today, any engagement would be appreciated.
	But do not let the internet be a distraction. Little would be more valuable to us than a heartfelt recommendation to a friend.
	`steward,r,cheeky`
	...except a late pledge on our Kickstarter page.
	`steward,l,irked`
	Ahem.
	`steward,l,neutral`
	Make no mistake:
	`steward,l,reassuring`
	Above all, we are extremely grateful you took the time to play this demo through.
	[[#signOff]]

## ksChoice
>I know.
>	`steward,r,cheeky`
>	Wow, nothing gets past you!
>	`steward,l,sternRight`
>	Yes, we're happy to hear you were already aware.
>	`steward,l,bowing`
>	We thank you for your interest.
>	`steward,r,cheery`
>	Don't forget to let your friends know! dioramabreak.com!
>	`steward,l,reassuring`
>	Of course.
>	Little would be more valuable to us than a heartfelt recommendation to a friend.
>	But above all, we are extremely grateful you took the time to play this demo through.
>Oh, tell me more.
>	`steward,l,neutral`
>	The campaign will run from the 28th of April to the 29th of May, 2026.
>	`steward,l,presenting`
>	A number of limited-time rewards will be available, including a chance to contribute designs to the full game.
>	`steward,r,cheery,presenting`
>	Go check it out! dioramabreak.com!
>	`steward,l,neutral`
>	Ultimately, any contribution you decide to make will be instrumental in helping us achieve this project's full potential.
>	`steward,l,reassuring`
>	Even if you are unable to donate, a heartfelt recommendation to a friend would go a long way.
>	`steward,r,cheery`
>	Yes, and the richer said friend, the better!
>	`steward,l,irked`
>	Ahem.
>	`steward,l,neutral`
>	Make no mistake:
>	`steward,l,reassuring`
>	Above all, we are extremely grateful that you took the time to play this demo through.
>I don't care.
>	`steward,r,annoyed`
>	`a,0.2`Oh yea-
>	`steward,l,irked``a`Then there's no need for us to press the matter.
>	`steward,l,neutral`
>	Still, if you enjoyed your time today in any capacity, it would be a great help to us to spread the word.
>	`steward,l,reassuring`
>	A heartfelt recommendation to a friend would especially go a long way.
>	`steward,r,presenting`
>	Or if you didn't enjoy your time, why not give a duplicitous recommendation to a hated enemy?
>	`steward,l,sternRight`
>	In any case...
>	`steward,l,reassuring`
>	We are, above all, extremely grateful that you took the time to play this demo through.

## signOff
`steward,r,cheery`
That's it then!
See you some day soon!
`steward,r,annoyed`
...hopefully.
## moreContentChoice

>Bye!
>	`x`
>Is that really it? There's nothing more?
>	[[#moreContent]]
## moreContent

`steward,r,distracted`
Well... not really...
`steward,r,giveUp`
But if you're desperate to keep running around I suppose we could send you back to the beginning.
Or we could just put you back in.
## returnedAfterCompletion
`steward,r,neutral`
What'll it be?
>Put me back in.
>	`steward,r,cheery`
>	Sure thing.
>	`steward,r,neutral`
>	But you'll have to let me do the talking for a bit.
>	>Got it.
>	>What do you mean? How?
>	>	`steward,r,presenting,neutral`
>	>	Hehe.
>	>	Who do you think has been picking your dialogue options this whole time?
>	>	>Oh, I see.
>	>	>Me...?
>	>	>	`steward,r,cheeky`
>	>	>	Oh really?
>	>	>	>Oh never mind, of course it was you. You're so cool and clever and hard-working.
>	>	>	>	`steward,l,irked`
>	>	>	>	Ahem.
>	>	>	>	`steward,r,cheery`
>	>	>	>	Teehee!
>	`steward,r,cheery`
>	Let's get on with it then.
>	`steward,r,neutral`
>	3...2...1...
>	`gameLoad`
>	`x`
>Start over.
>	`steward,l,neutral`
>	Very well.
>	Know that, besides your settings, this will fully reset this demo.
>	Even we will not pretend to recognize you.
>	Are you certain you wish to proceed?
>	>Yes.
>	>	`steward,l,bowing`
>	>	Understood.
>	>	`steward,l,neutral`
>	>	Goodbye, then.
>	>	`steward,r,cheery`
>	>	See ya around!
>	>	`steward,r,neutral`
>	>	3...2...1...
>	>	`c,demoReset,false`
>	>	`x`
>	>No, nevermind.
>	>	`steward,l,bowing`
>	>	Understood.
>	>	`steward,l,reassuring`
>	>	Until next time, then.
>	>	`steward,r,cheery`
>	>	Bye bye!
>	>	`x`
## demoContinues
`c,demoContinues`
![[minimaSmile.png]]
-th!

>Wait!

![[minimaSurprised.png]]
?

>You guys need to turn back. You can't leave the forest.

![[minimaSkeptical.png]]
Why...?

>Just trust me on this guys, we can go on our journey later, just don't leave the forest for now.

`if !proBladeShattered`
	![[minimaSkeptical.png]]
	But-
	![[proMeditating.png]]
	Fine.
	![[minimaSurprised.png]]
	What?
	![[pro.png]]
	There must be a good reason, right?
	>Yes! There's definitely a good reason!
	![[proCynical.png]]
	I... wasn't asking, but ok.
	![[pro.png]]
	I trust you on this.
	![[minimaSheepish.png]]
	W-well, ok. How long are we supposed to wait?
	>Can't say. Depends on the release schedule.
	![[minimaMildlyAnnoyed.png]]
	What?
	>Never mind.
	![[minimaSkeptical.png]]
	???
	![[proAnnoyed.png]]
	Come on.
	![[proRollingEyes.png]]
	I wanted to take a break anyway.
	![[minimaAnnoyed.png]]
	A-alright. It's not like there isn't another camp just up ahead but... fine, let's go back.
`else`
	![[proCynical.png]]
	I don't trust this at all.
	But... I probably should go get my sword repaired.
	![[minima.png]]
	Ah, good point.
	Guess I'll get to see what I came for after all!
	Can't say I wasn't curious.
	![[pro.png]]
	Trust me, it's nothing special.

`c, demoContinued`
`x`
# paxDemo
`c,prologueStart`
`steward,l,neutral`
`steward,r,presenting,neutral`
Hey there!
`steward,l,neutral`
Welcome to the Diorama Break demo.
`steward,r,cheery,neutral`
Yes, specifically, the super exclusive please-don't-judge-us-it's-not-finished playtesting build!
`steward,l,reassuring`
Thank you for stopping by.
`steward,r,cheery`
For real! 
`steward,r,cheeky`
`a,0.1``speed,1`Personally, I couldn't imagine taking all this time just to play a bunch of unfinish-`speed`
`steward,l,irked`Ahem.
`a``steward,r,cheery`Aha. I mean, um, what caught your eye?
>I'm trying everything here!
>	`steward,r,giveUp`
>	Mm. I feel a bit bad appearing at a student event. 
>	We've had so much more time and money to spend on this after all.
>	`steward,r,distracted`
>	So much money spent...
>	`steward,l,reassuring`
>	 Now, now. There will be certainly something of value to find in every game here.
>I liked the poster art.
>	Why thank you! Our artists are very talented, yes.
>	`steward,r,cheeky`
>	As evidenced by present company.
>	`steward,l,neutral`
>	Though we must caution...
>	`steward,r,giveUp,neutral`
>	Ah, yes.
>	`steward,r,neutral`
>	As you may have spotted, your actual experience today will be a lot more... stylized.
>	Hope that's ok.
>	>That's great! I love pixel art!
>	>That's ok, I get what you're going for.
>	>	`steward,r,cheery`
>	>	Wonderful!
>	>Oh.
>	>	`steward,l,irked,neutral`
>	>	We- nevertheless invite you to continue.
>	>	`steward,l,reassuring`
>	>	You may find yourself pleasantly surprised.
>I saw someone else playing.
>	`steward,r,giveUp`
>	Oh, first impression's out the window then.
>	`steward,r,cheery,neutral`
>	Best move on quick!
>	`steward,l,neutral`
>	Yes.
>I saw the teaser trailer online and wanted to try it!
>	`steward,r,cheery,neutral`
>	Oh wow, superfan over here!
>	`steward,r,cheeky`
>	I'm a little nervous...
>One of the devs asked me to try it.
>	`steward,r,giveUp`
>	Oof, how embarrassing.
>	`steward,r,presenting,neutral`
>	Well, at least you'll be going in blind. Exciting!

`steward,l,neutral`
Now then.
`steward,l,presenting`
Before us stands the Diorama.

`steward,r,presenting`
An entire world of adventure, mystery, and tragedy!
Packaged up and fit neatly in the crevice 'twixt mind and screen.

`steward,l,presenting,neutral`
You will guide a chosen inhabitant within on a journey to change said world.

>Sounds good!
>Sounds lame.
>	`steward,r,annoyed,neutral`
>	Feel free to leave then. Just walk away! Get up and go! Right now!
>	...
>	`steward,r,cheeky`
>	Ha! Can't do it.
>	Try bluffing someone your own size next time!
>	`steward,r,giveUp,neutral`
>	Er, metatextually speaking.
>	`steward,l,irked,neutral`
>	...
>	Moving on.
>"Change"? Isn't this game called Diorama *Break*?
>	`steward,r,cheery`
>	Oh yeah!
>	`steward,r,presenting,neutral`
>	`auto,0.1`What's up with that? Are we gonna take a hammer to this thi-
>	`auto``steward,l,sternRight,neutral`No touching.
>	`steward,l,stern`
>	All "breaking" is to remain purely metaphorical.
>	`steward,l,irked,neutral`
>	Now, as I was saying...

`steward,l,neutral`
We will, in turn, serve as *your* guides and stewards in this endeavor.
`steward,l,bowing`
Fret not though, you will scarcely feel our presence.

`steward,r,presenting,neutral`
Yes, we'll be very light-touch.
`steward,r,cheeky`
You'll have every opportunity to mess things up however you please.

`steward,l,reassuring`
Naturally. Still, some controls warrant explanation.
`steward,l,presenting,neutral`
Take this dialogue, for example. Clearly, you have a good grasp on the basic controls...
But were you aware that you may use Right Click or Shift to advance dialogue faster? Please try that now`speed, 0.1`. . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . . .`speed`

`steward,r,cheery`
Well done!
`steward,r,neutral,presenting`
Here's another fun fact:
`steward,r,presenting`
Sometimes, you'll be given a chance to optionally interject during dialogue!
`steward,r,neutral`
Watch for the prompt and then press the middle mouse button.

>!Like this?
>	`steward,r,cheery`
>	Yup! Good job!
>	[[#interjectionDonePax]]

...
`steward,r,annoyed`
I *said*, watch for the prompt.

>!Oh, I got it.
>	`steward,r,neutral`
>	Wonderful.
>	[[#interjectionDonePax]]

...
`unskip`Middle mouse button. *This*. *Prompt*. --->

>!Got it!
>	`unskip`
>	Third time's the charm, huh?
>	[[#interjectionDonePax]]

`unskip``steward,r,giveUp`
Ok, be that way. I give up.

`steward,l,bowing`
Now, now.
`steward,l,reassuring`
I am certain you will learn to seize these chances when it counts.

## interjectionDonePax

`steward,l,neutral`
Now then, your journey will begin shortly.
`steward,l,presenting`
But first, your mind and body must be properly attuned.
`steward,l,neutral`
I understand it may be difficult, given the crowded environment, but please attempt now to tighten your focus and shut out all distractions.

>I'm ready.

Excellent.
We will now connect you to the world within the Diorama.

`steward,r,neutral`
In a moment, move both hands above the spacebar. Relax, take a deep breath in, then hold it down while exhaling.

`c, meditationStart`

`x`

# loadFailed

`steward,r,neutral`
...
`steward,r,annoyed`
...
W-well, uh, this is a little embarassing...
Seems like there's been an issue loading your save file...
`steward,r,giveUp`
Did you get dust in your memory card or something?
`steward,l,irked`
Ahem. This is no laughing matter.
`steward,l,irked,neutral`
We are terribly sorry about this, but we are unfortunately limited in the help we can provide in this situation.
`steward,l,neutral`
Your save file can be found under **%APPDATA%/../Local/DioramaBreak**. We recommend you retrieve it and request support on Steam or in the official Discord server.
`steward,r,giveUp`
Sorry about that.
...
`steward,r,neutral`
Well...
See ya.
`x`