// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

// File luu tru du lieu dung chung cho he thong quan ly sinh vien
// StudentManagement se ke thua contract nay

abstract contract StudentData {

    // ==========================================
    // 1. TRANG THAI SINH VIEN
    // ==========================================

    enum StudentStatus {
        Studying,        // 0: Dang hoc
        AcademicWarning, // 1: Canh bao hoc tap
        Dismissed        // 2: Thoi hoc
    }

    // ==========================================
    // 2. CAU TRUC DU LIEU SINH VIEN
    // ==========================================

    struct Student {
        uint256 studentId;          // Ma sinh vien
        string fullName;            // Ho va ten
        string major;               // Nganh hoc
        uint8 age;                  // Tuoi
        StudentStatus status;       // Trang thai hoc tap
        uint8 consecutiveFails;     // So hoc ky khong dat lien tiep
        bool exists;                // Kiem tra sinh vien ton tai
    }

    // ==========================================
    // 3. CAU TRUC DU LIEU DIEM
    // ==========================================

    struct Score {
        string course;              // Ten mon hoc
        uint256 semester;           // Hoc ky

        // Diem duoc luu theo dang x100
        // Vi du:
        // 8.00  -> 800
        // 8.50  -> 850
        // 7.25  -> 725
        // 10.00 -> 1000
        uint16 score;

        uint8 credits;              // So tin chi
        bool exists;                // Kiem tra diem da ton tai
    }

    // ==========================================
    // 4. LUU TRU DANH SACH SINH VIEN
    // ==========================================

    // Mapping ma sinh vien -> thong tin sinh vien
    mapping(uint256 => Student) internal students;

    // Mang luu danh sach ma sinh vien
    uint256[] internal studentIds;

    // Tong so sinh vien da duoc them vao he thong
    uint256 public totalStudents;

    // ==========================================
    // 5. LUU TRU DIEM THEO MON HOC VA HOC KY
    // ==========================================

    // Cau truc:
    // Ma sinh vien -> Hoc ky -> Ma mon hoc -> Thong tin diem

    mapping(
        uint256 =>
        mapping(
            uint256 =>
            mapping(bytes32 => Score)
        )
    ) internal scores;

    // So lan sinh vien da dang ky/hoc mot mon
    // Ma sinh vien -> Ma mon hoc -> So lan hoc

    mapping(
        uint256 =>
        mapping(bytes32 => uint256)
    ) internal courseAttemptCount;

    // Danh sach ma mon hoc theo tung hoc ky
    // Ma sinh vien -> Hoc ky -> Danh sach ma mon hoc

    mapping(
        uint256 =>
        mapping(uint256 => string[])
    ) internal semesterCourseIds;

    // ==========================================
    // 6. LUU TRU GPA VA KET QUA DANH GIA
    // ==========================================

    // GPA cua sinh vien theo tung hoc ky
    //
    // GPA cung duoc luu theo dang x100
    //
    // Vi du:
    // GPA 8.50 -> 850
    // GPA 7.25 -> 725
    // GPA 5.00 -> 500

    mapping(
        uint256 =>
        mapping(uint256 => uint256)
    ) internal semesterGPA;

    // Danh dau hoc ky da duoc danh gia hay chua
    // Ma sinh vien -> Hoc ky -> Trang thai danh gia

    mapping(
        uint256 =>
        mapping(uint256 => bool)
    ) internal semesterEvaluated;

    // Hoc ky gan nhat da duoc danh gia cua sinh vien
    // Ma sinh vien -> Hoc ky cuoi cung

    mapping(uint256 => uint256) internal lastEvaluatedSemester;

    // ==========================================
    // 7. MODIFIER KIEM TRA SINH VIEN
    // ==========================================

    // Chi cho phep thuc hien neu sinh vien ton tai
    modifier onlyExistingStudent(uint256 studentId) {
        require(
            students[studentId].exists,
            "Student not found"
        );
        _;
    }
}