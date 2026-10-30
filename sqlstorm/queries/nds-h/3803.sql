WITH SupplierCost AS (
    SELECT 
        ps_suppkey,
        SUM(ps_supplycost * ps_availqty) AS total_supply_cost
    FROM 
        partsupp
    GROUP BY 
        ps_suppkey
),
CustomerOrderCount AS (
    SELECT 
        c_custkey,
        COUNT(o_orderkey) AS order_count,
        SUM(o_totalprice) AS total_spent
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c_custkey
),
HighValueSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        sc.total_supply_cost
    FROM 
        supplier s
    JOIN 
        SupplierCost sc ON s.s_suppkey = sc.ps_suppkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s_acctbal) FROM supplier)
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        cc.order_count,
        cc.total_spent
    FROM 
        customer c
    JOIN 
        CustomerOrderCount cc ON c.c_custkey = cc.c_custkey
    WHERE 
        cc.total_spent > (SELECT AVG(total_spent) FROM CustomerOrderCount)
)
SELECT 
    c.c_name AS customer_name,
    c.order_count,
    c.total_spent,
    s.s_name AS supplier_name,
    s.total_supply_cost,
    CASE 
        WHEN s.total_supply_cost IS NULL THEN 'No Supply Cost'
        ELSE 'Has Supply Cost'
    END AS supply_cost_status
FROM 
    TopCustomers c
LEFT JOIN 
    HighValueSuppliers s ON c.order_count > 5
WHERE 
    c.order_count > 0
ORDER BY 
    c.total_spent DESC, 
    s.total_supply_cost ASC
LIMIT 10;
