 // SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "./StudentData.sol";
contract StudentManagement is StudentData {
struct StudentInfo {
    uint256 studentId;              // Mã sinh viên
    string fullName;                // Họ và tên sinh viên
    uint256 age;                     // Tuổi sinh viên
    string major;                    // Ngành học của sinh viên
    string status;                    // Trạng thái sinh viên (Đang học, Cảnh báo, Thôi học)
    uint256 consecutiveFails;        // Số học kỳ liên tiếp không đạt
    uint256 lastEvaluatedSemester;   // Mã học kỳ gần nhất đã được đánh giá
}
    // =====================================================
    // FUNCTION 1: THÊM SINH VIÊN
    // =====================================================

    function addStudent(
        uint256 studentId,
        string calldata fullName,
        uint256 age,
        string calldata major
    )
        external
        
    {
        // Kiểm tra mã sinh viên
        require(
            studentId != 0,
            "Invalid student ID"
        );

        // Kiểm tra sinh viên đã tồn tại
        require(
            !students[studentId].exists,
            "Student already exists"
        );

        // Kiểm tra họ tên
        require(
            bytes(fullName).length > 0,
            "Student name is empty"
        );

        // Kiểm tra ngành học
        require(
            bytes(major).length > 0,
            "Student major is empty"
        );

        // Kiểm tra tuổi
        require(
            age >= 16 && age <= 100,
            "Age must be between 16 and 100"
        );

        // Tạo sinh viên mới
        students[studentId] = Student({
            studentId: studentId,
            fullName: fullName,
            major: major,
            age: uint8(age),
            status: StudentStatus.Studying,
            consecutiveFails: 0,
            exists: true
        });

        // Thêm mã sinh viên vào danh sách
        studentIds.push(studentId);

        // Tăng tổng số sinh viên
        totalStudents++;

    }

// =====================================================
// CHUYỂN ĐIỂM DẠNG CHUỖI SANG THANG 100
//
// Ví dụ:
// "8"    → 800
// "8.5"  → 850
// "7.25" → 725
// "10"   → 1000
//
// Chỉ cho phép tối đa 2 chữ số thập phân.
// =====================================================

function parseScore(
    string memory input
)
    internal
    pure
    returns (uint256)
{
    bytes memory b = bytes(input);

    require(
        b.length > 0,
        "Score cannot be empty"
    );

    uint256 integerPart = 0;
    uint256 decimalPart = 0;
    uint256 decimalDigits = 0;

    bool hasDot = false;

    for (uint256 i = 0; i < b.length; i++) {

        bytes1 c = b[i];

        // Dấu chấm thập phân
        if (c == ".") {

            require(
                !hasDot,
                "Invalid score format"
            );

            hasDot = true;

        } else {

            // Kiểm tra ký tự có phải chữ số không
            require(
                c >= "0" && c <= "9",
                "Invalid score"
            );

            uint256 digit = uint8(c) - uint8(bytes1("0"));

            if (!hasDot) {

                integerPart =
                    integerPart * 10 + digit;

            } else {

                require(
                    decimalDigits < 2,
                    "Maximum 2 decimals"
                );

                decimalPart =
                    decimalPart * 10 + digit;

                decimalDigits++;
            }
        }
    }

    // Không cho điểm lớn hơn 10
    require(
        integerPart <= 10,
        "Score must be between 0 and 10"
    );

    // 10 chỉ được phép là 10.00
    if (integerPart == 10) {
        require(
            decimalPart == 0,
            "Score cannot exceed 10"
        );
    }

    // Ví dụ:
    // 8.5 → decimalPart = 5
    // Cần chuyển thành 50
    if (decimalDigits == 1) {
        decimalPart *= 10;
    }

    return integerPart * 100 + decimalPart;
}

    // =====================================================
    // FUNCTION 2: KIỂM TRA SINH VIÊN TỒN TẠI
    //
    // Được FacultyManagement gọi qua IStudentManagement
    // trước khi gửi điểm sang.
    // =====================================================

    function studentExists(
        uint256 studentId
    )
        external
        view
        returns (bool)
    {
        return students[studentId].exists;
    }

    // =====================================================
    // FUNCTION 3: NHẬP ĐIỂM MÔN HỌC
    //
    // course: Tên môn học dạng chữ
    // scoreInput: Điểm dạng chuỗi, ví dụ "8.5", "9.5", "10"
    // credits: Số tín chỉ của môn học
    // =====================================================

    function addScoreWithCredits(
        uint256 studentId,
        string memory course,
        uint256 semester, //học kì 
        string memory scoreInput,
        uint256 credits
    )
        external
        onlyExistingStudent(studentId)
    {
        require(
    semester >= 1 && semester <= 2,
    "Only semester 1 and 2 are allowed"
);
        // Sinh viên đã thôi học không được nhập điểm
        require(
            students[studentId].status
                != StudentStatus.Dismissed,
            "Student has been dismissed"
        );

        // Không cho nhập điểm vào học kỳ đã đánh giá
        require(
            !semesterEvaluated[studentId][semester],
            "Semester already evaluated"
        );

        // Chuyển điểm dạng chuỗi ("8.5", "9.5"...) sang thang 1000
        // Ví dụ: "8.5" -> 850, "9.5" -> 950, "10" -> 1000
        uint256 score = parseScore(scoreInput);

        // Điểm từ 0 đến 10.00, lưu theo thang 1000
        require(
            score <= 1000,
            "Score must be between 0 and 10"
        );

        // Tên môn học không được để trống
        require(
            bytes(course).length > 0,
            "Course name cannot be empty"
        );

        // Số tín chỉ từ 1 đến 10
        require(
            credits > 0 && credits <= 10,
            "Credits must be between 1 and 10"
        );

        // Chuyển tên môn học thành khóa bytes32
        bytes32 courseKey = keccak256(
            bytes(course)
        );

        // Không cho nhập trùng môn trong cùng học kỳ
        require(
            !scores[studentId][semester][courseKey].exists,
            "Score already exists"
        );

        // Lưu điểm môn học (score đã ở thang 1000, ví dụ 8.5 -> 850)
        scores[studentId][semester][courseKey] = Score({
            course: course,
            semester: semester,
            score: uint16(score),
            credits: uint8(credits),
            exists: true
        });

        // Lưu tên môn vào danh sách môn của học kỳ
        semesterCourseIds[studentId][semester].push(
            course
        );

        // Tăng số lần học môn của sinh viên
        courseAttemptCount[studentId][courseKey]++;
    }

    // =====================================================
// FUNCTION 4: TÍNH GPA THEO HỌC KỲ
//
// Công thức:
// GPA = Tổng (điểm môn * tín chỉ) / Tổng tín chỉ
//
// Ví dụ:
// Toán: 8 điểm, 3 tín chỉ
// Văn: 7 điểm, 2 tín chỉ
//
// GPA = (8*3 + 7*2) / (3+2)
//     = 38 / 5
//     = 7
//
// Lưu ý:
// Solidity sử dụng số nguyên nên GPA được làm tròn xuống.
// =====================================================

    function calculateGPA(
        uint256 studentId,
        uint256 semesterId
    )
        public
        view
        onlyExistingStudent(studentId)
        returns (uint256)
    {
        // Lấy danh sách tên môn học của học kỳ
        string[] storage courseList =
            semesterCourseIds[studentId][semesterId];

        uint256 len = courseList.length;

        // Phải có ít nhất một môn học
        require(
            len > 0,
            "No scores in this semester"
        );

        uint256 totalWeightedScore = 0;
        uint256 totalCredits = 0;

        // Duyệt danh sách môn học
        for (uint256 i = 0; i < len; i++) {

            // Lấy tên môn học
            string storage course = courseList[i];

            // Chuyển tên môn thành khóa bytes32
            bytes32 courseKey = keccak256(
                bytes(course)
            );

            // Lấy điểm môn học
            Score storage s =
                scores[studentId][semesterId][courseKey];

            // Cộng điểm nhân với tín chỉ
            totalWeightedScore +=
                uint256(s.score) * uint256(s.credits);

            // Cộng tổng tín chỉ
            totalCredits += uint256(s.credits);
        }

        // Kiểm tra tổng tín chỉ
        require(
            totalCredits > 0,
            "Total credits must be greater than 0"
        );

        // Trả về GPA theo thang điểm 1000
        return totalWeightedScore / totalCredits;
    }

    // GPA >= 5:
//     Đạt, tiếp tục học
//
// GPA < 5 lần 1:
//     Cảnh báo học tập
//
// GPA < 5 lần 2 liên tiếp:
//     Thôi học

    function evaluateStudent(
        uint256 studentId,
        uint256 semesterId
    )
        external
        
        onlyExistingStudent(studentId)
    {
        require(
    semesterId >= 1 && semesterId <= 2,
    "Only semester 1 and 2 are allowed"
);
        // Không cho đánh giá sinh viên đã thôi học
        require(
            students[studentId].status
                != StudentStatus.Dismissed,
            "Student has been dismissed"
        );

        // Không đánh giá lại học kỳ đã đánh giá
        require(
            !semesterEvaluated[studentId][semesterId],
            "Semester already evaluated"
        );

        // Học kỳ phải lớn hơn học kỳ đã đánh giá gần nhất
        require(
            semesterId > lastEvaluatedSemester[studentId],
            "Invalid semester sequence"
        );

        // Kiểm tra học kỳ đã có điểm
        require(
            semesterCourseIds[studentId][semesterId].length > 0,
            "No scores in this semester"
        );

        // Tính GPA học kỳ
        uint256 gpa = calculateGPA(
            studentId,
            semesterId
        );

        // Lưu GPA học kỳ
        semesterGPA[studentId][semesterId] = gpa;

        // Đánh dấu học kỳ đã đánh giá
        semesterEvaluated[studentId][semesterId] = true;

        // Cập nhật học kỳ gần nhất
        lastEvaluatedSemester[studentId] = semesterId;

        // Lấy thông tin sinh viên
        Student storage s = students[studentId];

        // ---------------------------------------------
        // TRƯỜNG HỢP 1: GPA KHÔNG ĐẠT
        // ---------------------------------------------

        if (gpa < 500) {

            // Tăng số lần không đạt liên tiếp
            s.consecutiveFails++;

            // Không đạt 2 học kỳ liên tiếp: thôi học
            if (s.consecutiveFails >= 2) {

                s.status = StudentStatus.Dismissed;

            } else {

                // Không đạt lần 1: cảnh báo học tập
                s.status = StudentStatus.AcademicWarning;
            }

        }

        // ---------------------------------------------
        // TRƯỜNG HỢP 2: GPA ĐẠT
        // ---------------------------------------------

        else {

            // Đặt lại số lần không đạt liên tiếp
            s.consecutiveFails = 0;

            // Khôi phục trạng thái đang học
            s.status = StudentStatus.Studying;
        }

    }

function getStatusText(
    StudentStatus status
)
    internal
    pure
    returns (string memory)
{
    if (status == StudentStatus.Studying) {
        return unicode"Đang học";
    }

    if (status == StudentStatus.AcademicWarning) {
        return unicode"Cảnh báo học tập";
    }

    if (status == StudentStatus.Dismissed) {
        return unicode"Thôi học";
    }

    return unicode"Không xác định";
}
    function getStudent(
        uint256 studentId
    )
        external
        view
        onlyExistingStudent(studentId)
        returns (StudentInfo memory info)
    {
        Student storage s = students[studentId];

        info.studentId = s.studentId;

        info.fullName = s.fullName;

        info.age = uint256(s.age);

        info.major = s.major;

        info.status = getStatusText(s.status);

        info.consecutiveFails = uint256(
            s.consecutiveFails
        );

        info.lastEvaluatedSemester =
            lastEvaluatedSemester[studentId];
    }

    // =====================================================
    // FUNCTION 8: LẤY DANH SÁCH SINH VIÊN CHƯA THÔI HỌC
    function getAllStudents()
        external
        view
        returns (uint256[] memory)
    {
        uint256 total = studentIds.length;

        uint256 activeCount = 0;

        // Bước 1: Đếm sinh viên chưa thôi học
        for (uint256 i = 0; i < total; i++) {

            uint256 id = studentIds[i];

            if (
                students[id].status
                    != StudentStatus.Dismissed
            ) {
                activeCount++;
            }
        }

        // Bước 2: Tạo mảng chứa mã sinh viên
        uint256[] memory activeIds =
            new uint256[](activeCount);

        uint256 index = 0;

        // Bước 3: Lọc sinh viên chưa thôi học
        for (uint256 i = 0; i < total; i++) {

            uint256 id = studentIds[i];

            if (
                students[id].status
                    != StudentStatus.Dismissed
            ) {
                activeIds[index] = id;

                index++;
            }
        }

        return activeIds;
    }

    // =====================================================
    // FUNCTION 9: XEM ĐIỂM MÔN HỌC
    // Nhập tên môn học bằng chữ.
    // Trả về:
    // - Tên môn học
    // - Điểm môn học
    // - Số tín chỉ
    // - Học kỳ
    // =====================================================

    function getScore(
        uint256 studentId,
        uint256 semesterId,
        string memory course
    )
        external
        view
        onlyExistingStudent(studentId)
        returns (
            string memory,
            uint256,
            uint256,
            uint256
        )
    {
        // Chuyển tên môn thành khóa bytes32
        bytes32 courseKey = keccak256(
            bytes(course)
        );

        // Lấy thông tin điểm
        Score storage s =
            scores[studentId][semesterId][courseKey];

        // Kiểm tra điểm có tồn tại
        require(
            s.exists,
            "Score not found"
        );

        // Trả về thông tin điểm
        return (
            s.course,
            uint256(s.score),
            uint256(s.credits),
            s.semester
        );
    }

    // =====================================================
    // FUNCTION 10: XEM GPA ĐÃ ĐÁNH GIÁ
    //
    // Chỉ trả về GPA sau khi học kỳ được đánh giá.
    // =====================================================

    function getSemesterGPA(
        uint256 studentId,
        uint256 semesterId
    )
        external
        view
        onlyExistingStudent(studentId)
        returns (uint256)
    {
        // Kiểm tra học kỳ đã được đánh giá
        require(
            semesterEvaluated[studentId][semesterId],
            "Semester has not been evaluated"
        );

        // Trả về GPA đã lưu
        return semesterGPA[studentId][semesterId];
    }
        // =====================================================
    // FUNCTION 11: TÍNH GPA CẢ NĂM
    //
    // Tính GPA cả năm từ điểm và tín chỉ của 2 học kỳ.
    //
    // Công thức:
    // GPA năm = Tổng (điểm môn * tín chỉ) của 2 kỳ
    //           / Tổng tín chỉ của 2 kỳ
    //
    // Trả về GPA theo thang điểm 10.
    // Ví dụ: 528 tương đương 5.28
    // =====================================================

    function calculateYearGPA(
        uint256 studentId,
        uint256 semester1Id,
        uint256 semester2Id
    )
        external
        view
        onlyExistingStudent(studentId)
        returns (uint256)
    {
        // Hai học kỳ phải khác nhau
        require(
            semester1Id != semester2Id,
            "Semesters must be different"
        );

        // Cả hai học kỳ phải được đánh giá
        require(
            semesterEvaluated[studentId][semester1Id],
            "Semester 1 has not been evaluated"
        );

        require(
            semesterEvaluated[studentId][semester2Id],
            "Semester 2 has not been evaluated"
        );

        // Lấy danh sách môn học của học kỳ 1
        string[] storage courses1 =
            semesterCourseIds[studentId][semester1Id];

        // Lấy danh sách môn học của học kỳ 2
        string[] storage courses2 =
            semesterCourseIds[studentId][semester2Id];

        uint256 totalWeightedScore = 0;
        uint256 totalCredits = 0;

        // ---------------------------------------------
        // BƯỚC 1: TÍNH TỔNG ĐIỂM CÓ TRỌNG SỐ HỌC KỲ 1
        // ---------------------------------------------

        for (uint256 i = 0; i < courses1.length; i++) {

            // Lấy tên môn học
            bytes32 courseKey = keccak256(
                bytes(courses1[i])
            );

            // Lấy thông tin điểm môn học
            Score storage s =
                scores[studentId][semester1Id][courseKey];

            // Cộng điểm nhân tín chỉ
            totalWeightedScore +=
                uint256(s.score) * uint256(s.credits);

            // Cộng tổng tín chỉ
            totalCredits += uint256(s.credits);
        }

        // ---------------------------------------------
        // BƯỚC 2: TÍNH TỔNG ĐIỂM CÓ TRỌNG SỐ HỌC KỲ 2
        // ---------------------------------------------

        for (uint256 i = 0; i < courses2.length; i++) {

            // Lấy tên môn học
            bytes32 courseKey = keccak256(
                bytes(courses2[i])
            );

            // Lấy thông tin điểm môn học
            Score storage s =
                scores[studentId][semester2Id][courseKey];

            // Cộng điểm nhân tín chỉ
            totalWeightedScore +=
                uint256(s.score) * uint256(s.credits);

            // Cộng tổng tín chỉ
            totalCredits += uint256(s.credits);
        }

        // ---------------------------------------------
        // BƯỚC 3: KIỂM TRA TỔNG TÍN CHỈ
        // ---------------------------------------------

        require(
            totalCredits > 0,
            "Total credits must be greater than 0"
        );

        // ---------------------------------------------
        // BƯỚC 4: TÍNH GPA CẢ NĂM
        // ---------------------------------------------

        return totalWeightedScore / totalCredits;
    }

}
