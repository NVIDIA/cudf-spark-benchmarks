WITH  regional_sales AS (
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales 
    FROM region r
    INNER JOIN nation n ON r.r_regionkey = n.n_regionkey
    INNER JOIN supplier s ON n.n_nationkey = s.s_nationkey
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    INNER JOIN lineitem l ON p.p_partkey = l.l_partkey
    INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY r.r_regionkey, r.r_name
    UNION ALL
    SELECT r.r_regionkey, r.r_name, SUM(l.l_extendedprice * (1 - l.l_discount) * NULLIF(o.o_shippriority, 0)) * CASE WHEN r.r_name IS NOT NULL THEN 1 ELSE 0 END 
    FROM region r
    INNER JOIN nation n ON r.r_regionkey = n.n_regionkey
    INNER JOIN supplier s ON n.n_nationkey = s.s_nationkey
    INNER JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    INNER JOIN part p ON ps.ps_partkey = p.p_partkey
    INNER JOIN lineitem l ON p.p_partkey = l.l_partkey
    INNER JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE o.o_orderdate BETWEEN '1997-06-01' AND cast('1998-10-01' as date) 
    GROUP BY r.r_regionkey, r.r_name
)
, avg_sales AS (
    SELECT r_regionkey, AVG(total_sales) AS avg_total_sales
    FROM regional_sales
    GROUP BY r_regionkey
)
SELECT r.r_name, rs.total_sales, COALESCE(avg.avg_total_sales, 0) AS average_sales, 
       CASE WHEN rs.total_sales > COALESCE(avg.avg_total_sales, 0) * 1.1 THEN 'Above Average' 
            WHEN rs.total_sales < COALESCE(avg.avg_total_sales, 0) * 0.9 THEN 'Below Average'
            ELSE 'Average' END AS sales_category
FROM regional_sales rs
LEFT JOIN avg_sales avg ON rs.r_regionkey = avg.r_regionkey
JOIN region r ON rs.r_regionkey = r.r_regionkey 
ORDER BY r.r_name ASC, rs.total_sales DESC;