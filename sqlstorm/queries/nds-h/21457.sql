
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
        s.s_acctbal IS NOT NULL
),
AggregateData AS (
    SELECT 
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price,
        COUNT(DISTINCT l.l_partkey) AS part_count,
        MAX(l.l_discount) AS max_discount
    FROM 
        lineitem l
    WHERE 
        l.l_shipdate BETWEEN '1994-01-01' AND '1994-12-31'
    GROUP BY 
        l.l_orderkey
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        ROUND(SUM(a.total_price), 2) AS total_spent,
        RANK() OVER (ORDER BY SUM(a.total_price) DESC) AS customer_rank
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    JOIN 
        AggregateData a ON o.o_orderkey = a.l_orderkey
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT tc.c_custkey) AS top_customer_count,
    AVG(tc.total_spent) AS average_spent,
    COUNT(DISTINCT CASE WHEN r.r_name IS NULL THEN 'No Region' ELSE r.r_name END) AS region_null_count
FROM 
    TopCustomers tc
LEFT JOIN 
    customer c ON tc.c_custkey = c.c_custkey
LEFT JOIN 
    nation n ON c.c_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
RIGHT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = c.c_custkey
GROUP BY 
    n.n_name
ORDER BY 
    top_customer_count DESC NULLS LAST
LIMIT 10;
