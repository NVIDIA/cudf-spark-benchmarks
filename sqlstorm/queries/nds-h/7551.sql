
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
        n.n_regionkey
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_regionkey
), 
TopSuppliers AS (
    SELECT 
        ts.s_suppkey, 
        ts.s_name, 
        r.r_name,
        ts.total_supply_value
    FROM RankedSuppliers ts
    JOIN region r ON ts.n_regionkey = r.r_regionkey
    WHERE ts.supplier_rank <= 5
), 
OrderDetails AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(DISTINCT l.l_partkey) AS total_line_items,
        od.s_name,
        od.r_name
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN TopSuppliers od ON l.l_suppkey = od.s_suppkey
    GROUP BY o.o_orderkey, od.s_name, od.r_name
)
SELECT 
    od.o_orderkey,
    od.total_order_value,
    od.total_line_items,
    od.s_name AS supplier_name,
    od.r_name AS region_name
FROM OrderDetails od
WHERE od.total_order_value > 1000
ORDER BY od.total_order_value DESC;
