WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
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
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
    GROUP BY 
        r.r_name
), 
TopRegions AS (
    SELECT 
        region_name,
        total_revenue,
        total_orders,
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RegionalSales
)
SELECT 
    region_name,
    total_revenue,
    total_orders
FROM 
    TopRegions
WHERE 
    revenue_rank <= 10
ORDER BY 
    total_revenue DESC;