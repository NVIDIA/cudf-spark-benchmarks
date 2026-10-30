WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name
),
TopOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.c_name,
        o.total_revenue,
        ROW_NUMBER() OVER (PARTITION BY EXTRACT(MONTH FROM o.o_orderdate) ORDER BY o.total_revenue DESC) AS rn
    FROM 
        RankedOrders o
)
SELECT 
    t.o_orderkey,
    t.o_orderdate,
    t.c_name,
    t.total_revenue
FROM 
    TopOrders t
WHERE 
    t.rn <= 5
ORDER BY 
    t.o_orderdate, 
    t.total_revenue DESC;