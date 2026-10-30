
WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS order_rank
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
), SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
), HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) AS total_value
    FROM 
        lineitem lp 
    JOIN 
        supplier s ON lp.l_suppkey = s.s_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        SUM(lp.l_extendedprice * (1 - lp.l_discount)) > 100000
) 
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.c_name,
    sp.total_avail_qty,
    sp.avg_supply_cost,
    hvs.s_name AS high_value_supplier_name
FROM 
    RankedOrders ro
LEFT JOIN 
    SupplierParts sp ON sp.ps_partkey = (
        SELECT 
            ps.ps_partkey 
        FROM 
            partsupp ps 
        WHERE 
            ps.ps_suppkey IN (SELECT hvs.s_suppkey FROM HighValueSuppliers hvs)
        ORDER BY 
            ps.ps_availqty DESC 
        LIMIT 1
    )
LEFT JOIN 
    HighValueSuppliers hvs ON hvs.s_suppkey = (
        SELECT 
            s.s_suppkey 
        FROM 
            HighValueSuppliers s 
        ORDER BY 
            s.total_value DESC 
        LIMIT 1
    )
WHERE 
    ro.order_rank = 1
ORDER BY 
    ro.o_orderdate DESC;
