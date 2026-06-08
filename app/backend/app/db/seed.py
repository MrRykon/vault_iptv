from app.db.database import SessionLocal
from app.db.models import User
from app.core.config import settings

# Since we don't have security.py yet, use a simple pass or import later
# Wait, I shouldn't rely on it not failing if it lacks get_password_hash. I will implement a dummy or actually create core/security.py next.

def seed_admin_user():
    if not settings.SEED_ADMIN_ON_FIRST_RUN:
        return

    db = SessionLocal()
    try:
        # Check if any admin exists
        admin_exists = db.query(User).filter(User.admin_status == True).first()
        if not admin_exists:
            from app.core.security import get_password_hash
            new_admin = User(
                custom_username=settings.SEED_ADMIN_USERNAME,
                hashed_password=get_password_hash(settings.SEED_ADMIN_PASSWORD),
                display_name="Administrator",
                admin_status=True,
                account_status="active",
                profile_type="standard"
            )
            db.add(new_admin)
            db.commit()
            print("Seeded default admin user.")
    except Exception as e:
        print(f"Error seeding admin user: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_admin_user()
