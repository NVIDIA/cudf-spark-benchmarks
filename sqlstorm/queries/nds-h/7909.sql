WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name, p.p_partkey
),
BestSuppliers AS (
    SELECT 
        r.n_name AS nation_name,
        rs.s_name,
        rs.total_value
    FROM 
        RankedSuppliers rs
    JOIN 
        supplier s ON rs.s_suppkey = s.s_suppkey
    JOIN 
        nation r ON s.s_nationkey = r.n_nationkey
    WHERE 
        rs.supplier_rank = 1
)
SELECT 
    b.nation_name,
    COUNT(b.s_name) AS best_supplier_count,
    SUM(b.total_value) AS total_best_supplier_value
FROM 
    BestSuppliers b
GROUP BY 
    b.nation_name
ORDER BY 
    total_best_supplier_value DESC
LIMIT 10;
