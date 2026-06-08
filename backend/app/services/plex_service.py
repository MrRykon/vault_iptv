import httpx
from typing import List
from app.core.config import settings

kids_safe_keywords = {"kids", "children", "family", "animation"}

async def get_plex_library(profile_type: str) -> List[dict]:
    if settings.MOCK_PLEX:
        # Mock hardcoded database
        mock_items = [
            {
                "id": "mock_movie_1",
                "title": "Cosmic Adventure",
                "type": "movie",
                "poster": "placeholder_url",
                "tags": ["Action", "Sci-Fi"]
            },
            {
                "id": "mock_movie_2",
                "title": "Dark Thriller",
                "type": "movie",
                "poster": "placeholder_url",
                "tags": ["Horror", "Thriller"]
            },
            {
                "id": "mock_show_1",
                "title": "Cartoon Funtime",
                "type": "show",
                "poster": "placeholder_url",
                "tags": ["Animation", "Kids", "Family"]
            }
        ]
        
        for item in mock_items:
            item["is_kids_safe"] = any(tag.lower() in kids_safe_keywords for tag in item.get("tags", []))
        
        if profile_type == "kids":
             return [item for item in mock_items if item["is_kids_safe"]]
        return mock_items

    # ================= REAL PLEX PROXY =================
    try:
        async with httpx.AsyncClient() as client:
            headers = {"X-Plex-Token": settings.PLEX_TOKEN, "Accept": "application/json"}
            
            # Example logic pulling recently added from all libraries (simplified for abstraction)
            res = await client.get(f"{settings.PLEX_BASE_URL}/library/recentlyAdded", headers=headers, timeout=10.0)
            res.raise_for_status()
            
            data = res.json().get("MediaContainer", {})
            metadata_nodes = data.get("Metadata", [])
            
            results = []
            for node in metadata_nodes:
                # Extract genres/tags natively
                plex_genres = [gen.get("tag", "") for gen in node.get("Genre", [])]
                is_safe = any(t.lower() in kids_safe_keywords for t in plex_genres)
                
                # Exclude if profile is Kids and not safe
                if profile_type == "kids" and not is_safe:
                    continue
                    
                results.append({
                    "id": node.get("ratingKey"),
                    "title": node.get("title"),
                    "type": node.get("type"),
                    "poster": f"/plex/image?url={node.get('thumb')}", # Native proxy redirection
                    "tags": plex_genres,
                    "is_kids_safe": is_safe
                })
            return results
            
    except Exception as e:
        print(f"Plex Proxy Error: {e}")
        return []
