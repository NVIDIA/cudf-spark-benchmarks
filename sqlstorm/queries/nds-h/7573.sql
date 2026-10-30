WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_regionkey
), BestSuppliers AS (
    SELECT 
        r.r_name, 
        rs.s_suppkey, 
        rs.s_name, 
        rs.total_value
    FROM 
        RankedSuppliers rs
    JOIN 
        region r ON rs.rank = 1 AND r.r_regionkey = (SELECT n.n_regionkey FROM nation n WHERE n.n_nationkey = (SELECT MIN(s_nationkey) FROM supplier))
)
SELECT 
    bs.r_name AS region_name, 
    bs.s_suppkey AS supplier_id, 
    bs.s_name AS supplier_name, 
    bs.total_value AS total_supply_value
FROM 
    BestSuppliers bs
ORDER BY 
    bs.total_value DESC;
