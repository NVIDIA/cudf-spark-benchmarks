WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        DENSE_RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank,
        c.c_mktsegment,
        n.n_name AS nation_name
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderstatus,
        ro.o_totalprice,
        ro.o_orderdate,
        ro.c_mktsegment,
        ro.nation_name,
        ROW_NUMBER() OVER (PARTITION BY ro.nation_name ORDER BY ro.o_totalprice DESC) AS rn
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    t.o_orderkey,
    t.o_orderstatus,
    t.o_totalprice,
    t.o_orderdate,
    t.c_mktsegment,
    t.nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
FROM 
    TopOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey,
    t.o_orderstatus,
    t.o_totalprice,
    t.o_orderdate,
    t.c_mktsegment,
    t.nation_name
ORDER BY 
    revenue DESC;