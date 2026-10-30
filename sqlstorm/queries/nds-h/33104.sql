WITH  SalesCTE AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey, c.c_name
),
TopSales AS (
    SELECT c.c_custkey, c.c_name, s.total_sales
    FROM customer c
    JOIN SalesCTE s ON c.c_custkey = s.c_custkey
    WHERE s.rn = 1
)
SELECT 
    p.p_partkey,
    p.p_name,
    s.s_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    COALESCE(RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC), 0) AS revenue_rank
FROM part p
LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
LEFT JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE l.l_shipdate >= DATE '1996-01-01' 
  AND l.l_shipdate < DATE '1997-01-01'
  AND (l.l_discount <= 0.2 OR l.l_discount IS NULL)
GROUP BY p.p_partkey, p.p_name, s.s_name
HAVING SUM(l.l_quantity) > 100
UNION ALL
SELECT 
    0 AS p_partkey,
    'Total' AS p_name,
    NULL AS s_name,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
    NULL AS revenue_rank
FROM lineitem l
WHERE l.l_shipdate >= DATE '1996-01-01' 
  AND l.l_shipdate < DATE '1997-01-01'
  AND l.l_discount IS NOT NULL
ORDER BY total_revenue DESC;