
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part AS p
    WHERE p.p_retailprice IS NOT NULL
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUBSTRING(s.s_comment, 1, 20) AS short_comment
    FROM supplier AS s
    WHERE s.s_acctbal > (
        SELECT AVG(s2.s_acctbal)
        FROM supplier AS s2
        WHERE s2.s_nationkey IN (
            SELECT n.n_nationkey
            FROM nation AS n
            WHERE n.n_name LIKE 'A%'
        )
    )
),
JoinResults AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_availqty,
        COALESCE(ps.ps_supplycost, 0) AS supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS supplier_rank
    FROM RankedParts AS p
    LEFT OUTER JOIN partsupp AS ps ON p.p_partkey = ps.ps_partkey
    WHERE p.price_rank <= 3
),
FinalResults AS (
    SELECT 
        j.p_partkey,
        j.p_name,
        j.ps_availqty,
        j.supplycost,
        s.s_name AS supplier_name
    FROM JoinResults AS j
    LEFT JOIN HighValueSuppliers AS s ON j.supplier_rank = s.s_suppkey
    WHERE j.ps_availqty > (
        SELECT AVG(ps2.ps_availqty)
        FROM partsupp AS ps2
        WHERE ps2.ps_partkey = j.p_partkey
    ) OR j.supplycost IS NULL
)
SELECT 
    DISTINCT f.p_partkey,
    f.p_name,
    COALESCE(f.ps_availqty, 0) AS availability,
    CASE 
        WHEN f.supplier_name IS NOT NULL THEN f.supplier_name
        ELSE 'No Supplier'
    END AS supplier_name
FROM FinalResults AS f
WHERE f.p_partkey IN (
    SELECT l.l_partkey
    FROM lineitem AS l
    WHERE l.l_returnflag = 'N'
)
ORDER BY f.p_partkey DESC, availability ASC;
