WITH Revenue AS (
    SELECT 
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        n_name,
        r_name,
        o_orderdate
    FROM 
        lineitem
    JOIN 
        orders ON l_orderkey = o_orderkey
    JOIN 
        partsupp ON l_partkey = ps_partkey
    JOIN 
        supplier ON ps_suppkey = s_suppkey
    JOIN 
        nation ON s_nationkey = n_nationkey
    JOIN 
        region ON n_regionkey = r_regionkey
    WHERE 
        o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        n_name, r_name, o_orderdate
),
RankedRevenue AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY r_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        Revenue
)
SELECT 
    r_name AS region,
    n_name AS nation,
    o_orderdate,
    total_revenue
FROM 
    RankedRevenue
WHERE 
    revenue_rank <= 5
ORDER BY 
    region, total_revenue DESC;