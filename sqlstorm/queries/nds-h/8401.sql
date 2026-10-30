WITH SupplierPartRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * l.l_quantity) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        s.s_suppkey
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        sr.total_revenue
    FROM 
        supplier s
    JOIN 
        SupplierPartRevenue sr ON s.s_suppkey = sr.s_suppkey
    ORDER BY 
        sr.total_revenue DESC
    LIMIT 10
)
SELECT 
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count
FROM 
    TopSuppliers t
LEFT JOIN 
    orders o ON t.s_suppkey = o.o_custkey
GROUP BY 
    t.s_suppkey, t.s_name, t.total_revenue
ORDER BY 
    t.total_revenue DESC;