WITH PartSupplierDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        s.s_name,
        s.s_acctbal,
        s.s_comment,
        ps.ps_availqty,
        ps.ps_supplycost,
        ps.ps_comment
    FROM 
        part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
),
HighValueSuppliers AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        COUNT(*) AS supplier_count
    FROM 
        PartSupplierDetails p
    WHERE 
        p.s_acctbal > 50000
    GROUP BY 
        p.p_partkey, p.p_name
),
ExtendedCommentAnalysis AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', p.p_brand, ': ', COALESCE(s.s_comment, 'No Comment')) AS extended_comment
    FROM 
        part p
    LEFT JOIN supplier s ON s.s_nationkey IN (SELECT n.n_nationkey FROM nation n WHERE n.n_name LIKE 'USA')
)
SELECT 
    hvs.p_partkey,
    hvs.supplier_count,
    eca.extended_comment,
    p.p_retailprice,
    CASE 
        WHEN hvs.supplier_count > 3 THEN 'Competitive'
        WHEN hvs.supplier_count = 3 THEN 'Moderately Competitive'
        ELSE 'Low Competition'
    END AS competition_level
FROM 
    HighValueSuppliers hvs
JOIN 
    ExtendedCommentAnalysis eca ON hvs.p_partkey = eca.p_partkey
JOIN 
    part p ON hvs.p_partkey = p.p_partkey
ORDER BY 
    hvs.supplier_count DESC, p.p_retailprice DESC;
