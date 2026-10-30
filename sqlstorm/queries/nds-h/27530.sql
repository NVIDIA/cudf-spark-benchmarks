
SELECT 
    CONCAT('Supplier Name: ', s.s_name, ', Address: ', s.s_address, ', Nation: ', n.n_name) AS supplier_info,
    LEFT(s.s_comment, 30) AS short_comment,
    COUNT(DISTINCT ps.ps_partkey) AS total_parts,
    AVG(ps.ps_supplycost) AS avg_supply_cost,
    MAX(l.l_extendedprice) AS max_extended_price,
    SUM(l.l_quantity) AS total_quantity_sold
FROM 
    supplier s
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    lineitem l ON ps.ps_partkey = l.l_partkey
WHERE 
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31' 
GROUP BY 
    s.s_suppkey, s.s_name, s.s_address, n.n_name, s.s_comment
HAVING 
    COUNT(DISTINCT ps.ps_partkey) > 10 AND AVG(ps.ps_supplycost) < 50.00
ORDER BY 
    total_quantity_sold DESC, avg_supply_cost ASC
LIMIT 100;
