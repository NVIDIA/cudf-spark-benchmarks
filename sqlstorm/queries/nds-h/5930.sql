WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
),
TopNOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        n.n_name,
        n.n_regionkey
    FROM 
        RankedOrders ro
    JOIN 
        nation n ON ro.c_nationkey = n.n_nationkey
    WHERE 
        ro.order_rank <= 5
),
OrderLineSummary AS (
    SELECT
        t.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        TopNOrders t
    JOIN 
        lineitem l ON t.o_orderkey = l.l_orderkey
    GROUP BY 
        t.o_orderkey
)
SELECT 
    t.n_name, 
    t.n_regionkey,
    ol.total_revenue,
    ol.line_item_count
FROM 
    OrderLineSummary ol
JOIN 
    TopNOrders t ON ol.o_orderkey = t.o_orderkey
ORDER BY 
    total_revenue DESC, 
    line_item_count DESC;