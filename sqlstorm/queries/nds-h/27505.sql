
SELECT 
    s.s_name AS supplier_name,
    CONCAT(
        'Supplier ', 
        s.s_name, 
        ' provides ', 
        p.p_name, 
        ' in ', 
        n.n_name, 
        ' with a price of $', 
        CAST(ps.ps_supplycost AS DECIMAL(10, 2)), 
        ' per unit. Remarks: ', 
        SUBSTRING(ps.ps_comment, 1, 50), 
        '...'
    ) AS detailed_info
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
WHERE 
    p.p_retailprice > 100.00 AND
    s.s_acctbal BETWEEN 5000.00 AND 20000.00
GROUP BY 
    s.s_name, 
    p.p_name, 
    n.n_name, 
    ps.ps_supplycost, 
    ps.ps_comment
ORDER BY 
    n.n_name, 
    s.s_name DESC
LIMIT 10;
