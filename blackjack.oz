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
{Init 10}

declare
fun {HandValueRecurse Hand Sum}
   19
end

declare
fun {HandValue Hand}
   {HandValueRecurse Hand 0}
end

declare
fun {ShuffleFromIndex I L Length}
   if I>Length then
      L
   else
      local R NI NR L1 L2 L3 LL in
	 R=({Rand} mod Length)+1
	 NI = {List.nth L I}
	 NR = {List.nth L R}
	 if R==I then
	    {ShuffleFromIndex I+1 L Length}
	 else
	    if R<I then
	       L1 = {List.take L R-1}
	       L2 = {List.drop {List.take L I-1} R}
	       L3 = {List.drop L I}
	       LL = {List.flatten L1|NI|L2|NR|L3}
	       {ShuffleFromIndex I+1 LL Length}
	    else
	       L1 = {List.take L I-1}
	       L2 = {List.drop {List.take L R-1} I}
	       L3 = {List.drop L R}
	       LL = {List.flatten L1|NR|L2|NI|L3}
	       {ShuffleFromIndex I+1 LL Length}
	    end
	 end
      end
   end
end

%Return dealt card|Deck|DiscardPile
declare
fun {DealCard Deck DiscardPile}
   case Deck of H|T then
      H|T|DiscardPile
   else
      {Browse 'Have to reshuffle'}
      case {ShuffleFromIndex 0 DiscardPile {List.length DiscardPile}} of H|T then
	 {Browse 'reshuffled properly'}
	 H|T|nil
      else
	 {Browse 'couldnt reshuffle'}
	 nil|nil|nil
      end
   end
end

%The dealer will be represented as the last player

%return PlayerHands|Deck|DiscardPile
declare
fun {DealRecurse Deck DiscardPile NumPlayers PlayerHands CurrPlayer CardsDealtEach}
   if CardsDealtEach==2 then
      PlayerHands|Deck|DiscardPile
   elseif CurrPlayer>NumPlayers then
      {DealRecurse Deck DiscardPile NumPlayers PlayerHands 1 CardsDealtEach+1}
   else
      case {DealCard Deck DiscardPile} of C|D|DP then
	 local NewHands Hand in
	    if CardsDealtEach==0 then
	       Hand = [C]
	    else
	       Hand = {List.append {List.nth PlayerHands CurrPlayer} [C]}
	    end
	    NewHands = {List.append {List.append {List.take PlayerHands CurrPlayer-1} [Hand] }  {List.drop PlayerHands CurrPlayer}}
	    {DealRecurse D DP NumPlayers NewHands CurrPlayer+1 CardsDealtEach}
	 end
      else
	 nil|nil|nil
      end
   end
end

declare
fun {EmptyHandsRecurse Hands RemainingPlayers}
   if RemainingPlayers==1 then
      Hands
   else
      {EmptyHandsRecurse {List.append Hands [[nil]]} RemainingPlayers-1}
   end
end

declare
fun {EmptyHands NumPlayers}
   {EmptyHandsRecurse [[nil]] NumPlayers}
end

%wrapper for the recursive initial deal
%return PlayerHands|Deck|DiscardPile
declare
fun {SimulateDeal Deck DiscardPile NumPlayers}
   {DealRecurse Deck DiscardPile NumPlayers {EmptyHands NumPlayers} 1 0}
end

declare
fun {PlayerMove Hand}
   local Handvalue={HandValue Hand} in
      if Handvalue>=17 then
	 stay
      elseif {And Handvalue=<16 Handvalue>=12} then
	  hit
      elseif {And Handvalue=<11 Handvalue>=9} then
	 doubledown
      elseif Handvalue=<8 then
	 hit      
      else
	 invalid
      end
   end
end

declare
fun {SimulatePlayer Deck DiscardPile Hand Bet PlayerMoney}
   local Move={PlayerMove Hand} in
      if {Or Move==hit {And Move==doubledown (PlayerMoney<(Bet*2))}} then
	 case {DealCard Deck DiscardPile} of C|D|DP then
	    {SimulatePlayer D DP {List.append Hand [C]} Bet PlayerMoney}
	 end
      elseif Move==doubledown then
	 case {DealCard Deck DiscardPile} of C|D|DP then
	    D|DP|{List.append Hand [C]}|Bet*2
	 end
      elseif Move==stay then
	 Deck|DiscardPile|Hand|Bet
      else
	 {Browse 'oh noez'}
	 nil|nil|nil|nil
      end
   end
end

