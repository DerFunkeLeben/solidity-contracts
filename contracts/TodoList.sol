// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

contract TodoList {
    struct Task {
        uint id;
        string description;
        bool isCompleted;
    }

    Task[] public tasks;
    mapping(uint => address) public taskToOwner;
    uint public nextId = 1;

    event TaskCreated(uint id, string description, address owner);
    event TaskUpdated(uint id, bool isCompleted);
    event TaskDeleted(uint id);

    modifier onlyOwner(uint _id) {
        require(msg.sender == taskToOwner[_id], "Not the owner");
        _;
    }

    function createTask(string memory _description) external {
        tasks.push(Task(nextId, _description, false));
        taskToOwner[nextId] = msg.sender;
        emit TaskCreated(nextId, _description, msg.sender);
        nextId++;
    }

    function toggleTask(uint _id) external onlyOwner(_id) {
        for (uint i = 0; i < tasks.length; i++) {
            if (tasks[i].id == _id) {
                tasks[i].isCompleted = !tasks[i].isCompleted;
                emit TaskUpdated(_id, tasks[i].isCompleted);
                break;
            }
        }
    }

    function deleteTask(uint _id) external onlyOwner(_id) {
        for (uint i = 0; i < tasks.length; i++) {
            if (tasks[i].id == _id) {
                tasks[i] = tasks[tasks.length - 1];
                tasks.pop();
                emit TaskDeleted(_id);
                break;
            }
        }
    }

    function getTasks() external view returns (Task[] memory) {
        return tasks;
    }
}
