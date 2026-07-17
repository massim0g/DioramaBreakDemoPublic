`steward,l,neutral`
`steward,r,neutral`

`if diedTo=="consequenceAmbush"`
	[[#diedToConsequenceAmbush]]
`else if diedTo=="consequence"`
	[[#diedToConsequence]]
`else if diedTo=="hatingMinima"`
	`steward,r,annoyed`
	Wow man...
	`steward,l,irked`
	Now, now. It was their decision to make.
	`steward,l,stern,neutral`
	Though I should caution that fostering such... distance... may be ultimately detrimental to your enjoyment.
	`steward,r,giveUp`
	Welp. Back to the last checkpoint then.
	>!What!? No!
	>	`steward,r,annoyed`
	>	What did you think was going to happen?
	>	`steward,r,presenting,neutral`
	>	Chin up!
	`steward,r,neutral`
	3...2...1...
	`if !gameLoad`
		[[#loadFailed]]
	`x`

`if deathMessageDefaultSeen`
	[[#diedBefore]]

`var, deathMessageDefaultSeen, 1, persistent`

Ooh, that's rough.

>What happened?
>	`steward,l,neutral`
>	You have unfortunately lost all means of maintaining your connection to the Diorama.
>	`steward,r,cheeky`
>	Wow, what a tactful way of saying "all your friends died".
>Darn.
>	`steward,r,cheeky`
>	Wow, that's your response to all your friends dying?
>	>!What, want me to cry and rage?
>	>	`steward,r,cheery`
>	>	Catharsis is good for the soul!
>	>I didn't realize...
>	>	`steward,r,cheeky`
>	>	Oh, sorry, I thought bright red flash made it obvious.

`steward,r,presenting,neutral`
Anyway, not to worry, we've got it covered.
`steward,l,neutral`
Yes, as with any kind of disconnection, the world will be returned to the last point that could be fixed.
That is, the last time you approached a Fixture.
The Diorama's inhabitants will naturally not retain any memory of the events undone.
`steward,l,bowing`
Now then, let us not take any more of your time.
`steward,r,cheery`
Yup!
`steward,r,neutral`
3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`
# diedToMonsters
//todo
`x`

# diedToConsequenceAmbush
`if deathMessageConsequenceAmbushSeen`
	[[#diedBefore]]

`var, deathMessageConsequenceAmbushSeen, 1, persistent`

`steward,r,giveUp`
Ooh, that's rough.
`steward,l,neutral`
Yes, unfortunate indeed.
With the death of your charge, you have lost all means of maintaining your connection to the Diorama.
`steward,r,cheeky`
Should've kept an eye out for ambushes!

>Darn.
>	`steward,r,neutral`
>	...
>	I sense you're thinking that was a little unfair, huh?
>That's ridiculous! There was no way I could've avoided that!
>	`steward,r,cheeky`
>	"No way you could've avoided that?"
>	You seem fine to me.
>	>You know what I mean.
>	>And Pro?
>	`steward,r,cheery`
>	Haha, alright.

`steward,r,neutral`
You do get to try again.
`steward,r,giveUp`
You'd think that'd be more than enough to call this fight even...
`steward,r,cheeky`
...but if not, why not get your friends in on it?

`steward,l,neutral`
Yes.
In the event of a disconnection, the world will be returned to the last point that could be fixed.
That is, the last time you visited a Fixture.
You may continue from there, but the Diorama's inhabitants will naturally not retain any memory of the events undone.
`steward,l,presenting`
However, in certain cases, you'll have the opportunity to warn your charge about the coming danger.

`steward,r,cheery`
Yup! This way, everyone can learn from your mistakes!
`steward,r,presenting`
So don't miss your chance!
`steward,l,bowing`
Now then, let us not take any more of your time.
`steward,r,cheery`
Yup!
`steward,r,neutral`
3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`

# diedToConsequence
`if deathMessageConsequenceSeen`
	[[#diedBefore]]

`var, deathMessageConsequenceSeen, 1, persistent`

`steward,r,giveUp`
Dang. That one's a toughie, isn't he?

>!...does this mean I have to go back to the camp?
>	`steward,r,cheery`
>	Nah!

`steward,r,neutral`
Normally we'd send you back to the last Fixture you visited, but a new connection is a special occasion!
`steward,l,neutral`
Yes, such events are not so easily undone.
You'll be returned to the moment your new bond was sealed.
`steward,r,presenting,neutral`
Remember, it's a 2v1 now! Push him back, really lay on the pressure!
`steward,r,cheery`
Give it your best!
`steward,r,neutral`
3...2...1...
`if !gameLoad`
	[[#loadFailed]]
`x`

# diedBefore
`steward,r,giveUp`
Whoops.
...
`steward,r,annoyed`
Sorry, we didn't have time to prepare a speech for this.
Guess that's what you get for dying more than once.
`steward,l,irked`
I... will return you.
`steward,l,neutral`
Unless you wish to take a break?
>I'm good, send me back.
>	`steward,l,bowing`
>	Understood.
>	`steward,l,neutral`
>	1...2...3...
>	`if !gameLoad`
>		[[#loadFailed]]
>	`x`
>Yeah, I'd like to take a break.
>	`steward,l,bowing`
>	Very well. We will eagerly await your return.
>	`steward,r,annoyed`
>	Not me! Standing around like this gets tiring you know!
>	`steward,l,sternRight`
>	...
>	`steward,r,giveUp,neutral`
>	Kidding! Kidding!
>	`steward,r,cheery`
>	Buh-bye!
>	`x`

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