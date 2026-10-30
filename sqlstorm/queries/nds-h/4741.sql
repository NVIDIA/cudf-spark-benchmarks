WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01'
    GROUP BY 
        s.s_suppkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
RankedSuppliers AS (
    SELECT 
        sr.s_suppkey,
        sr.total_revenue,
        RANK() OVER (ORDER BY sr.total_revenue DESC) AS revenue_rank
    FROM 
        SupplierRevenue sr
)
SELECT 
    n.n_name,
    COUNT(DISTINCT r.s_suppkey) AS supplier_count,
    COALESCE(SUM(CASE WHEN rs.revenue_rank <= 5 THEN rs.total_revenue END), 0) AS top_supplier_revenue,
    MAX(r.s_suppkey) AS max_supplier_id
FROM 
    nation n
LEFT JOIN 
    supplier r ON n.n_nationkey = r.s_nationkey
LEFT JOIN 
    RankedSuppliers rs ON r.s_suppkey = rs.s_suppkey
GROUP BY 
    n.n_name
ORDER BY 
    supplier_count DESC, top_supplier_revenue DESC;