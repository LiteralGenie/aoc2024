```bash
$ cd day_20

$ mix run -e "Main.p1_ex()"

Path
 ## ## ## ## ## ## ## ## ## ## ## ## ## ## ##
 ##  2  3  4 ## 10 11 12 ## 26 27 28 29 30 ##
[...]


Jumps (time saved, start, end)
{2, 71, 75}
{2, 33, 37}
{2, 63, 67}
[...]

Answer: 44
```

```bash
$ mix run -e "Main.p1()"
Answer: 1499
```

```bash
$ \time -v mix run -e "Main.p2()"
Answer: 1027164

[...] >:(
User time (seconds): 42.24
System time (seconds): 45.58
Maximum resident set size (kbytes): 1205808
```
