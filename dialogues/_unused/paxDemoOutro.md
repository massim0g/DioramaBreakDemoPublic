`steward, l, neutral`
`steward, r, cheery, neutral`
And... that's all for this demo!
>What? No!
>	`steward, r, neutral`
>	Oh yes! Gotta let someone else try.
>Aw...
>	`steward, r, neutral`
>	I know, what a shame, but you gotta let someone else try.
>Thank goodness.
>	`steward,r,annoyed`
>	Ah? Got something to say?
>	`steward,l,irked, neutral`
>	Now, now.
>	`steward,l,neutral`
>	I'm sure one of the developers would be happy to receive any constructive criticism you might have.
>	But first,
>	[[#thanksForPlayingToTheEnd]]
>Ok, I understand.
>But what will happen to Pro!?
>	`steward, r, presenting, giveUp`
>	Hm, what indeed?
>	`steward,r,giveUp`
>	If only there was some way to stay in touch...
>	`steward,l,sternRight`
>	That's quite enough.

# thanksForPlayingToTheEnd
`steward,l, presenting, neutral`
We can't thank you enough for playing to the end.
`steward,r,cheery,neutral`
Congrats on beating Polema!
`steward,l,bowing`
Yes, a remarkable achievement.
# thanksForPlaying
`steward,l,neutral`
We are sorry that we can only offer you this fleeting excerpt, time and resource constraints being what they are.
But rest assured, a full demo will be made available to the public in short order. 
Our entire team is dedicated to realizing the full potential of our vision.
`steward,l,reassuring`
We hope to see you again then.
`steward,r,presenting,neutral`
Yessir! You won't wanna miss it! So sign up for the mailing list, wishlist on Steam, and follow our socials!

>I sure will!
>	`steward,r,cheeky`
>	"Will"?
>	You've got a phone, right? Do it now. dioramabreak.com
>	>Ok!
>	>	`steward,r,cheery`
>	>	Great! Thanks for your support!
>	>	[[#socials]]
>	>Oh, uh, I would, but, uh, you know how the internet gets out here, and uh, I wanna save battery...
>	>	`steward, r, giveUp, neutral`
>	>	`a,0.1`Oh I see. But surely you'll at least make a note and tell your friends and take a picture to share later and-
>	>	`a`[[#socialsDone]]
>No.
>	`steward,r,annoyed`
>	`a,0.1`Huh, what was that? Are you implying you have something better to d-
>	`a`

# socialsDone
`steward,l,irked`
Alright, enough.
`steward,l,reassuring, neutral`
While we appreciate any support, please do as you will.
Ultimately, we only wish to bring you and your friends a fun, valuable experience.
`steward,l,sternRight`
Not to come off as beggars.
`steward,r,cheeky`
Hehe. Let's not take up any more time then.
`steward,r,cheery`
Thanks for playing! Bye-bye for now!
`c,resetDemo`
`x`
# socials
`steward,r,neutral`
...
All done?
>Yes.
>	`steward, r, cheery`
>	Wonderful!
>	...
>	You're telling the truth right?
>	`a,0.1`Normally we wouldn't be able to tell, but you are in *public*-
>	[[#socialsDone]]
>One sec...
>	[[#socials]]


# combatFailure
`if tutorialFailed`
	[[#combatFailure2]]
`steward,l,neutral`
`steward,r,giveUp`
`tutorialFailed`
Ooh, that's a shame.

>What happened?
>	[[#whatHappened]]
>Darn.
>	[[#darn]]

## whatHappened
`steward,r,neutral`
You lost, buddy.
`if tutorialLostTo == kion`
	`steward,r,giveUp,neutral`
	To Kion, at that... that one feels kind of on us.
`else if tutorialLostTo == akro`
	`steward,r,neutral,giveUp`
	Couldn't figure out how to nail him?
	`steward,r,neutral`
	Remember, you gotta wait until he's tired.
`else if tutorialLostTo == guards`
	`steward,r,giveUp`
	Don't feel too bad, getting ganged up on is never easy.
`else if tutorialLostTo == polema`
	`steward,l,neutral,irked`
	Yes, the captain of the guard is indeed quite the obstacle.
[[#whatsNext]]
## darn
Darn indeed.
`if tutorialLostTo == kion`
	`steward,r,giveUp,neutral`
	Though, losing to Kion... that one feels kind of on us.
`else if tutorialLostTo == akro`
	`steward,r,neutral,giveUp`
	Couldn't figure out how to nail him?
	`steward,r,neutral`
	Remember, you gotta wait until he's tired.
`else if tutorialLostTo == guards`
	`steward,r,giveUp`
	Don't feel too bad, getting ganged up on is never easy.
`else if tutorialLostTo == polema`
	`steward,l,neutral,irked`
	Yes, the captain of the guard is quite the obstacle.
[[#whatsNext]]
## whatsNext

`steward,l,neutral`
Normally, your bridge losing consciousness like this would hardly be cause to end your connection so abruptly.
`steward,r,cheery,neutral`
But we gotta keep things moving!
`steward,l,irked`
...yes, I'm certain you can understand our being abnormally constrained in these circumstances.

>I want to keep trying!
>	`steward,l,reassuring`
>	My. Your determination is appreciated...
>	`steward,l,bowing`
>	...very well. There should be little issue with one more attempt.
>	`steward,l,reassuring`
>	We will turn back the clock slightly.
>	`steward,r,cheeky`
>	Do your best this time!
>	`steward,r,neutral,presenting`
>	`a,0.4`3... 2... 1...
>	`c,tutorialReset`
>	`x`
>Alright, I'll let the next person try.
>	`steward,r,cheery`
>	Thanks for playing!
>	`steward,r,presenting`
>	Remember to wishlist and follow us on social media! dioramabreak.com!
>	`steward,r,cheery`
>	Bye-bye!
>	`c,resetDemo`
>	`x`

# combatFailure2
`steward,l,neutral`
`steward,r,giveUp`
Ooh man, that's rough.

>One more shot!
>	`steward,l,stern`
>	Have you asked the booth attendants?
>	>Yes, they're fine with it.
>	>	`steward,l,bowing`
>	>	Then there should be no issue.
>	>	`steward,l,reassuring`
>	>	Good luck.
>	>	`steward,r,neutral,presenting`
>	>	`a,0.4`3... 2... 1...
>	>	`c,tutorialReset`
>	>	`x`
>	>They said no...
>	>	`steward,l,neutral`
>	>	Then that's that unfortunately.
>	>	[[#thanksForPlaying]]
>	>There's uh, nobody attending the booth...
>	>	`steward,l,irked`
>	>	Oh. Well... is there anyone near you waiting for their turn?
>	>	>No
>	>	>	`steward,l,bowing`
>	>	>	Then there should be no issue.
>	>	>	`steward,l,reassuring`
>	>	>	Good luck.
>	>	>	`steward,r,neutral,presenting`
>	>	>	`a,0.4`3... 2... 1...
>	>	>	`c,tutorialReset`
>	>	>	`x`
>	>	>Yes...
>	>	>	`steward,l,neutral`
>	>	>	Then that's that unfortunately.
>	>	>	[[#thanksForPlaying]]
>Alright, I'm done.
>	`steward,l,reassuring`
>	Thank you for giving it your best.
>	[[#thanksForPlaying]]

`x`