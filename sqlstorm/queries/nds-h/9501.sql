WITH ProductSupplierStats AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        p.p_partkey, p.p_name
),
NationCustomerOrders AS (
    SELECT 
        n.n_name AS nation,
        COUNT(DISTINCT c.c_custkey) AS customer_count,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        nation n
    JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    p.p_name,
    p.total_available,
    p.avg_supply_cost,
    p.supplier_count,
    n.nation,
    n.customer_count,
    n.total_order_value
FROM 
    ProductSupplierStats p
JOIN 
    NationCustomerOrders n ON p.p_partkey = n.customer_count
ORDER BY 
    total_order_value DESC, avg_supply_cost ASC
LIMIT 100;
