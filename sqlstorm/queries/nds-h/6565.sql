WITH TotalSales AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey
),
SupplierRevenue AS (
    SELECT 
        s.s_suppkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS supplier_revenue
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    GROUP BY 
        s.s_suppkey
),
RegionalSales AS (
    SELECT 
        r.r_name,
        SUM(ts.total_revenue) AS region_revenue
    FROM 
        TotalSales ts
    JOIN 
        partsupp ps ON ts.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        r.r_name
)
SELECT 
    rs.r_name,
    rs.region_revenue,
    COUNT(DISTINCT sr.s_suppkey) AS supplier_count,
    RANK() OVER (ORDER BY rs.region_revenue DESC) AS revenue_rank
FROM 
    RegionalSales rs
JOIN 
    SupplierRevenue sr ON rs.region_revenue = sr.supplier_revenue
GROUP BY 
    rs.r_name, rs.region_revenue
ORDER BY 
    rs.region_revenue DESC
LIMIT 10;
