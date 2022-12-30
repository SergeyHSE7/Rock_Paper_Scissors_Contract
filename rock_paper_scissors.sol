pragma solidity ^0.8.0;

// SPDX-License-Identifier: MIT

// Смарт-контракт для игры в Камень-Ножницы-Бумага с использованием схемы commit-reveal, а также modifier и events.
contract rock_paper_scissors {
    uint256 public startBlock = block.number;
    
    bool gameEnded = false;

    mapping(address=>uint) public balances;

    address playerA /* = ... */;
    address playerB /* = ... */;

    bytes32 playerAHash;
    bytes32 playerBHash;

    enum Choice { Rock, Paper, Scissor, None }
    
    Choice public playerAChoice = Choice.None;
    Choice public playerBChoice = Choice.None;

    // Events
    event RestartEvent(address indexed _from);
    event CommitChoiceEvent(address indexed _from, bytes32 indexed hash);
    event RevealChoiceEvent(address indexed _from, Choice indexed choice, uint indexed nonce);
    event FindResultEvent(address indexed _from, string indexed result);
    event ClaimMoneyEvent(address indexed _from, uint256 indexed amount);

    // Modifier
    modifier OnlyPlayerAOrPlayerB {
        require(msg.sender == playerA || msg.sender == playerB, "not playerA or playerB");
        _;
    }

    // Functions
    function restart() public {
        require(gameEnded);
        startBlock = block.number;
        playerAHash = 0;
        playerBHash = 0;
        playerAChoice = Choice.None;
        playerBChoice = Choice.None;
        gameEnded = false;
        emit RestartEvent(msg.sender);
    }


    // commit the choice (Rock / Paper / Scissor)
    function commitChoice(bytes32 hash) public payable {
        require(block.number < (startBlock + 100));
        require((msg.sender == playerA && playerAHash == 0) || (msg.sender == playerB && playerBHash == 0), "not playerA or playerB");
        require(msg.value == 0.01 ether, "must pay to participate");

        if(msg.sender == playerA) {
            playerAHash = hash;
        } else {
            playerBHash = hash;
        }

        emit CommitChoiceEvent(msg.sender, hash);
    }




    // reveal the choice (Rock / Paper / Scissor)
    function revealChoice(Choice choice, uint nonce) public OnlyPlayerAOrPlayerB {
        require(block.number >= (startBlock + 100) && block.number < (startBlock + 200));
        require(playerAHash != 0 && playerBHash != 0, "everyone must submit hash");
        require(choice != Choice.None, "must choose Rock/Paper/Scissor");
        
        if(msg.sender == playerA) {
            if (playerAHash == sha256(abi.encodePacked(choice, nonce))) {
                playerAChoice = choice;
            }
        } else {
            if (playerBHash == sha256(abi.encodePacked(choice, nonce))) {
                playerBChoice = choice;
            }
        }

        emit RevealChoiceEvent(msg.sender, choice, nonce);
    }


    // check the result
    function findResult() public {
        require(block.number > (startBlock + 200));
        require(!gameEnded, "can only compute result once");
        require(playerAChoice != Choice.None && playerBChoice != Choice.None, "everyone must reveal choice");

        // draw
        if (playerAChoice == playerBChoice) {
            balances[playerA] += 0.01 ether;
            balances[playerB] += 0.01 ether;

            emit FindResultEvent(msg.sender, "Draw");
        } else if (playerAChoice == Choice.Rock) {
            if (playerBChoice == Choice.Paper) {
                balances[playerB] += 0.02 ether;
                emit FindResultEvent(msg.sender, "PlayerB won!");
            } else {
                balances[playerA] += 0.02 ether;
                emit FindResultEvent(msg.sender, "PlayerA won!");
            }
        } else if (playerAChoice == Choice.Paper) {
            if (playerBChoice == Choice.Scissor) {
                balances[playerB] += 0.02 ether;
                emit FindResultEvent(msg.sender, "PlayerB won!");
            } else {
                balances[playerA] += 0.02 ether;
                emit FindResultEvent(msg.sender, "PlayerA won!");
            }
        } else if (playerAChoice == Choice.Scissor) {
            if (playerBChoice == Choice.Rock) {
                balances[playerB] += 0.02 ether;
                emit FindResultEvent(msg.sender, "PlayerB won!");
            } else {
                balances[playerA] += 0.02 ether;
                emit FindResultEvent(msg.sender, "PlayerA won!");
            }
        }

        gameEnded = true;
    }


    function claimMoney() public {
        require(msg.sender == playerA || msg.sender == playerB, "not playerA or playerB");
        require(balances[msg.sender] > 0);

        uint amount = balances[msg.sender];
        balances[msg.sender] = 0;
        bool transferred = payable(msg.sender).send(amount);
        if (transferred != true) {
            balances[msg.sender] = amount;
        }

        emit ClaimMoneyEvent(msg.sender, amount);
    }
}