
WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(ps.ps_availqty) AS available_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    LEFT JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
RankedSuppliers AS (
    SELECT 
        s.s_name,
        s.available_parts,
        s.total_supply_cost,
        ROW_NUMBER() OVER (ORDER BY s.total_supply_cost DESC) AS supply_rank
    FROM 
        SupplierStats s
),
RankedCustomers AS (
    SELECT 
        c.c_name,
        c.total_orders,
        c.order_count,
        RANK() OVER (ORDER BY c.total_orders DESC) AS order_rank
    FROM 
        CustomerStats c
),
HighValueCustomers AS (
    SELECT 
        rc.c_name,
        rc.total_orders,
        rs.s_name,
        rs.available_parts
    FROM 
        RankedCustomers rc
    JOIN 
        RankedSuppliers rs ON rc.order_count > 10 AND rs.supply_rank <= 5
)
SELECT 
    hvc.c_name AS customer_name,
    CONCAT('Orders: ', CAST(hvc.total_orders AS STRING), ', Supplier: ', hvc.s_name) AS order_details,
    CASE 
        WHEN hvc.available_parts IS NULL THEN 'No available parts' 
        ELSE CAST(hvc.available_parts AS STRING) 
    END AS part_availability
FROM 
    HighValueCustomers hvc
WHERE 
    hvc.total_orders > 5000
ORDER BY 
    hvc.total_orders DESC;
