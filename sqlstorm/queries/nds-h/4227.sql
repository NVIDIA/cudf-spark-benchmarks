WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM 
        supplier s
    WHERE 
        s.s_acctbal IS NOT NULL
), 
HighValueParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice, 
        SUM(ps.ps_supplycost * ps.ps_availqty) AS supply_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 1000
)
SELECT 
    n.n_name AS nation_name,
    COUNT(DISTINCT c.c_custkey) AS customer_count,
    SUM(o.o_totalprice) AS total_revenue,
    COALESCE(SUM(lp.l_extendedprice * (1 - lp.l_discount)), 0) AS total_sales,
    AVG(lp.l_quantity) AS avg_quantity,
    (CASE 
        WHEN AVG(lp.l_discount) IS NOT NULL THEN AVG(lp.l_discount)
        ELSE 0 
    END) AS avg_discount
FROM 
    nation n
LEFT JOIN 
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN 
    orders o ON c.c_custkey = o.o_custkey
LEFT JOIN 
    lineitem lp ON o.o_orderkey = lp.l_orderkey
JOIN 
    RankedSuppliers rs ON rs.s_suppkey = lp.l_suppkey AND rs.rnk = 1
JOIN 
    HighValueParts hvp ON hvp.p_partkey = lp.l_partkey
WHERE 
    n.n_name LIKE 'A%'
    AND o.o_orderdate >= DATE '1997-01-01'
    AND o.o_orderdate < DATE '1998-01-01'
GROUP BY 
    n.n_name
ORDER BY 
    total_revenue DESC
LIMIT 10;