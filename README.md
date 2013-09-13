ACRO: Anyone Can Ride Ostriches
===============================
This project is a reimplementation of the game "Acrophobia" (also known in some
communities as "Acrobot" or "Acro"). A random set of letters is produced, and
players must expand the acronym. (For example, the acro "ESC" could be expanded
as "enter secret codes" or "eat some cheese", among many other options.)

Requirements
------------
* Lua 5.1 or higher
* [LuaSocket](http://w3.impa.br/~diego/software/luasocket/)
* A sense of humour

Gameplay
--------
Each round, a new set of letters is generated, and players have a set amount of
time to enter their acronym.

After the entry phase is over, voting begins. Voting is as simple as sending the
number you'd like to vote for. Please note that you cannot vote for yourself, and
in some rulesets, there are penalties for doing so.

Once voting is over, the points are awarded, scores are checked to see if anyone
has won. If not, then another round begins.

Rulesets
--------
Part of what makes the Acro experience fun is custom rulesets.
These will be explained in the future, when the details have been hammered out.

Future Plans
------------
Other, non-acro gametypes may be supported in the future.
