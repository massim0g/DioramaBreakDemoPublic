ようこそ! Welcome to the DML demo!

What's DML? Why, only the special markup language that makes writing RPG dialogue easy!

DML stands for Dialogue Markup Language, which doesn't make sense anymore because this is the third iteration and it's no longer really a *markup* language and, uh...
Maybe we can just call it Dialogue Massimodin Language. Anyway...

As you might have noticed, DML lets you write text that will show up as dialogue in-game!
Each new line will show up as a new text box, 
just
like
this!
Though empty lines will be skipped. //You can also add comments like this which won't be displayed.

//Since this is just a comment, this counts as an empty line.

If you want to style your text, markdown shorthand for **bold** and *italic* text works. 
You can also use the \<span style\> html tag for <span style="color:rgb(98, 190, 255)">colored text</span>, quickly accessible using the colored text plugin in obsidian. //***bolditalic*** text will also work, but most fonts don't support it!

<span style="color:rgb(98, 190, 255)">Colored Text</span>

# Labels
Labels can be used to organize your dialogue and jump from one place to another. They're denoted using markdown headers (i.e. starting a line with 1-6 '#' symbols, followed by a space). 
If a line contains an obsidian header link (something like \[\[#labelname]]), the dialogue will jump to that label immediately.
Let's try jumping to a label now!
[[#My Second Label]]

## My First Label
Here we are at the first label!
Wait, is that right?
Well whatever, let's jump to the end!
[[#My Last Label]]

## My Second Label
...
Did it work?
I guess it feels like we skipped over some stuff...
Let's try jumping back.
[[#My First Label]]

## My Last Label
Ta-da!
Lines with labels will be skipped over just like empty lines, so you can also just use them to organize your dialogue.
# Branching dialogue
Now let's see something *really* cool: branching dialogue!
Choices can be concisely expressed using markdown quotes (>) and indentation.
Quick question, what's your favorite food?

>Apple pie
>	Wow, me too!
>	We have so much in common.
>Haddock
>	Oh.
>	That's a little unusual.
>	But you do you!
>Benits
>	That's, uh... 
>	That's nice.

No matter the choice, dialogue will move on to the next line after the choice block (unless you jumped to a label).
You can even nest choices!

Here's another question, where do you like to hang out?
## Nested choice
>The mall
>	The one with the good bagels?
>	>I'm vegan so I wouldn't know.
>	>	Are bagels not vegan?
>	>	>Not the good ones.
>	>	>	Oh.
>	>No, the one with the bad bagels.
>	>	Haha!
>	>	I hate that place!
>The sky
>	Oh, are you a pilot or something?
>	>No. I astral project.
>	>	Groovy!
>	>Uh, yeah, definitely.
>	>	Cool! 
>	>	My mom flew on a plane once.
>My house
>	Sounds lonely.
>Haddock
>	Uh, wrong question.
>	Wanna try that again?
>	[[#Nested choice]]

# Interjections
Sometimes, you may want choice blocks to appear "optionally". 
Rather than appearing when the player advances the dialogue, the player will instead be prompted at the previous line to view the dialogue option. 
They can ignore this prompt and continue the dialogue normally, or they can choose to "interject", which will open up the choice menu (in these cases, the menu will also have an option to cancel).
You can make choices act like this by prepending the first option with '!'.
...say, nice day we're having.
>!It sure is!
>	Glad you agree, but I don't need your affirmation.

Anyway, up next: expressions!
# Expressions, commands, and flag variables
Expressions can be inserted into dialogue to interface with the main engine. There are two kinds of expressions: Commands and Flag expressions.
Expressions are always wrapped in backticks, e.g.: \`myFlag = true\`. Whitespace within expressions is ignored.
Flags are a specific kind of variable designed to be easy for things like dialogue and cutscene systems to interface with. There are three kinds of flags: Local, Global, and Persistent.

Local flags exist for the duration of a dialogue, and will be freed as soon as the dialogue closes. They are useful if you want to avoid polluting the global flag namespace but in general should not see much use. 

Global flags are the "default" kind of flag, when referring to "flags" assume this is the type being referred to. These exist globally and are tied to a save file. The state of all global flags is reloaded when loading a save.

Persistent flags work the same as global flags with one exception: their state is *not* affected when loading a save.

When retrieving a flag value, all types of flags will be checked. If two flags of different types have the same name, the more local flag will take precedence, but this should generally be avoided.

There are three types of flag expressions: Declarations, Assignments, and Comparisons.
Declarations: Simply naming a flag (e.g. \`myFlag\`) will set that flag's value to "1" *if and only if* that flag doesn't exist. If the flag has an existing value, it will not be overridden.
Assignments: You can assign a specific value to a flag like so: \`myFlag = awesome\`, or add/subtract from numerical flags like so: \`myNum += 2\`.
Comparisons: You can compare expressions to get a boolean value, e.g. \`myFlag == name\` or \`myFlag > 5\`. Supports boolean && and ||.

Appending '\$' to the start of an expression will insert its result into the visible dialogue. Let's try it now!
`balls = 1` //lines that only have expressions will be skipped too!
Say I have `$balls` ball.
Let me get the other one...`balls+=1`
Now I have `$balls` balls!
...anyway...

In addition to flag expressions, shell-like commands can be used for various effects. 
Comma separated arguments can be passed to them as well (example syntax: \`myCommand, arg1, arg2\`). 
There are a whole bunch of built-in commands, and you can even make your own!
Here's a quick example of the pause command, which can be used to insert a`pause,3` pause into the dialogue.
You could use the speed command to `speed,0.1`slow things down...`speed` just call it again with no arguments to go back to normal! 
You can also use shorthand for many common commands like`p,2` this!
Isn't that cool? But we're not done yet!

# Conditional blocks
You can run lines of dialogue conditionally using if-else statements and indentation!
Let's check how many balls I have...
`balls+=1`
`if balls > 3`
	...
	I have way too many balls...
`else if balls == 3`
	Wow!
	I have three balls!
	Crazy!
`else if balls == 2`
	Ok.
	I feel like I have pretty normal number of balls.
`else`
	Oh, uh...
	That's not good.

Choices and if blocks can be combined and nested as much as you please!

## NestTest
>Check your balls again.
>	`balls -= 0.5`
>	`if balls == 2`
>		Woah!
>		I have 2 balls now!
>	`else`
>		What the heck!?
>		Stop that!
>	[[#NestTest]]
>Let's move on
>	I agree.

# Seen and Unseen labels
Labels will track whether the player has seen them before.
Whether the current label has been seen or not is kept in a local flag called, aptly, 'seen', where it can be used in conditionals.
You can also use this to make non-repeating choices. If you place a label jump *on the same line* as a choice, that choice will not be displayed if the label has been seen before. To avoid this behavior, simply place the jump on the next line as normal. 
For example:

## seenTest
What did you want to ask me?
>What do you mean? [[#clarify]] //this choice can only be selected once
>Nothing. //this choice can be selected multiple times
>	Are you sure?
>	>Yes.
>	>	[[#done]]
>	>No.
>	>	[[#seenTest]]

(should be impossible to see this)
## clarify
Well... you came up to me.
So, I ask again,
[[#seenTest]]

## done




There's one last thing-

![[proProfileExample.png]]
Profile pictures.
![[minimaProfileExample.png]]
Hey, I was gonna- uh...
These don't fit right.
![[proProfileExample.png]]
I'm sure it'll be fixed in production.

![[]]
Well said!
You can set profile pictures (and preview them in obsidian) using an expression like this: \!\[\[spriteName]]
Well, that's all for now, thanks for watching!
