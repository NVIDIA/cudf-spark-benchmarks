WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) as rn
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
        COUNT(*) AS item_count
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY 
        l.l_orderkey
)
SELECT 
    r.o_orderkey,
    r.o_orderdate,
    r.c_name,
    COALESCE(l.total_revenue, 0) AS total_revenue,
    COALESCE(l.item_count, 0) AS item_count,
    CASE 
        WHEN l.total_revenue IS NULL THEN 'No Items'
        WHEN l.item_count > 5 THEN 'High Volume'
        ELSE 'Low Volume'
    END AS order_category
FROM 
    RankedOrders r
LEFT OUTER JOIN 
    LineItemSummary l ON r.o_orderkey = l.l_orderkey
WHERE 
    r.rn = 1
ORDER BY 
    r.o_orderdate DESC, r.o_orderkey ASC;