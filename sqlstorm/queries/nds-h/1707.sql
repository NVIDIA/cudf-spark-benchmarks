WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM 
        supplier s
),
TotalOrderValue AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
),
CustomerOrderTotals AS (
    SELECT 
        c.c_custkey,
        SUM(t.total_value) AS customer_total
    FROM 
        customer c
    JOIN 
        TotalOrderValue t ON c.c_custkey = t.o_orderkey
    GROUP BY 
        c.c_custkey
)
SELECT 
    r.r_name,
    AVG(c.customer_total) AS avg_customer_spend,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(s.s_acctbal) AS max_account_balance
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    CustomerOrderTotals c ON s.s_suppkey = c.c_custkey
WHERE 
    s.s_acctbal IS NOT NULL 
    AND r.r_name IS NOT NULL
GROUP BY 
    r.r_name
HAVING 
    AVG(c.customer_total) > (
        SELECT 
            AVG(customer_total)
        FROM 
            CustomerOrderTotals
    ) 
ORDER BY 
    avg_customer_spend DESC
LIMIT 10 OFFSET 5;
