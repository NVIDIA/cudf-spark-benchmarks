WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS total_orders
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROW_NUMBER() OVER (ORDER BY total_spent DESC) AS rank
    FROM 
        CustomerOrders c
    WHERE 
        total_spent IS NOT NULL
),
MaxSupplyCost AS (
    SELECT 
        MAX(total_supply_cost) AS max_supply
    FROM 
        SupplierParts
),
SuppliersWithMaxCost AS (
    SELECT 
        s.s_name,
        s.total_supply_cost
    FROM 
        SupplierParts s
    JOIN 
        MaxSupplyCost m ON s.total_supply_cost = m.max_supply
)
SELECT 
    tc.c_name AS top_customer,
    sc.s_name AS supplier_with_max_cost,
    sc.total_supply_cost
FROM 
    TopCustomers tc
CROSS JOIN 
    SuppliersWithMaxCost sc
WHERE 
    tc.rank <= 5
ORDER BY 
    sc.total_supply_cost DESC;
