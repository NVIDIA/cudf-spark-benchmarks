WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
LineItemSummary AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_suppkey) AS unique_suppliers
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderstatus,
    ro.o_orderdate,
    ro.o_totalprice,
    COALESCE(ls.total_revenue, 0) AS total_revenue,
    ss.s_name,
    ss.total_available,
    ss.avg_supply_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItemSummary ls ON ro.o_orderkey = ls.l_orderkey
JOIN 
    SupplierStats ss ON ss.total_available > 100 
WHERE 
    ro.rn = 1
ORDER BY 
    ro.o_orderdate DESC, ro.o_totalprice DESC;