WITH  SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY o.o_orderdate DESC) AS rn
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'F' AND o.o_totalprice > 1000
),
RecentSupplierOrders AS (
    SELECT s_name, o_orderkey, o_orderdate, o_totalprice
    FROM SupplierOrders
    WHERE rn = 1
),
AggregatedOrders AS (
    SELECT so.s_name, COUNT(so.o_orderkey) AS total_orders,
           SUM(so.o_totalprice) AS total_spent
    FROM RecentSupplierOrders so
    GROUP BY so.s_name
)
SELECT a.s_name, a.total_orders, a.total_spent, r.r_name
FROM AggregatedOrders a
LEFT JOIN supplier s ON a.s_name = s.s_name
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE a.total_spent > (SELECT AVG(total_spent) FROM AggregatedOrders) 
  AND r.r_name IS NOT NULL 
ORDER BY a.total_spent DESC
LIMIT 10;


