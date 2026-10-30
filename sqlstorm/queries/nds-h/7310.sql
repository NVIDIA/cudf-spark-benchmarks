WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        AVG(s.s_acctbal) AS avg_acct_balance
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY 
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        co.total_spent
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent > (SELECT AVG(total_spent) FROM CustomerOrders)
)
SELECT 
    hs.s_name AS supplier_name,
    hs.total_supply_cost,
    hc.c_name AS customer_name,
    hc.total_spent
FROM 
    SupplierStats hs
JOIN 
    HighValueCustomers hc ON hs.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
ORDER BY 
    hs.total_supply_cost DESC,
    hc.total_spent DESC
LIMIT 10;
