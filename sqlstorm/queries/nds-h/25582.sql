
WITH RankedParts AS (
    SELECT 
        p_name, 
        p_mfgr, 
        p_retailprice, 
        LENGTH(p_comment) AS comment_length,
        ROW_NUMBER() OVER (PARTITION BY p_mfgr ORDER BY p_retailprice DESC) AS rank,
        p_type,
        p_partkey
    FROM 
        part
    WHERE 
        p_retailprice > (SELECT AVG(p_retailprice) FROM part)
), CategoryCount AS (
    SELECT 
        p_type, 
        COUNT(*) AS part_count 
    FROM 
        part 
    GROUP BY 
        p_type
), SupplierDetails AS (
    SELECT 
        s_name, 
        s_address, 
        s_phone, 
        (CASE 
            WHEN s_acctbal < 100.00 THEN 'Low'
            WHEN s_acctbal BETWEEN 100.00 AND 1000.00 THEN 'Medium'
            ELSE 'High' 
        END) AS balance_category,
        s_suppkey
    FROM 
        supplier
)
SELECT 
    p.p_name, 
    p.p_mfgr, 
    p.p_retailprice, 
    pp.part_count, 
    s.s_name, 
    s.balance_category
FROM 
    RankedParts p
JOIN 
    CategoryCount pp ON p.p_type = pp.p_type
JOIN 
    SupplierDetails s ON s.s_suppkey = p.p_partkey
WHERE 
    p.rank <= 5
ORDER BY 
    p.p_retailprice DESC, 
    pp.part_count ASC;
