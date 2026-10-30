WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        LENGTH(p.p_name) AS name_length,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        RANK() OVER (ORDER BY LENGTH(p.p_name) DESC, COUNT(DISTINCT ps.ps_suppkey) ASC) AS rank
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY 
        p.p_partkey, p.p_name
),
TopParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.name_length,
        p.supplier_count
    FROM 
        RankedParts p
    WHERE 
        p.rank <= 10
)
SELECT 
    p.p_partkey,
    p.p_name,
    p.name_length,
    p.supplier_count,
    CONCAT('Part: ', p.p_name, ' | Length: ', p.name_length, ' | Suppliers: ', p.supplier_count) AS description
FROM 
    TopParts p
ORDER BY 
    p.supplier_count DESC, p.name_length ASC;
