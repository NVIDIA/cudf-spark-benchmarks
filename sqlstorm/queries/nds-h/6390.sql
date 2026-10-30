WITH RegionalSummary AS (
    SELECT 
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        COUNT(DISTINCT c.c_custkey) AS customer_count
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
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        r.r_name
),
TopRegions AS (
    SELECT 
        region_name,
        total_revenue,
        order_count,
        customer_count,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        RegionalSummary
)
SELECT 
    region_name,
    total_revenue,
    order_count,
    customer_count
FROM 
    TopRegions
WHERE 
    revenue_rank <= 5
ORDER BY 
    total_revenue DESC;