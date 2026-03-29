from fastapi import FastAPI, Depends
from sqlalchemy.orm import Session
from database import engine, SessionLocal, Base
from models import Claim
from fastapi.middleware.cors import CORSMiddleware

app = FastAPI()

# ✅ Allow frontend to connect
app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

# ✅ Create tables
Base.metadata.create_all(bind=engine)

# ✅ DB connection
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# ✅ Submit Claim API
@app.post("/claims")
def create_claim(data: dict, db: Session = Depends(get_db)):
    claim = Claim(**data)
    db.add(claim)
    db.commit()
    db.refresh(claim)
    return {"message": "Claim submitted successfully"}

@app.get("/claims")
def get_claims(db: Session = Depends(get_db)):
    return db.query(Claim).all()