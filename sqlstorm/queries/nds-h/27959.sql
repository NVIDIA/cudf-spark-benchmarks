SELECT 
    CONCAT('Supplier: ', S.s_name, ' | Part: ', P.p_name, ' | Price: ', PS.ps_supplycost, 
           ' | Region: ', R.r_name, ' | Nationality: ', N.n_name) AS full_description
FROM 
    supplier S
JOIN 
    partsupp PS ON S.s_suppkey = PS.ps_suppkey
JOIN 
    part P ON PS.ps_partkey = P.p_partkey
JOIN 
    nation N ON S.s_nationkey = N.n_nationkey
JOIN 
    region R ON N.n_regionkey = R.r_regionkey
WHERE 
    P.p_retailprice > (
        SELECT AVG(p_retailprice) 
        FROM part
    )
AND 
    S.s_acctbal BETWEEN 1000.00 AND 5000.00
ORDER BY 
    P.p_name ASC, S.s_name DESC;
