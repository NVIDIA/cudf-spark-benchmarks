WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
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
OrderStats AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_value,
        COUNT(l.l_orderkey) AS total_line_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY 
        o.o_orderkey
),
HighValueOrders AS (
    SELECT 
        o.o_orderkey,
        os.total_order_value,
        ROW_NUMBER() OVER (ORDER BY os.total_order_value DESC) AS order_rank
    FROM 
        OrderStats os
    JOIN 
        orders o ON os.o_orderkey = o.o_orderkey
    WHERE 
        os.total_order_value > (
            SELECT AVG(total_order_value) FROM OrderStats
        )
),
SupplierOrderDetails AS (
    SELECT 
        ss.s_name,
        COUNT(DISTINCT ho.o_orderkey) AS high_value_order_count,
        SUM(ho.total_order_value) AS total_value_of_high_orders
    FROM 
        SupplierStats ss
    LEFT JOIN 
        partsupp ps ON ss.s_suppkey = ps.ps_suppkey
    LEFT JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    LEFT JOIN 
        HighValueOrders ho ON l.l_orderkey = ho.o_orderkey
    GROUP BY 
        ss.s_name
)
SELECT 
    sod.s_name,
    sod.high_value_order_count,
    sod.total_value_of_high_orders,
    CASE 
        WHEN sod.high_value_order_count IS NULL THEN 'No Orders'
        ELSE 'Orders Present'
    END AS order_status
FROM 
    SupplierOrderDetails sod
ORDER BY 
    sod.high_value_order_count DESC, sod.total_value_of_high_orders DESC;