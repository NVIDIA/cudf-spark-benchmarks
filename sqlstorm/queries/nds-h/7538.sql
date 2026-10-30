WITH SupplierStats AS (
    SELECT 
        s_nationkey,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps_suppkey) AS supplier_count
    FROM 
        partsupp
    JOIN 
        supplier ON partsupp.ps_suppkey = supplier.s_suppkey
    GROUP BY 
        s_nationkey
),
OrderStats AS (
    SELECT 
        c_nationkey,
        COUNT(DISTINCT o_orderkey) AS total_orders,
        SUM(o_totalprice) AS total_revenue
    FROM 
        orders
    JOIN 
        customer ON orders.o_custkey = customer.c_custkey
    GROUP BY 
        c_nationkey
)
SELECT 
    r.r_name AS region_name,
    COALESCE(s.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(s.supplier_count, 0) AS total_suppliers,
    COALESCE(o.total_orders, 0) AS total_orders,
    COALESCE(o.total_revenue, 0) AS total_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    SupplierStats s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    OrderStats o ON n.n_nationkey = o.c_nationkey
ORDER BY 
    region_name;
