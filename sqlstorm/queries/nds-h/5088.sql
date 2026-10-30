WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        l.l_shipdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts_supplied,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_avail_qty
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), TopSuppliers AS (
    SELECT 
        ss.s_suppkey, 
        ss.unique_parts_supplied, 
        ss.avg_supply_cost, 
        ss.total_avail_qty,
        ROW_NUMBER() OVER (ORDER BY ss.total_avail_qty DESC) AS supplier_rank
    FROM 
        SupplierStats ss
)
SELECT 
    ro.o_orderkey,
    ro.total_revenue,
    ts.unique_parts_supplied,
    ts.avg_supply_cost,
    ts.total_avail_qty
FROM 
    RankedOrders ro
JOIN 
    TopSuppliers ts ON ro.order_rank <= 5
WHERE 
    ro.total_revenue > 10000
ORDER BY 
    ro.total_revenue DESC, 
    ts.avg_supply_cost ASC;