SELECT 
    trim(s.s_name) AS supplier_name,
    count(distinct o.o_orderkey) AS total_orders,
    sum(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    substring(p.p_name from '^[A-Za-z]+') AS first_word_part_name,
    concat(n.n_name, ' ', r.r_name) AS nation_region,
    avg(c.c_acctbal) AS average_account_balance,
    upper(p.p_type) AS upper_case_part_type
FROM 
    supplier s
JOIN 
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN 
    part p ON ps.ps_partkey = p.p_partkey
JOIN 
    lineitem l ON p.p_partkey = l.l_partkey
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    r.r_name LIKE '%North%'
    AND l.l_shipdate BETWEEN '1995-01-01' AND '1995-12-31'
GROUP BY 
    supplier_name, first_word_part_name, nation_region, upper_case_part_type
ORDER BY 
    total_revenue DESC
LIMIT 10;