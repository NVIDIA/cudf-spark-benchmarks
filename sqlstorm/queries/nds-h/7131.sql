WITH OrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS parts_supplied,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
RevenueByNation AS (
    SELECT 
        n.n_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM 
        nation n
    JOIN 
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        n.n_name
)
SELECT 
    os.c_custkey,
    os.c_name,
    os.total_spent,
    os.total_orders,
    os.avg_order_value,
    sp.s_suppkey,
    sp.s_name,
    sp.parts_supplied,
    sp.total_supply_cost,
    rn.n_name,
    rn.total_revenue
FROM 
    OrderSummary os
JOIN 
    SupplierPerformance sp ON os.total_orders > 10
JOIN 
    RevenueByNation rn ON os.total_spent > 1000 AND rn.total_revenue > 5000
ORDER BY 
    os.total_spent DESC, sp.total_supply_cost ASC;