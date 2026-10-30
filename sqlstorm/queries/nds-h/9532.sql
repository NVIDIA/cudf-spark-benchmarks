WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey
), 
SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS supply_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerSegment AS (
    SELECT 
        c.c_mktsegment,
        COUNT(DISTINCT c.c_custkey) AS customer_count
    FROM 
        customer c
    GROUP BY 
        c.c_mktsegment
)
SELECT 
    ro.o_orderkey,
    ro.total_revenue,
    si.s_name,
    si.supply_count,
    cs.c_mktsegment,
    cs.customer_count
FROM 
    RankedOrders ro
JOIN 
    lineitem l ON ro.o_orderkey = l.l_orderkey
JOIN 
    SupplierInfo si ON l.l_suppkey = si.s_suppkey
JOIN 
    CustomerSegment cs ON cs.customer_count > 100
WHERE 
    ro.rn = 1
ORDER BY 
    ro.total_revenue DESC
LIMIT 10;