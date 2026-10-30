WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_per_nation
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
        r.c_name
    FROM 
        RankedOrders r
    WHERE 
        r.rank_per_nation <= 5
),
OrderDetails AS (
    SELECT 
        t.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS total_lineitems
    FROM 
        TopOrders t
    JOIN 
        lineitem l ON t.o_orderkey = l.l_orderkey
    GROUP BY 
        t.o_orderkey
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    d.total_revenue,
    d.total_lineitems
FROM 
    TopOrders t
JOIN 
    OrderDetails d ON t.o_orderkey = d.o_orderkey
ORDER BY 
    d.total_revenue DESC, t.o_orderdate;
