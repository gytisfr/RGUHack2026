```
#All scripts are expected to start with the following syntax
use pico1 {
    #code here (hashtags are for comments)
}
#This defines the device you wish your code to be pushed to
#Multiple devices can, and should be defined within your program if you intend to use more than one
#They are exclusive to the global space of your script, and should therefore not be nested


#Data types
123 #Number
"Text"
True #Boolean

#Variable assignment
variable = "value"


if (condition) {
    #statement
}


statement(arguments)


import name


#Built-in packages
screen
nfc
crypt
```

screen
```
screen.something()
```