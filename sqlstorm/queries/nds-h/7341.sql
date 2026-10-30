
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        c.c_name, 
        n.n_name AS nation_name,
        RANK() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey, 
        ro.o_orderdate, 
        ro.o_totalprice, 
        ro.c_name, 
        ro.nation_name
    FROM 
        RankedOrders ro
    WHERE 
        ro.order_rank <= 5
)
SELECT 
    t.o_orderkey, 
    t.o_orderdate, 
    t.o_totalprice, 
    t.c_name, 
    t.nation_name, 
    SUM(li.l_extendedprice * (1 - li.l_discount)) AS revenue,
    COUNT(li.l_orderkey) AS item_count
FROM 
    TopOrders t
JOIN 
    lineitem li ON t.o_orderkey = li.l_orderkey
GROUP BY 
    t.o_orderkey, 
    t.o_orderdate, 
    t.o_totalprice, 
    t.c_name, 
    t.nation_name
ORDER BY 
    revenue DESC;
