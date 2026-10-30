WITH SupplierSummary AS (
    SELECT 
        s.s_nationkey, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_nationkey
), 
CustomerOrders AS (
    SELECT 
        c.c_nationkey, 
        COUNT(DISTINCT o.o_orderkey) AS total_orders, 
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        c.c_nationkey
)
SELECT 
    n.n_name, 
    ss.total_supply_cost, 
    ss.supplier_count, 
    co.total_orders, 
    co.avg_order_value
FROM 
    nation n
LEFT JOIN 
    SupplierSummary ss ON n.n_nationkey = ss.s_nationkey
LEFT JOIN 
    CustomerOrders co ON n.n_nationkey = co.c_nationkey
WHERE 
    ss.total_supply_cost IS NOT NULL OR co.total_orders IS NOT NULL
ORDER BY 
    total_supply_cost DESC, avg_order_value DESC;