
WITH RECURSIVE SupplierHierarchy AS (
    SELECT s_nationkey, s_suppkey, s_name, 0 AS level
    FROM supplier
    WHERE s_name LIKE 'A%'
    
    UNION ALL
    
    SELECT s.s_nationkey, s.s_suppkey, s.s_name, sh.level + 1
    FROM supplier s
    JOIN SupplierHierarchy sh ON s.s_nationkey = sh.s_nationkey
    WHERE s.s_name LIKE 'B%'
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_partkey) AS part_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopSuppliers AS (
    SELECT 
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE ps.ps_availqty > 0
    GROUP BY s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (SELECT AVG(ps_supplycost) FROM partsupp)
),
NationSummary AS (
    SELECT 
        n.n_name AS nation,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(od.revenue) AS total_revenue,
        AVG(od.revenue) AS avg_order_value
    FROM nation n
    LEFT JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    LEFT JOIN OrderDetails od ON o.o_orderkey = od.o_orderkey
    GROUP BY n.n_name
)
SELECT 
    ns.nation,
    ns.total_orders,
    ns.total_revenue,
    ns.avg_order_value,
    ths.s_name AS top_supplier,
    ths.total_cost
FROM NationSummary ns
LEFT JOIN TopSuppliers ths ON ns.total_revenue > ths.total_cost
ORDER BY ns.total_revenue DESC, ns.total_orders DESC
LIMIT 10;