declare
fun {SimulatePlayers Deck DiscardPile FinishedHands UnfinishedHands FinalBets OriginalBets B PlayerMoney}
   {Browse UnfinishedHands}
   {Browse OriginalBets}
   {Browse PlayerMoney}
   case UnfinishedHands of H|T then
      case OriginalBets of H1|T1 then
	 case PlayerMoney of H2|T2 then
	    case {SimulatePlayer Deck DiscardPile H H1 H2} of D|DP|Hand|B then
	       {Browse 'ooop'}
	       {SimulatePlayers D DP {List.append FinishedHands [Hand]} T {List.append FinalBets [B]} T1 B T2}
	    end
	 end
      end	 
   else
      Deck|DiscardPile|{List.drop FinishedHands 1}|{List.drop FinalBets 1}
   end
end

declare
fun {SimulateDealerRecurse Deck DiscardPile Hand}
   if {HandValue Hand}<17 then
      case {DealCard Deck DiscardPile} of C|D|DP then
	 {SimulateDealerRecurse D DP {List.append Hand [C]}}
      end
   else
      Deck|DiscardPile|{List.drop Hand 1}
   end
end

declare
fun {SimulateDealer Deck DiscardPile}
   {SimulateDealerRecurse Deck DiscardPile [nil]}
end

declare
fun {BetListRecurse RemainingPlayers BetAmount Bets}
 if RemainingPlayers==0 then
      {List.drop Bets 1}
   else
      {BetListRecurse RemainingPlayers-1 BetAmount {List.append Bets [BetAmount]}}
   end
end

declare
fun {BetList NumPlayers BetAmount}
   {BetListRecurse NumPlayers BetAmount [nil]}
end

declare
fun {CalcMoneyRecurse OriginalMoney FinalMoney Bets Hands DealerHand DealerNet}
   case OriginalMoney of HMoney|TMoney then
      case Bets of HBets|TBets then
	 case Hands of HHands|THands then
	    local PlayerVal={HandValue HHands} DealerVal={HandValue DealerHand} in
	       if PlayerVal>21 then
		  {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney - HBets]} TBets THands DealerHand DealerNet+HBets}
	       elseif DealerVal>21 then
		  {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney + HBets]} TBets THands DealerHand DealerNet-HBets}
	       else
		  if PlayerVal>DealerVal then
		     if PlayerVal==21 then
			{CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney + (HBets*2)]} TBets THands DealerHand DealerNet-(HBets*2)}
		     else
			{CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney + HBets]} TBets THands DealerHand DealerNet-HBets}
		     end
		  elseif PlayerVal==DealerVal then
		     {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney]} TBets THands DealerHand DealerNet}
		  else
		     {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney - HBets]} TBets THands DealerHand DealerNet+HBets}
		  end
	       end
	    end
	 end
      end
   else
      {List.drop FinalMoney 1}|DealerNet
   end
end

declare
fun {CalculateMoney PlayerMoney Bets Hands DealerHand}
   {CalcMoneyRecurse PlayerMoney [nil] Bets Hands DealerHand 0}
end

declare
fun {SimulateRound Deck DiscardPile NumPlayers PlayerBalances Bet}
   case {SimulateDeal Deck DiscardPile NumPlayers} of PH|D|DP then
      case {SimulatePlayers D DP [nil] PH [nil] {BetList NumPlayers Bet} Bet PlayerBalances} of Deck2|DiscardPile2|FinishedHands|FinalBets then
	 case {SimulateDealer Deck2 DiscardPile2} of Deck3|DiscardPile3|DealerHand then
	    case {CalculateMoney PlayerBalances FinalBets FinishedHands DealerHand} of FinalMoney|DealerNet then
	       Deck3|{List.flatten DiscardPile3|PH|DealerHand}|FinalMoney|DealerNet
	    end
	 end
      end
   end
end

declare
fun {StarterMoneyRecurse NumPlayers Amount MoneyList}
   if NumPlayers==0 then
      {List.drop MoneyList 1}
   else
      {StarterMoneyRecurse NumPlayers-1 Amount {List.append MoneyList [Amount]}}
   end
end

declare
fun {StarterMoney NumPlayers Amount}
   {StarterMoneyRecurse NumPlayers Amount [nil]}
end

{Browse {StarterMoney 6 44}}

{Browse {SimulateRound {ShuffleFromIndex 1 {List.number 1 52 1} 52} [nil] 5 {StarterMoney 5 50} 5}} 

%case {SimulateDeal {ShuffleFromIndex 1 {List.number 1 52 1} 52} nil 4} of H|D|DP then
%   {Browse {SimulatePlayers D DP [nil] H [nil] [30 30 30 30] 30}}
%end

declare
fun {BlackJack S N M B R}
   {Init S}
   4
end

%{Browse {List.number 1 52 1}} 

   
