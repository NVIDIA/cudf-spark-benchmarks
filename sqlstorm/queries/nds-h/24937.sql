
WITH RECURSIVE SupplierCTE AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE s.s_acctbal IS NOT NULL
    UNION ALL
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN SupplierCTE cte ON s.s_nationkey = cte.s_suppkey
    WHERE cte.rank > 1
),
FilteredOrders AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
      AND l.l_returnflag = 'N'
    GROUP BY o.o_orderkey
),
TopCustomers AS (
    SELECT c.c_custkey, c.c_name, COALESCE(SUM(fo.revenue), 0) AS total_revenue
    FROM customer c
    LEFT JOIN FilteredOrders fo ON c.c_custkey = fo.o_orderkey
    GROUP BY c.c_custkey, c.c_name
    HAVING COALESCE(SUM(fo.revenue), 0) > (
        SELECT AVG(total_revenue) FROM (
            SELECT SUM(fo.revenue) AS total_revenue
            FROM customer c
            LEFT JOIN FilteredOrders fo ON c.c_custkey = fo.o_orderkey
            GROUP BY c.c_custkey
        ) AS avg_revenue
    )
)
SELECT DISTINCT p.p_name, r.r_name, 
       SUM(sct.ps_availqty) AS total_available_quantity,
       SUM(sct.ps_supplycost) AS total_supply_cost, 
       tc.total_revenue
FROM part p
JOIN partsupp sct ON p.p_partkey = sct.ps_partkey
JOIN nation n ON sct.ps_suppkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN TopCustomers tc ON n.n_nationkey = tc.c_custkey
WHERE p.p_size BETWEEN 10 AND 20
  AND r.r_comment NOT LIKE '%test%'
GROUP BY p.p_name, r.r_name, tc.total_revenue
HAVING COUNT(DISTINCT sct.ps_suppkey) > 5
ORDER BY total_available_quantity DESC, total_supply_cost ASC
LIMIT 10;
