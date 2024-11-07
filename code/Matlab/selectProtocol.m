function returnStruct = selectProtocol(structIn, protNum)
%This function return the protocol as specified by protNum.
%Counting starts beyond the first protocol that every site has.
    switch protNum
        case 0 
            returnStruct = structIn;
        case 1
            returnStruct = structIn.secondProtocol;
        case 2
            returnStruct = structIn.thirdProtocol;
        case 3
            returnStruct = structIn.fourthProtocol;
        case 4
            returnStruct = structIn.fifthProtocol;
        case 5
            returnStruct = structIn.sixthProtocol;
    end
end