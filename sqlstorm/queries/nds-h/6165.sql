WITH ranked_orders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_name,
        c.c_mktsegment,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-10-01'
),
top_segment_orders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.o_totalprice, 
        ro.o_orderstatus, 
        ro.c_name, 
        ro.c_mktsegment
    FROM 
        ranked_orders ro
    WHERE 
        ro.price_rank <= 10
),
line_item_summary AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(lo.l_orderkey) AS total_items
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    tso.o_orderkey,
    tso.o_orderdate,
    tso.o_totalprice,
    tso.o_orderstatus,
    tso.c_name,
    tso.c_mktsegment,
    lis.total_revenue,
    lis.total_items
FROM 
    top_segment_orders tso
JOIN 
    line_item_summary lis ON tso.o_orderkey = lis.l_orderkey
ORDER BY 
    tso.o_orderdate DESC, 
    tso.o_totalprice DESC;