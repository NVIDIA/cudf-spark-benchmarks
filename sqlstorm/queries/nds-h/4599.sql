WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
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
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueSuppliers AS (
    SELECT 
        ss.s_suppkey,
        ss.s_name,
        ss.total_available_qty,
        ss.total_supply_cost
    FROM 
        SupplierStats ss
    WHERE 
        ss.total_available_qty > 1000 AND 
        ss.total_supply_cost / NULLIF(ss.total_available_qty, 0) < 10
)
SELECT 
    co.c_name,
    co.total_orders,
    co.total_spent,
    hvs.s_name AS high_value_supplier,
    hvs.total_available_qty,
    hvs.total_supply_cost,
    RANK() OVER (PARTITION BY co.c_custkey ORDER BY co.total_spent DESC) AS spending_rank
FROM 
    CustomerOrders co
LEFT JOIN 
    HighValueSuppliers hvs ON co.total_spent > 5000
WHERE 
    co.total_orders > 1 AND
    (co.c_name LIKE '%Inc%' OR co.total_spent > 1000)
ORDER BY 
    co.total_spent DESC, co.c_name;
