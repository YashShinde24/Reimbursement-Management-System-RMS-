from sqlalchemy import Column, Integer, String, Float
from database import Base

class Claim(Base):
    __tablename__ = "claims"

    id = Column(Integer, primary_key=True, index=True)
    title = Column(String)
    category = Column(String)
    amount = Column(Float)
    date = Column(String)
    description = Column(String)
<<<<<<< HEAD
    status = Column(String, default="pending")
=======
    status = Column(String, default="pending")
    comment = Column(String, nullable=True)
>>>>>>> 8489bb5 (Edited Submit Model)
