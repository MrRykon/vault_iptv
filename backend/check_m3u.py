import urllib.request
import re

url = "https://raw.githubusercontent.com/MrRykon/vault_iptv/refs/heads/main/channels.m3u"
req = urllib.request.urlopen(url)
text = req.read().decode('utf-8')

categories = set()
for line in text.splitlines():
    if line.startswith("#EXTINF"):
        match = re.search(r'group-title="([^"]*)"', line)
        if match:
            categories.add(match.group(1))

print("EXTRACTED CATEGORIES:")
for cat in sorted(categories):
    print(cat)
