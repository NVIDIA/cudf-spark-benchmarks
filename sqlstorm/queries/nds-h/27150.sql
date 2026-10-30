WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        ROW_NUMBER() OVER (PARTITION BY p.p_type ORDER BY s.s_acctbal DESC) AS rnk,
        p.p_type
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN 
        part p ON ps.ps_partkey = p.p_partkey
),
HighValueSuppliers AS (
    SELECT 
        r.p_type,
        COUNT(DISTINCT r.s_suppkey) AS supplier_count,
        SUM(r.s_acctbal) AS total_acctbal
    FROM 
        RankedSuppliers r
    WHERE 
        r.rnk <= 5
    GROUP BY 
        r.p_type
),
AugmentedComments AS (
    SELECT 
        p.p_partkey,
        CONCAT(p.p_name, ' - ', COALESCE(hs.supplier_count, 0), ' suppliers, ', COALESCE(hs.total_acctbal, 0.00)) AS augmented_comment
    FROM 
        part p
    LEFT JOIN 
        HighValueSuppliers hs ON p.p_type = hs.p_type
)
SELECT 
    p.p_partkey,
    p.p_name,
    a.augmented_comment
FROM 
    part p
JOIN 
    AugmentedComments a ON p.p_partkey = a.p_partkey
WHERE 
    LENGTH(a.augmented_comment) > 50
ORDER BY 
    p.p_partkey;
