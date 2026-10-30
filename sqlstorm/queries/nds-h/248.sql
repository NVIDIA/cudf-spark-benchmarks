
WITH SupplierPerformance AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supply_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name, s.s_nationkey
), 
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue,
        COUNT(l.l_orderkey) AS item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F' AND o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
), 
CustomerPerformance AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.net_revenue) AS customer_revenue,
        COUNT(os.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        OrderSummary os ON c.c_custkey = os.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        cp.c_custkey,
        cp.c_name,
        cp.customer_revenue,
        cp.total_orders,
        CASE 
            WHEN cp.customer_revenue > 10000 THEN 'VIP'
            WHEN cp.customer_revenue BETWEEN 5000 AND 10000 THEN 'Gold'
            ELSE 'Regular' 
        END AS customer_segment
    FROM 
        CustomerPerformance cp
    WHERE 
        cp.customer_revenue IS NOT NULL
)
SELECT 
    hvc.c_name AS customer_name,
    hvc.customer_segment,
    sp.s_name AS supplier_name,
    sp.total_supply_cost,
    hvc.customer_revenue
FROM 
    HighValueCustomers hvc
LEFT JOIN 
    SupplierPerformance sp ON hvc.total_orders > 2 AND sp.supply_rank = 1
WHERE 
    hvc.customer_revenue IS NOT NULL
ORDER BY 
    hvc.customer_revenue DESC, sp.total_supply_cost ASC;
