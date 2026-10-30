
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 0 AS level
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL

    UNION ALL

    SELECT s.s_suppkey, s.s_name, s.s_acctbal, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_suppkey = sh.s_suppkey
    WHERE sh.level < 5
),
SalesSummary AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_revenue,
        AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY c.c_nationkey
),
PartSupplier AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE ps.ps_availqty > 0
),
FilteredNation AS (
    SELECT 
        n.n_nationkey, 
        n.n_name
    FROM nation n
    WHERE n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Europe%')
)
SELECT 
    fn.n_name,
    SUM(ss.total_orders) AS total_orders,
    SUM(ss.total_revenue) AS total_revenue,
    COUNT(DISTINCT p.p_partkey) AS distinct_parts,
    AVG(p.ps_supplycost) AS avg_supply_cost,
    MAX(s.s_acctbal) AS max_supplier_balance
FROM FilteredNation fn
LEFT JOIN SalesSummary ss ON fn.n_nationkey = ss.c_nationkey
LEFT JOIN PartSupplier p ON p.rn = 1
LEFT JOIN supplier s ON s.s_suppkey = p.p_partkey
GROUP BY fn.n_name
HAVING SUM(ss.total_revenue) > 1000000
ORDER BY total_orders DESC
LIMIT 10 OFFSET 10;
