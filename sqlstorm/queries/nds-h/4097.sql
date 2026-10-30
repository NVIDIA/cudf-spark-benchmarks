WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        CTE.cust_region,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN (
        SELECT 
            c.c_custkey,
            r.r_name AS cust_region
        FROM 
            customer c
        JOIN 
            nation n ON c.c_nationkey = n.n_nationkey
        JOIN 
            region r ON n.n_regionkey = r.r_regionkey
    ) AS CTE ON o.o_custkey = CTE.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
top_orders AS (
    SELECT 
        o.*
    FROM 
        ranked_orders o
    WHERE 
        o.order_rank <= 10
),
order_line_summary AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(DISTINCT lo.l_partkey) AS unique_parts
    FROM 
        lineitem lo
    INNER JOIN 
        top_orders t ON lo.l_orderkey = t.o_orderkey
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    ol.total_revenue,
    ol.unique_parts,
    CASE 
        WHEN t.o_totalprice IS NULL THEN 'No Price'
        WHEN ol.total_revenue > t.o_totalprice THEN 'Over Revenue'
        ELSE 'Within Revenue'
    END AS revenue_status
FROM 
    top_orders t
LEFT JOIN 
    order_line_summary ol ON t.o_orderkey = ol.l_orderkey
ORDER BY 
    t.o_totalprice DESC NULLS LAST;