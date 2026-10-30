WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        DENSE_RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS price_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name,
        r.price_rank
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.price_rank <= 5
),
OrderDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS revenue,
        COUNT(lo.l_orderkey) AS line_item_count
    FROM 
        lineitem lo
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.n_name,
    d.revenue,
    d.line_item_count,
    o.o_totalprice,
    (d.revenue / o.o_totalprice) AS revenue_ratio
FROM 
    TopOrders o
JOIN 
    OrderDetails d ON o.o_orderkey = d.l_orderkey
ORDER BY 
    o.o_orderdate DESC, revenue DESC
LIMIT 10;
