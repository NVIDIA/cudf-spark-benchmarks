WITH RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
        RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name LIKE 'Europe%')
    GROUP BY 
        s.s_name, s.s_suppkey, n.n_name
), 
TopSuppliers AS (
    SELECT 
        r.r_name,
        rs.s_name,
        rs.total_value
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_suppkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.supplier_rank <= 5
)
SELECT 
    t.r_name AS region_name,
    t.s_name AS supplier_name,
    t.total_value
FROM 
    TopSuppliers t
ORDER BY 
    t.r_name, t.total_value DESC;
