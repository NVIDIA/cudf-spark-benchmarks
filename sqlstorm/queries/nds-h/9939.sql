WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        c.c_mktsegment,
        ROW_NUMBER() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-12-31'
),
TopOrders AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.o_orderstatus,
        ro.c_mktsegment
    FROM 
        RankedOrders ro
    WHERE 
        ro.rn <= 5
),
LineItemSummary AS (
    SELECT 
        t.o_orderkey,
        SUM(l.l_extendedprice) AS total_lineitem_value,
        AVG(l.l_discount) AS average_discount,
        COUNT(l.l_orderkey) AS lineitem_count
    FROM 
        TopOrders t
    JOIN 
        lineitem l ON t.o_orderkey = l.l_orderkey
    GROUP BY 
        t.o_orderkey
)
SELECT 
    o.o_orderkey,
    o.o_orderdate,
    o.o_totalprice,
    o.o_orderstatus,
    o.c_mktsegment,
    lis.total_lineitem_value,
    lis.average_discount,
    lis.lineitem_count
FROM 
    TopOrders o
JOIN 
    LineItemSummary lis ON o.o_orderkey = lis.o_orderkey
ORDER BY 
    o.o_orderdate DESC, 
    o.o_totalprice DESC;