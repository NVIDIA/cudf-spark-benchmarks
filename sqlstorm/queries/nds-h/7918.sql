WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice, 
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        n.n_name AS nation_name
    FROM 
        RankedOrders o
    JOIN 
        nation n ON o.c_nationkey = n.n_nationkey
    WHERE 
        o.order_rank <= 5
)
SELECT 
    t.nation_name,
    COUNT(t.o_orderkey) AS top_order_count,
    SUM(t.o_totalprice) AS total_revenue,
    AVG(t.o_totalprice) AS avg_order_value,
    MAX(t.o_totalprice) AS max_order_value
FROM 
    TopOrders t
GROUP BY 
    t.nation_name
ORDER BY 
    total_revenue DESC, 
    top_order_count DESC;