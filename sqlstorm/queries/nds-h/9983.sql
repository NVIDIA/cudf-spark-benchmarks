WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS total_price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
top_customers AS (
    SELECT 
        ro.c_name,
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice
    FROM 
        ranked_orders ro
    WHERE 
        ro.total_price_rank <= 5
),
lineitem_summary AS (
    SELECT 
        li.l_orderkey,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS total_revenue,
        SUM(li.l_quantity) AS total_quantity,
        COUNT(DISTINCT li.l_linenumber) AS unique_lineitems
    FROM 
        lineitem li
    GROUP BY 
        li.l_orderkey
)
SELECT 
    tc.c_name,
    tc.o_orderkey,
    tc.o_orderdate,
    tc.o_totalprice,
    ls.total_revenue,
    ls.total_quantity,
    ls.unique_lineitems
FROM 
    top_customers tc
JOIN 
    lineitem_summary ls ON tc.o_orderkey = ls.l_orderkey
ORDER BY 
    tc.o_orderdate DESC, tc.o_totalprice DESC;