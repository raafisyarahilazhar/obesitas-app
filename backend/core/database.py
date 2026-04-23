from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker, declarative_base

# Format URL: mysql+pymysql://<username>:<password>@<host>:<port>/<nama_database>
# Contoh di bawah jika pakai XAMPP (username: root, password: [kosong])
SQLALCHEMY_DATABASE_URL = "mysql+pymysql://root:@localhost:3306/foodscan_obesity"

# Untuk MySQL, kita tidak perlu check_same_thread=False
engine = create_engine(SQLALCHEMY_DATABASE_URL)

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
Base = declarative_base()

# Dependency untuk dipanggil di setiap endpoint
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()