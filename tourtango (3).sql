-- phpMyAdmin SQL Dump
-- version 5.2.1
-- https://www.phpmyadmin.net/
--
-- Host: 127.0.0.1:3306
-- Generation Time: May 08, 2025 at 05:35 PM
-- Server version: 10.4.32-MariaDB
-- PHP Version: 8.0.30

SET SQL_MODE = "NO_AUTO_VALUE_ON_ZERO";
START TRANSACTION;
SET time_zone = "+00:00";


/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;

--
-- Database: `tourtango`
--

DELIMITER $$
--
-- Procedures
--
CREATE DEFINER=`root`@`localhost` PROCEDURE `CreateBookingTransaction` (IN `bookingDate` DATE, IN `numberOfPeople` INT, IN `packageID` INT, IN `customerID` INT, IN `paymentAmount` DOUBLE, IN `payment_mode` VARCHAR(20), OUT `var_bookingID` INT, OUT `var_paymentID` INT, OUT `statusMessage` VARCHAR(50))   BEGIN
    -- Error handler for rollback
    DECLARE CONTINUE HANDLER FOR SQLEXCEPTION 
    BEGIN
        ROLLBACK; -- Undo changes if an error occurs
        SET statusMessage = 'Transaction failed and rolled back.';
    END;

    -- Start the transaction
    START TRANSACTION;

    -- Step 2: Insert into Payment
    INSERT INTO payment (amount, paymentDate, payment_mode)
    VALUES (paymentAmount, CURDATE(), payment_mode);
    
    SET var_paymentID = LAST_INSERT_ID();
    
    INSERT INTO booking (BookingDate, noOfPeople, packageID, customerID, confirmationStatus, paymentID)
    VALUES (CURDATE(), numberOfPeople, packageID, customerID, 'Y', var_paymentID);

	SET var_bookingID = LAST_INSERT_ID();
 

    -- Commit transaction if all steps succeed
    COMMIT;

    SET statusMessage = 'Transaction completed successfully.';
END$$

DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `accommodation`
--

