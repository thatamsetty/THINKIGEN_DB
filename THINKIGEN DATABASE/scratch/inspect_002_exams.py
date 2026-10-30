import re

with open('database/seeds/002_THINKIGEN_REALISTIC_MOCK_DATA_V22.sql', 'r', encoding='utf-8') as f:
    text = f.read()

exam_matches = re.findall(r'INSERT INTO management_schema\.exam\s*\((.*?)\)\s*VALUES\s*(.*?);', text, re.DOTALL | re.IGNORECASE)
print(f"Exams in 002: {len(exam_matches)}")
if exam_matches:
    print("Exam values:\n", exam_matches[0][1].strip()[:300])

sched_matches = re.findall(r'INSERT INTO management_schema\.exam_schedule\s*\((.*?)\)\s*VALUES\s*(.*?);', text, re.DOTALL | re.IGNORECASE)
print(f"Exam schedules in 002: {len(sched_matches)}")
if sched_matches:
    print("Sched values:\n", sched_matches[0][1].strip()[:300])
