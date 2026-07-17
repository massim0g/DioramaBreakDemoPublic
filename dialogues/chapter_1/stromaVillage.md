# inspectables

## pinwheel
`pinwheelsFound+=1`

`if pinwheelsFound == 1`
	![[proNonchalant.png]]
	(Supposedly these pinwheels are useful for measuring Air flow.)
	(But we obviously wouldn't need a dozen and change for just that. People just like them as decorations.)
`else if pinwheelsFound == 2`
	![[pro.png]]
	(... Another pinwheel.)
`else if pinwheelsFound == 3`
	![[proSkeptical.png]]
	(You really like these, huh?)
`else if pinwheelsFound == 4`
	![[proCynical.png]]
	(Are you just running around to look at these?)
`else if pinwheelsFound == 5`
	![[proAnnoyed.png]]
	(What is this, the fourth, fifth one?)
	>Fifth one.
	>	![[proBemused.png]]
	>	(Heh. Glad to see you're keeping track too.)
	>Fourth one.
	>	![[proBemused.png]]
	>	(Ha. Gotcha. It's the fifth.)
	>	(What's the point of this if you're not even keeping track properly?)
	>I'm not keeping track.
	>	![[proCynical.png]]
	>	(Then what's the point...?)
`else if pinwheelsFound == 6`
	![[pro.png]]
	(That's the sixth one now. Are you trying to find all of them?)
	>Yeah!
	>Nah. I just think they're cool.
	![[proNonchalant.png]]
	(Well... whatever. It's better than having to stand around while people talk to you.)
`else if pinwheelsFound == 7`
	![[proNonchalant.png]]
	(Seventh one. That's halfway.)
`else if pinwheelsFound == 8`
	![[pro.png]]
	(Heyo, number eight.)
`else if pinwheelsFound == 9`
	![[pro.png]]
	(Eighth one.)
	>!I think you miscounted.
	>	![[proSmirk.png]]
	>	(Glad to see you're paying attention.)
`else if pinwheelsFound == 10`
	![[proDetermined.png]]
	(The BIG one-oh.)
	![[proNonchalant.png]]
	(Just a few more now.)
`else if pinwheelsFound == 11`
	![[proNonchalant.png]]
	(Number eleven.)
	(...)
	(Can't think of anything to say about this one.)
`else if pinwheelsFound == 12`
	![[proSkeptical.png]]
	(Huh, didn't remember one being here.)
	![[proNonchalant.png]]
	(Two more then.)
`else if pinwheelsFound == 13`
	![[proNonchalant.png]]
	(Just one left, how exciting.)
`else if pinwheelsFound == 14`
	![[proNonchalant.png]]
	(Aaand... that's all of them.)
	(Good job?)
	>Hooray!
	>	![[proNonchalant.png]]
	>	(Yeeah!)
	>	![[proCynical.png]]
	>	(Can we go now?)
	>What do I win?
	>	![[proThinking.png]]
	>	(Hmm...)
	>	![[proFacade.png]]
	>	(A special secret thing that will only be revealed once we leave the village.)
	>	(Let's go get it!)
	>	`pinwheelPrizeMentioned`
`x`

## cabinet
![[proCynical.png]]
`if cabinetInspected`
	(Stop trying to get me to go through random cabinets.)
`else`
	(What do you want with this? I'm not about to start rifling through people's cabinets.)`cabinetInspected`
`x`
## prosHouse
### ergsRoom
`if !introDone`
	`x`
![[pro.png]]
(Grandpa's room.)
![[pro.png]]
(Kinda stuffy in there, but I never hear him complain.)
![[proRollingEyes.png]]
(Except when he's trying to be annoying.)
`x`

### salviasRoom
`if !introDone`
	`x`
![[pro.png]]
(Mom's room.)
>!Let's go in!
>	`playerClueless+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(No.)

`x`
### prosKitchenCabinet
![[pro.png]]
(I'm not really hungry...)
![[proFacade.png]]
(Why don't we get out there and work up an appetite?)
`x`

## prosNeighbourhood
### salviasGarden
![[proSmirk.png]]
I tell ya, my mom grows some great vegetables, `$player`.
`x`

### salviasTools
![[pro.png]]
(Mom's tools.)
>!She gardens?
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Yup. *All* the gardening.)
>	(Ivy doesn't perfectly, artfully drape itself y'know.)
>	![[pro.png]]
>	(I think she finds growing all our food more important though.)

`x`

### prosArmor
![[pro.png]]
(My old set of armor. Grew out of it a little while back.)
![[proCynical.png]]
(Used to hate wearing this crap, limits my movement.)
>!Can't you get a new set?
>	![[proSmirk.png]]
>	(I've been "procrastinating" on getting it refitted.)
>	![[pro.png]]
>	(No one's really rushing me though.)
>	(I'm doing well enough at sparring,)
>	![[proRollingEyes.png]]
>	(so it's probably at the bottom of the long list of things people feel the need to give me grief for.)

`x`

### chionAndKionArmor
![[pro.png]]
(Looks like Chion and Kion's spare armor.)
![[proCynical.png]]
(I don't think they were quite thinking it through when they ordered four identical sets.)
(I guess Edif just isn't as on top of that kinda stuff as his wife.)
`x`

### chionAndKionSpears
![[pro.png]]
(Spare spears. I guess when half your household uses them it's good to keep a few around.)
`x`
### prosLaundry
![[proSmirk.png]]
(Interested in my laundry?)
`x`
## townCenter
### Pond
![[pro.png]]
(The creature in the middle is supposed to have helped shape the world.)
![[proCynical.png]]
(I don't remember what its contribution was exactly...)
>!Your face?
>	...?

`x`
### akrosSpears
![[pro.png]]
(Akro's spare spears.)
![[proCynical.png]]
(He's the only one in his family who uses them, but I guess he needs enough for three people.)
>!Why would you need so many?
>	![[pro.png]]
>	(The tips break pretty easily.)
>	![[proCynical.png]]
>	(Kind of inevitable when all we have to make them are the cheap bits of metal we can scrape from the inside of the tree.)

`x`

## townHallExterior

### observationDeck
//todo: observation deck dialogue
`x`

### townHallLandscaping
![[pro.png]]
(These are the tools we use for landscaping around the town hall.)
>!The landscaping seems a bit half-finished.
>	![[proSmirk.png]]
>	(Yeah...)
>	(They pawn that work off to us young'uns.)
>	(And for once I'm not the only one with better things to do.)

`x`

### townHallEntrance
`if sprinklerCutsceneDone`
	`x`

![[proCynical.png]]
(What? Did you forget something?)
(C'mon, let's go. They're probably still cleaning up in there anyways.)
`x`
## townHallInterior
### mayorsOfficeDoor
`if introDone || dendroOfficeMentioned`
	`x`

![[dendro.png]]
That's the door to my office.
Feel free to stop by once you've had a chance to familiarize yourself with the village.
`x`
### stainedGlass
`if introDone`
	`x`

`camPan, stromaStainedGlassMural`

![[pro.png]]
...

![[dendro.png]]
Interested in the mural?
I would be happy to shed detail on the meaning.

![[proCynical.png]]
(Please say no.)

>I wanna hear about it.
>	![[proAnnoyed.png]]
>	(Fine.)
>	![[proCynical.png]]
>	Keep it short.
>	![[dendro.png]]
>	Yes, certainly.
>	![[dendroClearingThroat.png]]
>	Ahem.
>	![[dendroPreaching.png]]
>	This mural depicts the Vessel, the symbol of our <span style="color:rgb(225, 188, 105)">Ministry</span>.
>	The earth and the sea seen in the lower-`a,0.3`
>	![[proAnnoyed.png]]
>	`a`Shorter.
>	![[dendroSurprised.png]]
>	...
>	It- the symbol represents the universe as we understand it.
>	![[dendro.png]]
>	A higher observer's mind above, shrouded, then an image of the land below.
>	And finally our world, given form by their intersection.
>	`camReset`
>Ok.
>	`camReset`
>	![[pro.png]]
>	No, that's alright.
>	![[dendro.png]]
>	Very well.

`x`

### townHallBulletinBoard
![[proCynical.png]]
(The mayor wanted to keep this ritual quiet...)
(...but he reserved the town hall for hours.)
(Makes it pretty obvious what's going on.)
![[proRollingEyes.png]]
(Though I'm sure literally everyone knows anyway.)
![[proCynical.png]]
(Hard to keep a secret around here.)
`x`
### townHallClock
![[pro.png]]
(Huh. That clock isn't moving. Must be out of <span style="color:rgb(225, 188, 105)">Air</span>.)
![[proNonchalant.png]]
(I guess no one feels the need to check the time in here.)
`x`

### townHallFood
![[proSkeptical.png]]
Why is there food here?
![[phyllo.png]]
We thought the Patron might... want to eat?
![[proSkeptical.png]]
?
(Are you hungry?)
>Yes.
>	![[proNonchalant.png]]
>	(Well... I'm not.)
>No.
>	![[proNonchalant.png]]
>	(Good, neither am I.)
>I can't eat that, stupid.
>	`proAff+=0.5`
>	![[proRollingEyes.png]]
>	(I thought as much.)
>	![[proSmirk.png]]
>	The Patron says that's dumb!
>	![[dendroSurprised.png]]
>	Ah... forgive us.
>	The exact nature- how you experience your charge's senses was not made clear.
>	![[proSmirk.png]]
>	I forgive you.
>	![[proNonchalant.png]]
>	(Either way, I wasn't hungry.)

`x`

## library

## libraryCounter
`if sprinklerCutsceneDone`
	[[#phyllo]]
`else`
	[[#Libra]]

### libraryBackOfComputer
![[proNonchalant.png]]
(If you want me to tell you how all these wires and pipes work then you're out of luck.)
`x`

### emptyPlanter
![[pro.png]]
(Oh, empty planter.)
(Guess whatever was in it died.)
![[proThinking.png]]
(Or just wasn't pretty enough.)
`x`
### repository
![[pro.png]]
`if !repositoryExplained && !repositoryMentioned`
	(It's our copy of the <span style="color:rgb(225, 188, 105)">Repository</span>.)
`else`
	(It's our copy of the Repository.)
#### repoChoice
>What's that?[[#repoAsk]]`if !repositoryExplained`
>Read me the prophecy.[[#repoProphecy]]`if repositoryExplained`
>Flip to a random page.
>	![[]]
>	(...)
>	(`$repoLine`)
>	[[#repoChoice]]
>Leave it.

`x`
#### repoAsk
![[proCynical.png]]
(It's a big magic encyclopedia of your world, if you can believe it.)
![[proNonchalant.png]]
(Been around since the dawn of time.)
(Phyllo can probably explain it better than me.)`repositoryMentioned`
[[#repoChoice]]

#### repoProphecy
![[proNonchalant.png]]
(I doubt it's anything you don't already know...)
(But alright.)
![[pro.png]]
(...)
(Here it is.)
![[]]
Sometime, a chosen individual will be born.
Their birth will be accompanied by an obvious sign.
On their 20th birthday, they will be bonded with a human observer from Earth.
Said human will be the player of a great game.
>!Hm... so far this game is ok at best.
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Sorry to disappoint.)

![[]]
Together, if and only if they choose to persevere, the chosen and this player will bring a significant change to the world.
Once this change is wrought, the player's connection to the world will be closed.

![[pro.png]]
(That's it.)
>That's it!?
>	![[proAnnoyed.png]]
>	(Right? And yet...)
>	![[proNonchalant.png]]
>	(There are some other sections explaining what "human observer" actually means...)
>	(Though, they're pretty... abstract? It always kinda goes over my head.)
>	![[proThinking.png]]
>	(And... there's also the encrypted section.)
>	![[proCynical.png]]
>	(The mayor says it's just details about procedure.)
>	(Yet I'm supposedly not allowed to read it.)
>	(Real suspicious.)
>	`encryptedPropheciesMentioned`
>You were right, I did already know all that.
>	![[proNonchalant.png]]
>	(Well, at least it's all out in the open now.)
>Awfully dry for a prophecy.
>	![[proSkeptical.png]]
>	(What do you mean? All the prophecies are like this.)
>	![[proRollingEyes.png]]
>	(It'll rain here on this day. The temperature will be measured as exactly so-and-so.)
>	![[proNonchalant.png]]
>	(Relatively speaking, this one is exhilarating.)
>	`normalPropheciesExplained`
>What was that last part?
>	![[pro.png]]
>	(About your connection being closed?)
>	(Seems like you're not meant to stick around.)
>	![[proNonchalant.png]]
>	(Don't get too attached, I guess.)


`x`

## mainTrunk
### sprinkler
![[pro.png]]
(This is the transformer we need to use to power the Sprinkler.)
`camPan, stromaFixture`
![[pro.png]]
(Air comes in from the <span style="color:rgb(225, 188, 105)">Fixture</span> and gets compressed before getting sent through the hose.)

>The "Fixture"?
>	![[proSkeptical.png]]
>	(Do you not know?)
>	![[proThinking.png]]
>	(It's basically a giant magical Air font. And it keeps the monsters away, within a certain distance.)
>	![[pro.png]]
>	(That it's there is the whole reason we had to retreat all the way up here in the branches.)
>	>!Why did you put it there?
>	>	![[proSkeptical.png]]
>	>	(Put it?)
>	>	![[pro.png]]
>	>	(Oh. We don't know how to make these. They've always just been here.)
>	>	>!A *fixture* of the landscape?
>	>	>	![[proCynical.png]]
>	>	>	(... Yes. That's why we call them that.)
>	![[pro.png]]
>	(Anyway...)
>I see.

`camReset`

`if sprinklerExplained`
	![[pro.png]]
	(Regarding the Sprinkler itself, Mrs Kitamura already explained it better than I could.)
`else`
	![[pro.png]]
	(If you want to know how the Sprinkler itself works, Mrs Kitamura over there can probably explain it better than me.)`sprinklerMentioned`
	>!You're ok with stopping to ask?
	>	`proAff+=0.5`
	>	![[proSmirk.png]]
	>	(Well, it's pretty cool. I'd be curious too.)
	>	![[proNonchalant.png]]
	>	(And she's right there, not like it'll take long.)

`x`

### centerBranch
`camPan, stromaTrunkCenterLamp`
![[pro.png]]
(We keep this branch free of leaves so that the lamp we hung there can shine down properly.)
`camReset`
![[proHidingSomething.png]]
(Also so it doesn't keep growing and break the flooring.)
![[pro.png]]
(Whenever any pop up someone goes up and plucks them off.)
>!Hm.
>	![[proSkeptical.png]]
>	(What?)
>	>Seems a little heavy-handed.
>	>	(You want a bunch of lamp shade?)
>	>Nothing.

`x`

### playerIsLost
![[proCynical.png]]
(Ok, this is the third time we've been through here.)
(Are you lost?)

>Yes.
>	![[proAnnoyed.png]]
>	(...)
>	`face,pro,left`
>	![[proCynical.png]]
>	(The bridge to the exit is *right* over there man.)
>	`camPan,stromaBridgeToTrainingArea`
>	`a,1.5`
>	`camReset`
>	(Let's go already.)
>No.
>	`face,pro,left`
>	![[proCynical.png]]
>	(Mm. Ok. Just letting you know though, the bridge to the exit is right over there.)

`x`

## workshopArea

### workshopEquipment
![[pro.png]]
(Here's what we use to make all those spears and tools.)
>!You should start touching stuff at random and generally be a nuisance.
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Heh. I know how to use this stuff y'know.)
>	![[proNonchalant.png]]
>	(But Oiko does indeed get mad if I move things around.)
>	![[proSmirk.png]]
>	(As fun as that is...)
>	![[pro.png]]
>	(...we've got better things to do.)

`x`

### workshopAreaTable
![[pro.png]]
(Nothing like drinking juice in the shade on a hot day.)
![[proNonchalant.png]]
(You'd think it wouldn't get so warm all the way up here.)
(Something to do with the way the Great Tree circulates Air.)
>!How high up are we exactly?
>	![[proThinking.png]]
>	(Oh... about three thousand meters I think.)
>	>Wow!
>	>	![[proSmirk.png]]
>	>	(Yeah, we don't really think about it often but it is pretty cool.)
>	>I see.

`x`
### captainsHouse
`if encounteredPolema`
	![[pro.png]]
	(Captain's house.)
	![[proCynical.png]]
	(Let's not fool around here, I don't need her any more mad at me than she already is.)
`else`
	![[pro.png]]
	(Captain's house. Door's locked, as usual.)
	>!Captain?
	>	![[proCynical.png]]
	>	(Yeah, the guard captain. "Everyone's" captain.)
	>	![[proDisdainful.png]]
	>	(I could tell you more, but I don't think we're getting out of here without meeting her.)

`x`

## trainingArea
### spareTrainingEquipment
![[pro.png]]
(This is the spare stuff for sparring with the others.)
![[proSkeptical.png]]
(Come to think of it, where are they? I thought they'd be hanging around here.)
>!Who?
>	![[proNonchalant.png]]
>	(My fellow guard trainees.)
>	(Not that they're anything special.)
>	(All the men have to do combat training starting at around eleven.)
>	![[proHidingSomething.png]]
>	(Unless you're in with the mayor.)

`x`

## architectsHouse
### architectBookshelves
![[pro.png]]
(Hm. Even without all the architecture books this is an impressive collection.)
>!*You* would know.
>	`playerTeasedProAboutBooks``proAff-=0.5`
>	![[proCynical.png]]
>	(Har har.)

`x`

### architectKitchen
![[proNonchalant.png]]
(... It's a kitchen. Can't say there's anything special about it.)
>!Why don't you guys have sinks?
>	![[proSkeptical.png]]
>	(Sink...? Like, a hole?)
>	>For water.
>	>	![[proNonchalant.png]]
>	>	(Oh, water hole, I see. We don't need to eat and drink all the time.)
>	>	>Doesn't your mom have a vegetable garden?
>	>	>	![[pro.png]]
>	>	>	(I mean, it still helps to eat when you're hurt or tired.)
>	>	>Gotcha.
>	>Nevermind.

`x`

### architectUpstairsDoor
![[pro.png]]
(This door goes upstairs.)
![[proHidingSomething.png]]
(Haven't really had a reason to go up there lately.)
![[proNonchalant.png]]
(And I still don't.)
`x`

## mayorsHouse
### apiDoor
![[pro.png]]
(...)
(...if I listen closely, I can hear her tapping something in annoyance.)
`x`

### mediDoor
![[pro.png]]
(Must be Medi's room.)
(Funny to think he and his sister sleep under that deck behind the house.)
![[proRollingEyes.png]]
(I wonder if they can hear people stomping around up there.)
`x`
### mayorsRoomDoor
![[pro.png]]
(...)
[Hedera]
`camPan,hedera`
Ah... is the Patron... interested in mine and my husband's bedroom?
![[proFacade.png]]
`camReset`
No, just... admiring the floorplan.
![[proCynical.png]]
(Let's please not give the mayor any extra reasons to be upset with me.)
[Hedera]
`camPan, hedera`
I see! Yes, we do take immense pride in our unique building methods.
`camReset`
`x`

### mayorsHomeBookshelves
![[pro.png]]
(Hm... I've never really looked closely at this shelf.)
(Lots of books on business, government, leadership...)
![[proCynical.png]]
(...parenting...)
`x`

### mayorsKitchen
`if seen`
	`x`

![[proRollingEyes.png]]
(Surprisingly modest kitchen.)
![[proCynical.png]]
(I guess they're all too busy to eat very often.)
`x`

## mayorsOffice
### mayorsOfficeChair
![[proHidingSomething.png]]
(Screw this chair.)
>!Why?
>	`playerClueless+=1``proAff-=0.5`
>	(Should be obvious.)

`x`

### mayorsBookshelf
![[pro.png]]
(Just some old ledgers and stuff back here.)
![[dendro.png]]
Ah, I'd ask that you take care if examining those archives.
It's a little disorganized but that's still important documentation.
![[proCynical.png]]
Don't worry, I won't touch anything.
>!What's in there?
>	![[proAnnoyed.png]]
>	(...)
>	![[proCynical.png]]
>	What's in here?
>	![[dendro.png]]
>	Oh, various inventories, transcripts, electoral records, letters...
>	Anything to do with the village's operations.
>	![[proNonchalant.png]]
>	Exhilarating...

`x`

### mayorsAssistantDesk
![[proNonchalant.png]]
(Phyllo's little assistant desk.)
(... What's this?)
![[proMildlyConflicted.png]]
(...)
![[proSmirk.png]]
Haha. Is this a draft for your little speech?
![[dendroSurprised.png]]
Ah, that...
![[proSmirk.png]]
"O' Observer, we beseech you!"
![[dendroStern.png]]
...
![[proMildSurprise.png]]
"Pwease, pwease save us!"
![[dendroAngry.png]]
Pro...
![[proJovial.png]]
Alright, alright.
`x`

## artisansHouse
### artisansBackDoor
![[pro.png]]
(Gotta go through a patio if they want to go upstairs.)
(Must be a little annoying, but it's not like the village ever gets bad weather.)
`x`

### floraScribbles
![[proHaughty.png]]
(Hm...)
`if collectedPaper`
	(The composition is good, but the specific choices of color could be improved.)
	>!Oh! Grab a crayon!
	>	![[proSkeptical.png]]
	>	(Huh? What for?)
	>	>For taking notes!
	>	>	![[proCynical.png]]
	>	>	(I'm not gonna take notes in *crayon*.)
	>	>	![[proBemused.png]]
	>	>	(Or steal from a toddler, for that matter.)
	>	>Nevermind.
`else`
	(The composition is good, but the specific choices of color could be improved.)

`x`
# trainingDummy
`if beatUpTrainingDummy`
	![[pro.png]]
	(Let's wait until someone fixes it up before going at it again.)
	`x`

`c, proWalksToTrainingDummy`
![[pro.png]]
(...)
>Want to hit it?
>	(You're supposed to grant me special powers right?)
>	>Of course.
>	>	![[pro.png]]
>	>	(Mm...)
>	>	(Let's see them, then.)
>	>I am!?
>	>	![[proCynical.png]]
>	>	(...)
>	>	(I guess we oughta check to make sure, then.)
>	`c,trainingDummyFightStart`
>	`x`
>...
>	![[proMildlyConflicted.png]]
>	(Nah, no time.)

`x`

## trainingDummyEnd
![[pro.png]]
(Ok, ok, enough.)`beatUpTrainingDummy`

`c,combatEnd`

![[proCynical.png]]
(Another earful over breaking this thing is the last I want right now.)
![[proConflicted.png]]
(...)
(That didn't really feel all that different than normal.)
![[proNonchalant.png]]
(Oh well. Let's go.)
`camReset`
`x`
# fixture
`c,cameraPanToFixture`
![[pro.png]]
(Exit's right over there, to the left then down that bridge.)

## fixtureChoice
>What's with the giant screw? [[#fixtureA]]
>What's behind the big door? [[#fixtureB]]
>Let's go.

`x`

## fixtureA
(That's the village's Fixture.)

>!Fixture?
>	![[pro.png]]
>	(Keeps monsters away. Among other things.)
>	(That it's here is the whole reason we had to retreat all the way up here in the branches.)
>	>!Why did you put it there?
>	>	![[proSkeptical.png]]
>	>	(Put it?)
>	>	![[pro.png]]
>	>	 (Oh. You must know how to make these, but we don't. They've just always been part of the world for us.)
>	>	>!A *fixture* of the landscape?
>	>	>	![[proCynical.png]]
>	>	>	(... Yes. That's why we call them that.)

[[#fixtureChoice]]

## fixtureB
(Old people.)
>!... Care to elaborate?
>	(We house the elderly in there.)
>	(Much safer indoors, close to the screw.)

[[#fixtureChoice]]



# edif
`if seen`
	![[proCynical.png]]
	(Looks like we need to go back around.)
	`walkBack,left`
	`x`
[Edif]
Ah, Pro! Yer done with the ritual!
How're ya feeling? Needed to take a walk?

![[pro.png]]
Hey Edif. Feeling, uh, fine. Reevaluating a lot of things.
I'm giving my Patron the tour.
![[proCynical.png]]
(Apparently.)
>!Hey! How else would we get to talk to everyone?
>	(I see them every day. They'll manage.)
>	>!But *I've* never met them!
>	>	![[proAnnoyed.png]]
>	>	(Trust me, you'll be fine.)
>	(Anyway,)

![[pro.png]]
Took a little detour, but they finally seem ready to get back on the right path.
So if I could just squeeze past...?

[Edif]
Oh, sorry to say but path's closed.
Real beast of a branch just came down and tore a big chunk off the bridge.
'fraid you'll have to head back 'round.

![[proCynical.png]]
Ah.
(Was wondering why he was just standing there.)

[Edif]
Oh, no need to worry, Hinoki'll have it patched up in no time.
Want to help me keep watch?

![[proCynical.png]]
Would love to, but y'know, busy busy with the tour and all.

[Edif]
Oh, yes yes, wouldn't want to keep the Patron waiting, eh?

![[proCynical.png]]
Indeed.

[Edif]
Well, good luck!
And drop by for a visit, I'm sure Flora'll want to hear all about it.

![[pro.png]]
Right...
`walkBack,left`
`spokeToEdif`
`x`

# sprinklerCutscene

`c, sprinklerCutsceneStart`

[Trabe]
Turning the valve now!

`c, sprinklerActivation`

[Trabe]
Everything went well?

[Hinoki]
`camPan, hinoki, false`
`face,hinoki,left`
Yes. The path is clear and I managed to seal up the gap.
You'll have to go pave it properly and fix the railing, but the bridge is usable for now.

[Trabe]
`camPan, trabe, false`
Fantastic, darling! You did a wonderful job.

[Hinoki]
`camPan, hinoki, false`
`face,hinoki,right`
Don't patronize me.

[Trabe]
`camPan, trabe, false`
Ah...
I can see you're tired. Go sit, Elder Arb and I can put the <span style="color:rgb(225, 188, 105)">Sprinkler</span> away.

[Hinoki]
`camPan, hinoki, false`
`face,hinoki,right`
Yes. Though you ought to go let Edif know we're done.`a,0.8`

`c,trabeRunsOff,false`Right.`a,1.5`

`a,-1`

![[pro.png]]
(Exit's right over there, to my left then down the lower bridge.)

>What was that all about?
>	![[pro.png]]
>	(Just some construction, by the looks of it.)
>	(That's the village architect and her husband, they handle that sort of stuff.)
>Let's go.

`sprinklerCutsceneDone`
`x`

# proRoom

## proCloset
`if !introDone`
	![[pro.png]]
	(...)
	![[proMildlyConflicted.png]]
	(Why am I looking at the closet again? I didn't forget anything.)
	`x`
### proClosetPostIntro
`if seen`
	`x`
![[proNonchalant.png]]
(This is where I keep the digs.)

>Change into your casual clothes.
>Change into your winter clothes.
>Change into your fancy clothes.
>Cool.
>	(Yup.)
>	`x`

![[proMildSurprise.png]]
(What? I'm not changing, you're `speed,0.5`*watching*.)

`x`
## proDesk
`if !introDone`
	![[pro.png]]
	(I wonder if I'll miss this desk.)
	(...)
	![[proMocking.png]]
	(Not likely.)
	`x`
### proDeskPostIntro
`if seen`
	`x`

![[pro.png]]
`if prosRoomMentioned`
	(It's my desk. Not much else to say about it.)
	>What did you need to grab?
	>	![[proSkeptical.png]]
	>	(Huh?)
	>	>You said you needed to grab something in your room.
	>	>	`proAff+=0.5`
	>	>	![[proMildSurprise.png]]
	>	>	(O-oh, right, uh...)
	>	>	(Let's see...)
	>	>	![[proConflicted.png]]
	>	>	(...)
	>	>	![[proFacade.png]]
	>	>	(Here! A piece of paper.)
	>	>	(For notes! Very useful.)
	>	>	`itemCollect, paper`
	>	>	![[pro.png]]
	>	>	(Alright, let's go now.)`collectedPaper`
	>	>	>!Do you have something to write with?
	>	>	>	![[proCynical.png]]
	>	>	>	(You really think of everything...)
	>	>	>	![[proConflicted.png]]
	>	>	>	(...)
	>	>	>	![[proNonchalant.png]]
	>	>	>	(Nope. Fresh out of pencils. Oh well.)
	>	>	>	(I'm sure we'll figure something out.)
	>	>Nevermind.
	>...
`else`
	(It's my desk. Not much else to say about it.)
	(There's nothing useful in the drawers, in case you were wondering.)

`x`
## proSwordHolder
`if !introDone`
	`if seen`
		`x`
	![[proConflicted.png]]
	(Should I really bring the sword with me...?)
	![[proConflicted.png]]
	(...)
	![[proDetermined.png]]
	(Yes. I'm getting out of here *today*.)
	`x`
### proSwordHolderPostIntro
`if seen`
	`x`
![[pro.png]]
(I like to keep my sword within arms reach.)
(For home defense.)

>!Defense against what?
>	![[proHidingSomething.png]]
>	(... Birds, I guess.)
>	>!You kill birds that fly in here?
>	>	![[proEmbarrassed.png]]
>	>	(Well, one bird, one time.)
>	>	(And I didn't *kill* it, just... smacked it around until it stopped moving.)
>	>	(...)
>	>	![[proAnnoyed.png]]
>	>	(Look, when else was I gonna get a chance to practice on a target like that?)
>	>	(Besides, it's its own fault for trespassing.)

`x`
## proBed
`if !introDone`
	![[proBemused.png]]
	(I really shouldn't...)
	`x`
### proBedPostIntro
`if seen`
	`x`

![[pro.png]]
(You know what they say.)
(Plenty of sleep, no need to eat.)

>That's not at all how it works.
>	![[proMildSurprise.png]]
>	(Oh, right, you need to do both.)
>	![[proBemused.png]]
>	(Must suck.)
>Makes sense.

`x`

# hinoki
`if interactCount>1`
	[[#hinokiInteract]]

[Hinoki]
Oh, hello Pro. Did your ritual go well?

![[pro.png]]
Yes, Mrs Kitamura.

[Hinoki]
... You don't seem all that different.

![[proCynical.png]]
I have a feeling I'll be hearing that a lot.

[Hinoki]
Yes. Well, I'm certain it will mean a whole world of difference to some.

![[pro.png]]
You're not happy about the lockdown being lifted?

[Hinoki]
Mm. What difference is it to me?
With all the monsters out there it's all quite moot.
Certainly, my days of dangerous pilgrimages have been behind me for a long time.
Still, it will be nice to let my sisters know what's been going on. They've always been so concerned about it in their letters.

![[pro.png]]
Mm.

>I have questions!
>	![[proAnnoyed.png]]
>	(...)
>	(Fine, let's make it quick.)
>	[[#hinokiInteract]]
>Let's move on.
>	![[pro.png]]
>	(You got it.)

`x`

## hinokiQuestionsStart
![[proCynical.png]]
Er...
The Patron wants to ask you stuff.

[Hinoki]
Oh. I... see.
...
Well, go ahead.
[[#hinokiQuestions]]

## hinokiInteract
`if !seen`
	[[#hinokiQuestionsStart]]
[Hinoki]
Yes?
## hinokiQuestions

>How does the Sprinkler work?[[#hinokiSprinklerStart]]`if sprinklerMentioned && !sprinklerExplained`
>What was she doing just now?[[#hinokiWork]]`if !sprinklerMentioned`
>Sisters?[[#hinokiSisters]]
>Ask about her hometown.[[#hinokiHometown]]`if hinokiHometownMentioned`
>Let's go.
>	![[pro.png]]
>	No more questions. Goodbye, Mrs Kitamura.
>	[Hinoki]
>	Goodbye, Pro.
>	`x`

## hinokiWork
![[pro.png]]
What were you working on just now?

[Hinoki]
Ah, a stray branch damaged the bridge to the library this morning.
I was conducting initial clearing and repairs.`sprinklerMentioned`

>With a hose?`if !sprinklerExplained`
>	![[proSkeptical.png]]
>	(Do you not know...?)
>	![[proNonchalant.png]]
>	(No, I can see how you wouldn't.)
>	I don't think the Patron knows how the Sprinkler works.
>	[[#hinokiSprinkler]]
>Gotcha.
>	![[proNonchalant.png]]
>	Got it.
>	[Hinoki]
>	Good. Did the Patron have any more questions?
>	[[#hinokiQuestions]]

## hinokiSprinklerStart
![[pro.png]]
The Patron wants to know how the Sprinkler works.
## hinokiSprinkler
[Hinoki]
I see.
Let me start from the beginning then.
Our fine settlement is blessed with a <span style="color:rgb(225, 188, 105)">Modeler</span> indispensable to its construction.
`camPan,hoseFocus`
Simply running a strong enough current of Air through that hose will cause a miraculous essence to spray forth.
`camReset`
Well, really any hose or canister will do, the real device is just a special attachment.
Anyway... 
Our Great Tree, when met with this substance, will experience sudden, dramatic growth.
So dramatic, in fact, that unlike the other Modelers, the Sprinkler is quite useless for finer construction.
But it will still respond to the user's desire.
Give it clear instructions, and it functions well enough for demolition and the laying of foundations.
Indeed, it is safe to say Pro's forefathers could never have built such a village without it.
My, what I would give to have seen the old Stromal capital in its full glory... the whole tree, wrapped in a hive-like structure...
![[proNonchalant.png]]
You make it sound a bit creepy.
[Hinoki]
Hives are very beautiful, young man. Ordered, but organic.
But anyhow, I've gone off track. Did the Patron have any more questions?`sprinklerExplained`
[[#hinokiQuestions]]

## hinokiSisters
![[pro.png]]
They want to know about your sisters.
[Hinoki]
What about them?
![[proCynical.png]]
It's unclear.
[Hinoki]
Mm. I suppose it's unusual enough that I have relatives outside the village.
Yes, I have some family back in <span style="color:rgb(225, 188, 105)">Kiba</span>. We send each other letters.
Nothing too intimate. I just didn't want to lose touch entirely.
Also because that fretful bureaucrat insists on reading them all before they're sent out.
![[proSmirk.png]]
Heh.
[Hinoki]
I oughtn't complain. We all agreed to this lockdown after all.
![[proCynical.png]]
"All"?
[Hinoki]
Griping about it to the end, I see. You of all people shouldn't complain, it was for *your* safety after all.
![[proAnnoyed.png]]
Yes, yes.
[Hinoki]
In truth, it's been barely an inconvenience.
It shouldn't come as a surprise that I want little to do with my hometown.`hinokiHometownMentioned`
...[[#hinokiQuestions]]

## hinokiHometown
![[proFacade.png]]
(Trying to make me look bad for never having asked before?)
![[proAnnoyed.png]]
(Hmph...)
![[proNonchalant.png]]
The Patron is interested in hearing about your hometown.

[Hinoki]
Kiba? Let's see...
Awfully stuffy place. Every day a new "battle".
Their Modeler lets them maintain a great big wall in exchange for working their great big land.
And they all take *immeasurable* pride in defending it.
Frankly, they could just pull it back a bit and not face nearly as much trouble, but "every inch is an insult". Belligerent nonsense.
It was certainly no place to raise a child, so here we are.
I'll admit though, sometimes I do miss solid ground.

![[pro.png]]
Couldn't you have gone to Tongue?

[Hinoki]
Goodness, that rat's nest? No thank you, I quite like seeing the sun every once in a while.
Now then, any more questions?
[[#hinokiQuestions]]

# returnedHome

![[salvia.png]]
!

`c,momWalksToGreetPro`

![[salvia.png]]
You're back.
![[salviaConcern.png]]
You feeling alright? ...yourself?

![[pro.png]]
Yeah. I'm good. Fine. Patron's talking to me.
>!Hi!
>	They say hi.

![[salviaSmiling.png]]
I-I see. That's wonderful. I'm glad it all went well.

![[pro.png]]
Yeah.

![[salviaSmiling.png]]
You'll be setting off for good now, then?

![[proMildSurprise.png]]
Y-yes.
![[proHidingSomething.png]]
They're very impatient to go.

![[salviaSmiling2.png]]
Are they now?
Well, we oughtn't keep our great Patron waiting.
Tell them I wish you both luck.
And that you can always come home.

![[proAnnoyed.png]]
Yeah...

![[salviaSerious.png]]
And to remind you to eat! And to keep your recklessness in check!

>Will do!
>	`proAff+=1`
>	![[proAnnoyed.png]]
>	(You both make me want to crawl into a hole...)
>	![[pro.png]]
>	They say they will, Mom.
>	![[salviaSmiling2.png]]
>	Oh my!
>	Thank you.
>Alright. Can we go now?
>	`playerClueless+=1``proAff-=2`
>	![[proHidingSomething.png]]
>	They... say they will.
>	![[salviaSmiling2.png]]
>	Oh my!
>	Thank you.
>She's awfully casual about all this.
>	`proAff+=0.5`
>	![[proHidingSomething.png]]
>	(...)
>	(I know we're kinda rushing things...)
>	(But everyone expects me to leave *eventually*.)
>	(And she knows she's the only person I...)
>	![[proAnnoyed.png]]
>	(Aah, forget it. Let's just go. I hate this.)
>	![[proCynical.png]]
>	They- they say they will Mom. Keep me in check and all.
>	![[salviaSmiling2.png]]
>	Oh my!
>	Thank you.
>...
>	`proAff+=0.5`
>	![[proAnnoyed.png]]
>	Mom.
>	![[salviaSmiling2.png]]
>	Alright, alright.

![[salvia.png]]
...
![[salviaSmiling.png]]
Well then, I'll be in the kitchen if you still need me.

`c, salviaWalksToKitchen`

`spokeToMom`
`x`


# salviaInteract
![[proHidingSomething.png]]
(Let's give her some space...)

`x`


# oiko
`if seen`
	![[proCynical.png]]
	(She's clearly not up for talking to me.)
	`x`

![[pro.png]]
Hey, Oiko.

[Oiko]
Huh?
`face, oiko, down`
Oh. I'm kinda working on something here. What is it?

![[pro.png]]
Are you not interested in hearing about, y'know...

[Oiko]
What, here to bandy it around? I don't care.
You can finally do your job now, so go do it.

![[proConflicted.png]]
I... ok, yeah, way ahead of you.

[Oiko]
Thanks.
`face, oiko, up`
`p,1`
`face,pro,down`
![[proHidingSomething.png]]
(...)
>!What's her deal?
>	![[proCynical.png]]
>	(The girls are just like that.)
>	(A while ago they got it in their heads not to let me get too big for my britches or something dumb like that.)
>	>This displeases me!
>	>	`proAff+=0.5`
>	>	![[proSmirk.png]]
>	>	(Heh. Thanks. Though I doubt mentioning that would go over well.)
>	>	![[proNonchalant.png]]
>	>	(Can't even say I blame them too much...)
>	>Makes sense.
>	>	`playerSidedWithGirls``proAff-=0.5`
>	>	![[proCynical.png]]
>	>	(Does it now?)
>	>	(...)
>	>	![[proHidingSomething.png]]
>	>	(... Well, can't say I blame them *too* much...)
>	>I see.
>	>	![[proHidingSomething.png]]
>	>	(Can't say I blame them *too* much...)
>	![[proCynical.png]]
>	(But would it kill them to cut me some slack at this point?)
>	(I mean, who *doesn't* say embarrassing stuff as a kid?)

`spokeToOiko`
`x`
# erg
`if seen`
	[Erg]
	Hey!
	[[#ergInteract]]

[Erg]
Hey! Look who it is, makin' the rounds. 
Big day today, how ya holdin' up?

![[pro.png]]
Fine. Kinda. Turned out to be, uh, realer than I was expecting.

[Erg]
Oh?

![[pro.png]]
Yeah, there's definitely *something* listening in.
(This is my grandpa, by the way.)

[Erg]
Ooh! Wow-wee, who'd've thought!

![[proLaughing.png]]
Ha ha!
![[proSmirk.png]]
Yeah, who could've possibly seen this coming?

[Erg]
What'd ya say to the mayor?

![[proSmile.png]]
Oh, not much. I don't think it really mattered, he was so... ready to buy into anything.

[Erg]
Ha! Must've been a good change of pace for him! I'd've loved to see it.
But you, then, you've got the voice of the Patron in ya now? How's that feel?

![[proMildlyConflicted.png]]
Still getting used to it. People were right, I don't really feel all that different.
![[proHidingSomething.png]]
I... don't know that I'd have rushed over here on my own though.

[Erg]
Didn't want t'come see your old man's old man?

![[proSmirk.png]]
Worried about me?

[Erg]
'course I was.
And you'll worry your mother even more if you just take off.

`if spokeToMom`
	![[pro.png]]
	It's alright, we've spoken.
	[Erg]
	Ah. Good, good.
`else`
	![[proHidingSomething.png]]
	Yeah. I'll talk to her.
	[Erg]
	Good on ya.

And you can talk to me too. Anytime.

![[pro.png]]
Mm.

## ergInteract
[Erg]
Anything you wanted to say?
## ergQuestions

//todo: want to add more here but can't think of anything rn

>What's this building for?[[#ergWorkshopExplainer]]
>Let's go.
>	![[pro.png]]
>	I gotta go.
>	[Erg]
>	Alright.
>	`if !swordReminded`
>		Let your new friend know that you can always stop by if you need some smithing done.
>		`swordReminded`

`x`
## ergWorkshopExplainer

![[proNonchalant.png]]
The Patron wants to know about your job.

[Erg]
Ah, very sensible.
We make all the village's tools right here in this workshop. Swords, rakes, lamps, and everything else.
>!We?
>	![[pro.png]]
>	(Oiko helps him out.)
>	(She's the architects' daughter.)
>	[Erg]
>	Still with me?
>	![[proNonchalant.png]]
>	Hm? Oh, yeah.

[Erg]
Good material's hard to come by up here though so we tend to have to get creative. Hard to get it shipped in too.
Lotsa good wood though.

![[proSmirk.png]]
You've got a good grasp on working great wooden grates with the great green woods' good wood.

[Erg]
Darn straight.

[[#ergQuestions]]


# Xylo
![[proNonchalant.png]]
(That's Phyllo's dad.)
(Looks like he can't decide what order he wants those books in.)

`x`

# Libra
`if spokeToLibra`
	`x`

![[pro.png]]
Hey Libra.

[Libra]
Hm?
`face,libra,left`
Oh! Pro!
How nice to see you in here! You must be making the rounds!
Tell me, tell me, how does it feel?

![[proCynical.png]]
Um. Fine really. Not too different than normal.

[Libra]
Mm? Surely you're feeling the Patron in *some* way?

![[proCynical.png]]
Yeah. I can hear them talk.

[Libra]
Woow! Direct communion, fascinating!
Are they bossing you around?

![[proRollingEyes.png]]
Kinda.
>!Am not!
>	![[proSmirk.png]]
>	(Yeah, 'cause you can only try.)

[Libra]
So it's a bit give and take, huh?
That reminds of a book I read once!

![[proCynical.png]]
(Shocker.)

[Libra]
It was the story of a man grafted to a sapient worm.
Despite inhabiting the same body, neither could fully control the other, and they were forced to work together to pursue their mutual goals.
From a certain point of view, it's quite a romantic setup.

![[proSkeptical.png]]
Uh-huh...
... Did you just call the Patron a worm?

[Libra]
Haha! Good question!

`p,2`

Did you want to borrow a book?

![[proCynical.png]]
Uh, we're just browsing for now.

[Libra]
Aha! "We"! Of course!
Careful though, some people might get the wrong idea if you call yourself that.

![[proAnnoyed.png]]
R-right.

>!What wrong idea?
>	![[proCynical.png]]
>	(Er... I'm not actually royalty you know.)
>	(Though I see how you might have gotten that impression.)

`spokeToLibra`
`x`

# phyllo
`if spokeToPhyllo`
	[[#phylloInteract]]

![[phyllo.png]]
`spokeToPhyllo`
Hey, Pro.

![[pro.png]]
Hey hey.

![[phyllo.png]]
I'm surprised to see you here. With how long it took the mayor and I to clean up, I thought you'd be long gone by now.

![[proSkeptical.png]]
How little do you think of me?
![[phyllo.png]]
...
![[pro.png]]
...
![[proCynical.png]]
Ok, turns out the Patron wants the grand tour, or something.
They've just been running me all over the place.
![[phylloSurprised.png]]
Oh! I see now.
Well, if they have any questions about the library, that's why I'm here.
![[pro.png]]
(Do you?)
>Yeah.
>	![[proCynical.png]]
>	(Well, we're here. Might as well get it out of the way.)
>	[[#phylloQuestions]]
>Nah.
>	![[pro.png]]
>	We don't have any questions right now.
>	![[phyllo.png]]
>	Alright. I'm here if you need me.
>	`x`

## phylloInteract
![[phyllo.png]]
Any questions?
## phylloQuestions
>What's the selection like?[[#phylloSelection]]
>What's that machine with the tubes?[[#phylloComputer]]
>What's the "Original Repository"?[[#phylloRepository]]`if repositoryMentioned`
>Where's the lady that was here earlier?[[#phylloAskAboutLibra]]`if spokeToLibra`
>No more questions.
>	![[pro.png]]
>	No questions left.
>	![[phyllo.png]]
>	Alright. Feel free to just look around then.
>	`x`

## phylloSelection
![[pro.png]]
What kind of books do we have?
![[phyllo.png]]
Well, like a lot of libraries nowadays, it's mostly stuff that people thought was worth saving during the <span style="color:rgb(225, 188, 105)">Collapse</span>.
So mostly nonfiction, with lots of simple, practical reference books. We keep the more valuable stuff in the back.
![[phylloConcerned.png]]
It's a shame we only have one copy of the <span style="color:rgb(225, 188, 105)">Original Repository</span> we can display.`repositoryMentioned`
I guess people thought materials would be easy to come by, and prioritized saving other books.
But nowadays it's hard to find some of the ones needed to make copies.
![[phyllo.png]]
Anyway, in terms of fiction we only really have the one shelf.
It's not a great selection, I'll admit, but Moriko seems to like it.
The remaining shelves are organized according t-`a,0.3`
`a`![[proCynical.png]]
Alright, alright.
I think we get it.
![[phylloSurprised.png]]
Ah, yeah. You can always check the guide pamphlet.
Did you have any more questions?
[[#phylloQuestions]]

## phylloComputer
![[pro.png]]
They want to know about the computer.
![[phylloSurprised.png]]
Ah! I read about this.
Apparently the higher beings' computers take advantage of a mysterious force that only exists at their level of reality.
![[phylloConcerned.png]]
`face,phyllo,up`
Meanwhile, our computers can only run on <span style="color:rgb(225, 188, 105)">Air</span>, so they must look pretty weird to them.
![[phyllo.png]]
Still, even if this one's an older model, its clock runs at over four hundred kilohertz, very respectable.
At least, it's enough for the library's needs.
![[phylloConcerned.png]]
`face,phyllo,left`
Though I hear the most advanced models at <span style="color:rgb(225, 188, 105)">Front Academy</span> can fit that much juice in something that can sit on a desk.
![[phylloSurprised.png]]
And the Patron probably has access to computers tens, maybe hundreds of times faster.
![[phylloConcerned.png]]
It's strange though, the Original Repository never specifies precise numbers when it comes to computer stuff.`repositoryMentioned`
![[proSkeptical.png]]
(Do you know why that is?)
>Probably to spare you guys the embarrassment.
>	![[proCynical.png]]
>	(What's that supposed to...)
>	(Y'know what, I don't care.)
>	[[#phylloComputerEnd]]
>I'll never tell...
>No.

![[proCynical.png]]
(Fine. I really don't care.)
#### phylloComputerEnd
![[phyllo.png]]
Anyway, did you have any more questions?
[[#phylloQuestions]]
## phylloRepository
![[proCynical.png]]
(I guess if anyone's gonna explain it...)
![[pro.png]]
Can you tell the Patron about the Repository?
![[phyllo.png]]
Certainly! Let me think...
The Original Repository is a magical encyclopedia of the Patron and the <span style="color:rgb(225, 188, 105)">Creators</span>' world.
It's said to be the first <span style="color:rgb(225, 188, 105)">Modeler</span>, an irreplicable item from beyond this world, with magical powers.
![[phylloConcerned.png]]
Though, there's debate as to whether the Repository is a "proper" Modeler.
It doesn't really seem to have direct applications in construction, like the others.
And in its case specifically, "irreplicable" isn't *quite* right.
![[phyllo.png]]
We *can* make copies of it by performing a short ritual with the right materials assembled near an existing copy. 
Curiously, the copies made this way won't carry over any wear, erasure, or... edits.
You can always produce the same, exact, original version of the contents.
Even if you start from a copy with, say, half its pages torn out.
![[phylloSurprised.png]]
Which should be impossible! Lost information is lost after all. But I guess that's what makes it magical.
Oh, and also the fact that it's waaay bigger in the inside than it looks. 
![[phyllo.png]]
You could probably fill several dozen bookshelves if it were all printed to normal books.
![[phylloConcerned.png]]
And even then, there's clearly stuff being left out. 
So despite centuries of studying in and between the lines... there's still a ton we don't know about the Patron's world.
![[phylloSurprised.png]]
The complexity and volume of information is undeniably of a higher order.
![[proRollingEyes.png]]
Yes, praise be. (You're all very impressive.)
>!Thanks!

![[phyllo.png]]
Well, that about sums it up. You can go read the display copy on the bookstand over there if you want to know more.
Any more questions?
`repositoryExplained`
[[#phylloQuestions]]

## phylloAskAboutLibra
![[pro.png]]
(His mom?)
![[proRollingEyes.png]]
(Xylo's not here either...)
![[pro.png]]
Where are your parents?
![[phyllo.png]]
Oh. Working in the back, like usual.
![[proCynical.png]]
They're back there an awful lot.
![[phylloConcerned.png]]
Mm. Yeah. And still no brothers or sisters to help me out here.
![[proBemused.png]]
Huh?
![[phylloSurprised.png]]
Uh, forget I said that. 
What else did the Patron want to know?

[[#phylloQuestions]]
# moriko
`if interactCount>1`
	[[#morikoInteract]]

![[proNonchalant.png]]
Hey Moriko.

[Moriko]
Ah. Um. Hey.
Did the Patron tell you to talk to me?

![[proNonchalant.png]]
Basically.

[Moriko]
Oh wow. That's so cool.
I don't... what did they want to say?

## morikoResponse

>Wow, found a girl who doesn't hate you.[[#morikoHate]]`if spokeToOiko || spokeToHedera`
>I do have something to ask.
>	![[pro.png]]
>	(Yeah?)
>	[[#morikoQuestions]]
>I don't have anything to say.
>	![[pro.png]]
>	Oh. Nothing, apparently. Sorry.
>	[Moriko]
>	Oh! No! I-I'm sorry, I shouldn't have assumed.
>	![[proNonchalant.png]]
>	's fine.
>	I'm gonna keep looking around.
>	[Moriko]
>	Ok.
>	`x`

## morikoQuestions
>Ask about her.[[#morikoAbout]]
>Ask for her opinion of you.[[#morikoOpinion]]
>Ask for her opinion of me.[[#morikoOpinionPatron]]
>No more questions.`if morikoAsked`
>	![[proNonchalant.png]]
>	No more questions.
>	[Moriko]
>	O-ok. I'll get back to what I was doing then. Bye Pro.
>	![[proNonchalant.png]]
>	Bye.
>	`x`
## morikoHate
![[proAnnoyed.png]]
`playerClueless+=1``proAff-=0.5`
(Don't be weird.)
[Moriko]
...?
[[#morikoResponse]]

## morikoAbout
![[pro.png]]
They want to know more about you.
[Moriko]
Oh, of course. Um.
I don't really know what to say.
Can't you just tell them?
![[proCynical.png]]
I mean, I could, but you're right here.
[Moriko]
O-oh, you're right. Sorry.
M-my name is Moriko Kitamura. I'm the youngest of three siblings, and my mother is the village architect.
I guess... I like reading and drawing?
![[proSkeptical.png]]
Is that a question?
[Moriko]
I mean, my parents don't think it's very practical. And that's putting it lightly.
So I don't know. My mother does give me supplies, but I think she wants my drawings to be more... technical.
Mostly I just like drawing the characters I read about.

>!That's a fine hobby.
>	`proAff+=0.5`
>	![[proSkeptical.png]]
>	(You really think so?)
>	![[proNonchalant.png]]
>	(I guess she could use the encouragement.)
>	The Patron says it's a fine hobby to have.
>	[Moriko]
>	Aha. Th-thanks.
>	But yeah. Just a hobby.
>That's a lame hobby.
>	`proAff+=0.5`
>	![[proAnnoyed.png]]
>	(I'm not gonna say that.)
>	![[proCynical.png]]
>	(But I agree, it's kinda weird.)

[Moriko]
...
Sometimes I feel like I should want to do more with it, but I just... don't. Want to, I mean.
It's just for fun. But it probably is a waste if it won't help anyone.
I don't know. It's dumb. I shouldn't bother your Patron with this. Sorry.
![[proNonchalant.png]]
`a,0.3`It's-
`a`[Moriko]
No, really. It's silly.
Ask me something else.`morikoAsked`
[[#morikoQuestions]]

## morikoOpinion
![[proCynical.png]]
(Urgh.)
![[pro.png]]
The Patron wants to know what you think of me.
[Moriko]
Oh. Um. If I'm being honest...
![[proCynical.png]]
You don't need to be.
[Moriko]
N-no, no, I think it's great what you're doing, really.
I mean, I'm sure everyone does, even if, like, my sister gets upset about you getting special treatment.
![[proRollingEyes.png]]
Not surprised.
[Moriko]
But my brother always says you have a lot on your plate.
![[proCynical.png]]
Does he.
[Moriko]
Yeah. So I think I get what you're going through.
People say your attitude doesn't live up to your station or whatever but I can see you're working hard.
And I'd never be able to go out and risk my life like you will.
So I really appreciate it and all.
![[pro.png]]
Oh. Well, thanks.
![[proHidingSomething.png]]
(Would be nice to hear it from anyone who's not a kid, but at least *someone* is appreciative.)
[Moriko]
N-no problem.
`p,1`
Was there something else?
[[#morikoQuestions]]

## morikoOpinionPatron
![[pro.png]]
The Patron wants to know what you think of them.
[Moriko]
Ah, ok. I don't really know them, but I'm sure they're great!
And I'm really happy they've come to solve the monster problem and all that.
I... guess I've also thought it would be fun to have someone to talk to all the time.
![[proSmirk.png]]
Really?
[Moriko]
Oh, not that I can't... it's just, the village is so small, y'know?
![[proJovial.png]]
No kidding.
[Moriko]
Haha, yeah.
...
[[#morikoQuestions]]

## morikoInteract
![[pro.png]]
(She keeps glancing at me, but it doesn't look like she wants to talk anymore.)
`x`

# medi
`if interactCount>1`
	![[pro.png]]
	(Let's leave him be.)
	`x`
[Medi]
Pro! Good morning.
![[pro.png]]
Hey, Medi.
[Medi]
You've finished the ritual already? I saw you run by earlier.
Father must have been in quite a huff to see you arrive so late!
![[proRollingEyes.png]]
Yeah. Thanks for rubbing it in.
[Medi]
Oh. Um. I didn't mean...
![[proNonchalant.png]]
It's fine, I'm just messing around.
[Medi]
A-ah. Of course.
I'm relieved to see that the bonding has not affected you too much.
![[pro.png]]
Mm.
(Speaking of, why are you making me talk to Medi?)

>Just making the rounds.
>	![[proCynical.png]]
>	(So do we *have* to get into a long conversation?)
>	>What's wrong with Medi?
>	>	[[#mediWhatsWrong]]
>	>No, we can go.
>	>	[[#mediLeave]]
>What's wrong with talking to Medi?
>	[[#mediWhatsWrong]]
>No reason, we can go.
>	[[#mediLeave]]

## mediWhatsWrong
![[proHidingSomething.png]]
(Hrm. I don't have a problem with *him* exactly.)
![[proCynical.png]]
(But everything I say to him has a strange way of making it back to his dad.)
>I just wanted to ask him some stuff.
>	![[proAnnoyed.png]]
>	(Fine, let's keep it brief though.)
>	![[pro.png]]
>	The Patron wants to ask you some stuff.
>	[Medi]
>	Wow! You're that acclimated to them already?
>	By all means then, ask away.
>	[[#mediQuestions]]
>Alright, we can go.
>	[[#mediLeave]]

## mediQuestions
>Who is he?[[#mediAbout]]
>What's he reading?[[#mediBook]]
>No more questions.[[#mediLeaveAfterQuestions]]`if askedMedi`

## mediAbout
![[pro.png]]
The Patron wants to know more about you.
[Medi]
I'm honored! Let's see...
I'm the first son of this town's mayor, though I have an elder sister.
And... it is a bit presumptuous of me to say, we are a democracy after all...
but at some time or another I will likely be stepping into my father's role, just as he took the role from his father.
So I try to spend most of my time preparing. It's a big responsibility.
Although, that's not to say that I feel unduly burdened. Statecraft has always been an interest of mine.
...enough so that at times I wonder what it would be like to hold an even higher office.
It's just a fancy though, I can hardly envision the weight of such a task. My father seems stressed enough with his duties alone!
![[proSmirk.png]]
We can agree on that.
>!Why's he so sure he'll be mayor? What about his sister?
>	![[pro.png]]
>	The Patron wants to know why your sister couldn't be mayor.
>	[Medi]
>	Api!?
>	Ahem.
>	Ultimately we all want what's best for the village. 
>	If she ends up the most suited, then, naturally, she'll be elected.

Now, was there anything else?`askedMedi`
[[#mediQuestions]]
## mediBook
![[pro.png]]
What are you reading?
[Medi]
Oh, it's a book on courtly etiquette.
A bit dry in most sections, but the dialogues are entertaining.
![[proNonchalant.png]]
Is it like an instruction manual?
[Medi]
In a sense, yes.
I'll admit, in all likelihood the advice won't ever serve me.
But sometimes it's fun to imagine oneself in a more cutthroat environment.
![[proSkeptical.png]]
Really? Sounds stressful.
[Medi]
Well, it's just a fantasy. I don't think places like that really exist anywhere in this era.
Perhaps a century after the monsters are driven away and we see the return of proper states.
But even I'll have died of old age by then...

>!How old is this kid?
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Heh.)
>	I think the Patron thinks that's a pretty dark thing to say for someone your age.
>	[Medi]
>	I-I'm old enough!
>	And I have responsibilities! Father says it's right not to shy away from these sorts of thoughts.
>	Though perhaps I got a bit carried away...

Regardless, I hope I've answered to your satisfaction, Observer. Was there anything else?`askedMedi`

[[#mediQuestions]]

## mediLeaveAfterQuestions
![[pro.png]]
No more questions. I'll leave you to it.
[Medi]
Yes, good luck with everything.
It... was good to talk with you after all this time, Pro.
![[pro.png]]
`proAff+=0.5`
Oh. Uh, good talking with you too.
Bye.
[Medi]
Goodbye.
`x`

## mediLeave
![[pro.png]]
(Cool.)
![[proNonchalant.png]]
Well, I can see you're in your book, and I've got a whole *bunch* of business to deal with, so I'll leave you to it.
[Medi]
Ah. Yes, of course.
Good luck.
![[proNonchalant.png]]
See ya.
`x`

# hederaMeeting
[Hedera]
Ah!
`c,hederaWalksToPro`
Welcome, welcome.
We are honored to have you visit.
Feel free to explore our home as you please.
![[proSkeptical.png]]
Um. Quite the warm welcome.
[Hedera]
I endeavor to offer your Patron nothing but the gentlest hospitality.
As we all should.
![[proNonchalant.png]]
Ah.
[Hedera]
`face,hedera,left`
Api!
We have a guest!

`c, apiComesOut`

[Api]
What- oh, mother, you let him *in*?

`camPan,hedera,false,16`
[Hedera]
Api! Mind yourself!

`camPan,api,false,16`
[Api]
No! I don't care what you say, I won't wheedle and grovel in front of *him*!

`camPan,hedera,false,16`
[Hedera]
It's-! 
Manners, Api! Manners!

`camPan,api,true,16`
[Api]
Ugh!

`c, apiLeaves`

[Hedera]
`face,hedera,right`
Please forgive her.
She's still attached to certain childish ideals.

![[proFacade.png]]
I-it's fine.

>!What did you do to her?
>	![[proMildSurprise.png]]
>	(I, uh...)
>	(I may have been a bit lacking in humility in the past. About my job, y'know.)
>	![[proHidingSomething.png]]
>	(In my defense I was, like, 12.)
>	![[proAnnoyed.png]]
>	(The things people hold against you...)
>	>!Did you ever apologize?
>	>	`playerSidedWithGirls``proAff-=0.5`
>	>	![[proCynical.png]]
>	>	(Er... the opportunity kinda passed me by.)
>	>	![[proEmbarrassed.png]]
>	>	(In my defense I was... just a bit older than 12...)
>	>	![[proAnnoyed.png]]
>	>	(Look, at a certain point she just decided anything I could do would be too little, too late.)

![[pro.png]]
Anyway, Mrs Demos, I think the Patron would like to poke around.
![[proCynical.png]]
(You seem into that.)

[Hedera]
By all means.

`c,hederaWalksBack`
`spokeToHedera`
`x`

# hederaInteract
![[proMildlyConflicted.png]]
`if !hederaCreepy`
	(I... don't really want to talk to Hedera.)
	>!Why?
	>	![[proDisdainful.png]]
	>	(She creeps me out, man! Always feels like she's looking through your skull at something...)
	>	`hederaCreepy`
`else`
	(...)
`x`

# edifAndTrabe
`face,pro,right`
`if seen`
	![[pro.png]]
	(Let's not bother them while they're working.)
	`walkBack, left`
	`x`

[Edif]
`camPan, edif`
Ah, Pro!
`if spokeToEdif`
	Good to see ya again!

[Trabe]
`camPan, trabe`
`face,trabe,left`
Oh, yes, hello there.
Sorry I couldn't welcome you in, as you can see we're a bit swamped here.

![[proNonchalant.png]]
Don't worry about it. Really.

[Trabe]
What bad luck to have this happen on your big day, eh?
I assume you must be making the rounds?

![[proAnnoyed.png]]
Seems so.

[Trabe]
Well, believe me, I'd love to talk, but we've got to work out our plan to repair this railing quickly.
Don't want anyone, ehm, taking an accidental dive.
Why don't you come by again tomorrow?

![[proNonchalant.png]]
... Sure.

`face,trabe,right`
`camReset`
`walkBack,left`

`x`


# arb
## arbInterrupt
`if spokeToArb`
	`x`
[Arb]
Ahem.

`c, proWalksToArb`
## arbInteract
[Arb]
...
It is done?
![[pro.png]]
Yes, Elder.
[Arb]
Good.
I will address the Patron directly then.
...
Welcome to our fair village.
I hope its splendor reaches you well, up there. Enjoy it at your leisure.
However, the chambers beyond these doors are forbidden to outsiders, as they have been for generations.
Within them, we keep our most vulnerable, our injured and our elderly.
And while we do not doubt your good intentions, accidents happen.
We humbly ask that you restrain your curiosity until you and your charge have proven the stability of your bond.
>Understood.
>But I wanna see!!
>	`playerWhiny+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(Sorry, but I don't feel like going to put my sword away just so I can get gawked at by a bunch of retirees.)
>	`var, lying`
>This is a pretty transparent attempt to save resources.
>	`proAff+=0.5`
>	![[proSmirk.png]]
>	(Heh.)
>	(Yeah, our warehouses are through there too.)
>	(Trust me though, there's nothing worth stealing.)
>	`var, lying`
>"Elder"? How unusually respectful.
>	![[proAnnoyed.png]]
>	(I learned the hard way not to mess around with him.)
>	![[proSmirk.png]]
>	(But it's not like he needs me to say anything else. I can just nod and zone out while he's talking.)
>	[Arb]
>	Boy?
>	![[proMildSurprise.png]]
>	A-ah, yes, Elder.
>	`var, lying`

![[pro.png]]
The Patron understands.

[Arb]
`if lying`
	...
	The way will open in due time. Thank you for your understanding.
`else`
	That is good. Thank you.

I must now go and return the Sprinkler to its safe. I wish you the best.

`c, arbLeaves`

`spokeToArb`

`x`

# fibra
[Fibra]
Mm?
Oh, Pro, come in, come in!

`c, proWalksToFibra`

![[proSoftSmile.png]]
Heya Fibra.
[Fibra]
My, look at you with your sword and everything! The cloak suits you well.
![[proMildlyEmbarassed.png]]
Th-thanks.
[Fibra]
Mm, but those shoes don't really fit you anymore, do they?
Remind me to make you some new ones when the next shipment comes in.
![[proHidingSomething.png]]
Oh. Sure.
[Fibra]
What's wrong?
Oh! Dear, how silly of me, you'll have left by then, right?
![[proMildSurprise.png]]
Er- well... yeah.
![[proFacade.png]]
Don't want to keep the Patron waiting.
[Fibra]
Yes, of course.
My... it's hard to believe they're finally here...
Ah! Then, are you here on the Patron's behalf? If you're looking for Edif I hear he's out fixing the bridge.
![[proCynical.png]]
No, I'm just... talking to everyone, I guess.
[Fibra]
Oho! Looks like you're already sick of it, eh?
I won't keep you long then.
![[proMeditating.png]]
Thank you.
[Fibra]
I reckon you'll get your proper fill of questions at tomorrow's celebration after all.
![[proFacade.png]]
Y-Yeah.
`x`

## fibraInteract
![[pro.png]]
(Did you want to ask her something?)
## fibraQuestions

>Why does your village have so few kids?[[#fibraKids]]
>What's all this equipment for?[[#fibraEquipment]]`if !fibraEquipmentAsked`
>No, nevermind.
>	`x`

## fibraKids
![[proSkeptical.png]]
(Is that a question for her?)
![[pro.png]]
(I guess it couldn't hurt to ask.)
![[pro.png]]
The Patron's wondering why the village has so few children.
[Fibra]
Aha, my daughter is just that adorable, isn't she?
![[proNonchalant.png]]
Maybe.
[Fibra]
Yes!
Well then, to answer your question... hm... 
I couldn't really say!
I s'pose we're not lacking hands. Although the captain might disagree.

>But with so many couples, doesn't it just... happen?
>	![[proSkeptical.png]]
>	(... No? Why would it?)
>	>Accidents?
>	>	![[proSkeptical.png]]
>	>	(You can accidentally choose to have a kid?)
>	>	![[proMildSurprise.png]]
>	>	(Oh! That's right! That *is* the case for you guys!)
>	>	![[proNonchalant.png]]
>	>	(Sorry. Been a while since we covered that part of the textbook.)
>	>	>!This is so unfair.
>	>	>	![[proCynical.png]]
>	>	>	(Wanna trade places then?)
>	>	![[proNonchalant.png]]
>	>	(Anyway.)
>	>	(Did you want to ask her something else?)
>	>	[[#fibraQuestions]]
>	>Nevermind.
>Don't you guys want more kids?
>	![[pro.png]]
>	Do you think people want more kids?
>	[Fibra]
>	Well, maybe. 
>	I can say in our case that three is already quite the handful!
>	And it wouldn't be very fair to the others if me and Edif had many more.
>	There's only so much space after all.
>	![[pro.png]]
>	Yeah...
>	![[proSkeptical.png]]
>	We're not *that* cramped though, are we?
>	[Fibra]
>	No... but these things have a way of getting out of hand, I think.
>	![[proMildlyConflicted.png]]
>	Hm.
>Alright.

![[proNonchalant.png]]
(Moving on then.)
(Did you want to ask her something else?)
[[#fibraQuestions]]


## fibraEquipmentAsk
![[pro.png]]
The Patron's curious about your tools.
`var askedDirectly`
## fibraEquipment
`if fibraEquipmentAsked`
	![[pro.png]]
	(Fibra's tools.)
	![[proNonchalant.png]]
	(She could probably go on forever about any of them, so let's not stare too hard.)
	`x`
[Fibra]
`if !askedDirectly`
	`camPan, fibra`
Ah! Interested in the goods, eh?
This is what I use to make things for the village.
Clothes, trinkets, knickknacks, what have you.
With you kids and all your growing, there's no shortage of work!
![[pro.png]]
Thanks for that.
[Fibra]
Oh, don't mention it. Without your mother's crops I could hardly do half the things I'm able to.
It's a fun challenge though, working with what we have.
![[proNonchalant.png]]
(She seems a little wistful...)

`fibraEquipmentAsked`

`if askedDirectly`
	![[proNonchalant.png]]
	(Anyway.)
	(Did you want to ask something else?)
	[[#fibraQuestions]]
`else`
	`camReset`
	`x`
# flora
`if spokeToFlora`
	![[pro.png]]
	(Looks like she's lost interest in talking, so she won't even look at me.)
	![[proMeditating.png]]
	(How enviable.)
	`x`

![[proFacade.png]]
Hey Flora!
[Flora]
Hello!
Mumma said you can hear the Patron now.
![[proSmile.png]]
Sure can! Did you want to tell them something?
[Flora]
No!
Thank you!

`c, floraRunsAway`

![[pro.png]]
...
(At least someone gets it.)

`spokeToFlora`

`x`

# dendroIntro
![[dendro.png]]
`facePlayer, dendro`
Hm?
Ah, welcome, welcome.
You've had a chance to look around?
![[proCynical.png]]
Mm.
![[dendro.png]]
And how is the connection? Are you both well acclimated?
>It's going great!
>	![[proNonchalant.png]]
>	They seem to be enjoying themselves at least.
>	![[dendroSurprised.png]]
>	I... see. Well, all the better.
>I'm getting the hang of it.
>	`playerClueless+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(Of what? Running me around like a gopher?)
>	![[dendroStern.png]]
>	Something wrong?
>	![[proFacade.png]]
>	Not at all! The Patron apparently loved getting the tour!
>	![[dendroStern.png]]
>	Hmph. If I were you I wouldn't be so glib about my last days of peace.
>	![[proCynical.png]]
>	Yes, peace. Hanging out with you, what comes to mind is peace. 
>	![[dendroOhReally.png]]
>	Today, at least, the Patron guided you here. Peace or not, perhaps it would behoove you to find something in that.
>	![[proAnnoyed.png]]
>	You wouldn't say that if you knew them like I do...
>	![[dendroOhReally.png]]
>	Oho, perhaps, perhaps.
>No, he keeps talking back and telling me what to do!
>	`playerWhiny+=1``proAff-=0.5`
>	![[proCynical.png]]
>	(You know he can't hear you, right?)
>	![[proFacade.png]]
>	It's going great!
>	![[dendroOhReally.png]]
>	Mm. I suppose I'll have to take you at your word.
>	>!See! This is what I'm talking about!
>	>	![[proNonchalant.png]]
>	>	(Looks like you'll just have to "acclimate".)

![[dendro.png]]
Anyhow, if you came with any questions then please, ask away. 
I am here to help.
![[proCynical.png]]
I'll let you know.
`x`

# dendro
![[pro.png]]
(What do you want to ask him?)

## dendroQuestions
>Why is he so mean to you?[[#dendroMean]]`if !judgedDendro`
>Why are you so flippant with him?[[#dendroNotMean]]`if !judgedDendro`
>What's he working on?[[#dendroWork]]
>Do you guys worship me? It seems unclear.[[#dendroWorship]]
>Why doesn't the village have any toilets? Seems like a serious institutional failing.[[#dendroToilets]]
>What's in the encrypted prophecies?[[#dendroProphecies]]`if encryptedPropheciesMentioned`
>No more questions.
>	`x`

## dendroMean
`proAff+=0.5`
![[proLaughing.png]]
Hah!
![[dendroSurprised.png]]
Mm?
![[proSmirk.png]]
Yes, why *are* you so mean to me?
![[dendroAngry.png]]
...
![[dendroClearingThroat.png]]
...
![[dendro.png]]
We can only hope to do the best with what we have.
![[dendroStern.png]]
Let's leave it at that.
Was there anything else?`judgedDendro`
![[pro.png]]
(Was there?)
[[#dendroQuestions]]

## dendroNotMean
`proAff-=2`
![[proHidingSomething.png]]
Tch.
![[dendro.png]]
What is it?
![[proCynical.png]]
Why do you have to take *everything* so seriously *all* the time?
![[dendroStern.png]]
I've told you a thousand times. It's the fate of the world, Pro.
To be lenient in our efforts would be irresponsible.
![[proCynical.png]]
Even if it makes "us" miserable?
![[dendroStern.png]]
If that's the price to pay, it's barely worth thinking about.
But come now, you're not miserable. A proper education is hardly so torturous.
![[proCynical.png]]
(And there you have it.)`judgedDendro`
>!I'm sorry.
>	`proAff+=3`
>	![[proMildSurprise.png]]
>	(Oh. Don't worry about it, it's not like you had anything to do with it.)
>	![[proCynical.png]]
>	(Well, not directly.)
>	![[pro.png]]
>	(Anyway, had anything else to ask?)
>	[[#dendroQuestions]]

`playerSidedWithDendro`
[[#dendroQuestions]]

## dendroWork
![[pro.png]]
The Patron wants to know what you're working on.
![[dendro.png]]
Oh, right now, well...
I'm drafting various letters, formal announcements, what have you. 
Now that we're going public with your existence, it's important the heads of the other settlements are informed.
![[dendroClearingThroat.png]]
That being said, <span style="color:rgb(225, 188, 105)">Kiba Village</span>'s mayor should already be aware.
![[proMildSurprise.png]]
Huh?
![[dendro.png]]
Yes, the message was sent as of a few weeks ago.
I thought it best to make someone aware sooner rather than later, in case of emergency, and he's a trusted man.
![[proCynical.png]]
Twenty years of keeping a secret and you felt like blabbing right before the ritual?
![[dendroClearingThroat.png]]
Now, now. No one would have been in a position to act on that information in time.
The insurance it provides is well worth the risk of a leak.
![[proCynical.png]]
Insurance against what?
![[dendroStern.png]]
We can't be certain we're the only ones who have access to the restricted knowledge in the <span style="color:rgb(225, 188, 105)">Repository</span>.`repositoryMentioned`
Or that there hasn't been *any* sort of leak in the past two decades.
If there had been any with that information poised to act against you,
it would've been all too obvious what the village has been up to.
Having the option to flee to Kiba seemed desirable in many cases. That's also why I had that badge made.
![[proRollingEyes.png]]
Sounds paranoid to me.
![[dendro.png]]
Perhaps. But it doesn't hurt to be too careful when the world is at stake.
It's all somewhat moot now. With the Patron at your side, you're sure to be in much less danger.
![[proCynical.png]]
Er, right.
>!Thanks for believing in me!
>	![[proCynical.png]]
>	The Patron says thanks.
>	![[dendroSurprised.png]]
>	Ah. They're very welcome...?

![[pro.png]]
(Did you have something else to ask?)
[[#dendroQuestions]]

## dendroWorship
![[proThinking.png]]
(Ah... sorta? The details were always a bit confusing to me.)
![[pro.png]]
The Patron wants to know if we worship them or not.
![[dendroSurprised.png]]
My, to be ignorant of even that...
![[dendroClearingThroat.png]]
Ah- um, I apologize, I did not mean to imply you were derelict in any regard, Observer.
![[dendro.png]]
Allow me to explain then.
Firstly, ours is not a blind faith.
The evidence granted to us by the <span style="color:rgb(225, 188, 105)">Creators</span> of a set path for this world is indisputable.
![[dendroClearingThroat.png]]
That this path is a desirable one has been historically debated...
![[dendro.png]]
But trust in the plan has been, one could say, the central pillar of our organization and its allies.
![[dendroClearingThroat.png]]
And remains so, for what is left of it.
![[dendro.png]]
So, all that to say, we trust and respect your role in this process.
Including your mind's nature as... substrate, so to speak, for our world's instantiation in higher reality.
We feel grateful for all of it.
But that is the extent of it.
We are not, say, under the illusion that you or the Creators can see and act without constraint.
![[dendroClearingThroat.png]]
Though to be completely frank, the *exact* nature of those constraints,
and your respective... positions, metaphysically speaking...
Even today, there is a lot that remains ambiguous there...

>I get it. I can explain.
>	![[proAnnoyed.png]]
>	Mmm...
>	![[dendroSurprised.png]]
>	Ah- judging by Pro's expression, you've begun to explain, but please, do not feel obliged.
>	![[dendro.png]]
>	Under your tutelage, he'll have plenty of time to come to a deep, first-hand understanding of it all.
>	![[dendroStern.png]]
>	And it will be easier for everyone to have him explain it himself, rather than by proxy.
>	![[proNonchalant.png]]
>	Absolutely.
>I don't really get it.
>	![[proNonchalant.png]]
>	(We're all peas in a pod then.)
>...


![[pro.png]]
(Did you have something else to ask?)
[[#dendroQuestions]]

## dendroToilets
![[pro.png]]
...
What's a toilet?
![[dendro.png]]
Hm?
Ah, wait, I see.
Observer, we do not produce waste as you do.
What little we do excrete is flushed entirely by our breathing.

>No fair!
>	![[proSkeptical.png]]
>	(Is it really that inconvenient?)
>How dreadful. You will never know the joy of a full unloading.
>	![[proCynical.png]]
>	(Uh... I think we're making do.)

![[pro.png]]
(Anyway, did you have something else to ask?)
[[#dendroQuestions]]

## dendroProphecies
`proAff+=0.5`
![[proSmirk.png]]
The Patron wants to know what's in the encrypted prophecies.
![[dendroOhReally.png]]
Nice try.
![[proFrustrated.png]]
Oh come on, I'm not lying.
![[dendro.png]]
There is nothing in there that your Patron wouldn't already be aware of.
If they wish to reveal it to you they are free to do so directly.
>!But... what is it?
>	![[proCynical.png]]
>	They don't know what you're talking about.
>	![[dendro.png]]
>	Ah. Well.
>	I understand the issue, but without a means of verifying the Patron's true feelings, my hands are tied.
>	My apologies.

![[proHidingSomething.png]]
Hmph.
[[#dendroQuestions]]