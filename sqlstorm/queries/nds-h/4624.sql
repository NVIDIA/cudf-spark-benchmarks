WITH CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
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
        c.c_custkey,
        c.c_name,
        co.total_spent,
        co.order_count,
        RANK() OVER (ORDER BY co.total_spent DESC) AS sales_rank
    FROM 
        CustomerOrders co
    JOIN 
        customer c ON co.c_custkey = c.c_custkey
    WHERE 
        co.total_spent IS NOT NULL
),
PartSupplier AS (
    SELECT 
        ps.ps_partkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
)
SELECT 
    tc.c_custkey,
    tc.c_name,
    COALESCE(tpc.total_cost, 0) AS total_cost_of_parts,
    CASE 
        WHEN tc.order_count > 0 THEN tc.total_spent / NULLIF(tc.order_count, 0)
        ELSE 0
    END AS avg_order_value,
    tc.sales_rank
FROM 
    TopCustomers tc
LEFT JOIN 
    (SELECT 
         l.l_partkey,
         SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_cost
     FROM 
         lineitem l
     JOIN 
         PartSupplier ps ON l.l_partkey = ps.ps_partkey
     GROUP BY 
         l.l_partkey) tpc ON tc.total_spent > tpc.total_cost
WHERE 
    tc.sales_rank <= 10
ORDER BY 
    tc.sales_rank;
