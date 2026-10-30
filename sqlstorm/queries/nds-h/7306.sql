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
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        s.s_suppkey
),
RegionSupplierRevenue AS (
    SELECT 
        n.n_regionkey, 
        r.r_name,
        SUM(sr.total_revenue) AS region_revenue
    FROM 
        SupplierRevenue sr
    JOIN 
        supplier s ON sr.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    GROUP BY 
        n.n_regionkey, r.r_name
)
SELECT 
    r.r_name,
    r.region_revenue,
    RANK() OVER (ORDER BY r.region_revenue DESC) AS revenue_rank
FROM 
    RegionSupplierRevenue r
ORDER BY 
    r.region_revenue DESC
LIMIT 10;