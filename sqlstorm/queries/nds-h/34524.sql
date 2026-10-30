WITH  NationalSales AS (
    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY n.n_nationkey, n.n_name

    UNION ALL

    SELECT 
        n.n_nationkey,
        n.n_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    WHERE l.l_shipdate >= (SELECT MAX(l2.l_shipdate) FROM lineitem l2) - INTERVAL '1 YEAR'
    GROUP BY n.n_nationkey, n.n_name
)

SELECT 
    r.r_name,
    COALESCE(ns.total_sales, 0) AS total_sales_last_year,
    ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY COALESCE(ns.total_sales, 0) DESC) AS sales_rank
FROM region r
LEFT JOIN NationalSales ns ON r.r_regionkey = ns.n_nationkey
WHERE r.r_comment IS NULL OR r.r_comment NOT LIKE '%test%'
ORDER BY r.r_name, total_sales_last_year DESC;
