WITH  SupplierRank AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
RankedSuppliers AS (
    SELECT sr.*,
           ROW_NUMBER() OVER (PARTITION BY sr.s_nationkey ORDER BY sr.total_cost DESC) AS rank
    FROM SupplierRank sr
)
SELECT n.n_name, 
       SUM(o.o_totalprice) AS total_revenue,
       COUNT(DISTINCT o.o_orderkey) AS order_count,
       MAX(rs.total_cost) AS top_supplier_cost
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON c.c_nationkey = n.n_nationkey
JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
WHERE o.o_orderstatus = 'O' 
  AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY n.n_name
ORDER BY total_revenue DESC, n.n_name;