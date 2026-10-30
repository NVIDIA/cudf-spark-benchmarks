WITH SupplierParts AS (
    SELECT 
        s.s_suppkey, 
        s.s_nationkey, 
        SUM(ps.ps_availqty) AS total_availability, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, 
        s.s_nationkey
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        c.c_nationkey, 
        COUNT(o.o_orderkey) AS total_orders, 
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, 
        c.c_nationkey
),
RegionSummary AS (
    SELECT 
        r.r_regionkey, 
        r.r_name, 
        SUM(sp.total_availability) AS total_parts_available, 
        SUM(co.total_orders) AS total_orders, 
        SUM(co.total_spent) AS total_spent
    FROM 
        region r
    JOIN 
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN 
        SupplierParts sp ON n.n_nationkey = sp.s_nationkey
    JOIN 
        CustomerOrders co ON n.n_nationkey = co.c_nationkey
    GROUP BY 
        r.r_regionkey, 
        r.r_name
)
SELECT 
    r.r_name,
    r.total_parts_available,
    r.total_orders,
    r.total_spent,
    CASE 
        WHEN r.total_orders = 0 THEN 0 
        ELSE r.total_spent / r.total_orders 
    END AS avg_spent_per_order
FROM 
    RegionSummary r
ORDER BY 
    r.total_spent DESC;
