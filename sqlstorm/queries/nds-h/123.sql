WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT p.p_partkey) AS unique_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey, 
        o.o_custkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_custkey
    HAVING 
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000 
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(h.order_value) AS total_order_value
    FROM 
        customer c
    LEFT JOIN 
        HighValueOrders h ON c.c_custkey = h.o_custkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    cs.c_custkey,
    cs.c_name,
    cs.total_orders,
    cs.total_order_value,
    COALESCE(ss.total_available_quantity, 0) AS total_available_quantity,
    COALESCE(ss.total_supply_cost, 0) AS total_supply_cost,
    ss.unique_parts_supplied,
    CASE 
        WHEN cs.total_order_value IS NULL THEN 'No Orders'
        WHEN cs.total_order_value < 5000 THEN 'Regular Customer'
        ELSE 'VIP Customer'
    END AS customer_status
FROM 
    CustomerOrderStats cs
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT 
            ps.ps_suppkey 
        FROM 
            partsupp ps 
        JOIN 
            part p ON ps.ps_partkey = p.p_partkey 
        WHERE 
            p.p_name LIKE '%premium%'
        LIMIT 1
    )
ORDER BY 
    cs.total_order_value DESC, 
    cs.c_name;