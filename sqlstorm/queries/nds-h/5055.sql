
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank,
        n.n_nationkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal, n.n_name, n.n_nationkey
),
TopSuppliers AS (
    SELECT 
        r.r_name AS region_name, 
        COUNT(*) AS top_supplier_count
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.n_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        rs.rank <= 5
    GROUP BY 
        r.r_name
)
SELECT 
    r.r_name AS region_name, 
    r.r_comment, 
    COALESCE(ts.top_supplier_count, 0) AS top_supplier_count
FROM 
    region r
LEFT JOIN 
    TopSuppliers ts ON r.r_name = ts.region_name
ORDER BY 
    ts.top_supplier_count DESC NULLS LAST;
