WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        COUNT(DISTINCT s_suppkey) AS total_suppliers,
        SUM(s_acctbal) AS total_balance
    FROM 
        supplier
    GROUP BY 
        s_nationkey
),
OrderStats AS (
    SELECT 
        c.c_nationkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_nationkey
),
PartSupplierStats AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
AggregateStats AS (
    SELECT 
        r.r_name,
        COALESCE(ss.total_suppliers, 0) AS supplier_count,
        COALESCE(os.total_orders, 0) AS order_count,
        COALESCE(os.total_order_value, 0) AS order_value,
        COALESCE(ps.total_available, 0) AS total_available,
        COALESCE(ps.total_supply_cost, 0) AS total_supply_cost
    FROM 
        region r
    LEFT JOIN 
        SupplierStats ss ON r.r_regionkey = ss.s_nationkey
    LEFT JOIN 
        OrderStats os ON r.r_regionkey = os.c_nationkey
    LEFT JOIN 
        PartSupplierStats ps ON ss.s_nationkey = ps.ps_partkey
)
SELECT 
    r_name,
    SUM(supplier_count) AS total_suppliers,
    SUM(order_count) AS total_orders,
    SUM(order_value) AS total_order_value,
    SUM(total_available) AS total_available_qty,
    SUM(total_supply_cost) AS total_supply_cost
FROM 
    AggregateStats
GROUP BY 
    r_name
ORDER BY 
    total_order_value DESC, 
    total_suppliers DESC;
