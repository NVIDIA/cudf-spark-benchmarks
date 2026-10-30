WITH SupplierCost AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sc.total_cost
    FROM SupplierCost sc
    JOIN supplier s ON sc.s_suppkey = s.s_suppkey
    WHERE sc.total_cost > (SELECT AVG(total_cost) FROM SupplierCost)
),
OrderDetails AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS line_count,
        hs.total_cost AS supplier_cost
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN HighCostSuppliers hs ON l.l_suppkey = hs.s_suppkey
    WHERE o.o_orderdate >= DATE '1996-01-01' 
    GROUP BY o.o_orderkey, o.o_orderstatus, hs.total_cost
)
SELECT 
    od.o_orderkey,
    od.o_orderstatus,
    od.revenue,
    od.line_count,
    od.supplier_cost,
    ROW_NUMBER() OVER (PARTITION BY od.o_orderstatus ORDER BY od.revenue DESC) as rank
FROM OrderDetails od
ORDER BY od.supplier_cost DESC, od.revenue DESC;