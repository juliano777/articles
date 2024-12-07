# Listar dispositivos de armazenamento:

lsblk

# 

top

"wa percentage - Basically the amount of time this CPU spending wait IO operations to finish.
Reasonable: 10% or 20%.
"

# 
iostat -hymx 1 4

"
h
y
m - Megabytes per second.
x -
1 - 1 second
4 - 4 iterations 
"

#
iostat -o

"
o Only show processes or threads actually doing I/O, instead of all processes or threads. This can dynamically toggled by pressing o.



