WITH  SupplyCTE AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ps.ps_partkey,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
),
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        o.o_orderdate,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationSupplier AS (
    SELECT 
        n.n_name, 
        SUM(s.s_acctbal) AS total_acctbal
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY n.n_name
)
SELECT 
    p.p_name,
    p.p_brand,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    COALESCE(SUM(CASE WHEN fs.rn = 1 THEN fs.ps_supplycost END), 0) AS min_supply_cost,
    ns.total_acctbal
FROM part p
LEFT JOIN SupplyCTE fs ON p.p_partkey = fs.ps_partkey
LEFT JOIN FilteredOrders o ON p.p_partkey = o.o_orderkey
LEFT JOIN NationSupplier ns ON p.p_brand = ns.n_name
WHERE p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
AND (p.p_container IN ('SM CASE', 'MED BOX') OR p.p_size BETWEEN 1 AND 10)
GROUP BY p.p_name, p.p_brand, ns.total_acctbal
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_acctbal DESC, order_count DESC;
