// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;
import "./IStudentManagement.sol";
contract FacultyManagement {
    // 1. KET NOI STUDENT MANAGEMENT

    IStudentManagement public studentManagement;
    // 2. STRUCTS
    // Thong tin mon hoc
    struct Course {
        uint256 courseId;
        string courseName;
        uint8 credits;
        bool exists;
    }

    // Thong tin hoc ky
    struct Semester {
        uint256 semesterId;
        string semesterName;
        bool exists;
    }

    // Thong tin lop hoc phan
    struct CourseOffering {
        uint256 offeringId;
        uint256 courseId;
        uint256 semesterId;
        bool exists;
    }

    // =====================================================
    // 3. MAPPINGS
    // =====================================================

    // Ma mon hoc -> Thong tin mon hoc
    mapping(uint256 => Course) public courses;

    // Ma hoc ky -> Thong tin hoc ky
    mapping(uint256 => Semester) public semesters;

    // Ma lop hoc phan -> Thong tin lop hoc phan
    mapping(uint256 => CourseOffering) public offerings;

    // =====================================================
    // 4. COUNTERS
    // =====================================================

    uint256 public totalCourses;
    uint256 public totalSemesters;
    uint256 public totalOfferings;

    // =====================================================
    // 6. CONSTRUCTOR
    // =====================================================

    // Ket noi voi StudentManagement khi deploy
    constructor(address studentContractAddress) {
        require(
            studentContractAddress != address(0),
            "Invalid student contract address"
        );

        require(
            studentContractAddress.code.length > 0,
            "Address is not a contract"
        );

        studentManagement =
            IStudentManagement(studentContractAddress);
    }

    // =====================================================
    // FUNCTION 1: THEM MON HOC
    // =====================================================

    function addCourse(
        uint256 courseId,
        string calldata courseName,
        uint256 credits
    ) external {

        // Ma mon hoc khong duoc bang 0
        require(
            courseId != 0,
            "Invalid course ID"
        );

        // Kiem tra mon hoc da ton tai
        require(
            !courses[courseId].exists,
            "Course already exists"
        );

        // Ten mon hoc khong duoc de trong
        require(
            bytes(courseName).length > 0,
            "Course name is empty"
        );

        // Tin chi tu 1 den 10
        require(
            credits > 0 && credits <= 10,
            "Credits must be between 1 and 10"
        );

        // Luu thong tin mon hoc
        courses[courseId] = Course({
            courseId: courseId,
            courseName: courseName,
            credits: uint8(credits),
            exists: true
        });

        // Tang tong so mon hoc
        totalCourses++;


    }

    // =====================================================
    // FUNCTION 2: TAO HOC KY
    // Chi cho phep hoc ky 1 va hoc ky 2
    // =====================================================

    function createSemester(
        uint256 semesterId,
        string calldata semesterName
    ) external {

        // Chi cho phep tao hoc ky 1 va 2
        require(
            semesterId >= 1 && semesterId <= 2,
            "Only semester 1 and 2 are allowed"
        );

        // Kiem tra hoc ky da ton tai
        require(
            !semesters[semesterId].exists,
            "Semester already exists"
        );

        // Ten hoc ky khong duoc de trong
        require(
            bytes(semesterName).length > 0,
            "Semester name is empty"
        );

        // Luu thong tin hoc ky
        semesters[semesterId] = Semester({
            semesterId: semesterId,
            semesterName: semesterName,
            exists: true
        });

        // Tang tong so hoc ky
        totalSemesters++;
    }
    // =====================================================
    // FUNCTION 3: TAO LOP HOC PHAN
    //
    // Gan mot mon hoc vao mot hoc ky cu the, tao thanh
    // mot lop hoc phan (offering) de submitScore su dung.
    // =====================================================

    function createOffering(
        uint256 offeringId,
        uint256 courseId,
        uint256 semesterId
    ) external {

        require(
            offeringId != 0,
            "Invalid offering ID"
        );

        require(
            !offerings[offeringId].exists,
            "Offering already exists"
        );

        require(
            courses[courseId].exists,
            "Course not found"
        );

        require(
            semesters[semesterId].exists,
            "Semester not found"
        );

        offerings[offeringId] = CourseOffering({
            offeringId: offeringId,
            courseId: courseId,
            semesterId: semesterId,
            exists: true
        });

        totalOfferings++;
    }

    // =====================================================
    // FUNCTION 4: GUI DIEM SINH VIEN
    // scoreInput: diem dang chuoi, vi du "8.5", "9.5", "10"
    // =====================================================

    function submitScore(
        uint256 studentId,
        uint256 offeringId,
        string memory scoreInput
    ) external {

        // Kiem tra lop hoc phan ton tai
        require(
            offerings[offeringId].exists,
            "Offering not found"
        );

        // Lay thong tin lop hoc phan
        CourseOffering storage offering =
            offerings[offeringId];

        // Kiem tra hoc ky hop le
        require(
            offering.semesterId >= 1 &&
            offering.semesterId <= 2,
            "Invalid semester"
        );

        // Lay thong tin mon hoc
        Course storage course =
            courses[offering.courseId];

        // Kiem tra sinh vien ton tai
        require(
            studentManagement.studentExists(studentId),
            "Student not found"
        );

        // Gui diem sang StudentManagement
        studentManagement.addScoreWithCredits(
            studentId,
            course.courseName,
            offering.semesterId,
            scoreInput,
            uint256(course.credits)
        );

    }
}
