WITH SupplierRevenue AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE l.l_shipdate >= '1996-01-01' 
      AND l.l_shipdate < '1997-01-01'
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, sr.total_revenue,
           RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM supplier s
    JOIN SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
),
OrderSummary AS (
    SELECT o.o_orderkey, 
           o.o_orderdate, 
           o.o_totalprice,
           SUM(l.l_quantity) AS total_quantity,
           AVG(l.l_extendedprice) AS avg_price
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderstatus = 'F'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
),
SupplierOrderCount AS (
    SELECT s.s_suppkey, 
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1996-01-01'
    GROUP BY s.s_suppkey
)
SELECT ts.s_suppkey, 
       ts.s_name, 
       ts.total_revenue, 
       oc.order_count,
       CASE 
           WHEN ts.revenue_rank <= 10 THEN 'Top Supplier'
           ELSE 'Regular Supplier'
       END AS supplier_type
FROM TopSuppliers ts
FULL OUTER JOIN SupplierOrderCount oc ON ts.s_suppkey = oc.s_suppkey
WHERE (ts.total_revenue IS NOT NULL OR oc.order_count IS NOT NULL)
  AND (ts.total_revenue > 10000 OR oc.order_count > 5)
ORDER BY ts.s_suppkey;