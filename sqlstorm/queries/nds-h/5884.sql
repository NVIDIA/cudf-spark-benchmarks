WITH RankedOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        o.o_totalprice, 
        o.o_orderstatus, 
        o.o_orderpriority, 
        c.c_name,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierParts AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
),
LineItems AS (
    SELECT 
        l.l_orderkey,
        l.l_partkey,
        l.l_quantity,
        SUM(l.l_discount) AS total_discount,
        SUM(l.l_extendedprice) AS total_extended_price
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey, l.l_partkey, l.l_quantity
)
SELECT 
    ro.c_name,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus,
    ro.o_orderpriority,
    COUNT(lp.l_orderkey) AS total_line_items,
    SUM(lp.total_extended_price) AS total_line_item_value,
    sp.total_available_qty,
    sp.total_supply_cost
FROM 
    RankedOrders ro
LEFT JOIN 
    LineItems lp ON ro.o_orderkey = lp.l_orderkey
LEFT JOIN 
    SupplierParts sp ON lp.l_partkey = sp.ps_partkey
WHERE 
    ro.rn <= 10
GROUP BY 
    ro.c_name, 
    ro.o_orderdate, 
    ro.o_totalprice, 
    ro.o_orderstatus, 
    ro.o_orderpriority,
    sp.total_available_qty, 
    sp.total_supply_cost
ORDER BY 
    ro.o_totalprice DESC;