WITH SupplierPartInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrderInfo AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    spi.s_name,
    spi.total_supply_cost,
    coi.c_name,
    coi.total_order_value,
    spi.total_parts_supplied,
    coi.total_orders
FROM 
    SupplierPartInfo spi
JOIN 
    CustomerOrderInfo coi ON spi.total_parts_supplied > 5 AND coi.total_order_value > 1000
ORDER BY 
    spi.total_supply_cost DESC, coi.total_order_value DESC
LIMIT 10;
