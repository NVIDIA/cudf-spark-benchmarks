WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_availqty) AS total_available_qty,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        sps.s_suppkey, 
        sps.s_name, 
        sps.total_available_qty,
        ROW_NUMBER() OVER (ORDER BY sps.total_available_qty DESC) AS rank
    FROM 
        SupplierParts sps
    WHERE 
        sps.total_available_qty > (SELECT AVG(total_available_qty) FROM SupplierParts)
)
SELECT 
    co.c_name AS CustomerName,
    co.total_spent AS TotalSpent,
    hvs.s_name AS SupplierName,
    hvs.total_available_qty AS TotalAvailableQty,
    CASE 
        WHEN hvs.total_available_qty IS NULL THEN 'No Supplies'
        ELSE 'Supplied'
    END AS SupplyStatus
FROM 
    CustomerOrders co
LEFT JOIN 
    HighValueSuppliers hvs ON co.c_custkey % 10 = hvs.s_suppkey % 10
WHERE 
    co.order_count > 5
ORDER BY 
    co.total_spent DESC, 
    hvs.total_available_qty DESC
LIMIT 10;
