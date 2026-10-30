
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        DENSE_RANK() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_acctbal DESC) AS rank_acctbal,
        ROW_NUMBER() OVER (PARTITION BY n.n_regionkey ORDER BY s.s_name) AS row_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice * (1 + COALESCE(SUM(l.l_discount), 0)) AS adjusted_price,
        p.p_comment
    FROM 
        part p
    LEFT JOIN 
        lineitem l ON p.p_partkey = l.l_partkey AND l.l_returnflag = 'N'
    GROUP BY 
        p.p_partkey, p.p_name, p.p_retailprice, p.p_comment
    HAVING 
        p.p_retailprice * (1 + COALESCE(SUM(l.l_discount), 0)) > (SELECT AVG(p2.p_retailprice) FROM part p2) * 1.5
),
SupplierPartCount AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count
    FROM 
        partsupp ps
    GROUP BY 
        ps.ps_partkey
),
FinalResults AS (
    SELECT 
        hp.p_partkey,
        hp.p_name,
        hp.adjusted_price,
        COUNT(DISTINCT rs.s_suppkey) AS count_top_suppliers,
        MAX(rs.rank_acctbal) AS max_rank,
        SUM(COALESCE(spc.supplier_count, 0)) AS total_suppliers_count
    FROM 
        HighValueParts hp
    LEFT JOIN 
        RankedSuppliers rs ON hp.p_partkey = rs.s_suppkey
    LEFT JOIN 
        SupplierPartCount spc ON hp.p_partkey = spc.ps_partkey
    GROUP BY 
        hp.p_partkey, hp.p_name, hp.adjusted_price
)
SELECT 
    f.p_partkey,
    f.p_name,
    f.adjusted_price,
    f.count_top_suppliers,
    f.max_rank,
    f.total_suppliers_count,
    CASE 
        WHEN f.total_suppliers_count = 0 THEN 'No suppliers'
        WHEN f.max_rank IS NULL THEN 'Rank not available'
        ELSE 'Valid data'
    END AS status_check
FROM 
    FinalResults f
WHERE 
    f.adjusted_price IS NOT NULL
ORDER BY 
    f.adjusted_price DESC
LIMIT 10;
