from sentence_transformers import SentenceTransformer
import chromadb
from rag_fetch import (
    get_all_tour_packages, get_all_customers, get_all_bookings, get_all_flights,
    get_all_itineraries, get_all_reviews, get_all_faqs, get_all_guides,
    get_all_tour_companies, get_all_transportations, get_all_accommodation,
    get_all_payments
)

def flatten_records(name, records, columns):
    return [f"{name}: " + ", ".join(f"{col}={val}" for col, val in zip(columns, rec)) for rec in records]

# Load embedding model
model = SentenceTransformer('all-MiniLM-L6-v2')
chroma_client = chromadb.Client()
collection = chroma_client.get_or_create_collection(name="tour_data")

# Fetch and index data
data_sources = [
    ("TourPackage", get_all_tour_packages(), ["id", "name", "description", "price", "location"]),
    ("Customer", get_all_customers(), ["id", "name", "email"]),
    ("Booking", get_all_bookings(), ["booking_id", "date", "people", "package_id", "customer_id"]),
    ("Flight", get_all_flights(), ["id", "airline", "departure", "arrival"]),
    ("Itinerary", get_all_itineraries(), ["id", "date", "time_of_day", "details"]),
    ("Review", get_all_reviews(), ["review_id", "package_id", "rating", "text"]),
    ("FAQ", get_all_faqs(), ["faq_id", "question", "answer"]),
    ("Guide", get_all_guides(), ["id", "name", "languages"]),
    ("TourCompany", get_all_tour_companies(), ["id", "name", "contact"]),
    ("Transport", get_all_transportations(), ["id", "type", "capacity"]),
    ("Accommodation", get_all_accommodation(), ["id", "name", "type", "location"]),
    ("Payment", get_all_payments(), ["id", "amount", "method", "status"]),
]

docs, ids = [], []

for i, (name, records, columns) in enumerate(data_sources):
    flat_docs = flatten_records(name, records, columns)
    docs.extend(flat_docs)
    ids.extend([f"{name}_{j}" for j in range(len(records))])

embeddings = model.encode(docs).tolist()
collection.add(documents=docs, embeddings=embeddings, ids=ids)

print("✅ Indexed data from all relevant tables.")
# Manually check what is indexed
for doc in collection.get()['documents']:
    print(doc)
