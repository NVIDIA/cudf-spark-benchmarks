WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_nationkey = s.s_nationkey)
),
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent,
        RANK() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS customer_rank
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.s_suppkey,
    r.s_name,
    r.s_acctbal,
    c.c_name AS top_customer,
    c.order_count,
    c.total_spent,
    CASE 
        WHEN c.total_spent IS NULL THEN 'No Orders'
        ELSE CONCAT('Spent: $', ROUND(c.total_spent, 2))
    END AS spent_info
FROM 
    RankedSuppliers r
LEFT JOIN 
    CustomerOrders c ON r.rnk = 1
ORDER BY 
    r.s_acctbal DESC, c.total_spent DESC
LIMIT 10;
