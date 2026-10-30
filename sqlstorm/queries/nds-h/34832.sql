WITH RECURSIVE SupplierHierarchy AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        1 AS level
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 1000

    UNION ALL
    
    SELECT 
        sp.s_suppkey,
        sp.s_name,
        sp.s_nationkey,
        sh.level + 1 AS level
    FROM 
        supplier sp
    JOIN 
        SupplierHierarchy sh ON sp.s_nationkey = sh.s_nationkey
    WHERE 
        sp.s_acctbal < sh.level * 1000
)
SELECT 
    p.p_name,
    COUNT(DISTINCT li.l_orderkey) AS order_count,
    AVG(li.l_extendedprice) AS avg_price,
    SUM(CASE WHEN li.l_discount = 0 THEN 1 ELSE 0 END) AS no_discount,
    r.r_name AS region_name,
    n.n_name AS nation_name,
    CONCAT(s.s_name, ' (', s.s_suppkey, ')') AS supplier_info,
    DENSE_RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(li.l_extendedprice) DESC) AS rank_within_nation
FROM 
    part p
JOIN 
    lineitem li ON p.p_partkey = li.l_partkey
JOIN 
    partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    customer c ON li.l_orderkey = c.c_custkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
LEFT JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    li.l_shipdate >= '1997-01-01'
    AND li.l_shipdate < '1998-01-01'
    AND p.p_size IN (10, 20, 30)
    AND (s.s_acctbal IS NOT NULL OR s.s_comment LIKE '%important%')
GROUP BY 
    p.p_name, r.r_name, n.n_name, s.s_name, s.s_suppkey
HAVING 
    COUNT(DISTINCT li.l_orderkey) > 5
ORDER BY 
    order_count DESC, avg_price ASC
LIMIT 15 OFFSET 10;