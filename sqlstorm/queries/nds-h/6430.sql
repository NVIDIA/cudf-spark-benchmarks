
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderkey ORDER BY o.o_orderdate DESC) AS rn
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(sp.total_available_qty) AS total_qty_supplied,
        AVG(sp.avg_supply_cost) AS avg_cost
    FROM 
        supplier s
    JOIN 
        SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    WHERE 
        s.s_acctbal > 1000.00
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(sp.total_available_qty) > 100
)
SELECT 
    r.r_name,
    COUNT(DISTINCT ro.o_orderkey) AS order_count,
    AVG(hv.avg_cost) AS avg_supplier_cost,
    SUM(ro.total_revenue) AS total_revenue
FROM 
    RankedOrders ro
JOIN 
    customer c ON ro.o_orderkey = c.c_custkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    HighValueSuppliers hv ON c.c_nationkey = hv.s_suppkey
WHERE 
    ro.rn = 1
GROUP BY 
    r.r_name
ORDER BY 
    total_revenue DESC;
