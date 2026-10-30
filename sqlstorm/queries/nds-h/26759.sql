
SELECT 
    p.p_name AS part_name,
    s.s_name AS supplier_name,
    c.c_name AS customer_name,
    o.o_orderkey AS order_key,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COUNT(DISTINCT l.l_orderkey) AS total_orders,
    AVG(s.s_acctbal) AS avg_supplier_balance,
    MAX(l.l_shipdate) AS latest_ship_date,
    MIN(l.l_receiptdate) AS earliest_receipt_date,
    CONCAT('Region: ', r.r_name, ' | Comment: ', r.r_comment) AS region_info
FROM 
    lineitem l
JOIN 
    orders o ON l.l_orderkey = o.o_orderkey
JOIN 
    customer c ON o.o_custkey = c.c_custkey
JOIN 
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
JOIN 
    part p ON l.l_partkey = p.p_partkey  -- Fixed potential missing join
WHERE 
    l.l_shipmode LIKE 'AIR%'
    AND o.o_orderstatus = 'O'
    AND l.l_returnflag = 'N'
GROUP BY 
    p.p_name, s.s_name, c.c_name, o.o_orderkey, r.r_name, r.r_comment
HAVING 
    SUM(l.l_extendedprice * (1 - l.l_discount)) > 1000
ORDER BY 
    total_revenue DESC, latest_ship_date DESC;
