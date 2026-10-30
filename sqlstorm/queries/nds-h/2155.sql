
WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (
        SELECT AVG(total_supply_value)
        FROM (
            SELECT SUM(ps_supplycost * ps_availqty) AS total_supply_value
            FROM partsupp
            GROUP BY ps_suppkey
        ) AS AverageSupplier
    )
),
RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, o.o_orderdate, o.o_orderstatus
    FROM orders o
    WHERE o.o_orderdate >= CURRENT_DATE - INTERVAL '90 days'
),
OrderDetails AS (
    SELECT lo.l_orderkey, lo.l_partkey, lo.l_suppkey, lo.l_quantity, lo.l_extendedprice, lo.l_discount,
           RANK() OVER (PARTITION BY lo.l_orderkey ORDER BY lo.l_linenumber) AS line_rank
    FROM lineitem lo
    JOIN RecentOrders ro ON lo.l_orderkey = ro.o_orderkey
)
SELECT 
    ns.n_name AS nation, 
    COUNT(DISTINCT c.c_custkey) AS customer_count, 
    SUM(od.l_extendedprice * (1 - od.l_discount)) AS total_revenue,
    AVG(od.l_quantity) AS avg_quantity_per_line,
    MAX(od.l_extendedprice * (1 - od.l_discount)) AS max_revenue_per_line
FROM customer c
JOIN nation ns ON c.c_nationkey = ns.n_nationkey
JOIN RecentOrders ro ON c.c_custkey = ro.o_custkey
LEFT JOIN OrderDetails od ON ro.o_orderkey = od.l_orderkey
LEFT JOIN TopSuppliers ts ON od.l_suppkey = ts.s_suppkey
WHERE od.line_rank = 1
GROUP BY ns.n_name
HAVING SUM(od.l_extendedprice * (1 - od.l_discount)) > 10000
ORDER BY total_revenue DESC;
