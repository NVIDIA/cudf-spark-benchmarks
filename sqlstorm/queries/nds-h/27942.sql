SELECT
    CONCAT('Supplier: ', s.s_name, ' | Address: ', s.s_address, ' | Nation: ', n.n_name) AS Supplier_Info,
    COUNT(DISTINCT o.o_orderkey) AS Total_Orders,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS Total_Revenue,
    MAX(l.l_shipdate) AS Last_Shipment,
    AVG(l.l_quantity) AS Avg_Quantity_Per_Order
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
WHERE
    l.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
    AND s.s_comment LIKE '%reliable%'
GROUP BY
    s.s_suppkey, s.s_name, s.s_address, n.n_name
ORDER BY
    Total_Revenue DESC, Total_Orders DESC
LIMIT 10;