WITH combined_data AS (
    SELECT 
        CONCAT(s.s_name, ' (', p.p_name, ')') AS supplier_part,
        r.r_name AS region,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    JOIN customer c ON o.o_custkey = c.c_custkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE p.p_size > 10
      AND l.l_shipmode IN ('AIR', 'RAIL')
      AND c.c_mktsegment = 'BUILDING'
      AND l.l_shipdate >= DATE '1997-01-01'
      AND l.l_shipdate <= DATE '1997-12-31'
    GROUP BY supplier_part, r.r_name
)
SELECT 
    region,
    COUNT(*) AS supplier_count,
    SUM(revenue) AS total_revenue,
    MAX(revenue) AS max_revenue_per_supplier,
    MIN(revenue) AS min_revenue_per_supplier
FROM combined_data
GROUP BY region
ORDER BY total_revenue DESC, supplier_count DESC;