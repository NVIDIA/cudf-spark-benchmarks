
WITH RankedOrders AS (
    SELECT 
        o_orderkey,
        o_custkey,
        o_totalprice,
        o_orderdate,
        ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS rn
    FROM orders
    WHERE o_orderstatus = 'O'
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    GROUP BY s.s_suppkey, s.s_name
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(p.p_retailprice, 0) AS retail_price_adj,
        CASE 
            WHEN p.p_size IS NULL THEN 'UNDEFINED'
            WHEN p.p_size < 10 THEN 'SMALL'
            WHEN p.p_size BETWEEN 10 AND 20 THEN 'MEDIUM'
            ELSE 'LARGE'
        END AS size_category
    FROM part p
    WHERE p.p_comment LIKE '%discount%'
),
JoinAggregates AS (
    SELECT 
        r.r_name,
        COUNT(DISTINCT n.n_nationkey) AS nation_count,
        AVG(sd.total_supplycost) AS avg_supplycost
    FROM region r
    LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
    LEFT JOIN SupplierDetails sd ON n.n_nationkey = sd.s_suppkey
    GROUP BY r.r_name
)
SELECT 
    fo.p_name,
    fo.size_category,
    jo.r_name,
    jo.nation_count,
    jo.avg_supplycost,
    o.o_orderdate,
    fro.total_price AS recent_order_price
FROM FilteredParts fo
JOIN JoinAggregates jo ON fo.p_partkey IN (
    SELECT ps.ps_partkey 
    FROM partsupp ps 
    WHERE ps.ps_availqty >= (
        SELECT AVG(ps_availqty) FROM partsupp
    )
)
LEFT JOIN RankedOrders o ON fo.p_partkey = o.o_custkey 
LEFT JOIN (
    SELECT 
        c.c_custkey, 
        SUM(o.o_totalprice) AS total_price
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '30 days'
    GROUP BY c.c_custkey
) fro ON o.o_custkey = fro.c_custkey
WHERE fo.retail_price_adj > 100
AND jo.avg_supplycost IS NOT NULL
ORDER BY jo.nation_count DESC, fro.total_price DESC
LIMIT 50;
