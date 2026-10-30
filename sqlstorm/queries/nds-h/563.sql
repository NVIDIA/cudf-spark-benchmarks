WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name, c.c_nationkey
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        co.order_count,
        co.total_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.rank <= 10
)
SELECT 
    tc.c_name AS Top_Customer,
    tc.total_spent,
    sp.total_available AS Supplier_Availability,
    sp.avg_supply_cost AS Avg_Supply_Cost,
    CASE 
        WHEN tc.total_spent > 10000 THEN 'High Value' 
        ELSE 'Standard Value' 
    END AS Customer_Value_Category
FROM 
    TopCustomers tc
LEFT JOIN 
    SupplierParts sp ON sp.total_available > 500
WHERE 
    (tc.total_spent IS NOT NULL OR sp.avg_supply_cost IS NOT NULL)
ORDER BY 
    tc.total_spent DESC;
