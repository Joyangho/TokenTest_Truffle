// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract Token {
    string public name; // 토큰의 이름
    string public symbol; // 토큰의 심볼
    uint256 public totalSupply; // 총 발행량
    mapping(address => uint256) public balanceOf; // 각 주소의 잔액을 저장하는 맵
    mapping(address => mapping(address => uint256)) public allowance; // 특정 주소가 다른 주소에 대해 인출할 수 있는 허용량을 저장하는 맵
    bool public isPaused; // 토큰 전송이 일시적으로 정지된 상태인지를 나타내는 변수
    address public owner; // 컨트랙트 소유자의 주소
    
    event Transfer(address indexed from, address indexed to, uint256 value); // 토큰 전송 이벤트
    event Approval(address indexed owner, address indexed spender, uint256 value); // 허용량 설정 이벤트
    event Pause(); // 토큰 전송 정지 이벤트
    event Unpause(); // 토큰 전송 재개 이벤트
    
    modifier onlyOwner() {
        require(msg.sender == owner, "Only the contract owner can call this function"); // 소유자만 호출할 수 있는 함수 제한
        _;
    }
    
    modifier whenNotPaused() {
        require(!isPaused, "The contract is paused"); // 전송이 정지된 상태에서만 호출할 수 있는 함수 제한
        _;
    }
    
    constructor(string memory _name, string memory _symbol, uint256 _totalSupply) {
        name = _name;
        symbol = _symbol;
        totalSupply = _totalSupply;
        balanceOf[msg.sender] = _totalSupply;
        owner = msg.sender;
        isPaused = false;
    }
    
    function pause() public onlyOwner {
        isPaused = true;
        emit Pause();
    }
    
    function unpause() public onlyOwner {
        isPaused = false;
        emit Unpause();
    }
    
    /*
     * @dev 토큰을 다른 주소로 전송하는 함수
     * @param _to 전송할 주소
     * @param _value 전송할 토큰의 양
     * @return 성공 여부
     */
    function transfer(address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance"); // 보유한 토큰 양보다 전송할 양이 작은지 확인
        require(_to != address(0), "Invalid recipient"); // 유효한 수신자 주소인지 확인
        
        balanceOf[msg.sender] -= _value;
        balanceOf[_to] += _value;
        
        emit Transfer(msg.sender, _to, _value);
        
        return true;
    }
    
    /*
     * @dev 다른 주소로부터 토큰을 받아 다른 주소로 전송하는 함수
     * @param _from 전송할 주소
     * @param _to 전송할 주소
     * @param _value 전송할 토큰의 양
     * @return 성공 여부
     */
    function transferFrom(address _from, address _to, uint256 _value) public whenNotPaused returns (bool success) {
        require(balanceOf[_from] >= _value, "Insufficient balance"); // 보유한 토큰 양보다 전송할 양이 작은지 확인
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance"); // 인출할 수 있는 허용량보다 전송할 양이 작은지 확인
        require(_to != address(0), "Invalid recipient"); // 유효한 수신자 주소인지 확인
        
        balanceOf[_from] -= _value;
        balanceOf[_to] += _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, _to, _value);
        
        return true;
    }
    
    /*
     * @dev 다른 주소에 대한 인출 허용량을 설정하는 함수
     * @param _spender 인출을 허용할 주소
     * @param _value 허용량
     * @return 성공 여부
     */
    function approve(address _spender, uint256 _value) public whenNotPaused returns (bool success) {
        allowance[msg.sender][_spender] = _value;
        
        emit Approval(msg.sender, _spender, _value);
        
        return true;
    }
    
    /*
     * @dev 여러 주소로 토큰을 동시에 전송하는 함수 (에어드랍)
     * @param _recipients 토큰을 전송할 주소 배열
     * @param _values 전송할 토큰의 양 배열
     */
    function dropTokens(address[] memory _recipients, uint256[] memory _values) public whenNotPaused onlyOwner {
        require(_recipients.length == _values.length, "Invalid input lengths"); // 입력 배열의 길이가 동일한지 확인
        
        for (uint256 i = 0; i < _recipients.length; i++) {
            address recipient = _recipients[i];
            uint256 value = _values[i];
            
            require(recipient != address(0), "Invalid recipient"); // 유효한 수신자 주소인지 확인
            require(balanceOf[msg.sender] >= value, "Insufficient balance"); // 보유한 토큰 양보다 전송할 양이 작은지 확인
            
            balanceOf[msg.sender] -= value;
            balanceOf[recipient] += value;
            
            emit Transfer(msg.sender, recipient, value);
        }
    }

    /*
     * @dev 새로운 토큰을 발행하는 함수
     * @param _recipient 발행된 토큰을 받을 주소
     * @param _value 발행할 토큰의 양
     */
    function mint(address _recipient, uint256 _value) public whenNotPaused onlyOwner {
        require(_recipient != address(0), "Invalid recipient"); // 유효한 수신자 주소인지 확인
        
        totalSupply += _value;
        balanceOf[_recipient] += _value;
        
        emit Transfer(address(0), _recipient, _value);
    }
    
    /*
     * @dev 토큰을 소각하는 함수
     * @param _value 소각할 토큰의 양
     */
    function burn(uint256 _value) public whenNotPaused {
        require(balanceOf[msg.sender] >= _value, "Insufficient balance"); // 보유한 토큰 양보다 소각할 양이 작은지 확인
        
        balanceOf[msg.sender] -= _value;
        totalSupply -= _value;
        
        emit Transfer(msg.sender, address(0), _value);
    }
    
    /*
     * @dev 다른 주소로부터 토큰을 소각하는 함수
     * @param _from 소각할 주소
     * @param _value 소각할 토큰의 양
     */
    function burnFrom(address _from, uint256 _value) public whenNotPaused {
        require(balanceOf[_from] >= _value, "Insufficient balance"); // 보유한 토큰 양보다 소각할 양이 작은지 확인
        require(allowance[_from][msg.sender] >= _value, "Insufficient allowance"); // 인출할 수 있는 허용량보다 소각할 양이 작은지 확인
        
        balanceOf[_from] -= _value;
        totalSupply -= _value;
        allowance[_from][msg.sender] -= _value;
        
        emit Transfer(_from, address(0), _value);
    }
}