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
fun {CardValue C}
   local Cardval = ((C-1) mod 13)+1 in
      if Cardval>=10 then
	 10
      else
	 Cardval
      end
   end
end

declare
fun {CardValueCompare C1 C2}
   {CardValue C1} > {CardValue C2}
end

declare
fun {HandValueRecurse Hand Sum}
   case Hand of H|T then
      local Cardval={CardValue H} in
	 if {And Sum=<10 {And Cardval==1 {List.length Hand}==1}} then
	    {HandValueRecurse T Sum+11}
	 else
	    {HandValueRecurse T Sum+Cardval}
	 end
      end
   else
      Sum
   end
end

declare
fun {HandValue Hand}
   {HandValueRecurse {List.sort Hand CardValueCompare} 0}
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

declare
fun {DealCard Deck DiscardPile}
   case Deck of H|T then
      H|T|DiscardPile
   else
      case {ShuffleFromIndex 1 DiscardPile {List.length DiscardPile}} of H|T then
	 H|{List.append Deck T}|nil
      else
	 nil|nil|nil
      end
   end
end

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
      if Move==hit then
	 case {DealCard Deck DiscardPile} of C|D|DP then
	    {SimulatePlayer D DP {List.append Hand [C]} Bet PlayerMoney}
	 end
      elseif Move==doubledown then
	 if PlayerMoney<(Bet*2) then
	    case {DealCard Deck DiscardPile} of C|D|DP then
	       {SimulatePlayer D DP {List.append Hand [C]} Bet PlayerMoney}
	    end
	 else
	    case {DealCard Deck DiscardPile} of C|D|DP then
	       D|DP|{List.append Hand [C]}|Bet*2
	    end
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
fun {SimulatePlayers Deck DiscardPile FinishedHands UnfinishedHands FinalBets OriginalBets Bet PlayerMoney}
   case PlayerMoney of H2|T2 then
      if H2>=Bet then
	 case UnfinishedHands of H|T then
	    case OriginalBets of H1|T1 then
	       
	       case {SimulatePlayer Deck DiscardPile H H1 H2} of D|DP|Hand|B then
		  {SimulatePlayers D DP {List.append FinishedHands [Hand]} T {List.append FinalBets [B]} T1 Bet T2}
	       end
	    end	 
	 end
	 
      else
	 {SimulatePlayers Deck DiscardPile FinishedHands UnfinishedHands FinalBets OriginalBets Bet T2}
      end
   else
      Deck|DiscardPile|{List.drop FinishedHands 1}|{List.drop FinalBets 1} 
   end
end
declare
fun {SimulateDealer Deck DiscardPile Hand}
   if {HandValue Hand}<17 then
      case {DealCard Deck DiscardPile} of C|D|DP then
	 {SimulateDealer D DP {List.append Hand [C]}}
      end
   else
      Deck|DiscardPile|Hand
   end
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
fun {CalcMoneyRecurse OriginalMoney FinalMoney BetMin Bets Hands DealerHand DealerNet}
   case OriginalMoney of HMoney|TMoney then
      if HMoney<BetMin then
	 {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney]} BetMin Bets Hands DealerHand DealerNet}
      else
	 case Bets of HBets|TBets then
	    case Hands of HHands|THands then
	       local PlayerVal={HandValue HHands} DealerVal={HandValue DealerHand} in
		  if PlayerVal>21 then
		     {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney - HBets]} BetMin TBets THands DealerHand DealerNet+HBets}
		  elseif DealerVal>21 then
		     if PlayerVal==21 then
			{CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney + (HBets*2)]} BetMin TBets THands DealerHand DealerNet-(HBets*2)}
		     else
			{CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney + HBets]} BetMin TBets THands DealerHand DealerNet-HBets}
		     end
		  else
		     if PlayerVal>DealerVal then
			if PlayerVal==21 then
			   {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney + (HBets*2)]} BetMin TBets THands DealerHand DealerNet-(HBets*2)}
			else
			   {CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney + HBets]} BetMin TBets THands DealerHand DealerNet-HBets}
			end
		     elseif PlayerVal==DealerVal then
			{CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney]} BetMin TBets THands DealerHand DealerNet}
		     else
			{CalcMoneyRecurse TMoney {List.append FinalMoney [HMoney - HBets]} BetMin TBets THands DealerHand DealerNet+HBets}
		     end
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
fun {CalculateMoney PlayerMoney BetMin Bets Hands DealerHand}
   {CalcMoneyRecurse PlayerMoney [nil] BetMin Bets Hands DealerHand 0}
