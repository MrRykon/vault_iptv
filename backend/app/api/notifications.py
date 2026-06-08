from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.db.models import GlobalNotification, User

router = APIRouter()

@router.get("/")
def get_active_notifications(db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    notes = db.query(GlobalNotification).filter(GlobalNotification.is_active == True).order_by(GlobalNotification.created_at.desc()).all()
    return [{"id": n.id, "subject": n.subject, "content": n.content, "created_at": n.created_at} for n in notes]

@router.post("/")
def send_notification(subject: str, content: str, db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    if not current_user.admin_status:
        return {"error": "Admin required natively"}
    n = GlobalNotification(subject=subject, content=content)
    db.add(n)
    db.commit()
    return {"status": "sent"}
