
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
HighValueCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) AS customer_rank
    FROM 
        customer c
    WHERE 
        c.c_acctbal IS NOT NULL AND 
        c.c_acctbal > (
            SELECT AVG(c2.c_acctbal) 
            FROM customer c2 
            WHERE c2.c_acctbal IS NOT NULL
        )
)
SELECT 
    n.n_name,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    AVG(CASE 
            WHEN l.l_returnflag = 'Y' THEN 1 
            ELSE 0 
        END) AS return_flag_ratio,
    (SELECT COUNT(*)
     FROM RankedSuppliers rs 
     WHERE rs.supplier_rank = 1) AS top_supplier_count
FROM 
    nation n
LEFT JOIN 
    customer c ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    orders o ON o.o_custkey = c.c_custkey
LEFT JOIN 
    lineitem l ON l.l_orderkey = o.o_orderkey
WHERE 
    EXISTS (
        SELECT 1 
        FROM HighValueCustomers hvc 
        WHERE hvc.c_custkey = c.c_custkey AND 
              hvc.customer_rank <= 10
    ) OR 
    (n.n_name LIKE 'A%' AND c.c_acctbal IS NULL)
GROUP BY 
    n.n_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5 AND 
    SUM(l.l_extendedprice) <> 0
ORDER BY 
    total_revenue DESC
LIMIT 10;
