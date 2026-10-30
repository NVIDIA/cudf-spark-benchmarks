WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        r.r_name, 
        SUM(ps.ps_availqty) AS total_available
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
    ORDER BY 
        total_available DESC
    LIMIT 5
)
SELECT 
    ts.s_suppkey,
    ts.s_name,
    ts.total_available,
    sr.total_revenue
FROM 
    TopSuppliers ts
LEFT JOIN 
    SupplierRevenue sr ON ts.s_suppkey = sr.s_suppkey
WHERE 
    sr.total_revenue IS NOT NULL
ORDER BY 
    sr.total_revenue DESC;
