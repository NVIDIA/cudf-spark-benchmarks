WITH revenue_data AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY 
        n.n_name
),
ranked_revenue AS (
    SELECT 
        nation_name,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        revenue_data
)

SELECT 
    rr.nation_name,
    rr.total_revenue,
    rr.revenue_rank,
    PERCENT_RANK() OVER (ORDER BY rr.total_revenue DESC) AS revenue_percentile
FROM 
    ranked_revenue rr
WHERE 
    rr.revenue_rank <= 5
ORDER BY 
    rr.revenue_rank;