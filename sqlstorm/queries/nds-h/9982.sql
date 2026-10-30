WITH SupplierRevenue AS (
    SELECT s_suppkey, SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM supplier
    JOIN partsupp ON supplier.s_suppkey = partsupp.ps_suppkey
    JOIN lineitem ON partsupp.ps_partkey = lineitem.l_partkey
    GROUP BY s_suppkey
),
TopSuppliers AS (
    SELECT s_suppkey, total_revenue
    FROM SupplierRevenue
    ORDER BY total_revenue DESC
    LIMIT 10
),
CustomerOrderCounts AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
)
SELECT 
    s.s_name AS supplier_name,
    r.r_name AS region,
    n.n_name AS nation,
    SUM(COALESCE(ol.order_count, 0)) AS total_orders
FROM TopSuppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
LEFT JOIN CustomerOrderCounts ol ON c.c_custkey = ol.c_custkey
WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY s.s_suppkey, s.s_name, r.r_name, n.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
ORDER BY total_orders DESC;