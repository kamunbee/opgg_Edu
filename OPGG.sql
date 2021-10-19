# 1. 패치 버전 및 패치 날짜를 출력하는 쿼리 작성
# 출력 컬럼: `lolVersionHistory` 테이블에 있는 모든 컬럼
EXPLAIN
SELECT *
FROM lolVersionHistory FORCE INDEX(`date`);
                        # 인덱스 안태워도 상관없음 어차피 다 가져올거니까
# 2.  본인 계정 닉네임(혹은 'Hide on bush')에 대한 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사 id, 소환사 닉네임
#EXPLAIN
SELECT id, name
FROM opSummoner o FORCE INDEX(ix_name)
WHERE o.name = '으른고양이';
# 침착하자 동주야 = 1902775
# 으른고양이     = 5162983

# 3.  summornerId= 4460427인 플레이어가 플레이한 게임 정보를 10개만 출력하는 쿼리 작성
# 출력 컬럼 : 게임id, 챔피언 id, 포지션, 승패
EXPLAIN
SELECT gameId, championId, position, result
FROM p_opGameStats p FORCE INDEX(ix_summonerId_createDate)
WHERE p.summonerId =4460427
LIMIT 10;


# 4. 자유랭크 랭킹 1~20위의 랭크 정보를 출력하는 쿼리 작성
# 출력 컬럼 : 소환사id, 포인트(LP), 승리 수, 패배 수
EXPLAIN
SELECT summonerId, leaguePoints, wins, losses
FROM opSummonerLeague
WHERE queueType = 'RANKED_FLEX_SR'
AND tier = 'CHALLENGER'
AND `rank` = 1             # 이게 없어도 크게 상관은 없는데 인덱싱을 다 활용하기위해 추가한 조건
ORDER BY leaguePoints DESC
LIMIT 20;


# 5. 솔로랭크 티어, 랭크별로 소환사 수 출력하는 쿼리 작성
# 출력 컬럼 : 티어, 랭크, 유저 수 (userCount)
# `tier` 컬럼은 단순 CHARACTER가 아니라 ordering이 된 특수한 데이터 타입입니다.
# 높은 티어 (챌린저 > 그랜드 마스터> ...), 높은 랭크(1>2>3>4)가 위에 출력되도록 하세요.
EXPLAIN
SELECT tier, `rank`, COUNT(*) AS userCount
FROM opSummonerLeague o
WHERE o.queueType = 'RANKED_SOLO_5x5'
GROUP BY tier, `rank`
ORDER BY tier DESC,`rank`;
# COUNT(*) 로 row 수를 셀 수있음



# 6. 솔로랭크 티어, 랭크별로 승급전 진행 중인 유저 수를 출력하는 쿼리 작성
# 출력 컬럼: 티어, 랭크, 유저 수(userCount)
# 높은 티어(챌린저>그랜드마스터>...), 높은 랭크(1>2>3>4)가 위에 출력되게 하세요.
# HAVING을 사용하는 쿼리, HAVING을 사용하지 않는 쿼리를 둘 다 작성하세요.

# HAVING 없음
EXPLAIN
SELECT tier, `rank`, COUNT(*) AS userCount
FROM opSummonerLeague o
WHERE o.queueType = 'RANKED_SOLO_5x5'
AND o.seriesTarget IS NOT NULL
GROUP BY tier ,`rank`
ORDER BY tier DESC;

# HAVING
SELECT tier, `rank`, COUNT(seriesTarget) AS userCount
FROM opSummonerLeague o
WHERE o.queueType = 'RANKED_SOLO_5x5'
AND o.leaguePoints = 100
GROUP BY tier ,`rank`
HAVING userCount > 0
ORDER BY tier DESC;



# 7. 닉네임이 'Hide on'으로 시작하거나 'SKT T1'으로 시작하는 계정 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 소환사 닉네임
# 각 분류마다 10개씩만 출력하세요. 총 20개 (Hide on ## 10개 + SKT T1 ## 10개)
# SUBSTRING을 사용하지 말고 작성하세요.

EXPLAIN
(SELECT id, name
 FROM opSummoner o
 WHERE o.name like ('Hide on%')
LIMIT 10)
UNION
(SELECT id, name
FROM opSummoner o
WHERE o.name like ('SKT T1%')
LIMIT 10);

# SUBSTRING을 쓰면 안되는 이유가 연산하느라 인덱스를 못잡게되서
# %가 뒤에 오는건 상관없는데 앞으로 가면 인덱스를 못잡음
# NAME 이 연산해야해서


# 8. 솔로랭크 랭킹 1~10위의 랭크 정보를 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 티어, 랭크, LP, 판 수(gameCount), 승률(Winrate)

