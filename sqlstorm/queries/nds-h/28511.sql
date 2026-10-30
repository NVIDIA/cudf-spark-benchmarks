
SELECT
    CONCAT(c.c_name, ' from ', s.s_name, ' in ', r.r_name) AS Supplier_Customer_Info,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    AVG(s.s_acctbal) AS Avg_Supplier_Balance
FROM
    customer c
JOIN
    orders o ON c.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN
    nation n ON s.s_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    c.c_acctbal > 1000 AND
    l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
GROUP BY
    c.c_name, s.s_name, r.r_name, s.s_acctbal
HAVING
    COUNT(DISTINCT o.o_orderkey) > 10
ORDER BY
    Total_Revenue DESC;
