WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_orderdate, c.c_name, c.c_nationkey
), SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
), BestSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.total_available,
        ss.avg_supply_cost,
        RANK() OVER (ORDER BY ss.total_available DESC) AS supplier_rank
    FROM 
        SupplierStats ss
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.c_name,
    ro.total_revenue,
    COALESCE(bs.total_available, 0) AS supplier_avail_qty,
    bs.avg_supply_cost,
    bs.supplier_rank
FROM 
    RankedOrders ro
LEFT JOIN 
    BestSuppliers bs ON ro.o_orderkey % 10 = bs.s_suppkey  
WHERE 
    ro.rn <= 5
ORDER BY 
    ro.total_revenue DESC, bs.avg_supply_cost ASC;