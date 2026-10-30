
WITH SupplierPartCosts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
), 
TopSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        spc.total_supply_cost
    FROM 
        SupplierPartCosts spc
    JOIN 
        supplier s ON spc.s_suppkey = s.s_suppkey
    ORDER BY 
        spc.total_supply_cost DESC
    LIMIT 10
), 
OrderLineItemDetails AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderdate, 
        l.l_partkey, 
        l.l_suppkey, 
        l.l_quantity, 
        l.l_extendedprice, 
        l.l_discount, 
        l.l_tax
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
), 
SupplierOrderSummary AS (
    SELECT 
        tsl.s_suppkey, 
        tsl.s_name, 
        SUM(ol.l_quantity * ol.l_extendedprice) AS total_order_value
    FROM 
        TopSuppliers tsl
    JOIN 
        OrderLineItemDetails ol ON tsl.s_suppkey = ol.l_suppkey
    GROUP BY 
        tsl.s_suppkey, tsl.s_name
) 
SELECT 
    sos.s_suppkey, 
    sos.s_name, 
    sos.total_order_value, 
    COALESCE(spc.total_supply_cost, 0) AS total_supply_cost,
    (sos.total_order_value - COALESCE(spc.total_supply_cost, 0)) AS profit_margin
FROM 
    SupplierOrderSummary sos
LEFT JOIN 
    SupplierPartCosts spc ON sos.s_suppkey = spc.s_suppkey
ORDER BY 
    profit_margin DESC
LIMIT 10;
