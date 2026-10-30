WITH revenue AS (
    SELECT 
        l_orderkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1997-01-01' AND l_shipdate < DATE '1997-12-31'
    GROUP BY 
        l_orderkey
),
order_summary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        r.total_revenue
    FROM 
        orders o
    JOIN 
        revenue r ON o.o_orderkey = r.l_orderkey
)
SELECT 
    os.o_orderstatus,
    COUNT(*) AS order_count,
    SUM(os.total_revenue) AS total_revenue
FROM 
    order_summary os
GROUP BY 
    os.o_orderstatus
ORDER BY 
    os.o_orderstatus;