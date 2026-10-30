WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON p.p_partkey = ps.ps_partkey
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighAccountSuppliers AS (
    SELECT * 
    FROM RankedSuppliers 
    WHERE rnk = 1
), 
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent,
        AVG(o.o_totalprice) AS avg_order_value
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        c.c_acctbal BETWEEN 100.00 AND 5000.00
    GROUP BY 
        c.c_custkey
)

SELECT 
    n.n_name,
    SUM(CASE 
            WHEN li.l_discount > 0.10 THEN li.l_extendedprice * (1 - li.l_discount) 
            ELSE li.l_extendedprice 
        END) AS total_revenue,
    MAX(cos.total_orders) AS max_customer_orders,
    COUNT(DISTINCT hs.s_suppkey) AS distinct_suppliers
FROM 
    nation n
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN 
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN 
    lineitem li ON li.l_partkey = p.p_partkey
LEFT JOIN 
    HighAccountSuppliers hs ON hs.s_suppkey = s.s_suppkey
LEFT JOIN 
    CustomerOrderStats cos ON cos.c_custkey = (SELECT o.o_custkey FROM orders o ORDER BY o.o_orderdate DESC LIMIT 1)
WHERE 
    li.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    AND (n.n_name LIKE 'A%' OR n.n_name LIKE '%B')
GROUP BY 
    n.n_name
HAVING 
    SUM(CASE WHEN li.l_tax IS NULL THEN 0 ELSE li.l_tax END) < 1000
ORDER BY 
    total_revenue DESC;