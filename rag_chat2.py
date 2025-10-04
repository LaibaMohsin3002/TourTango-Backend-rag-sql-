from sentence_transformers import SentenceTransformer
import chromadb
import openai

openai.api_key = "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"  # your key
openai.api_base = "https://openrouter.ai/api/v1"

# Init models
model = SentenceTransformer('all-MiniLM-L6-v2')
client = chromadb.Client()
collection = client.get_or_create_collection(name="tour_data")

# User query
query = input("Ask something about your tours, bookings, etc.: ")
query_embed = model.encode(query).tolist()
results = collection.query(query_embeddings=[query_embed], n_results=5)
context = "\n".join(results['documents'][0])

# OpenRouter call
response = openai.ChatCompletion.create(
  model="mistralai/mistral-7b-instruct",
  messages=[
    {"role": "system", "content": "You're a helpful tour assistant for Tour Tango. Use the provided context to answer clearly and helpfully."},
    {"role": "user", "content": f"Context:\n{context}\n\nQuestion:\n{query}"}
  ]
)

print("\nBot:", response['choices'][0]['message']['content'])
