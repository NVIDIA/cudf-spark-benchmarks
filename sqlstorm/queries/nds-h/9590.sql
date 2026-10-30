
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT 
        rs.s_suppkey,
        rs.s_name,
        n.n_name AS nation_name,
        rs.total_cost,
        ROW_NUMBER() OVER (PARTITION BY rs.s_nationkey ORDER BY rs.total_cost DESC) AS rank
    FROM 
        RankedSuppliers rs
    JOIN 
        nation n ON rs.s_nationkey = n.n_nationkey
)
SELECT 
    ts.nation_name,
    COUNT(*) AS supplier_count,
    SUM(ts.total_cost) AS total_spending
FROM 
    TopSuppliers ts
WHERE 
    ts.rank <= 5
GROUP BY 
    ts.nation_name
ORDER BY 
    total_spending DESC;
