WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus = 'F'
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_quantity,
        COUNT(*) AS lineitem_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
FinalReport AS (
    SELECT 
        r.o_orderkey,
        r.o_orderdate,
        r.c_name,
        l.total_revenue,
        l.avg_quantity,
        l.lineitem_count
    FROM 
        RankedOrders r
    JOIN 
        LineItemSummary l ON r.o_orderkey = l.l_orderkey
    WHERE 
        r.rn <= 5
)
SELECT 
    f.o_orderkey,
    f.o_orderdate,
    f.c_name,
    f.total_revenue,
    f.avg_quantity,
    f.lineitem_count
FROM 
    FinalReport f
ORDER BY 
    f.total_revenue DESC
LIMIT 10;
