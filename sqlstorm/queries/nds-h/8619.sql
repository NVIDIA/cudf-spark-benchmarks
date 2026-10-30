
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
), BestRegions AS (
    SELECT n.n_nationkey, r.r_regionkey, RANK() OVER (PARTITION BY r.r_regionkey ORDER BY SUM(order_total) DESC) AS rank
    FROM (
        SELECT o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total
        FROM orders o
        JOIN lineitem l ON o.o_orderkey = l.l_orderkey
        GROUP BY o.o_custkey
    ) AS customer_orders
    JOIN customer c ON customer_orders.o_custkey = c.c_custkey
    JOIN nation n ON c.c_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    GROUP BY n.n_nationkey, r.r_regionkey
)
SELECT r.r_name, rs.s_name, rs.total_cost
FROM RankedSuppliers rs
JOIN nation n ON rs.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE EXISTS (
    SELECT 1
    FROM BestRegions br
    WHERE br.n_nationkey = n.n_nationkey 
      AND br.r_regionkey = r.r_regionkey 
      AND br.rank = 1
)
ORDER BY r.r_name, rs.total_cost DESC
LIMIT 10;
