WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s_acctbal) 
            FROM supplier 
            WHERE s_acctbal IS NOT NULL
        )
),
AggregatedOrders AS (
    SELECT 
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY 
        o.o_custkey
)
SELECT 
    c.c_name AS customer_name,
    COALESCE(rn.rn, 0) AS supplier_rank,
    COALESCE(a.total_spent, 0) AS customer_total_spent,
    p.p_name,
    p.p_retailprice,
    (CASE 
        WHEN a.total_spent > 1000 THEN 'High Value'
        WHEN a.total_spent BETWEEN 500 AND 1000 THEN 'Medium Value'
        ELSE 'Low Value'
    END) AS customer_value_segment,
    (p.p_retailprice * 1.1) AS adjusted_price
FROM 
    customer c
LEFT JOIN 
    AggregatedOrders a ON c.c_custkey = a.o_custkey
LEFT JOIN 
    RankedSuppliers rn ON rn.s_suppkey = (
        SELECT ps.ps_suppkey 
        FROM partsupp ps 
        JOIN part p ON ps.ps_partkey = p.p_partkey
        WHERE p.p_size > 20
        LIMIT 1
    )
JOIN 
    part p ON p.p_partkey IN (
        SELECT ps.ps_partkey 
        FROM partsupp ps 
        WHERE ps.ps_availqty > 0
    )
WHERE 
    c.c_nationkey IN (
        SELECT n.n_nationkey 
        FROM nation n 
        WHERE n.n_regionkey = (
            SELECT r.r_regionkey 
            FROM region r 
            WHERE r.r_name = 'Europe'
        )
    )
ORDER BY 
    customer_total_spent DESC;