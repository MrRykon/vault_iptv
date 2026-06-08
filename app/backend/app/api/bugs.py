from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
from app.db.database import get_db
from app.core.dependencies import get_current_user
from app.db.models import User, BugReport
from typing import Dict, Any

router = APIRouter()

@router.post("/report")
def submit_bug_report(payload: Dict[str, Any], db: Session = Depends(get_db), current_user: User = Depends(get_current_user)):
    new_bug = BugReport(
        user_id=current_user.id,
        message=payload.get("message", "Empty Report")
    )
    db.add(new_bug)
    db.commit()
    return {"message": "Bug Report transmitted securely."}

@router.get("/active")
def get_active_bugs(db: Session = Depends(get_db), admin: User = Depends(get_current_user)):
    if not admin.admin_status: return {"error": "Admin exclusively natively"}
    
    bugs = db.query(BugReport, User).join(User, BugReport.user_id == User.id).order_by(BugReport.created_at.desc()).all()
    results = []
    for b, u in bugs:
        results.append({
            "id": b.id,
            "message": b.message,
            "status": b.status,
            "created_at": b.created_at,
            "username": u.custom_username
        })
    return results
