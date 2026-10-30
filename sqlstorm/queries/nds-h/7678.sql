WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, n.n_name
),

CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),

HighValueSuppliers AS (
    SELECT 
        sd.s_suppkey,
        sd.s_name,
        sd.nation_name,
        sd.total_supply_cost
    FROM 
        SupplierDetails sd
    WHERE 
        sd.total_supply_cost > (
            SELECT 
                AVG(total_supply_cost) 
            FROM 
                SupplierDetails
        )
),

HighValueCustomers AS (
    SELECT 
        co.c_custkey,
        co.c_name,
        co.total_order_value
    FROM 
        CustomerOrders co
    WHERE 
        co.total_order_value > (
            SELECT 
                AVG(total_order_value) 
            FROM 
                CustomerOrders
        )
)

SELECT 
    hvs.s_suppkey,
    hvs.s_name,
    hvs.nation_name,
    hvs.total_supply_cost,
    hvc.c_custkey,
    hvc.c_name,
    hvc.total_order_value
FROM 
    HighValueSuppliers hvs
JOIN 
    HighValueCustomers hvc ON hvc.total_order_value > 1000
ORDER BY 
    hvs.total_supply_cost DESC, hvc.total_order_value DESC
LIMIT 50;
