WITH SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) as total_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        s.s_suppkey, s.s_name, r.r_name
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 100000
),
RankedSuppliers AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY r_name ORDER BY total_revenue DESC) as revenue_rank
    FROM 
        HighValueSuppliers
)
SELECT 
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(rs.r_name, 'No Region') AS region_name,
    COALESCE(rs.total_revenue, 0) AS total_revenue,
    CASE 
        WHEN rs.revenue_rank IS NULL THEN 'Not Ranked'
        ELSE 'Ranked #' || rs.revenue_rank
    END AS ranking_status
FROM 
    RankedSuppliers rs
FULL OUTER JOIN SupplierRevenue sr ON rs.s_suppkey = sr.s_suppkey
WHERE 
    sr.total_revenue IS NULL OR rs.total_revenue IS NULL
ORDER BY 
    COALESCE(rs.total_revenue, 0) DESC, 
    COALESCE(sr.total_revenue, 0) DESC;