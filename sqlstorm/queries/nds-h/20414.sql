
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
),
FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        part p
    LEFT JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_retailprice BETWEEN 100 AND 500 AND 
        p.p_size IN (SELECT DISTINCT p_size FROM part WHERE p_size IS NOT NULL)
    GROUP BY 
        p.p_partkey, p.p_name, p.p_mfgr, p.p_brand, p.p_type
    HAVING 
        COUNT(DISTINCT ps.ps_suppkey) > 5
),
ConfirmedOrders AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    INNER JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= DATE '1996-01-01' AND 
        o.o_orderstatus IN ('O', 'F')
    GROUP BY 
        o.o_orderkey
)
SELECT 
    r.r_name,
    COUNT(DISTINCT cp.p_partkey) AS confirmed_parts,
    SUM(CASE WHEN cs.rank = 1 THEN 1 ELSE 0 END) AS top_suppliers_count,
    AVG(co.total_revenue) AS average_revenue
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    RankedSuppliers cs ON n.n_nationkey = cs.s_nationkey
LEFT JOIN 
    FilteredParts cp ON cs.s_suppkey = cp.p_partkey  
LEFT JOIN 
    ConfirmedOrders co ON co.o_orderkey IN (SELECT o_orderkey FROM orders WHERE o_custkey = (SELECT c.c_custkey FROM customer c WHERE c.c_name LIKE '%Customer%' LIMIT 1))
GROUP BY 
    r.r_name
HAVING 
    MAX(CASE WHEN cs.rank = 1 THEN 1 ELSE 0 END) = 1 AND 
    AVG(co.total_revenue) IS NOT NULL
ORDER BY 
    confirmed_parts DESC NULLS LAST;
