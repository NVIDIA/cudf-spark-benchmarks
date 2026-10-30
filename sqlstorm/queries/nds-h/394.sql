WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
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
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        supplier s
    LEFT JOIN 
        SupplierRevenue sr ON s.s_suppkey = sr.s_suppkey
)
SELECT 
    n.n_name AS nation,
    SUM(CASE WHEN t.revenue_rank <= 10 THEN t.total_revenue ELSE 0 END) AS top_supplier_revenue,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(s.s_acctbal) AS avg_supplier_acctbal
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    TopSuppliers t ON s.s_suppkey = t.s_suppkey
LEFT JOIN 
    customer c ON s.s_nationkey = c.c_nationkey
WHERE 
    s.s_acctbal IS NOT NULL AND 
    (n.n_name LIKE 'A%' OR n.n_name LIKE '%N')
GROUP BY 
    n.n_name
HAVING 
    SUM(t.total_revenue) > 10000
ORDER BY 
    top_supplier_revenue DESC;
