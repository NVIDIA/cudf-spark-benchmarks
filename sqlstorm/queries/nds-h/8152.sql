WITH RegionalSummary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(o.o_totalprice) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
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
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_revenue,
        unique_customers,
        total_orders,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RegionalSummary
)
SELECT 
    region_name,
    total_revenue,
    unique_customers,
    total_orders
FROM 
    TopRegions
WHERE 
    revenue_rank <= 5
ORDER BY 
    total_revenue DESC;