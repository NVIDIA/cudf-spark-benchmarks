WITH RankedOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_orderdate DESC) AS order_rank
    FROM 
        orders o
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS unique_parts,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderLineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT l.l_partkey) AS unique_line_items
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
)
SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    ro.o_orderstatus,
    ss.s_name AS supplier_name,
    ss.unique_parts,
    ss.total_available_quantity,
    ss.total_supply_value,
    ol.total_revenue,
    ol.unique_line_items
FROM 
    RankedOrders ro
JOIN 
    OrderLineItemStats ol ON ro.o_orderkey = ol.l_orderkey
JOIN 
    supplier s ON s.s_nationkey IN (
        SELECT n.n_nationkey FROM nation n WHERE n.n_name IN ('USA', 'Canada')
    )
JOIN 
    (SELECT ss.s_suppkey, ss.s_name, ss.unique_parts, ss.total_available_quantity, ss.total_supply_value
     FROM SupplierStats ss
     WHERE ss.unique_parts > 5) ss ON ss.s_suppkey = s.s_suppkey
ORDER BY 
    ro.o_orderdate DESC,
    ss.total_supply_value DESC;