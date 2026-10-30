WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
), HighCostSuppliers AS (
    SELECT 
        rs.s_suppkey, 
        rs.s_name 
    FROM 
        RankedSuppliers rs 
    WHERE 
        rs.rank <= 5
)
SELECT 
    c.c_custkey, 
    c.c_name, 
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(CASE WHEN hs.s_suppkey IS NOT NULL THEN l.l_quantity ELSE 0 END) AS total_quantity_from_high_cost_suppliers,
    AVG(o.o_totalprice) AS avg_order_value
FROM 
    customer c
JOIN 
    orders o ON c.c_custkey = o.o_custkey
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    HighCostSuppliers hs ON l.l_suppkey = hs.s_suppkey
WHERE 
    o.o_orderstatus = 'O'
    AND l.l_shipdate >= DATE '1996-01-01'
GROUP BY 
    c.c_custkey, c.c_name
ORDER BY 
    revenue DESC
LIMIT 10;