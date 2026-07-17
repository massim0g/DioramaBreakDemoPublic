# q0
![[]]
(She was right...)

>No she wasn't.
>It doesn't matter now.
>	`revivalPoints+=1`
>That's reductive.

`revivalAdvance`

# q1
![[]]
(I didn't know what I was getting into...)

>You can handle it.
>	`revivalPoints-=1`
>I can handle it.
>	`revivalPoints+=1`
>We can handle it.
>	`revivalPoints+=1`

`revivalAdvance`
# q2
![[]]
(I never asked for this...)

>Yes you did.
>Not all of it.
>	`revivalPoints+=1`
>It's what you were born for.
>	`revivalPoints-=1`

`revivalAdvance`

# q3
![[]]
(I'll never find what I'm looking for...)

>Not with that attitude.
>	`revivalPoints+=1`
>You won't find anything if you die here.
>And what is that, exactly?
>	`revivalPoints-=1`

`revivalAdvance`

# q4
![[]]
`if proBladeShattered`
	(My sword...)
	>We'll get you a new one.
	>I'm sorry.
	>	`revivalPoints+=1`
	>It's just a sword. Your life is on the line.
	>	`revivalPoints-=1`
`else`
	![[]]
	(Why did I bother practicing...)
	>You love it.
	>	`revivalPoints+=1`
	>You're good at it.
	>You had to.
	>	`revivalPoints-=1`

`revivalAdvance`

# q5
(...)
>Get up! Please!
>	`revivalPoints+=1`
>Get up.
>	`revivalPoints-=1`
>Pro!
>	`revivalPoints+=1`

`revivalAdvance`

# revivalStart
`c,revivalStart`
![[]]
`p,2`
(...)
`revivalAdvance`
# revivalSuccess
![[]]
(...)
![[proMeditating.png]]
(...)
![[pro.png]]
(Hm?)
(What's going on?)
![[proMildlyConflicted.png]]
(It feels like you were calling me in my dream...)
(It... wasn't bad.)

>Get up!

![[proMildSurprise.png]]
(Ah!)
![[proDetermined.png]]
(Right!)

`revivalEnd,true`
`x`
# revivalFailure
(... I wish they'd all just leave me alone.)

`revivalEnd,false`
`x`
# revivalGuaranteedCatch
(...)
![[proExhausted.png]]
(Urgh... what...)
![[proCynical.png]]
(...what's going on?)
(Feels like I just had a nightmare.)
(Were you... saying something?)

>Get up!

![[proMildSurprise.png]]
(Oh! R-right!)

`revivalEnd,true`
`x`