
WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost ASC) AS rn
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE 
        p.p_size > 10
), 
PartDetails AS (
    SELECT 
        rp.p_partkey, 
        rp.p_name, 
        rp.ps_supplycost,
        p.p_comment,
        COUNT(DISTINCT s.s_nationkey) AS supplier_count
    FROM 
        RankedParts rp
    JOIN 
        supplier s ON rp.p_partkey = s.s_suppkey 
    JOIN 
        part p ON rp.p_partkey = p.p_partkey  -- Added join to access p.p_comment
    GROUP BY 
        rp.p_partkey, rp.p_name, rp.ps_supplycost, p.p_comment
), 
FinalOutput AS (
    SELECT 
        pd.p_partkey,
        pd.p_name,
        pd.ps_supplycost,
        pd.p_comment,
        CASE 
            WHEN pd.supplier_count > 5 THEN 'Multiple Suppliers'
            ELSE 'Limited Suppliers' 
        END AS supplier_status
    FROM 
        PartDetails pd
    WHERE 
        pd.ps_supplycost < (SELECT AVG(ps.ps_supplycost) FROM partsupp ps)
    ORDER BY 
        pd.ps_supplycost DESC
)
SELECT 
    * 
FROM 
    FinalOutput
WHERE 
    supplier_status = 'Multiple Suppliers'
LIMIT 10;  -- Changed LIMIT to standard SQL syntax
