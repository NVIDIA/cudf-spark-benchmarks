SELECT 
    SUBSTRING(p.p_name, 1, 10) AS short_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    SUM(l.l_extendedprice) AS total_revenue,
    r.r_name AS region_name,
    AVG(c.c_acctbal) AS average_balance,
    MAX(CASE 
            WHEN o.o_orderstatus = 'F' THEN l.l_extendedprice 
            ELSE 0 
        END) AS max_filled_price
FROM part p
JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN lineitem l ON ps.ps_partkey = l.l_partkey
JOIN orders o ON l.l_orderkey = o.o_orderkey
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE 
    p.p_container LIKE '%box%'
    AND l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
GROUP BY 
    short_name, region_name
ORDER BY 
    total_revenue DESC, average_balance DESC;