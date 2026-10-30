WITH SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.total_available_quantity,
        sp.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY sp.total_supply_cost DESC) AS ranking
    FROM 
        SupplierParts sp
    WHERE 
        sp.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierParts)
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    n.n_name AS nation,
    hs.s_name AS supplier_name,
    os.total_order_value,
    hs.total_available_quantity,
    hs.total_supply_cost
FROM 
    HighValueSuppliers hs
JOIN 
    customer c ON hs.s_suppkey = c.c_nationkey
JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
JOIN 
    OrderSummary os ON hs.s_suppkey = os.o_orderkey
WHERE 
    hs.ranking <= 10
ORDER BY 
    os.total_order_value DESC, hs.total_supply_cost DESC;
