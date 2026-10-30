WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
),
SelectedOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderpriority,
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.rank <= 10
),
OrderDetails AS (
    SELECT 
        so.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_linenumber) AS total_line_items
    FROM 
        SelectedOrders so
    JOIN 
        lineitem l ON so.o_orderkey = l.l_orderkey
    GROUP BY 
        so.o_orderkey
)
SELECT 
    so.o_orderkey,
    so.o_orderdate,
    so.o_totalprice,
    so.o_orderpriority,
    so.c_mktsegment,
    od.revenue,
    od.total_line_items
FROM 
    SelectedOrders so
JOIN 
    OrderDetails od ON so.o_orderkey = od.o_orderkey
ORDER BY 
    so.o_orderdate DESC, od.revenue DESC;