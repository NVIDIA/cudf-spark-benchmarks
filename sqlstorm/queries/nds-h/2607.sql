WITH SupplierStats AS (
    SELECT 
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS total_suppliers
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
),
CustomerStats AS (
    SELECT 
        c.c_nationkey,
        SUM(o.o_totalprice) AS total_order_value,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
JoinedStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
        COALESCE(cs.total_order_value, 0) AS total_order_value,
        ss.total_suppliers,
        cs.total_orders
    FROM 
        nation n
    LEFT JOIN 
        SupplierStats ss ON n.n_nationkey = ss.s_nationkey
    LEFT JOIN 
        CustomerStats cs ON n.n_nationkey = cs.c_nationkey
)
SELECT 
    j.n_name,
    j.total_supply_cost,
    j.total_order_value,
    j.total_suppliers,
    j.total_orders,
    (j.total_order_value - j.total_supply_cost) AS profit_margin,
    CASE 
        WHEN j.total_orders = 0 THEN 'No Orders'
        ELSE CONCAT('Orders: ', j.total_orders)
    END AS order_summary
FROM 
    JoinedStats j
WHERE 
    j.total_supply_cost > 0
ORDER BY 
    profit_margin DESC
LIMIT 10;
