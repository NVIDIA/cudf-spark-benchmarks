WITH SupplierCost AS (
    SELECT 
        ps.ps_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_suppkey
),
NationStats AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        COUNT(DISTINCT c.c_custkey) AS total_customers,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_order_value
    FROM 
        nation n
    LEFT JOIN 
        supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN 
        customer c ON s.s_suppkey = c.c_nationkey
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_nationkey, n.n_name
),
LineItemStats AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        lineitem l
    GROUP BY 
        l.l_orderkey
),
FinalReport AS (
    SELECT 
        n.n_name,
        n.total_customers,
        n.total_orders,
        COALESCE(SUM(l.total_quantity), 0) AS total_lineitems,
        COALESCE(SUM(l.revenue), 0) AS total_revenue,
        sc.total_supply_cost
    FROM 
        NationStats n
    LEFT JOIN 
        LineItemStats l ON n.total_orders = l.l_orderkey
    LEFT JOIN 
        SupplierCost sc ON n.n_nationkey = sc.ps_suppkey
    GROUP BY 
        n.n_name, n.total_customers, n.total_orders, sc.total_supply_cost
)
SELECT 
    f.n_name,
    f.total_customers,
    f.total_orders,
    f.total_lineitems,
    f.total_revenue,
    CASE 
        WHEN f.total_orders > 0 THEN f.total_supply_cost / f.total_orders 
        ELSE NULL 
    END AS cost_per_order
FROM 
    FinalReport f
WHERE 
    f.total_revenue > (SELECT AVG(total_revenue) FROM FinalReport)
ORDER BY 
    f.total_revenue DESC;
