WITH SupplierOrderStats AS (
    SELECT 
        s.s_name,
        n.n_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        AVG(l.l_quantity) AS avg_order_quantity,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY 
        s.s_name, n.n_name
),
RevenueRank AS (
    SELECT 
        s_name,
        n_name,
        total_orders,
        total_revenue,
        avg_order_quantity,
        total_supply_cost,
        RANK() OVER (PARTITION BY n_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        SupplierOrderStats
)
SELECT 
    n_name,
    COUNT(s_name) AS number_of_suppliers,
    SUM(total_orders) AS total_orders,
    SUM(total_revenue) AS total_revenue,
    AVG(avg_order_quantity) AS avg_quantity_per_order,
    SUM(total_supply_cost) AS total_supply_cost
FROM 
    RevenueRank
WHERE 
    revenue_rank <= 5
GROUP BY 
    n_name
ORDER BY 
    total_revenue DESC;