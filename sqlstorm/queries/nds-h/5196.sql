WITH SupplierCost AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
CustomerOrderTotal AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_orders
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
NationRegionSummary AS (
    SELECT n.n_nationkey, n.n_name, r.r_regionkey, r.r_name,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM nation n
    JOIN region r ON n.n_regionkey = r.r_regionkey
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN orders o ON s.s_suppkey = o.o_custkey
    GROUP BY n.n_nationkey, n.n_name, r.r_regionkey, r.r_name
)

SELECT ns.n_name, ns.r_name, 
       sc.s_name AS top_supplier, 
       sc.total_cost AS supplier_total_cost, 
       ct.total_orders AS customer_total_orders
FROM NationRegionSummary ns
JOIN SupplierCost sc ON ns.supplier_count > 0
JOIN CustomerOrderTotal ct ON ct.total_orders > 0
WHERE sc.total_cost = (SELECT MAX(total_cost) FROM SupplierCost)
ORDER BY ns.r_name, ns.n_name;
