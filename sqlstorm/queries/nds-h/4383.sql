WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as rn
    FROM orders o
),
SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           SUM(ps.ps_availqty) AS total_available,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
),
RecentOrders AS (
    SELECT ro.*, c.c_name, c.c_acctbal, 
           CASE 
               WHEN c.c_acctbal IS NULL THEN 'No Balance'
               WHEN c.c_acctbal < 1000 THEN 'Low Balance'
               ELSE 'Good Balance'
           END AS balance_status
    FROM RankedOrders ro
    JOIN customer c ON ro.o_custkey = c.c_custkey
    WHERE ro.rn = 1
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.o_totalprice,
    r.c_name,
    r.balance_status,
    si.s_name AS supplier_name,
    si.total_available,
    si.avg_supply_cost,
    (r.o_totalprice / NULLIF(si.avg_supply_cost, 0)) AS price_supply_ratio
FROM RecentOrders r
LEFT JOIN SupplierInfo si ON r.o_custkey = si.s_suppkey
WHERE r.o_totalprice > 5000
ORDER BY r.o_orderdate DESC, price_supply_ratio DESC
LIMIT 100;