CREATE TABLE `accommodation` (
  `accommodationID` int(11) NOT NULL,
  `HotelName` varchar(20) DEFAULT NULL,
  `plotNo` int(11) DEFAULT NULL,
  `street_address` varchar(50) DEFAULT NULL,
  `city` varchar(20) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `accommodation`
--

INSERT INTO `accommodation` (`accommodationID`, `HotelName`, `plotNo`, `street_address`, `city`, `country`) VALUES
(1, 'Seaside Resort', 12, '123 Ocean Drive', 'Miami', 'USA'),
(2, 'Mountain Lodge', 34, '456 Mountain Road', 'New York', 'USA');

-- --------------------------------------------------------

--
-- Table structure for table `booking`
--

CREATE TABLE `booking` (
  `BookingID` int(11) NOT NULL,
  `BookingDate` date DEFAULT NULL,
  `confirmationStatus` char(1) DEFAULT NULL,
  `noOfPeople` int(11) NOT NULL,
  `customerID` int(11) DEFAULT NULL,
  `packageID` int(11) NOT NULL,
  `paymentID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `booking`
--

INSERT INTO `booking` (`BookingID`, `BookingDate`, `confirmationStatus`, `noOfPeople`, `customerID`, `packageID`, `paymentID`) VALUES
(72, '2024-12-13', 'Y', 1, 1, 33, 80),
(75, '2024-12-14', 'Y', 1, 1, 2, 86),
(77, '2024-12-14', 'Y', 1, 1, 37, 88),
(78, '2025-05-05', 'Y', 2, 1, 31, 90);

--
-- Triggers `booking`
--
DELIMITER $$
CREATE TRIGGER `AfterBookingInsert` AFTER INSERT ON `booking` FOR EACH ROW BEGIN
    -- Declare variables to hold the data from SELECT queries
    DECLARE new_amount DOUBLE;
    DECLARE paymentMode VARCHAR(20);
    DECLARE company_name VARCHAR(20);
    DECLARE package_name VARCHAR(20);
    DECLARE startDate DATE;
    DECLARE endDate DATE;

    -- Fetch payment amount and payment mode based on paymentID
    SELECT amount, payment_mode INTO new_amount, paymentMode
    FROM payment
    WHERE paymentID = NEW.paymentID;

    -- Check if the amount is NULL
    IF new_amount IS NULL THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Payment amount not found for the updated paymentID.';
    END IF;
    
    -- Fetch the package and company details
    SELECT t.packageName, t.start_date, t.end_date, c.companyName 
    INTO package_name, startDate, endDate, company_name
    FROM tourPackage t
    JOIN tourCompany c ON t.tourCompanyID = c.companyID
    WHERE t.packageID = NEW.packageID;

    -- Insert a record into the booking_history table
    INSERT INTO booking_history (
        customer_id,
        booking_id,
        tourCompany,
        packageName,
        start_date,
        end_date,
        payment_mode,
        noOfPeople,
        operation,
        booking_date,
        total_amount,
        action_timestamp
    )
    VALUES (
        NEW.customerID,
        NEW.bookingID,
        company_name,
        package_name,
        startDate,
        endDate,
        paymentMode,
        NEW.noOfPeople,
        'BOOKED',
        NEW.bookingDate,
        new_amount,
        CURRENT_TIMESTAMP
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_booking_delete` AFTER DELETE ON `booking` FOR EACH ROW BEGIN
    -- Declare variables
    DECLARE new_amount DOUBLE;
    DECLARE paymentMode VARCHAR(20);
    DECLARE company_name VARCHAR(20);
    DECLARE package_name VARCHAR(20);
    DECLARE startDate DATE;
    DECLARE endDate DATE;

    -- Fetch payment details
    SELECT amount, payment_mode 
    INTO new_amount, paymentMode
    FROM payment
    WHERE paymentID = OLD.paymentID;

    -- Fetch package and company details
    SELECT t.packageName, t.start_date, t.end_date, c.companyName 
    INTO package_name, startDate, endDate, company_name
    FROM tourPackage t
    JOIN tourCompany c ON t.tourCompanyID = c.companyID
    WHERE t.packageID = OLD.packageID;

    -- Insert a record into the booking_history table
    INSERT INTO booking_history (
        customer_id,
        booking_id,
        tourCompany,
        packageName,
        start_date,
        end_date,
        payment_mode,
        noOfPeople,
        operation,
        booking_date,
        total_amount,
        action_timestamp
    )
    VALUES (
        OLD.customerID,
        OLD.bookingID,
        company_name,
        package_name,
        startDate,
        endDate,
        paymentMode,
        OLD.noOfPeople,
        'CANCELLED',
        OLD.bookingDate,
        new_amount,
        CURRENT_TIMESTAMP
    );
END
$$
DELIMITER ;
DELIMITER $$
CREATE TRIGGER `after_booking_insert_tr` BEFORE INSERT ON `booking` FOR EACH ROW BEGIN
    DECLARE current_noOfCustomers INT;
    DECLARE customer_limit INT;
    DECLARE updated_noOfCustomers INT;


    SELECT noOfCustomers, customerLimit
    INTO current_noOfCustomers, customer_limit
    FROM tourPackage
    WHERE packageID = NEW.packageID;

    -- Calculate the updated number of customers
    SET updated_noOfCustomers = current_noOfCustomers + NEW.noOfPeople;

    -- Check if the updated number of customers exceeds the limit
    IF updated_noOfCustomers > customer_limit THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Booking cannot be processed because the number of customers exceeds the package limit.';

    ELSE
        -- Update the number of customers in the tour package table
        UPDATE tourPackage
        SET noOfCustomers = updated_noOfCustomers
        WHERE packageID = NEW.packageID;

        -- If the number of customers is exactly equal to the customer limit, set availability to 'N'
        IF updated_noOfCustomers = customer_limit THEN
            UPDATE tourPackage
            SET availability = 'N'
            WHERE packageID = NEW.packageID;
        END IF;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `booking_history`
--

CREATE TABLE `booking_history` (
  `history_id` int(11) NOT NULL,
  `customer_id` int(11) DEFAULT NULL,
  `booking_id` int(11) DEFAULT NULL,
  `tourCompany` varchar(50) NOT NULL,
  `packageName` varchar(20) NOT NULL,
  `start_date` date NOT NULL,
  `end_date` date NOT NULL,
  `payment_mode` varchar(20) DEFAULT NULL,
  `noOfPeople` int(11) NOT NULL,
  `reviewID` int(11) DEFAULT NULL,
  `operation` varchar(50) NOT NULL,
  `booking_date` date DEFAULT NULL,
  `total_amount` double DEFAULT NULL,
  `action_timestamp` timestamp NOT NULL DEFAULT current_timestamp()
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `booking_history`
--

INSERT INTO `booking_history` (`history_id`, `customer_id`, `booking_id`, `tourCompany`, `packageName`, `start_date`, `end_date`, `payment_mode`, `noOfPeople`, `reviewID`, `operation`, `booking_date`, `total_amount`, `action_timestamp`) VALUES
(48, 1, 71, 'Adventure Travels', 'bodsi', '2024-12-08', '2024-12-25', 'test', 1, NULL, 'BOOKED', '2024-12-13', 330, '2024-12-12 21:47:57'),
(49, 1, 72, 'Adventure Travels', 'bodsi', '2024-12-08', '2024-12-25', 'Credit Card', 1, NULL, 'BOOKED', '2024-12-13', 400, '2024-12-12 21:50:24'),
(50, 1, 73, 'Globe Trotters', 'Mountain Adventure', '2024-12-18', '2024-12-22', 'Credit Card', 1, NULL, 'BOOKED', '2024-12-13', 1500.75, '2024-12-12 21:58:02'),
(52, 1, 75, 'Globe Trotters', 'Mountain Adventure', '2024-12-18', '2024-12-22', 'Credit Card', 1, NULL, 'BOOKED', '2024-12-14', 1500.75, '2024-12-14 13:09:53'),
(53, 1, 71, 'Adventure Travels', 'bodsi', '2024-12-08', '2024-12-25', 'test', 1, NULL, 'CANCELLED', '2024-12-13', 330, '2024-12-14 13:14:15'),
(57, 1, 77, 'Adventure Travels', 'Paris Tour', '2024-12-05', '2024-12-12', 'Credit Card', 1, 37, 'BOOKED', '2024-12-14', 34, '2024-12-14 13:40:16'),
(58, 1, 73, 'Globe Trotters', 'Mountain Adventure', '2024-12-18', '2024-12-22', 'Credit Card', 1, NULL, 'CANCELLED', '2024-12-13', 1500.75, '2024-12-14 14:09:12'),
(59, 1, 78, 'Atravels', 'Desert Expedition', '2024-12-12', '2024-12-16', 'Credit Card', 2, NULL, 'BOOKED', '2025-05-05', 440, '2025-05-05 07:04:34');

-- --------------------------------------------------------

--
-- Table structure for table `customer`
--

CREATE TABLE `customer` (
  `customerID` int(11) NOT NULL,
  `name` varchar(30) DEFAULT NULL,
  `email` varchar(20) NOT NULL,
  `password` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer`
--

INSERT INTO `customer` (`customerID`, `name`, `email`, `password`) VALUES
(1, 'alice', 'alice@gmail.com', 'abcdef'),
(2, 'Bob Smith', 'bob@gmail.com', '');

-- --------------------------------------------------------

--
-- Table structure for table `customer_phonenumber`
--

CREATE TABLE `customer_phonenumber` (
  `phoneNumber` varchar(15) NOT NULL,
  `customerID` int(11) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `customer_phonenumber`
--

INSERT INTO `customer_phonenumber` (`phoneNumber`, `customerID`) VALUES
('0987654321', 2),
('567789', 1),
('98898707', 1);

-- --------------------------------------------------------

--
-- Table structure for table `faqs`
--

CREATE TABLE `faqs` (
  `faqID` int(11) NOT NULL,
  `question` varchar(200) NOT NULL,
  `answer` varchar(500) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `faqs`
--

INSERT INTO `faqs` (`faqID`, `question`, `answer`) VALUES
(1, 'What is included in a typical tour package?', 'A typical tour package includes transportation, accommodation, meals, sightseeing, and a tour guide. Some packages may also include additional activities or experiences.'),
(2, 'How do I book a tour?', 'You can book a tour by visiting our website, selecting your desired package, and following the booking process. You can also contact our customer service for assistance.'),
(3, 'What is the cancellation policy for tours?', 'Our cancellation policy varies depending on the tour package. Please check the specific tour details for the policy or contact us for more information.'),
(4, 'What should I bring for a tour?', 'It’s recommended to bring comfortable clothing, sunscreen, a hat, and any personal items you may need. Specific tours may require additional gear, which will be listed in the tour details.'),
(5, 'What happens if I miss the start time of the tour?', 'It is important to arrive on time for the tour. If you miss the start time, please contact the tour guide immediately. However, depending on the tour’s schedule, joining after the start may not be possible.');

-- --------------------------------------------------------

--
-- Table structure for table `favourites`
--

CREATE TABLE `favourites` (
  `customerID` int(11) NOT NULL,
  `tourPackageID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `favourites`
--

INSERT INTO `favourites` (`customerID`, `tourPackageID`) VALUES
(2, 2),
(2, 27);

-- --------------------------------------------------------

--
-- Table structure for table `flight`
--

CREATE TABLE `flight` (
  `flightID` int(11) NOT NULL,
  `departureTime` date DEFAULT NULL,
  `arrivalTime` date DEFAULT NULL,
  `FlightCompany` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `flight`
--

INSERT INTO `flight` (`flightID`, `departureTime`, `arrivalTime`, `FlightCompany`) VALUES
(1, '2024-12-15', '2024-12-15', 'Airways Express'),
(2, '2024-12-16', '2024-12-16', 'Skyline Airlines');

-- --------------------------------------------------------

--
-- Table structure for table `guide`
--

CREATE TABLE `guide` (
  `guideID` int(11) NOT NULL,
  `companyID` int(11) NOT NULL,
  `guideName` varchar(20) DEFAULT NULL,
  `guideAvailability` char(1) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `guide`
--

INSERT INTO `guide` (`guideID`, `companyID`, `guideName`, `guideAvailability`) VALUES
(1, 1, 'John Doe', 'Y'),
(2, 2, 'Jane Smith', 'Y'),
(6, 1, 'Sam', 'Y');

-- --------------------------------------------------------

--
-- Table structure for table `itinerary`
--

CREATE TABLE `itinerary` (
  `itineraryID` int(11) NOT NULL,
  `date` date NOT NULL,
  `time_of_day` varchar(15) NOT NULL,
  `activity_name` varchar(50) DEFAULT NULL,
  `description` varchar(60) DEFAULT NULL,
  `city` varchar(20) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `itinerary`
--

INSERT INTO `itinerary` (`itineraryID`, `date`, `time_of_day`, `activity_name`, `description`, `city`) VALUES
(0, '2024-02-13', 'Morning', 'swimming', 'xyz', 'hawaii'),
(1, '2024-12-20', 'Morning', 'Beach Exploration', 'Exploring the famous Miami Beach', 'Miami'),
(2, '2024-12-21', 'Afternoon', 'Mountain Hiking', 'Hiking in the Rockies', 'New York'),
(3, '2024-02-13', 'MOrinign', 'hawaii', 'xyz', 'hawaii');

-- --------------------------------------------------------

--
-- Table structure for table `payment`
--

CREATE TABLE `payment` (
  `paymentID` int(11) NOT NULL,
  `amount` double DEFAULT NULL,
  `paymentDate` date DEFAULT NULL,
  `payment_mode` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `payment`
--

INSERT INTO `payment` (`paymentID`, `amount`, `paymentDate`, `payment_mode`) VALUES
(73, 800, '2024-12-13', 'Credit Card'),
(74, 9200, '2024-12-13', 'Credit Card'),
(75, 400, '2024-12-13', 'Credit Card'),
(76, 330, '2024-12-13', 'test'),
(77, 330, '2024-12-13', 'test'),
(78, 330, '2024-12-13', 'test'),
(79, 330, '2024-12-13', 'test'),
(80, 400, '2024-12-13', 'Credit Card'),
(84, 1500.75, '2024-12-13', 'Credit Card'),
(85, 34, '2024-12-13', 'Credit Card'),
(86, 1500.75, '2024-12-14', 'Credit Card'),
(87, 34, '2024-12-14', 'Credit Card'),
(88, 34, '2024-12-14', 'Credit Card'),
(90, 440, '2025-05-05', 'Credit Card');

-- --------------------------------------------------------

--
-- Table structure for table `review`
--

CREATE TABLE `review` (
  `reviewID` int(11) NOT NULL,
  `rating` double DEFAULT NULL,
  `comment` varchar(50) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `review`
--

INSERT INTO `review` (`reviewID`, `rating`, `comment`) VALUES
(37, 1, 'nice');

-- --------------------------------------------------------

--
-- Table structure for table `tourcompany`
--

CREATE TABLE `tourcompany` (
  `companyID` int(11) NOT NULL,
  `companyName` varchar(50) DEFAULT NULL,
  `website` varchar(20) DEFAULT NULL,
  `plotNo` varchar(11) DEFAULT NULL,
  `street_address` varchar(50) DEFAULT NULL,
  `city` varchar(20) DEFAULT NULL,
  `country` varchar(20) DEFAULT NULL,
  `email` varchar(20) NOT NULL,
  `password` varchar(20) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tourcompany`
--

INSERT INTO `tourcompany` (`companyID`, `companyName`, `website`, `plotNo`, `street_address`, `city`, `country`, `email`, `password`) VALUES
(1, 'Atravels', 'www.adventure.com', '12', 'Add street address number', 'Miami', 'USA', 'atravels@gmail.com', 'abcdef'),
(2, 'Globe Trotters', 'www.globetrotters.co', '34', '456 Mountain Street', 'New York', 'USA', '', ''),
(3, 'tour co A', 'tourcoa.com', NULL, NULL, NULL, NULL, 'tourcoa@gmail.com', 'abcdefg');

-- --------------------------------------------------------

--
-- Table structure for table `tourpackage`
--

CREATE TABLE `tourpackage` (
  `packageID` int(11) NOT NULL,
  `packageName` varchar(20) DEFAULT NULL,
  `price` double DEFAULT NULL,
  `availability` varchar(15) DEFAULT NULL,
  `description` varchar(200) NOT NULL,
  `tourCompanyID` int(11) DEFAULT NULL,
  `start_date` date DEFAULT NULL,
  `end_date` date DEFAULT NULL,
  `transportID` int(11) DEFAULT NULL,
  `guideID` int(11) DEFAULT NULL,
  `accommodationID` int(11) DEFAULT NULL,
  `country` varchar(30) DEFAULT NULL,
  `noOfCustomers` int(11) NOT NULL,
  `customerLimit` int(11) NOT NULL,
  `imageUrl` varchar(100) NOT NULL,
  `specialOffers` varchar(100) NOT NULL,
  `average_rating` double NOT NULL DEFAULT 0
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tourpackage`
--

INSERT INTO `tourpackage` (`packageID`, `packageName`, `price`, `availability`, `description`, `tourCompanyID`, `start_date`, `end_date`, `transportID`, `guideID`, `accommodationID`, `country`, `noOfCustomers`, `customerLimit`, `imageUrl`, `specialOffers`, `average_rating`) VALUES
(2, 'Mountain Adventure', 1500.75, 'active', '', 2, '2024-12-18', '2024-12-22', 2, 2, 1, 'USA', 6, 50, 'https://asset.cloudinary.com/dbrnniorg/49d2c5c3e8f5d9251e88b68aa95e6f02', '20% off', 0),
(26, 'Beach Getaway', 200, 'active', '', 1, '2024-12-01', '2024-12-03', 1, 1, 2, 'Maldives', 0, 0, 'https://asset.cloudinary.com/dbrnniorg/49d2c5c3e8f5d9251e88b68aa95e6f02', '', 0),
(27, 'City Tour', 150, 'upcoming', 'wrg', 1, '2024-12-05', '2024-12-08', 1, 1, 2, 'France', 0, 0, 'https://asset.cloudinary.com/dbrnniorg/49d2c5c3e8f5d9251e88b68aa95e6f02', '', 0),
(30, 'Safari Experience', 250, 'upcoming', 'ddrb', 1, '2024-12-18', '2024-12-22', 2, NULL, 1, 'Kenya', 0, 0, 'https://asset.cloudinary.com/dbrnniorg/49d2c5c3e8f5d9251e88b68aa95e6f02', '10% off', 0),
(31, 'Desert Expedition', 220, 'active', 'jhvjh', 1, '2024-12-12', '2024-12-16', 2, NULL, 2, 'UAE', 2, 50, 'https://asset.cloudinary.com/dbrnniorg/49d2c5c3e8f5d9251e88b68aa95e6f02', '', 0),
(32, 'Hawaii', 200, 'Y', 'ioenr', 1, '2024-11-12', '2024-12-01', 1, NULL, 2, 'hawaii', 0, 50, 'https://asset.cloudinary.com/dbrnniorg/49d2c5c3e8f5d9251e88b68aa95e6f02', '50% off', 0),
(33, 'bodsi', 400, 'Y', 'fnsgsnr', 1, '2024-12-08', '2024-12-25', 1, 1, 2, 'jneorne', 4, 50, 'assets/images/place3.jpg', '', 0),
(36, 'Northern Areas', 2300, 'Y', 'Northern area of pakistan', 1, '2024-12-10', '2024-12-19', 1, NULL, 2, 'pakistan', 0, 50, 'assets/images/place1.jpg', '', 0),
(37, 'Paris Tour', 34, 'Y', 'Travelling across paris spots.', 1, '2024-12-05', '2024-12-12', 1, 1, 2, 'wtwet', 3, 56, 'assets/images/place1.jpg', '', 0);

--
-- Triggers `tourpackage`
--
DELIMITER $$
CREATE TRIGGER `update_guide_availability` AFTER UPDATE ON `tourpackage` FOR EACH ROW BEGIN
    -- Check if the guideID has been updated
    IF OLD.guideID != NEW.guideID THEN
        -- Set the old guide's availability to 'N'
        UPDATE guide
        SET guideAvailability = 'N'
        WHERE guideID = OLD.guideID;
    END IF;
END
$$
DELIMITER ;

-- --------------------------------------------------------

--
-- Table structure for table `tourpackage_flight`
--

CREATE TABLE `tourpackage_flight` (
  `flightID` int(11) NOT NULL,
  `tourPackageID` int(11) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tourpackage_flight`
--

INSERT INTO `tourpackage_flight` (`flightID`, `tourPackageID`) VALUES
(1, 1),
(1, 34),
(1, 37),
(2, 2),
(2, 33),
(2, 35),
(2, 36);

-- --------------------------------------------------------

--
-- Table structure for table `tourpackage_itinerary`
--

CREATE TABLE `tourpackage_itinerary` (
  `packageID` int(11) NOT NULL,
  `itineraryID` int(11) NOT NULL,
  `itinerary_date` date NOT NULL,
  `itinerary_time_of_day` varchar(15) NOT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `tourpackage_itinerary`
--

INSERT INTO `tourpackage_itinerary` (`packageID`, `itineraryID`, `itinerary_date`, `itinerary_time_of_day`) VALUES
(1, 1, '2024-12-20', 'Morning'),
(2, 2, '2024-12-21', 'Afternoon'),
(34, 1, '2024-12-20', 'Morning'),
(34, 3, '2024-02-13', 'MOrinign'),
(35, 0, '2024-02-13', 'Morning'),
(35, 1, '2024-12-20', 'Morning'),
(36, 1, '2024-12-20', 'Morning'),
(37, 0, '2024-02-13', 'Morning');

-- --------------------------------------------------------

--
-- Table structure for table `transportation`
--

CREATE TABLE `transportation` (
  `transportID` int(11) NOT NULL,
  `companyID` int(11) NOT NULL,
  `vehicleType` varchar(30) DEFAULT NULL,
  `pickupLocation` varchar(50) DEFAULT NULL,
  `driverName` varchar(30) DEFAULT NULL
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_general_ci;

--
-- Dumping data for table `transportation`
--

INSERT INTO `transportation` (`transportID`, `companyID`, `vehicleType`, `pickupLocation`, `driverName`) VALUES
(0, 1, 'Jeep', 'London Bridge', 'Sally'),
(1, 1, 'Van', 'Miami Airport', 'Mike Johnson'),
(2, 2, 'Van', 'New York Central', 'Sarah Lee');

--
-- Indexes for dumped tables
--

--
-- Indexes for table `accommodation`
--
ALTER TABLE `accommodation`
  ADD PRIMARY KEY (`accommodationID`);

--
-- Indexes for table `booking`
--
ALTER TABLE `booking`
  ADD PRIMARY KEY (`BookingID`),
  ADD KEY `booking_payment_fk` (`paymentID`),
  ADD KEY `booking_customer_fk` (`customerID`),
  ADD KEY `booking_package_fk` (`packageID`);

--
-- Indexes for table `booking_history`
--
ALTER TABLE `booking_history`
  ADD PRIMARY KEY (`history_id`),
  ADD KEY `booking_history_ibfk_1` (`customer_id`),
  ADD KEY `booking_history_ibfk_2` (`booking_id`),
  ADD KEY `booking_history_review` (`reviewID`);

--
-- Indexes for table `customer`
--
ALTER TABLE `customer`
  ADD PRIMARY KEY (`customerID`);

--
-- Indexes for table `customer_phonenumber`
--
ALTER TABLE `customer_phonenumber`
  ADD PRIMARY KEY (`phoneNumber`);

--
-- Indexes for table `faqs`
--
ALTER TABLE `faqs`
  ADD PRIMARY KEY (`faqID`);

--
-- Indexes for table `favourites`
--
ALTER TABLE `favourites`
  ADD PRIMARY KEY (`customerID`,`tourPackageID`),
  ADD KEY `favorites_ibfk_2` (`tourPackageID`);

--
-- Indexes for table `flight`
--
ALTER TABLE `flight`
  ADD PRIMARY KEY (`flightID`);

--
-- Indexes for table `guide`
--
ALTER TABLE `guide`
  ADD PRIMARY KEY (`guideID`),
  ADD KEY `guide_company_fk` (`companyID`);

--
-- Indexes for table `itinerary`
--
ALTER TABLE `itinerary`
  ADD PRIMARY KEY (`itineraryID`,`date`,`time_of_day`);

--
-- Indexes for table `payment`
--
ALTER TABLE `payment`
  ADD PRIMARY KEY (`paymentID`);

--
-- Indexes for table `review`
--
ALTER TABLE `review`
  ADD PRIMARY KEY (`reviewID`);

--
-- Indexes for table `tourcompany`
--
ALTER TABLE `tourcompany`
  ADD PRIMARY KEY (`companyID`);

--
-- Indexes for table `tourpackage`
--
ALTER TABLE `tourpackage`
  ADD PRIMARY KEY (`packageID`),
  ADD KEY `package_company_fk` (`tourCompanyID`),
  ADD KEY `package_guide_fk` (`guideID`),
  ADD KEY `package_transport_fk` (`transportID`),
  ADD KEY `package_accommodation_fk` (`accommodationID`);

--
-- Indexes for table `tourpackage_flight`
--
ALTER TABLE `tourpackage_flight`
  ADD PRIMARY KEY (`flightID`,`tourPackageID`);

--
-- Indexes for table `tourpackage_itinerary`
--
ALTER TABLE `tourpackage_itinerary`
  ADD PRIMARY KEY (`packageID`,`itineraryID`,`itinerary_date`,`itinerary_time_of_day`),
  ADD KEY `itineraryID` (`itineraryID`,`itinerary_date`,`itinerary_time_of_day`);

--
-- Indexes for table `transportation`
--
ALTER TABLE `transportation`
  ADD PRIMARY KEY (`transportID`),
  ADD KEY `transport_company_fk` (`companyID`);

--
-- AUTO_INCREMENT for dumped tables
--

--
-- AUTO_INCREMENT for table `booking`
--
ALTER TABLE `booking`
  MODIFY `BookingID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=79;

--
-- AUTO_INCREMENT for table `booking_history`
--
ALTER TABLE `booking_history`
  MODIFY `history_id` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=60;

--
-- AUTO_INCREMENT for table `faqs`
--
ALTER TABLE `faqs`
  MODIFY `faqID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=6;

--
-- AUTO_INCREMENT for table `guide`
--
ALTER TABLE `guide`
  MODIFY `guideID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=7;

--
-- AUTO_INCREMENT for table `payment`
--
ALTER TABLE `payment`
  MODIFY `paymentID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=91;

--
-- AUTO_INCREMENT for table `review`
--
ALTER TABLE `review`
  MODIFY `reviewID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- AUTO_INCREMENT for table `tourcompany`
--
ALTER TABLE `tourcompany`
  MODIFY `companyID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=4;

--
-- AUTO_INCREMENT for table `tourpackage`
--
ALTER TABLE `tourpackage`
  MODIFY `packageID` int(11) NOT NULL AUTO_INCREMENT, AUTO_INCREMENT=38;

--
-- Constraints for dumped tables
--

--
-- Constraints for table `booking`
--
ALTER TABLE `booking`
  ADD CONSTRAINT `booking_customer_fk` FOREIGN KEY (`customerID`) REFERENCES `customer` (`customerID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `booking_package_fk` FOREIGN KEY (`packageID`) REFERENCES `tourpackage` (`packageID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `booking_payment_fk` FOREIGN KEY (`paymentID`) REFERENCES `payment` (`paymentID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `booking_history`
--
ALTER TABLE `booking_history`
  ADD CONSTRAINT `booking_history_review` FOREIGN KEY (`reviewID`) REFERENCES `review` (`reviewID`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `favourites`
--
ALTER TABLE `favourites`
  ADD CONSTRAINT `favourites_ibfk_1` FOREIGN KEY (`customerID`) REFERENCES `customer` (`customerID`) ON DELETE CASCADE ON UPDATE CASCADE,
  ADD CONSTRAINT `favourites_ibfk_2` FOREIGN KEY (`tourPackageID`) REFERENCES `tourpackage` (`packageID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `guide`
--
ALTER TABLE `guide`
  ADD CONSTRAINT `guide_company_fk` FOREIGN KEY (`companyID`) REFERENCES `tourcompany` (`companyID`) ON DELETE CASCADE ON UPDATE CASCADE;

--
-- Constraints for table `tourpackage`
--
ALTER TABLE `tourpackage`
  ADD CONSTRAINT `package_accommodation_fk` FOREIGN KEY (`accommodationID`) REFERENCES `accommodation` (`accommodationID`) ON DELETE SET NULL,
  ADD CONSTRAINT `package_company_fk` FOREIGN KEY (`tourCompanyID`) REFERENCES `tourcompany` (`companyID`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `package_guide_fk` FOREIGN KEY (`guideID`) REFERENCES `guide` (`guideID`) ON DELETE SET NULL ON UPDATE CASCADE,
  ADD CONSTRAINT `package_transport_fk` FOREIGN KEY (`transportID`) REFERENCES `transportation` (`transportID`) ON DELETE SET NULL ON UPDATE CASCADE;

--
-- Constraints for table `tourpackage_itinerary`
--
ALTER TABLE `tourpackage_itinerary`
  ADD CONSTRAINT `tourpackage_itinerary_ibfk_1` FOREIGN KEY (`itineraryID`,`itinerary_date`,`itinerary_time_of_day`) REFERENCES `itinerary` (`itineraryID`, `date`, `time_of_day`);

--
-- Constraints for table `transportation`
--
ALTER TABLE `transportation`
  ADD CONSTRAINT `transport_company_fk` FOREIGN KEY (`companyID`) REFERENCES `tourcompany` (`companyID`) ON DELETE CASCADE ON UPDATE CASCADE;
COMMIT;

/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
