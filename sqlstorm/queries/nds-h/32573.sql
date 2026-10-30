WITH RECURSIVE CustomerHierarchy AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal, 0 AS Level
    FROM customer c
    WHERE c.c_nationkey = (SELECT n.n_nationkey FROM nation n WHERE n.n_name = 'USA')
    
    UNION ALL
    
    SELECT c.c_custkey, c.c_name, c.c_acctbal, ch.Level + 1
    FROM customer c
    JOIN CustomerHierarchy ch ON c.c_custkey = ch.c_custkey 
)
SELECT 
    pr.p_name,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    COUNT(DISTINCT c.c_custkey) AS UniqueCustomers,
    RANK() OVER (PARTITION BY pr.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
FROM 
    part pr
JOIN 
    partsupp ps ON pr.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
LEFT JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    l.l_shipdate >= '1997-01-01' AND 
    l.l_shipdate < '1997-10-01' AND 
    (l.l_returnflag = 'N' OR l.l_returnflag IS NULL)
GROUP BY 
    pr.p_partkey, pr.p_name
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY 
    TotalRevenue DESC
LIMIT 10;