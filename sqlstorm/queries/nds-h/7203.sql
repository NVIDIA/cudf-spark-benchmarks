WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
),
TopOrders AS (
    SELECT 
        r.o_orderkey, 
        r.o_orderdate, 
        r.o_totalprice, 
        r.c_name, 
        r.nation_name
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    t.nation_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(l.l_orderkey) AS total_lineitems
FROM 
    TopOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.c_name, t.nation_name
ORDER BY 
    total_revenue DESC
LIMIT 5;