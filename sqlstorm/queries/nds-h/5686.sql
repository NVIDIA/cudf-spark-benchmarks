WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate <= DATE '1997-12-31'
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
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        HighValueOrders h
    JOIN 
        lineitem l ON h.o_orderkey = l.l_orderkey
    GROUP BY 
        h.o_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.c_name,
    d.total_revenue,
    d.total_quantity,
    d.unique_suppliers,
    ROUND(d.total_revenue * 0.15, 2) AS estimated_profit_margin
FROM 
    HighValueOrders o
JOIN 
    OrderDetails d ON o.o_orderkey = d.o_orderkey
ORDER BY 
    d.total_revenue DESC;