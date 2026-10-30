
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rn
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), FilteredParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_comment) AS comment_length,
        CASE 
            WHEN p.p_retailprice > (SELECT AVG(p2.p_retailprice) FROM part p2) THEN 'Above Average'
            ELSE 'Below Average'
        END AS price_comparison
    FROM 
        part p
    WHERE 
        p.p_size IN (10, 20, 30) 
    AND 
        p.p_name ILIKE '%Rubber%'
), SupplierParts AS (
    SELECT 
        ps.ps_partkey, 
        rs.s_name, 
        rs.nation_name,
        fp.comment_length,
        fp.price_comparison,
        rs.rn
    FROM 
        partsupp ps
    JOIN 
        RankedSuppliers rs ON ps.ps_suppkey = rs.s_suppkey
    JOIN 
        FilteredParts fp ON ps.ps_partkey = fp.p_partkey
)

SELECT 
    sp.s_name, 
    sp.nation_name, 
    sp.comment_length, 
    sp.price_comparison
FROM 
    SupplierParts sp
WHERE 
    sp.rn = 1 
ORDER BY 
    sp.nation_name, 
    sp.comment_length DESC;
