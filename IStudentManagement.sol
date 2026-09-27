
 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// =========================================================
// FILE: IStudentManagement.sol
// MỤC ĐÍCH: Giao tiếp giữa FacultyManagement và
//           StudentManagement
// =========================================================

interface IStudentManagement {

    // Kiểm tra sinh viên tồn tại
    function studentExists(
        uint256 studentId
    ) external view returns (bool);

    // Gửi điểm và tín chỉ cho sinh viên
    // scoreInput: điểm dạng chuỗi, ví dụ "8.5", "9.5", "10"
function addScoreWithCredits(
    uint256 studentId,
    string memory course,
    uint256 semester,
    string memory scoreInput,
    uint256 credits
) external;
}