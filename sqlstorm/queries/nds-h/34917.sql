WITH  CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
SupplierPartCost AS (
    SELECT ps.ps_partkey, AVG(ps.ps_supplycost) AS avg_supplycost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN lineitem l ON s.s_suppkey = l.l_suppkey
    WHERE l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
    ORDER BY total_revenue DESC
    LIMIT 10
)
SELECT 
    n.n_name AS nation,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
    COALESCE(ROUND(AVG(supply.avg_supplycost), 2), 0) AS average_supply_cost,
    COUNT(DISTINCT c.c_custkey) AS customer_count
FROM nation n
LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN orders o ON c.c_custkey = o.o_custkey
LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN SupplierPartCost supply ON supply.ps_partkey = l.l_partkey
LEFT JOIN TopSuppliers ts ON ts.s_suppkey = l.l_suppkey
WHERE l.l_returnflag = 'N'
GROUP BY n.n_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY total_sales DESC;