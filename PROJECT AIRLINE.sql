CREATE DATABASE AIRLINE;
USE AIRLINE;

1)SCHEMA DESIGN

CREATE TABLE Flights (
  flight_id INT AUTO_INCREMENT PRIMARY KEY,
  flight_number VARCHAR(10) NOT NULL UNIQUE,
  origin VARCHAR(50) NOT NULL,
  destination VARCHAR(50) NOT NULL,
  departure_time DATETIME NOT NULL,
  arrival_time DATETIME NOT NULL
);

CREATE TABLE Customers (
  customer_id INT AUTO_INCREMENT PRIMARY KEY,
  first_name VARCHAR(50),
  last_name VARCHAR(50),
  email VARCHAR(100) UNIQUE,
  phone VARCHAR(20)
);

CREATE TABLE Seats (
  seat_id INT AUTO_INCREMENT PRIMARY KEY,
  flight_id INT NOT NULL,
  seat_no VARCHAR(5) NOT NULL,
  status ENUM('free','reserved','booked') NOT NULL DEFAULT 'free',
  customer_id INT DEFAULT NULL,
  UNIQUE(flight_id, seat_no),
  FOREIGN KEY (flight_id) REFERENCES Flights(flight_id)
    ON DELETE CASCADE,
  FOREIGN KEY (customer_id) REFERENCES Customers(customer_id)
    ON DELETE SET NULL
);

CREATE TABLE Bookings (
  booking_id INT AUTO_INCREMENT PRIMARY KEY,
  flight_id INT NOT NULL,
  customer_id INT NOT NULL,
  seat_id INT NOT NULL,
  booking_time DATETIME NOT NULL DEFAULT NOW(),
  status ENUM('active','cancelled') NOT NULL DEFAULT 'active',
  FOREIGN KEY (flight_id) REFERENCES Flights(flight_id),
  FOREIGN KEY (customer_id) REFERENCES Customers(customer_id),
  FOREIGN KEY (seat_id) REFERENCES Seats(seat_id)
);

2) INSERTING DATA

INSERT INTO Flights (flight_number, origin, destination, departure_time, arrival_time) VALUES
('AI101','DEL','BOM','2025-07-15 08:00:00','2025-07-15 10:00:00'),
('AI102','BOM','DEL','2025-07-16 15:00:00','2025-07-16 17:00:00');

INSERT INTO Customers (first_name, last_name, email, phone) VALUES
('Amit','Sharma','amit@example.com','9810000001'),
('Neha','Kaur','neha@example.com','9810000002');

INSERT INTO Seats (flight_id, seat_no)
SELECT f.flight_id, CONCAT('A', n)
FROM Flights f
JOIN (SELECT 1 n UNION ALL SELECT 2 UNION ALL SELECT 3 UNION ALL SELECT 4 UNION ALL SELECT 5) nums
;

INSERT INTO Bookings (flight_id, customer_id, seat_id)
VALUES (
  (SELECT flight_id FROM Flights WHERE flight_number='AI101'),
  (SELECT customer_id FROM Customers WHERE email='amit@example.com'),
  (SELECT seat_id FROM Seats WHERE flight_id=(SELECT flight_id FROM Flights WHERE flight_number='AI101') AND seat_no='A1')
);


3) VIEWS AND QUERIES
a) Available Seats View
CREATE VIEW AvailableSeats AS
SELECT f.flight_number, s.seat_no
FROM Seats s JOIN Flights f USING(flight_id)
WHERE s.status = 'free';

b) Flight search with free seats
SELECT f.flight_id, f.flight_number, f.origin, f.destination, f.departure_time,
       COUNT(s.seat_id) AS free_seats
FROM Flights f
LEFT JOIN Seats s ON f.flight_id = s.flight_id AND s.status = 'free'
GROUP BY f.flight_id
HAVING free_seats > 0;

4)TRIGGERS FOR BOOKING AND CANCELLATION
DELIMITER $$
CREATE TRIGGER trg_after_booking_insert
AFTER INSERT ON Bookings
FOR EACH ROW
BEGIN
  UPDATE Seats
    SET status = 'booked', customer_id = NEW.customer_id
  WHERE seat_id = NEW.seat_id;
END$$

CREATE TRIGGER trg_after_booking_update
AFTER UPDATE ON Bookings
FOR EACH ROW
BEGIN
  IF NEW.status = 'cancelled' AND OLD.status = 'active' THEN
    UPDATE Seats
      SET status = 'free', customer_id = NULL
    WHERE seat_id = NEW.seat_id;
  END IF;
END$$
DELIMITER ;

5) BOOKING SUMMARY REPORT
SELECT b.booking_id, c.first_name, c.last_name,
       f.flight_number, f.origin, f.destination, s.seat_no,
       b.booking_time, b.status
FROM Bookings b
JOIN Customers c USING(customer_id)
JOIN Flights f USING(flight_id)
JOIN Seats s USING(seat_id)
ORDER BY b.booking_time DESC;

