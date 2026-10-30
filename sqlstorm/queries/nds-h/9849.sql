WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
        COUNT(DISTINCT p.p_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ss.total_supply_value,
        ss.part_count
    FROM 
        SupplierStats ss
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    WHERE 
        ss.total_supply_value > 100000
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_orders,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cu.c_custkey,
        cu.c_name,
        cu.total_orders,
        cu.order_count
    FROM 
        CustomerOrders cu
    WHERE 
        cu.total_orders > 50000
)
SELECT 
    hvs.s_suppkey,
    hvs.s_name,
    hvc.c_custkey,
    hvc.c_name,
    hvc.total_orders,
    hvc.order_count
FROM 
    HighValueSuppliers hvs
JOIN 
    HighValueCustomers hvc ON hvc.order_count > 5
ORDER BY 
    hvs.total_supply_value DESC, hvc.total_orders DESC
LIMIT 100;
