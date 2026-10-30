WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
), 
CustomerOrders AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey, c.c_name
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(rs.s_name, 'No Supplier') AS supplier_name,
    COALESCE(rs.s_acctbal, 0) AS supplier_account_balance,
    COALESCE(co.total_spent, 0) AS customer_total_spent,
    co.order_count,
    CASE 
        WHEN co.total_spent > 0 THEN 
            ROUND(co.total_spent / NULLIF(co.order_count, 0), 2)
        ELSE 0 
    END AS avg_order_value
FROM 
    part p
LEFT JOIN 
    RankedSuppliers rs ON p.p_partkey = rs.rnk AND rs.rnk = 1
LEFT JOIN 
    CustomerOrders co ON co.c_custkey = (
        SELECT c.c_custkey 
        FROM customer c 
        ORDER BY c.c_acctbal DESC 
        LIMIT 1
    )
WHERE 
    p.p_retailprice > (
        SELECT AVG(p2.p_retailprice) 
        FROM part p2
    )
ORDER BY 
    p.p_partkey;
