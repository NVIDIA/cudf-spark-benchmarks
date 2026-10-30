WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        n.n_name,
        r.order_rank
    FROM 
        RankedOrders r
    JOIN 
        nation n ON r.c_nationkey = n.n_nationkey
    WHERE 
        r.order_rank <= 5
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    t.n_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_suppkey) AS distinct_suppliers
FROM 
    TopOrders t
JOIN 
    lineitem l ON t.o_orderkey = l.l_orderkey
GROUP BY 
    t.o_orderkey, t.o_orderdate, t.o_totalprice, t.n_name
ORDER BY 
    t.o_orderdate DESC, total_revenue DESC;