EXPLAIN
SELECT o.summonerId, s.name, o.tier, o.`rank`, o.leaguePoints,
       o.wins + o.losses AS gameCount, o.wins/(o.wins + o.losses) *100 AS Winrate
FROM opSummonerLeague o
INNER JOIN opSummoner s
ON o.summonerId = s.id
WHERE o.queueType = 'RANKED_SOLO_5x5'
AND o.tier = 'CHALLENGER'
ORDER BY o.leaguePoints DESC
LIMIT 10;



# 9. 8번 문제에 나온 10명의 광복절 연휴(2021년 8월 14일~2021년 8월 16일) 승률을 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 판 수(gameCount), 승률(Winrate)
# 다시하기 게임 제외합니다.

SELECT o.summonerId, s.name, count(p.result) AS gameCount,
       count(if(result = 'WIN',1,NULL))/COUNT(p.result) * 100 AS Winrate
FROM opSummonerLeague o
INNER JOIN opSummoner s
ON o.summonerId = s.id
INNER JOIN p_opGameStats p
ON p.summonerId = s.id
WHERE o.queueType = 'RANKED_SOLO_5x5'
AND o.tier = 'CHALLENGER'
AND p.createDate > '2021-08-14 00:00:00'
AND p.createDate < '2021-08-17 00:00:00'
AND result != 'UNKNOWN'
GROUP BY s.name, leaguePoints
ORDER BY o.leaguePoints DESC
LIMIT 10;



# 10. 챌린저 300명에 대해 솔로랭크 게임당 용 처치 수를 내림차순으로 출력하는 쿼리 작성
# 출력 컬럼: 소환사id, 닉네임, 게임당 용 처치 수(AvgDragonKills)
# 다시하기 게임 제외합니다.

# EXPLAIN
SELECT id, name, avg(dragonKills) AS AvgDragonKills
FROM opSummonerLeague l
INNER JOIN opSummoner s
ON l.summonerId = s.id
INNER JOIN p_opGameStats p
ON p.summonerId = s.id
INNER JOIN opGame oG
ON oG.gameId = p.gameId
INNER JOIN opGameTeam oGT
ON (oGT.gameId = oG.gameId AND p.teamId = oGT.teamId)

WHERE l.queueType = 'RANKED_SOLO_5x5'
AND l.tier = 'CHALLENGER'
AND `rank` = 1
AND result != 'UNKNOWN'
AND oG.subType = 420
GROUP BY l.summonerId
ORDER BY AvgDragonKills DESC
LIMIT 300;




# 11. 마스터 이상 소환사가 포함된 솔로 랭크 게임에서 챔피언별로 밴된 횟수(banCount)를 출력하는 쿼리 작성
# 출력 컬럼: 챔피언id, 밴된 횟수(banCount)
# `p_opGameStats`의 `tierRank` 대신 opSummonerLeague의 `tier` 정보를 이용하세요.
# 다시하기 게임 제외합니다.
# banCount 내림차순으로 정렬하세요.
# Subquery를 사용하는 쿼리, 사용하지 않는 쿼리를 둘 다 작성하세요.

SELECT oBC.championId, count(DISTINCT(oBC.gameId)) AS banCount
FROM opSummonerLeague l
INNER JOIN opSummoner s
ON l.summonerId = s.id
INNER JOIN p_opGameStats p
ON p.summonerId = s.id
INNER JOIN opGame oG
ON oG.gameId = p.gameId
INNER JOIN opBannedChampion oBC
ON oG.gameId = oBC.gameId

WHERE l.queueType = 'RANKED_SOLO_5x5'
AND l.tier IN ('CHALLENGER','GRANDMASTER','MASTER')
AND `rank` = 1
AND result != 'UNKNOWN'
AND oG.subType = 420
GROUP BY oBC.championId
ORDER BY banCount DESC ;

# Subquert 사용
SELECT  b.championId, COUNT(*) AS banCount
FROM opBannedChampion b
WHERE gameID IN(
    SELECT DISTINCT (p.gameID)
    FROM p_opGameStats p
    INNER JOIN opSummonerLeague l
    ON p.summonerId = l.summonerId
    INNER JOIN opGame o
    ON p.gameId = o.gameId
    WHERE subType = 420
    AND result != 'UNKNOWN'
    AND queueType = 'RANKED_SOLO_5x5'
    AND l.tier IN ('CHALLENGER','GRANDMASTER','MASTER')
    )
GROUP BY b.championId
ORDER BY banCount DESC;


# 12. 2021년 8월 18일 솔로 랭크 게임에서 각 챔피언의 픽 횟수, 승률, KDA 출력
# 출력 컬럼: 챔피언id, 픽된 횟수(pickCount), KDA
# 다시하기 게임 제외합니다.
# pickCount 내림차순으로 정렬하세요.
# KDA = (KILL + ASSIST) / DEATH