
WITH SupplierStats AS (
    SELECT s.s_suppkey,
           s.s_name,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey,
           s.s_name,
           RANK() OVER (ORDER BY ss.total_value DESC) AS supplier_rank
    FROM SupplierStats ss
    JOIN supplier s ON ss.s_suppkey = s.s_suppkey
)
SELECT c.c_name,
       SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       CASE 
           WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000 THEN 'High Value Customer'
           ELSE 'Regular Customer'
       END AS customer_type
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey AND ts.supplier_rank <= 5
WHERE o.o_orderstatus = 'O' 
  AND l.l_shipdate >= DATE '1996-01-01' 
  AND (l.l_returnflag IS NULL OR l.l_returnflag <> 'R')
GROUP BY c.c_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 50000
ORDER BY revenue DESC;
