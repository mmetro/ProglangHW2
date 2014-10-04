declare
local A=333667 B=213453321 M=1000000000 in
  proc {NewRand ?Rand ?Init ?Max}
    X = {NewCell 0} in
    fun {Rand} X := (A*@X+B) mod M end
    proc {Init Seed} X := Seed end
    Max = M
  end
end

declare Rand Init 
{NewRand Rand Init _}
{Init 6969}

declare
fun {ShuffleFromIndex I L}
   if I>52 then
      L
   else
      local R NI NR L1 L2 L3 LL in
	 R=({Rand} mod 52)+1
	 NI = {List.nth L I}
	 NR = {List.nth L R}
	 if R==I then
	    {ShuffleFromIndex I+1 L}
	 else
	    if R<I then
	       L1 = {List.take L R-1}
	       L2 = {List.drop {List.take L I-1} R}
	       L3 = {List.drop L I}
	       LL = {List.flatten L1|NI|L2|NR|L3}
	       {ShuffleFromIndex I+1 LL}
	    else
	       L1 = {List.take L I-1}
	       L2 = {List.drop {List.take L R-1} I}
	       L3 = {List.drop L R}
	       LL = {List.flatten L1|NR|L2|NI|L3}
	       {ShuffleFromIndex I+1 LL}
	    end
	 end
      end
   end
end

{Browse {List.number 1 52 1}} 

{Browse {ShuffleFromIndex 1 {List.number 1 52 1}}}   
%{Browse deck}
