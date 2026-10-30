WITH RevenueBySupplier AS (
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
), RegionRevenue AS (
    SELECT 
        r.r_name, 
        SUM(rb.total_revenue) AS region_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        RevenueBySupplier rb ON s.s_suppkey = rb.s_suppkey
    GROUP BY 
        r.r_name
)
SELECT 
    rr.r_name, 
    rr.region_revenue,
    RANK() OVER (ORDER BY rr.region_revenue DESC) AS revenue_rank
FROM 
    RegionRevenue rr
WHERE 
    rr.region_revenue > 1000000
ORDER BY 
    rr.region_revenue DESC;
