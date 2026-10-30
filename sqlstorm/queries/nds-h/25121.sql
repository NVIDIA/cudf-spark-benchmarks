SELECT 
    CONCAT(
        'Name: ', s_name, 
        ', Address: ', s_address, 
        ', Nation: ', n_name, 
        ', Region: ', r_name, 
        ', Comment: ', s_comment
    ) AS supplier_info,
    SUM(ps_supplycost * ps_availqty) AS total_supply_value
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
GROUP BY 
    s.s_suppkey, s_name, s_address, n_name, r_name, s_comment
HAVING 
    SUM(ps_supplycost * ps_availqty) > 100000
ORDER BY 
    total_supply_value DESC
LIMIT 10;
