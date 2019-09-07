# LOVE2D Console
 LOVE2D based console. Usable for anything you might want a console for; making a game about hacking, hooking it up using sockets for debugging, a text based adventure with LOVE2D capabilities, or whatever you can come up with.

## How to install
Using the console is really easy. Download the "console" folder, and place it in your project wherever you'd like. Then, in your code, require the "console.lua" file. Then you will want to add the following in your main.lua (I went with 'c' for my naming scheme, but you use whatever you'd like):

```lua
c = require "bin/console/console"

function love.load()
	c.load()
end

function love.update(dt)
	c.update(dt)
end

function love.draw()
	c.draw()
end

function love.wheelmoved(x, y)
	c.wheelmoved(x, y)
end
```

Simple!

## How to Use
The console will run any and all valid lua code. You can scroll with the scrollwheel on your mouse, or just click on the bar on the right hand side. You have the ability to execute code at the same time that code is being printed to the console, although they are not using seperate threads to do it, so if too many things are being printed to the screen, you may have trouble typing.

Pressing up or down will allow you to scroll through the history of things that you have already typed.

## Callbacks
There are a number of callbacks I put in to make a few things easy.

#### function c.print(str)
Your replacement for the standard "print" function. Use c.print() to print to the custom console specifically. While the argument is str, it will take most types and convert them. Valid argument types are: strings, numbers, nil, booleans, and tables. Tables use "inspect" to print tables in a human readable format.

#### function c.log(str, level)
Similar to c.print(), this will take a string and output it to the console. However, c.log adds in a few other bits and bobs to make using the console as a debug tool easier. Adding a level parameter (a number between 1 and 3) will change the color of that specific line.

* 1 = green
* 2 = yellow
* 3 = red

Not adding a level parameter will keep it white. On top of that, each line will have a timestamp in front of it formatted as such; "[month-day-year] hour:min:sec". 

Adding colors to the c.log() function is easy! Scroll down inside console.lua until you get to console.log(), around line 576. A few lines in there are some if statements. Simply change the ones that are already there following this format or add your own: `{red, green, blue, alpha}`

MAKE SURE TO EITHER REMOVE THE ASSERT CHECK, OR ADD IN THE NEW LEVELS, OR AN ERROR WILL BE THROWN.

#### function c.readwrite(text)
Callback that can be used to modify input and output of the console. A usage example follows below
```lua
function c.readwrite(text)
  if text == "hello" then
  return "Hello there"
  end
end
```
Returning a string will change the output in the console, and returning any string will prevent the input from being run as code. If you return a second string, then the seconded returned string will replace the userinput in the console. If you want to replace just the userinput, you can return nil for the first argument, and whatever you pass will be run as code instead of the userinput.

#### function c.clear()
Clears the console. Simple.

#### function c.setAccessoryColor(color_or_R, G, B, A)
Will change the accessory colors, which is everything that isn't the text or the background. That includes the color of the scrollbar background, the cursor, and the color of the highlight when you ctrl-a.

#### function c.setBackgroundColor(color_or_R, G, B, A)
Will change the color of the background, as well as other colors linked to the background color. That includes the scrollbar itself, and the color of the text when it is being highlighted.

#### function c.setLineColor(color_or_R, line_or_G, B, A, line)
Will change the color of a specific line of text to whatever color is set. You must pass either a table with the following formatting: `{red, green, blue, alpha}` as well as the line index of the line you would like to change, or pass each item as a separate parameter. The easiest way to get a line index is either to start from the first line (the first line written) and work forwards, or from the most recent line (#c.text.str) and work backwards.

#### function c.setAllLinesColor(color_or_R, G, B, A)
Does the same as above, but will change all lines in one fell swoop. THIS WILL OVERWRITE ANY CUSTOM LINE COLORING, THIS WILL NOT CHANGE ONLY DEFAULT (white) LINES.

#### function c.reset()
If you bork everything, this will reset the console to the how it was in it's first state. Will most likely fix any problems you have if the console is being weird.

There are also a number of accessible variables, which are the following:
*   c.accessoryColor = {1,1,1,1}       //The direct variable for the textColor. While you can change the color directly, it's better to use the callback, and only access this variable for reading purposes.
*	c.bgColor        = {.05,.05,.05,1} //The direct variable for the bgColor. While you can change the color directly, it's better to use the callback, and only access this variable for reading purposes.
*	c.width          = 976             //This is the width of the console. Will be the same as the width from love.window.getModes()
*	c.height         = 480             //This is the width of the console. Will be the same as the height from love.window.getModes()
*	c.historyMax     = 1000            //The max amount of history that will be saved. 
*	c.input          = ""              //This is the variable that stores the string of whatever is being typed.
*	c.history        = {}              //This is the table that contains all of the history. Items over the max will be deleted, first in, first out.
*	c.text.str       = {}              //This is all the text that is being displayed on the screen.
*	c.text.color     = {}              //These are the colors for each line that is displayed. For each line in c.text.str at i, there must be a corresponding color at i as well. If there is one missing, it will throw an error when reaching the end of the table. The best way to modify this is through the callback.
*	c.flags          = {resizable = true, minwidth = 677, minheight = 343} //Flags that are set with love.window.setMode()
