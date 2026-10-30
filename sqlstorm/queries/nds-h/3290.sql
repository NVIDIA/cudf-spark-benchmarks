WITH CustomerOrderSummary AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.total_orders,
        c.total_spent,
        RANK() OVER (ORDER BY c.total_spent DESC) AS spend_rank
    FROM 
        CustomerOrderSummary c
    WHERE 
        c.total_orders > 0
),
SupplierPartSummary AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value
    FROM 
        supplier s
    INNER JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
)
SELECT 
    tc.c_name,
    tc.total_orders,
    tc.total_spent,
    sp.total_supply_value,
    CASE 
        WHEN sp.total_supply_value > 0 THEN sp.total_supply_value / NULLIF(tc.total_spent, 0) 
        ELSE NULL 
    END AS supply_to_spend_ratio
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    SupplierPartSummary sp ON tc.c_custkey = sp.s_suppkey
WHERE 
    COALESCE(tc.total_spent, 0) > 1000
    OR COALESCE(sp.total_supply_value, 0) > 50000
ORDER BY 
    tc.total_spent DESC NULLS LAST;
