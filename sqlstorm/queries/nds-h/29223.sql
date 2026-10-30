SELECT 
    CONCAT('Supplier: ', s.s_name, ' | Part: ', p.p_name, ' | Price: ', ps.ps_supplycost) AS Supply_Part_Info,
    LENGTH(s.s_address) AS Address_Length,
    UPPER(n.n_name) AS Nation_Uppercase,
    SUBSTRING(p.p_comment, 1, 10) AS Short_Comment,
    TRIM(REPLACE(p.p_type, 'Plastic', 'Polymer')) AS Processed_Type
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 50.00
AND 
    LENGTH(s.s_phone) = 15
ORDER BY 
    Supply_Part_Info DESC
LIMIT 100;
