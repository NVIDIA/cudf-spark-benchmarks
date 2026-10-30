WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name as customer_name,
        n.n_name as nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) as rank_order
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.customer_name,
        ro.nation_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank_order <= 5
),
LineItemDetails AS (
    SELECT 
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue,
        COUNT(lo.l_orderkey) AS lineitem_count
    FROM 
        lineitem lo
    WHERE 
        lo.l_shipdate > DATE '1997-06-30'
    GROUP BY 
        lo.l_orderkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    t.customer_name,
    t.nation_name,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(l.lineitem_count, 0) AS lineitem_count
FROM 
    TopOrders t
LEFT JOIN 
    LineItemDetails l ON t.o_orderkey = l.l_orderkey
ORDER BY 
    t.o_orderdate DESC, t.o_totalprice DESC;