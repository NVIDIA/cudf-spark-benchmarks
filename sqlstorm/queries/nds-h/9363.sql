WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_custkey) AS unique_customers,
        RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
TopRegions AS (
    SELECT 
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS region_revenue
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    JOIN 
        lineitem l ON l.l_partkey = p.p_partkey
    GROUP BY 
        r.r_name
    ORDER BY 
        region_revenue DESC
    LIMIT 5
)
SELECT 
    ro.o_orderkey,
    ro.total_revenue,
    ro.unique_customers,
    tr.r_name,
    tr.region_revenue
FROM 
    RankedOrders ro
JOIN 
    TopRegions tr ON ro.total_revenue > 100000
WHERE 
    ro.revenue_rank <= 10
ORDER BY 
    ro.total_revenue DESC;
