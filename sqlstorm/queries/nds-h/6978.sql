WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
),
HighValueOrders AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.o_totalprice,
        r.c_name
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 5
),
OrderDetails AS (
    SELECT 
        h.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        HighValueOrders h
    JOIN 
        lineitem l ON h.o_orderkey = l.l_orderkey
    GROUP BY 
        h.o_orderkey
)
SELECT 
    h.o_orderkey,
    h.o_orderdate,
    h.c_name,
    d.total_revenue,
    d.total_quantity
FROM 
    HighValueOrders h
JOIN 
    OrderDetails d ON h.o_orderkey = d.o_orderkey
ORDER BY 
    d.total_revenue DESC
LIMIT 10;
