WITH SupplierStats AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_custkey, 
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        orders o
    GROUP BY 
        o.o_custkey
),
NationStats AS (
    SELECT 
        n.n_nationkey, 
        n.n_name, 
        COUNT(DISTINCT s.s_suppkey) AS unique_suppliers
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY 
        n.n_nationkey, n.n_name
)

SELECT 
    ns.n_name, 
    ss.s_name, 
    ss.total_supply_cost, 
    ss.total_parts_supplied, 
    os.total_orders, 
    os.total_order_value, 
    ns.unique_suppliers
FROM 
    SupplierStats ss
JOIN 
    OrderStats os ON os.o_custkey = 
        (SELECT c.c_custkey 
         FROM customer c 
         WHERE c.c_nationkey = 
             (SELECT n.n_nationkey 
              FROM nation n 
              WHERE n.n_name = 'USA'))
LEFT JOIN 
    NationStats ns ON ns.unique_suppliers > 0
ORDER BY 
    ss.total_supply_cost DESC, os.total_order_value DESC
LIMIT 10;
