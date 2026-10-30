WITH SupplierTotals AS (
    SELECT s.s_suppkey,
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey
),
CustomerOrders AS (
    SELECT c.c_custkey,
           SUM(o.o_totalprice) AS total_spent,
           COUNT(o.o_orderkey) AS order_count
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
),
NationSuppliers AS (
    SELECT n.n_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           SUM(st.total_cost) AS total_supplier_cost,
           AVG(st.order_count) AS avg_order_count
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN SupplierTotals st ON s.s_suppkey = st.s_suppkey
    GROUP BY n.n_name
)
SELECT ns.n_name,
       ns.supplier_count,
       ns.total_supplier_cost,
       co.total_spent,
       co.order_count AS customer_order_count,
       ns.avg_order_count
FROM NationSuppliers ns
LEFT JOIN CustomerOrders co ON ns.supplier_count > 0
ORDER BY ns.total_supplier_cost DESC, co.total_spent DESC
LIMIT 10;
