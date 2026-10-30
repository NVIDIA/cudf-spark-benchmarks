WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), 
FilteredOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1997-01-01' 
        AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY 
        o.o_orderkey, o.o_custkey
)
SELECT 
    p.p_partkey,
    p.p_name,
    COALESCE(SUM(l.l_quantity), 0) AS total_quantity,
    COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS total_sales,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    rs.s_name AS supplier_name
FROM 
    part p
LEFT JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN 
    FilteredOrders o ON o.o_custkey = l.l_suppkey
LEFT JOIN 
    RankedSuppliers rs ON rs.s_suppkey = l.l_suppkey AND rs.rank <= 5
WHERE 
    p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) 
    AND p.p_size IN (SELECT DISTINCT p3.p_size FROM part p3 WHERE p3.p_type LIKE 'BRASS%')
GROUP BY 
    p.p_partkey, p.p_name, rs.s_name
HAVING 
    SUM(l.l_quantity) IS NOT NULL
ORDER BY 
    total_sales DESC
LIMIT 10;