/*
totalSupply와 balanceOf 함수는 ERC20 표준의 일부로, 토큰의 총 공급량과 특정 주소의 잔액을 반환합니다. 
이 함수들은 토큰의 가장 작은 단위인 wei를 반환하기 때문에 보통 decimals를 고려한 값이 반환됩니다.
하지만, 이 함수들을 직접 수정하거나 오버라이드하는 것은 권장되지 않습니다. 
왜냐하면 이는 ERC20 표준에서 벗어나는 행위이며, 이로 인해 토큰이 예상치 못한 방식으로 동작할 수 있기 때문입니다.
따라서 totalSupply와 balanceOf 값을 '토큰의 개수'로 바로 확인하려면, 이 값들을 10 ** decimals로 나눠서 확인해야 합니다. 
그래서 따로 함수를 생성하여 토큰 개수를 눈에보기 편하게 호출하였습니다.
전체 발행량의 토큰 개수: totalSupplyInToken()
특정 지갑의 토큰 개수: balanceOfInToken()

***remix안에서 decimals 계산을 추가하지 않았기 때문에 트랜스퍼(전송기능) 함수를 이용하면 안됩니다.
*/

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/security/Pausable.sol";

contract MyToken is ERC20, Ownable(msg.sender), Pausable {
    uint8 private _decimals;

    // 생성자 함수, 토큰명, 토큰심볼, 초기발행량, 소수점 자리수를 설정합니다.
    constructor(string memory name, string memory symbol, uint256 initialSupply, uint8 decimals) 
    ERC20(name, symbol) {
        _mint(msg.sender, initialSupply * 10 ** decimals);
        _decimals = decimals;
    }

    // 전송 기능, ERC20 표준의 transfer 함수입니다.
    function transfer(address to, uint256 amount) public override whenNotPaused returns (bool) {
        super.transfer(to, amount);
        return true;
    }

   // 추가 발행 기능, 특정 주소에 토큰을 추가 발행하며 총 발행량이 증가합니다.
    function mint(address to, uint256 amount) public onlyOwner {
        _mint(to, amount * 10 ** _decimals);
    }

    // 소각 기능, 본인 지갑 내의 토큰을 소각합니다.
    function burn(uint256 amount) public onlyOwner {
        _burn(msg.sender, amount * 10 ** _decimals);
    }

    // 현재 토큰의 소수점 자리수를 반환합니다.
    function getDecimals() external view returns (uint8) {
        return _decimals;
    }

    // 토큰 전송 정지 기능
    function pause() public onlyOwner {
        _pause();
    }

    // 토큰 전송 정지 해제 기능
    function unpause() public onlyOwner {
        _unpause();
    }

    // 소유주 변경 기능
    function transferOwnership(address newOwner) public onlyOwner override {
        super.transferOwnership(newOwner);
    }

    // 전체 토큰 개수 확인
    function totalSupplyInToken() external view returns (uint256) {
        return totalSupply() / (10 ** _decimals);
    }

    // 특정 주소 토큰 개수 확인
    function balanceOfInToken(address account) external view returns (uint256) {
        return balanceOf(account) / (10 ** _decimals);
    }
}
