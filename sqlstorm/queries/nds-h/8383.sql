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
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND l.l_returnflag = 'N'
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
    nation_name,
    total_revenue,
    revenue_rank
FROM 
    ranked_revenue
WHERE 
    revenue_rank <= 10
ORDER BY 
    revenue_rank;