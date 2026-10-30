WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
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
        r.c_name,
        r.c_acctbal
    FROM 
        RankedOrders r
    WHERE 
        r.order_rank <= 10
),
OrderDetails AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
OrderSummary AS (
    SELECT 
        h.o_orderkey,
        h.o_orderdate,
        h.o_totalprice,
        h.c_name,
        h.c_acctbal,
        COALESCE(d.total_revenue, 0) AS total_revenue,
        COALESCE(d.total_quantity, 0) AS total_quantity
    FROM 
        HighValueOrders h
    LEFT JOIN 
        OrderDetails d ON h.o_orderkey = d.l_orderkey
)
SELECT 
    os.o_orderkey,
    os.o_orderdate,
    os.c_name,
    os.c_acctbal,
    os.total_revenue,
    os.total_quantity,
    CASE 
        WHEN os.total_revenue > 50000 THEN 'High Revenue'
        WHEN os.total_revenue BETWEEN 20000 AND 50000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    OrderSummary os
ORDER BY 
    os.total_revenue DESC;
