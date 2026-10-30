WITH  AvgSupplierCost AS (
    SELECT ps_suppkey, AVG(ps_supplycost) AS avg_cost
    FROM partsupp
    GROUP BY ps_suppkey
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, a.avg_cost
    FROM supplier s
    JOIN AvgSupplierCost a ON s.s_suppkey = a.ps_suppkey
    WHERE a.avg_cost > (SELECT AVG(avg_cost) FROM AvgSupplierCost)
)
SELECT
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_orders,
    AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_revenue,
    STRING_AGG(DISTINCT p.p_name, ', ') FILTER (WHERE l.l_returnflag = 'R') AS returned_parts,
    CASE 
        WHEN SUM(o.o_totalprice) IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM lineitem l
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN TopSuppliers ts ON ps.ps_suppkey = ts.s_suppkey
JOIN part p ON l.l_partkey = p.p_partkey
WHERE l.l_shipdate >= '1997-01-01' 
  AND l.l_shipdate < '1997-10-01'
GROUP BY n.n_name
HAVING COUNT(DISTINCT c.c_custkey) > 0
ORDER BY total_orders DESC
LIMIT 10;