WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY pt.p_type ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part pt ON ps.ps_partkey = pt.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, pt.p_type
),
TopSuppliers AS (
    SELECT 
        SupplierRank, 
        s.s_suppkey, 
        s.s_name, 
        s.s_nationkey, 
        n.n_name AS nation_name
    FROM 
        RankedSuppliers sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        sr.SupplierRank = 1
)
SELECT 
    ts.nation_name,
    COUNT(DISTINCT ts.s_suppkey) AS num_top_suppliers,
    SUM(o.o_totalprice) AS total_order_value
FROM 
    TopSuppliers ts
JOIN 
    orders o ON ts.s_suppkey = o.o_custkey
WHERE 
    o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    ts.nation_name
ORDER BY 
    total_order_value DESC;