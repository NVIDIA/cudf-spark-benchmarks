WITH  SalesCTE AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus IN ('O', 'F') AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
), DistinctSuppliers AS (
    SELECT 
        DISTINCT s.s_suppkey,
        CASE 
            WHEN s.s_acctbal IS NULL THEN 'No Balance'
            WHEN s.s_acctbal < 500 THEN 'Low Balance'
            ELSE 'Adequate Balance'
        END AS balance_status
    FROM supplier s
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty IS NOT NULL
), MaxRevenue AS (
    SELECT 
        MAX(revenue) AS max_revenue 
    FROM SalesCTE
    WHERE rn = 1
), FilteredCustomers AS (
    SELECT DISTINCT c.c_custkey, c.c_name
    FROM customer c
    WHERE c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2 WHERE c2.c_nationkey = c.c_nationkey)
    AND c.c_mktsegment IN ('BUILDING', 'AUTOMOBILE')
)
SELECT 
    r.r_name AS region_name,
    COUNT(DISTINCT ns.n_nationkey) AS nation_count,
    SUM(COALESCE(ps.ps_supplycost, 0)) AS total_supply_cost,
    (SELECT COUNT(*) FROM FilteredCustomers) AS total_filtered_customers,
    (SELECT COUNT(*) FROM MaxRevenue WHERE max_revenue > 10000) AS high_revenue_orders
FROM region r
LEFT JOIN nation ns ON r.r_regionkey = ns.n_regionkey
LEFT JOIN supplier s ON s.s_nationkey = ns.n_nationkey
LEFT JOIN partsupp ps ON ps.ps_suppkey = s.s_suppkey
WHERE r.r_name LIKE 'Eu%'
GROUP BY r.r_name
HAVING COUNT(ns.n_nationkey) > 1
ORDER BY total_supply_cost DESC
LIMIT 10;
