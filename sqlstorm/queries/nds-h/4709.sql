
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        r.r_name,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2)
    GROUP BY 
        p.p_partkey, p.p_name
    HAVING 
        SUM(ps.ps_supplycost * ps.ps_availqty) > 100000
)
SELECT 
    o.o_orderkey,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
    COUNT(DISTINCT l.l_orderkey) AS total_lines,
    COALESCE(rg.r_name, 'Unknown Region') AS supplier_region,
    hp.p_name AS high_value_part
FROM 
    orders o
JOIN 
    lineitem l ON o.o_orderkey = l.l_orderkey
LEFT JOIN 
    RankedSuppliers rg ON l.l_suppkey = rg.s_suppkey AND rg.rank <= 3
JOIN 
    HighValueParts hp ON l.l_partkey = hp.p_partkey
WHERE 
    o.o_orderdate >= '1997-01-01'
    AND (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    o.o_orderkey, rg.r_name, hp.p_name
ORDER BY 
    revenue DESC
LIMIT 100;
