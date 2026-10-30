WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
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
        r.c_name,
        r.c_nationkey
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 5
)
SELECT 
    tp.c_name,
    n.n_name AS nation,
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue
FROM 
    TopOrders tp
JOIN 
    lineitem li ON tp.o_orderkey = li.l_orderkey
JOIN 
    customer c ON tp.c_name = c.c_name
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
WHERE 
    li.l_shipdate >= '1997-01-01' AND li.l_shipdate < '1998-01-01'
GROUP BY 
    tp.c_name, n.n_name
ORDER BY 
    revenue DESC
LIMIT 10;