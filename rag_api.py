from flask import Flask, request, jsonify
from sentence_transformers import SentenceTransformer
import chromadb
from rag_index import collection  # your indexed ChromaDB collection
import openai

# Initialize Flask and models
app = Flask(__name__)
model = SentenceTransformer('all-MiniLM-L6-v2')

# Set up OpenAI/OpenRouter API
openai.api_key = "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"
openai.api_base = "https://openrouter.ai/api/v1"  # Use your actual base if different

@app.route("/chat", methods=["POST"])
def chat():
    user_input = request.json.get("message")
    
    # Encode user query
    embedding = model.encode(user_input).tolist()
    
    # Retrieve context from ChromaDB
    results = collection.query(query_embeddings=[embedding], n_results=5)
    context = "\n".join(results['documents'][0])  # Join top retrieved documents
    
    # Generate chat response using LLM
    response = openai.ChatCompletion.create(
        model="mistralai/mistral-7b-instruct",
        messages=[
            {"role": "system", "content": "You're a helpful tour assistant for Tour Tango. Use the provided context to answer clearly and helpfully."},
            {"role": "user", "content": f"Context:\n{context}\n\nQuestion:\n{user_input}"}
        ]
    )
    
    return jsonify({"response": response['choices'][0]['message']['content']})

if __name__ == "__main__":
    app.run(debug=True)
