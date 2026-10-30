
WITH CustomerOrders AS (
    SELECT 
        c.c_custkey AS custkey,
        c.c_name AS name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT 
        c.custkey,
        c.name,
        c.total_spent,
        c.order_count,
        RANK() OVER (ORDER BY c.total_spent DESC) AS rank
    FROM 
        CustomerOrders c
)
SELECT 
    tc.rank,
    tc.custkey,
    tc.name,
    tc.total_spent,
    CASE 
        WHEN tc.order_count >= 5 THEN 'Frequent'
        WHEN tc.order_count BETWEEN 1 AND 4 THEN 'Occasional'
        ELSE 'Rare'
    END AS customer_type,
    COALESCE(SUM(p.ps_supplycost), 0) AS total_supply_cost
FROM 
    TopCustomers tc
LEFT JOIN 
    partsupp p ON tc.custkey = p.ps_partkey
LEFT JOIN 
    supplier s ON p.ps_suppkey = s.s_suppkey
WHERE 
    tc.rank <= 10
GROUP BY 
    tc.rank, tc.custkey, tc.name, tc.total_spent, tc.order_count
ORDER BY 
    tc.rank;
