# rag_chatbot.py

import chromadb
from sentence_transformers import SentenceTransformer
import requests

# Load model and connect to Chroma
model = SentenceTransformer("all-MiniLM-L6-v2")
chroma_client = chromadb.Client()
collection = chroma_client.get_or_create_collection(name="tour_data")

# Your OpenRouter key
OPENROUTER_API_KEY = "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"

def ask_chatbot(question):
    # Embed the user question
    embedding = model.encode(question).tolist()
    
    # Retrieve top 5 relevant docs
    results = collection.query(
        query_embeddings=[embedding],
        n_results=5
    )
    context = "\n".join(results["documents"][0])
    
    # Prepare the prompt
    prompt = f"""You are a helpful travel assistant. Use only the info below to answer.
Context:
{context}

Question: {question}
Answer:"""

    # Send to OpenRouter
    response = requests.post(
        "https://openrouter.ai/api/v1/chat/completions",
        headers={
            "Authorization": f"Bearer {OPENROUTER_API_KEY}",
            "Content-Type": "application/json"
        },
        json={
            "model": "openai/gpt-3.5-turbo",  # Or other available model
            "messages": [
                {"role": "user", "content": prompt}
            ]
        }
    )
    print("Raw response:", response.json())
    return response.json()["choices"][0]["message"]["content"]

# --- Test it ---
if __name__ == "__main__":
    while True:
        q = input("Ask me: ")
        if q.lower() in ["exit", "quit"]:
            break
        answer = ask_chatbot(q)
        print(f"\n🧠 Answer: {answer}\n")
