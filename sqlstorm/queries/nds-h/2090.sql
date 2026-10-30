
WITH RegionalSales AS (
    SELECT 
        r.r_name AS region_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        r.r_name
), RankedSales AS (
    SELECT 
        region_name, 
        total_revenue, 
        order_count,
        DENSE_RANK() OVER (ORDER BY total_revenue DESC) AS sales_rank
    FROM 
        RegionalSales
)
SELECT 
    r.region_name, 
    r.total_revenue, 
    r.order_count, 
    r.sales_rank,
    COALESCE(r2.order_count, 0) AS competitor_order_count
FROM 
    RankedSales r
LEFT JOIN (
    SELECT 
        r.r_name AS region_name, 
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31' 
        AND s.s_acctbal < (SELECT AVG(s.s_acctbal) FROM supplier s)
    GROUP BY 
        r.r_name
) r2 ON r.region_name = r2.region_name
WHERE 
    r.sales_rank <= 10
ORDER BY 
    r.total_revenue DESC;
