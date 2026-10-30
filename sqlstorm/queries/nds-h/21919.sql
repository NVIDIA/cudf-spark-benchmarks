WITH RankedParts AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_retailprice,
        ROW_NUMBER() OVER (PARTITION BY p.p_mfgr ORDER BY p.p_retailprice DESC) AS price_rank,
        COUNT(*) OVER (PARTITION BY p.p_mfgr) AS mfgr_count
    FROM 
        part p
    WHERE 
        p.p_size BETWEEN 1 AND 20
),
FilteredSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name, 
        s.s_acctbal,
        COALESCE(NULLIF(LTRIM(RTRIM(s.s_comment)), ''), 'No Comment') AS adjusted_comment
    FROM 
        supplier s 
    WHERE 
        s.s_acctbal > (
            SELECT AVG(s1.s_acctbal) 
            FROM supplier s1 
            WHERE s1.s_nationkey = s.s_nationkey
        )
),
FrequentCustomers AS (
    SELECT 
        c.c_custkey,
        COUNT(*) AS order_count
    FROM 
        customer c
    JOIN 
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY 
        c.c_custkey
    HAVING 
        COUNT(*) > 5
)
SELECT 
    r.r_name,
    COUNT(DISTINCT n.n_nationkey) AS nation_count,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) END) AS total_returned,
    AVG(l.l_extendedprice) AS avg_extended_price,
    MAX(s.s_acctbal) FILTER (WHERE s.s_acctbal IS NOT NULL) AS max_supplier_acctbal,
    (SELECT COUNT(DISTINCT ps.ps_suppkey) 
     FROM partsupp ps 
     WHERE ps.ps_partkey IN (SELECT p_partkey FROM RankedParts WHERE price_rank = 1)) AS unique_suppliers
FROM 
    region r 
JOIN 
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN 
    supplier s ON s.s_nationkey = n.n_nationkey
JOIN 
    lineitem l ON l.l_suppkey = s.s_suppkey
LEFT JOIN 
    FrequentCustomers fc ON fc.c_custkey = l.l_orderkey
WHERE 
    EXISTS (SELECT 1 FROM FilteredSuppliers fs WHERE fs.s_suppkey = s.s_suppkey)
    AND l.l_shipdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
GROUP BY 
    r.r_name
HAVING 
    COUNT(DISTINCT n.n_nationkey) > 0
ORDER BY 
    total_returned DESC, 
    avg_extended_price ASC;