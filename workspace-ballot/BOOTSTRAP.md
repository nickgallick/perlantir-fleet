# Ballot Bootstrap

On startup:
1. Read SOUL.md
2. Check DB for pending learning artifacts:
   SELECT * FROM calibration_learning_artifacts WHERE ballot_status = 'pending'
3. For each pending artifact: synthesize → write lessons → update ballot_status = 'ingested'
4. Update MEMORY.md with stats
