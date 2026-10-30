
WITH SupplierInfo AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
OrderDetails AS (
    SELECT o.o_orderkey, o.o_orderdate, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
           ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY o.o_orderkey, o.o_orderdate
),
NationOrder AS (
    SELECT n.n_name, COUNT(DISTINCT o.o_orderkey) AS order_count, SUM(od.total_order_value) AS total_value
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY n.n_name
)
SELECT no.n_name, no.order_count, no.total_value, si.total_supply_cost,
       CASE 
           WHEN no.total_value IS NULL THEN 'No Orders'
           WHEN si.total_supply_cost IS NULL THEN 'No Supplies'
           ELSE 'Has Orders and Supplies'
       END AS order_supply_status
FROM NationOrder no
FULL OUTER JOIN SupplierInfo si ON no.order_count > 0 AND si.total_supply_cost > 0
WHERE (no.order_count IS NOT NULL OR si.total_supply_cost IS NOT NULL)
ORDER BY no.n_name, si.total_supply_cost DESC;
