WITH RegionalSupplierTotals AS (
    SELECT r.r_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name, s.s_nationkey
),
TopRegions AS (
    SELECT r_name, DENSE_RANK() OVER (ORDER BY SUM(total_supply_cost) DESC) AS region_rank
    FROM RegionalSupplierTotals
    GROUP BY r_name
)
SELECT c.c_custkey, c.c_name, c.c_acctbal, 
       SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) ELSE 0 END) AS total_returned,
       CASE WHEN c.c_acctbal IS NULL THEN 'No Balance' ELSE 'Has Balance' END AS balance_status,
       T.r_name
FROM customer c
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN TopRegions T ON T.r_name IN (
    SELECT r.r_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY r.r_name, s.s_nationkey
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 1000000
)
GROUP BY c.c_custkey, c.c_name, c.c_acctbal, T.r_name
HAVING SUM(l.l_extendedprice) > 5000
ORDER BY c.c_custkey;
