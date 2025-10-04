import mysql.connector

def connect_db():
    return mysql.connector.connect(
        host="localhost",
        user="root",
        password="",
        database="tourtango"
    )

def get_tour_packages():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT packageName, description FROM tourpackage")
    results = cursor.fetchall()
    cursor.close()
    db.close()
    return [f"{name}: {desc}" for name, desc in results]

def get_customers():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT customerID, name, email FROM customer")
    results = cursor.fetchall()
    cursor.close()
    db.close()
    return results

def get_bookings():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT BookingID, BookingDate, noOfPeople, packageID, customerID FROM booking")
    results = cursor.fetchall()
    cursor.close()
    db.close()
    return results

def get_booking_history():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT customer_id, packageName, start_date, end_date, booking_date, total_amount FROM booking_history")
    results = cursor.fetchall()
    cursor.close()
    db.close()
    return results

def get_favourites_by_customer(customer_id):
    db = connect_db()
    cursor = db.cursor()
    query = """
    SELECT t.packageName, t.description
    FROM favourites f
    JOIN tourpackage t ON f.tourPackageID = t.packageID
    WHERE f.customerID = %s
    """
    cursor.execute(query, (customer_id,))
    results = cursor.fetchall()
    cursor.close()
    db.close()
    return results
# ---------------------- accommodation ----------------------
def get_all_accommodation():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM accommodation")
    results = cursor.fetchall()
    db.close()
    cursor.close()
    return results

# ---------------------- booking ----------------------
def get_all_bookings():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM booking")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- booking_history ----------------------
def get_booking_history_by_customer(customer_id):
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM booking_history WHERE customer_id = %s", (customer_id,))
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- customer ----------------------
def get_all_customers():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM customer")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- customer_phonenumber ----------------------
def get_customer_phone_numbers(customer_id):
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT phoneNumber FROM customer_phonenumber WHERE customerID = %s", (customer_id,))
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- faqs ----------------------
def get_all_faqs():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM faqs")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- favourites ----------------------
def get_customer_favourites(customer_id):
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT tourPackageID FROM favourites WHERE customerID = %s", (customer_id,))
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- flight ----------------------
def get_all_flights():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM flight")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- guide ----------------------
def get_all_guides():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM guide")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- itinerary ----------------------
def get_all_itineraries():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM itinerary")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- payment ----------------------
def get_all_payments():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM payment")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- review ----------------------
def get_all_reviews():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM review")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- tourcompany ----------------------
def get_all_tour_companies():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM tourcompany")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- tourpackage ----------------------
def get_all_tour_packages():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM tourpackage")
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- tourpackage_flight ----------------------
def get_flights_for_package(package_id):
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT flightID FROM tourpackage_flight WHERE tourPackageID = %s", (package_id,))
    results = cursor.fetchall()
    db.close()
    return results

# ---------------------- tourpackage_itinerary ----------------------
def get_itinerary_for_package(package_id):
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT itineraryID, itinerary_date, itinerary_time_of_day FROM tourpackage_itinerary WHERE packageID = %s", (package_id,))
    results = cursor.fetchall()
    cursor.close()
    db.close()
    return results

# ---------------------- transportation ----------------------
def get_all_transportations():
    db = connect_db()
    cursor = db.cursor()
    cursor.execute("SELECT * FROM transportation")
    results = cursor.fetchall()
    db.close()
    return results

# def get_all_data_for_rag():
    combined_docs = []

    # Tour Packages
    for name, desc in get_tour_packages():
        combined_docs.append(f"Tour Package - {name}: {desc}")

    # FAQs
    for faq in get_all_faqs():
        combined_docs.append(f"FAQ: {faq[1]} Answer: {faq[2]}")  # question, answer

    # Reviews
    for review in get_all_reviews():
        combined_docs.append(f"Review by customer {review[1]}: {review[2]}")  # customer_id, text

    # Customers
    for cust in get_all_customers():
        combined_docs.append(f"Customer {cust[1]} with email {cust[2]} and phone {cust[3]}")  # name, email, phone

    # Accommodations
    for acc in get_all_accommodation():
        combined_docs.append(f"Accommodation: {acc[1]} in {acc[3]}, {acc[4]}, Type: {acc[2]}, Description: {acc[5]}")  # hotelName, city, country, type, description

    # Flights
    for flight in get_all_flights():
        combined_docs.append(f"Flight {flight[0]} from {flight[1]} to {flight[2]} departs at {flight[3]} and arrives at {flight[4]}")  # id, from, to, depart, arrival

    # Guides
    for guide in get_all_guides():
        combined_docs.append(f"Guide: {guide[1]}, Experience: {guide[2]} years, Language: {guide[3]}")  # name, experience, language

    # Payments
    for payment in get_all_payments():
        combined_docs.append(f"Payment of {payment[2]} made by customer {payment[1]} on {payment[3]}, Status: {payment[4]}")  # customer_id, amount, date, status

    # Bookings
    for booking in get_all_bookings():
        combined_docs.append(f"Booking ID {booking[0]}: Customer {booking[1]} booked package {booking[2]} on {booking[3]}, Status: {booking[4]}")  # id, customer_id, package_id, date, status

    # Itineraries
    for itinerary in get_all_itineraries():
        combined_docs.append(f"Itinerary for package {itinerary[1]}: Day {itinerary[2]} - {itinerary[3]}")  # package_id, day_number, description

    # Favourites
    for fav in get_customer_favourites():
        combined_docs.append(f"Customer {fav[1]} favorited package {fav[2]}")  # customer_id, package_id

    return combined_docs
