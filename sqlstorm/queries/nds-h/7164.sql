WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        n.n_name AS nation_name, 
        RANK() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rank 
    FROM 
        supplier s 
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey 
)

SELECT 
    p.p_partkey, 
    p.p_name, 
    p.p_brand, 
    ps.ps_availqty, 
    ps.ps_supplycost, 
    rs.s_name AS top_supplier, 
    rs.nation_name, 
    SUM(l.l_extendedprice * l.l_discount) AS total_discounted_sales 
FROM 
    part p 
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey 
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey 
JOIN 
    RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey 
WHERE 
    rs.rank = 1 
    AND l.l_shipdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31' 
GROUP BY 
    p.p_partkey, p.p_name, p.p_brand, ps.ps_availqty, ps.ps_supplycost, rs.s_name, rs.nation_name 
ORDER BY 
    total_discounted_sales DESC 
LIMIT 100;