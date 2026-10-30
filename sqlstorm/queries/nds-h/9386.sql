
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= CURRENT_DATE - INTERVAL '6 MONTH'
),
SupplierDetails AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey, s.s_name
),
OrderLineStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        SUM(l.l_quantity) AS total_quantity,
        COUNT(l.l_linenumber) AS line_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
FinalResults AS (
    SELECT 
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name,
        ol.net_revenue,
        ol.total_quantity,
        ol.line_count,
        sd.s_name,
        sd.total_supply_cost
    FROM 
        RankedOrders ro
    LEFT JOIN 
        OrderLineStats ol ON ro.o_orderkey = ol.l_orderkey
    LEFT JOIN 
        SupplierDetails sd ON ol.net_revenue > sd.total_supply_cost
    WHERE 
        ro.rn = 1
)
SELECT 
    *,
    RANK() OVER (ORDER BY o_totalprice DESC) AS price_rank
FROM 
    FinalResults
WHERE 
    net_revenue IS NOT NULL
ORDER BY 
    o_orderdate DESC, price_rank;
