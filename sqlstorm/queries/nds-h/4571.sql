WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY ps_supplycost DESC) as rnk
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
        ROW_NUMBER() OVER (ORDER BY c.c_acctbal DESC) as rnk
    FROM 
        customer c
    WHERE 
        c.c_acctbal > (SELECT AVG(c_acctbal) FROM customer)
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.p_brand,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    CASE 
        WHEN SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000000 THEN 'High Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category,
    rs.s_name AS top_supplier
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey AND rs.rnk = 1
WHERE 
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    AND p.p_size IN (SELECT DISTINCT ps.ps_partkey FROM partsupp ps WHERE ps.ps_availqty > 0)
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, rs.s_name
HAVING 
    COUNT(DISTINCT o.o_orderkey) > 5
ORDER BY 
    total_revenue DESC
LIMIT 10;