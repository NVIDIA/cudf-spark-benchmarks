
WITH  region_sales AS (
    SELECT
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        r.r_regionkey
    
    UNION ALL
    
    SELECT
        r.r_regionkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) + COALESCE((SELECT SUM(l2.l_extendedprice * (1 - l2.l_discount))
                                                                   FROM lineitem l2
                                                                   WHERE l2.l_orderkey IN (SELECT o.o_orderkey
                                                                                           FROM orders o
                                                                                           WHERE o.o_orderstatus = 'O')), 0)
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE
        l.l_shipdate >= '1997-01-01' AND l.l_shipdate < '1997-12-31'
    GROUP BY
        r.r_regionkey
)

SELECT
    r.r_name,
    COALESCE(rs.total_sales, 0) AS total_sales,
    COUNT(DISTINCT c.c_custkey) AS unique_customers,
    AVG(o.o_totalprice) AS avg_order_value
FROM
    region r
LEFT JOIN
    region_sales rs ON r.r_regionkey = rs.r_regionkey
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN
    part p ON ps.ps_partkey = p.p_partkey
LEFT JOIN
    lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN
    orders o ON l.l_orderkey = o.o_orderkey
LEFT JOIN
    customer c ON o.o_custkey = c.c_custkey
WHERE
    p.p_retailprice > 100
AND
    (l.l_returnflag IS NULL OR l.l_returnflag NOT IN ('R'))
GROUP BY
    r.r_name, rs.total_sales
ORDER BY
    total_sales DESC;
