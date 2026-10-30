WITH SupplierOrders AS (
    SELECT s.s_suppkey, s.s_name, COUNT(o.o_orderkey) AS order_count, SUM(l.l_extendedprice) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderstatus = 'O'  
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s_suppkey, s_name, order_count, total_revenue
    FROM SupplierOrders
    ORDER BY total_revenue DESC
    LIMIT 10
)
SELECT ts.s_name, ts.order_count, ts.total_revenue, p.p_name, p.p_mfgr, p.p_type, r.r_name
FROM TopSuppliers ts
JOIN partsupp ps ON ts.s_suppkey = ps.ps_suppkey
JOIN part p ON ps.ps_partkey = p.p_partkey
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE p.p_retailprice > 100.00
ORDER BY ts.total_revenue DESC, p.p_name;