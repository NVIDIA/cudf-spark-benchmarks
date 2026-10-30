WITH agg_lineitem AS (
    SELECT 
        l_orderkey, 
        SUM(l_extendedprice * (1 - l_discount)) AS revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1995-01-01' AND l_shipdate < DATE '1996-01-01'
    GROUP BY 
        l_orderkey
),
order_details AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_mktsegment,
        n.n_name AS nation
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderstatus = 'O'
),
final_results AS (
    SELECT 
        od.o_orderkey,
        od.o_orderdate,
        od.o_totalprice,
        od.o_orderpriority,
        od.c_mktsegment,
        ol.revenue
    FROM 
        order_details od
    JOIN 
        agg_lineitem ol ON od.o_orderkey = ol.l_orderkey
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.o_totalprice,
    f.o_orderpriority,
    f.c_mktsegment,
    f.revenue,
    RANK() OVER (PARTITION BY f.c_mktsegment ORDER BY f.revenue DESC) AS revenue_rank
FROM 
    final_results f
WHERE 
    f.revenue > (SELECT AVG(revenue) FROM final_results)
ORDER BY 
    f.c_mktsegment, revenue_rank;
