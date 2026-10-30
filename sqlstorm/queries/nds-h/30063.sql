WITH  CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(o.o_totalprice) DESC) AS spend_rank
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
        co.total_spent,
        co.order_count
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.spend_rank <= 10
),
RichCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        COALESCE(SUM(p.ps_supplycost * p.ps_availqty), 0) AS total_supply_cost
    FROM 
        customer c
    LEFT JOIN 
        partsupp p ON c.c_custkey = p.ps_suppkey
    WHERE 
        c.c_acctbal IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name, c.c_acctbal
    HAVING 
        c.c_acctbal > (SELECT AVG(c2.c_acctbal) FROM customer c2)
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    tc.total_spent,
    rc.c_acctbal,
    rc.total_supply_cost,
    CASE 
        WHEN tc.total_spent > 5000 THEN 'High Roller'
        ELSE 'Average Joe'
    END AS customer_type
FROM 
    TopCustomers tc
FULL OUTER JOIN 
    RichCustomers rc ON tc.c_custkey = rc.c_custkey
WHERE 
    (rc.total_supply_cost > 10000 OR tc.order_count > 5)
ORDER BY 
    total_spent DESC, rc.c_acctbal DESC;