end

declare
fun {SimulateRound Deck DiscardPile NumPlayers PlayerBalances Bet}
   case {SimulateDeal Deck DiscardPile NumPlayers+1} of PH|D|DP then
      case {SimulatePlayers D DP [nil] {List.take PH NumPlayers} [nil] {BetList NumPlayers Bet} Bet PlayerBalances} of Deck2|DiscardPile2|FinishedHands|FinalBets then
	 case {SimulateDealer Deck2 DiscardPile2 {List.last PH}} of Deck3|DiscardPile3|DealerHand then
	    case {CalculateMoney PlayerBalances Bet FinalBets FinishedHands DealerHand} of FinalMoney|DealerNet then
	       
	       Deck3|{List.flatten DealerHand|{List.reverse FinishedHands}|DiscardPile3}|FinalMoney|DealerNet
	    end
	 end
      end
   end
end

declare
fun {RemainingPlayersRecurse PlayerBalances Bet NumRemaining}
   case PlayerBalances of H|T then
      if H>=Bet then
	 {RemainingPlayersRecurse T Bet NumRemaining+1}
      else
	 {RemainingPlayersRecurse T Bet NumRemaining}
      end
   else
      NumRemaining
   end
end

declare
fun {RemainingPlayers PlayerBalances Bet}
   {RemainingPlayersRecurse PlayerBalances Bet 0}
end

declare
fun {IncrementRoundsPlayedRecurse PlayerMoney MinBet RoundsPlayedLeft RoundsPlayedRight}
   case RoundsPlayedRight of H|T then
      case PlayerMoney of H1|T1 then
	 if H1>=MinBet then
	    {IncrementRoundsPlayedRecurse T1 MinBet {List.append RoundsPlayedLeft [H+1]} T}
	 else
	    {IncrementRoundsPlayedRecurse T1 MinBet {List.append RoundsPlayedLeft [H]} T}
	 end
      end
   else
      {List.drop RoundsPlayedLeft 1}
   end
end

declare
fun {IncrementRoundsPlayed PlayerMoney MinBet RoundsPlayed}
   {IncrementRoundsPlayedRecurse PlayerMoney MinBet [nil] RoundsPlayed}
end
   
declare
fun {Simulate Deck DiscardPile NumPlayers RoundsPlayed PlayerBalances Bet RemainingRounds DealerMoney}
   if {And RemainingRounds>0 NumPlayers>0} then
      case {SimulateRound Deck DiscardPile NumPlayers PlayerBalances Bet} of D|DP|FinalBal|DealerNet then
	 {Simulate D DP {RemainingPlayers FinalBal Bet} {IncrementRoundsPlayed PlayerBalances Bet RoundsPlayed} FinalBal Bet RemainingRounds-1 DealerMoney+DealerNet}
      end
   else
      DealerMoney|RoundsPlayed|PlayerBalances
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

declare
fun {MakeTupleRecurse Dealer RoundsList MoneyList CombinedList}
   case RoundsList of H|T then
      case MoneyList of H1|T1 then
	 {MakeTupleRecurse Dealer T T1 {List.append CombinedList [H#H1]}}
      end
   else
      game(Dealer CombinedList)
   end
end

declare
fun {MakeTuple Dealer RoundsList MoneyList}
   case RoundsList of H|T then
      case MoneyList of H1|T1 then
	 {MakeTupleRecurse Dealer T T1 [H#H1]}
      end
   end
end

declare
fun {BlackJack S N M B R}
   {Init S}
   case {Simulate {ShuffleFromIndex 1 {List.number 1 52 1} 52} [nil] N {BetList N 0} {StarterMoney N M} B R 0} of D|R|M then
      {MakeTuple D R M}
   end
end

{Browse {BlackJack 10 2 10 2 2}}

{Browse {BlackJack 15 3 10 9 2}}

{Browse {BlackJack 22 5 10 4 6}}

{Browse {BlackJack 13 5 30 4 10}}
