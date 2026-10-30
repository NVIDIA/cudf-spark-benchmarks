
WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        p.p_type, 
        p.p_size,
        p.p_retailprice,
        p.p_comment,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS rn
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 20
),
RecentOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        o.o_custkey,
        o.o_comment,
        RANK() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '6 months'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
    HAVING AVG(ps.ps_supplycost) > 100
),
CombinedResults AS (
    SELECT 
        rp.p_name,
        ro.o_orderkey,
        ro.o_totalprice,
        sd.s_name,
        COALESCE(NULLIF(rp.p_comment, ''), 'No Comment') AS p_comment_info,
        ROW_NUMBER() OVER (PARTITION BY ro.o_orderkey ORDER BY rp.p_retailprice ASC) AS part_rank
    FROM RankedParts rp
    JOIN RecentOrders ro ON ro.o_custkey IN (
        SELECT c.c_custkey FROM customer c WHERE c.c_acctbal > 5000
    )
    LEFT JOIN partsupp ps ON rp.p_partkey = ps.ps_partkey
    LEFT JOIN supplier sd ON ps.ps_suppkey = sd.s_suppkey
)
SELECT 
    cr.p_name,
    cr.o_orderkey,
    cr.o_totalprice,
    cr.s_name,
    cr.p_comment_info,
    cr.part_rank
FROM CombinedResults cr
WHERE cr.part_rank = 1
AND cr.o_totalprice BETWEEN (SELECT AVG(o_totalprice) FROM orders) * 0.8 
                       AND (SELECT AVG(o_totalprice) FROM orders) * 1.2
ORDER BY cr.o_orderkey DESC, cr.p_name ASC
LIMIT 10;
