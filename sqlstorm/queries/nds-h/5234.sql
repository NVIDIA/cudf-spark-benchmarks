WITH RankedCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY c.c_acctbal DESC) AS RankInRegion
    FROM 
        customer c
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
), 
TopCustomers AS (
    SELECT 
        c.c_custkey, c.c_name, c.c_acctbal, n.n_name AS region_name
    FROM 
        RankedCustomers c
    JOIN 
        nation n ON c.c_custkey = n.n_nationkey
    WHERE 
        c.RankInRegion <= 5
), 
CustomerOrders AS (
    SELECT 
        o.o_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM 
        orders o
    JOIN 
        TopCustomers t ON o.o_custkey = t.c_custkey
    GROUP BY 
        o.o_custkey
)
SELECT 
    tc.c_name,
    tc.region_name,
    co.total_orders,
    co.total_spent,
    RANK() OVER (ORDER BY co.total_spent DESC) AS spender_rank
FROM 
    TopCustomers tc
JOIN 
    CustomerOrders co ON tc.c_custkey = co.o_custkey
ORDER BY 
    co.total_spent DESC;
