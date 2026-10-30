
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS price_rank
    FROM part p
    WHERE p.p_retailprice > (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
),
SupplierWithHighBalance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS bal_rank
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2)
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year
    FROM orders o
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
)
SELECT 
    r.r_name AS region,
    np.n_name AS nation,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    CONCAT('Total Revenue from ', COUNT(DISTINCT c.c_custkey), ' unique customers in ', r.r_name) AS revenue_summary 
FROM region r
JOIN nation np ON r.r_regionkey = np.n_regionkey
LEFT JOIN supplier s ON np.n_nationkey = s.s_nationkey 
LEFT JOIN lineitem l ON s.s_suppkey = l.l_suppkey 
LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey 
LEFT JOIN customer c ON o.o_custkey = c.c_custkey
WHERE EXISTS (
    SELECT 1 FROM RankedParts rp 
    WHERE rp.p_partkey = l.l_partkey AND rp.price_rank <= 5
)
AND np.n_name NOT IN (SELECT DISTINCT n.n_name FROM nation n WHERE n.n_comment LIKE '%obsolete%')
GROUP BY r.r_name, np.n_name
HAVING COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) > (
    SELECT AVG(total_revenue) FROM (
        SELECT 
            SUM(l2.l_extendedprice * (1 - l2.l_discount)) AS total_revenue
        FROM lineitem l2 
        JOIN orders o2 ON l2.l_orderkey = o2.o_orderkey 
        GROUP BY o2.o_orderkey
    ) AS revenue_stats
)
ORDER BY total_revenue DESC
LIMIT 10;
