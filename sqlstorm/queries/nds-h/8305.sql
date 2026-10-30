WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_acctbal
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    ns.n_name AS nation_name,
    rs.r_name AS region_name,
    ss.s_name AS supplier_name,
    ss.total_available_quantity,
    ss.total_supply_cost,
    co.total_orders,
    co.total_order_value
FROM 
    nation ns
JOIN 
    region rs ON ns.n_regionkey = rs.r_regionkey
JOIN 
    SupplierStats ss ON ns.n_nationkey = ss.s_suppkey
JOIN 
    CustomerOrders co ON ns.n_nationkey = co.c_custkey
WHERE 
    ss.total_supply_cost > 1000
ORDER BY 
    total_order_value DESC, 
    total_available_quantity ASC
LIMIT 100;
