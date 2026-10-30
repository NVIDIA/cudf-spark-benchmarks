WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY SUM(ps.ps_supplycost) DESC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
), 
HighCostSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        AVG(s.s_acctbal) AS avg_acctbal,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    WHERE 
        s.s_acctbal IS NOT NULL
    GROUP BY 
        s.s_suppkey, s.s_name
    HAVING 
        AVG(s.s_acctbal) > (SELECT AVG(s2.s_acctbal) FROM supplier s2 WHERE s2.s_acctbal IS NOT NULL)
), 
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count
    FROM 
        customer c
    LEFT JOIN 
        orders o ON c.c_custkey = o.o_custkey
    WHERE 
        o.o_orderstatus IS NOT NULL
    GROUP BY 
        c.c_custkey, c.c_name
    HAVING 
        COUNT(o.o_orderkey) > 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT p.p_partkey) AS unique_parts,
    SUM(COALESCE(h.avg_acctbal, 0)) AS total_avg_acctbal,
    MAX(fc.order_count) AS max_order_count
FROM 
    region r
LEFT JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN 
    HighCostSuppliers h ON s.s_suppkey = h.s_suppkey
LEFT JOIN 
    lineitem l ON s.s_suppkey = l.l_suppkey
LEFT JOIN 
    RankedParts p ON l.l_partkey = p.p_partkey
LEFT JOIN 
    FrequentCustomers fc ON s.s_nationkey = fc.c_custkey
WHERE 
    (l.l_shipdate > cast('1998-10-01' as date) - INTERVAL '1 year' OR l.l_shipdate IS NULL)
    AND (h.part_count IS NULL OR h.part_count < 10)
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT p.p_partkey) > 3
ORDER BY 
    total_avg_acctbal DESC, unique_parts DESC
LIMIT 10;