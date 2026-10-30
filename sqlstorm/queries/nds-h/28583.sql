SELECT 
    CONCAT('Supplier: ', s.s_name, ' (', s.s_acctbal, '), Region: ', r.r_name) AS supplier_info,
    SUBSTR(p.p_name, 1, 10) AS short_part_name,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    SUM(CASE 
        WHEN l.l_returnflag = 'R' THEN l.l_extendedprice * (1 - l.l_discount) 
        ELSE 0 
    END) AS total_returns,
    AVG(CASE 
        WHEN l.l_shipmode = 'MAIL' THEN l.l_extendedprice 
        ELSE NULL 
    END) AS avg_mail_ship_price
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN lineitem l ON p.p_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
WHERE 
    r.r_name LIKE '%East%' 
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    s.s_name, s.s_acctbal, r.r_name, SUBSTR(p.p_name, 1, 10)
ORDER BY 
    unique_customers DESC, total_returns DESC;