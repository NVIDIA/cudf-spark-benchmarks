WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END), 0) AS total_returns,
           COALESCE(SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_quantity ELSE 0 END), 0) AS total_sales,
           ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) DESC) AS rank
    FROM part p
    LEFT JOIN lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY p.p_partkey, p.p_name
),
TieredParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.total_returns, 
           p.total_sales,
           CASE
               WHEN p.rank <= 5 THEN 'Top Performer'
               WHEN p.rank <= 15 THEN 'Average Performer'
               ELSE 'Low Performer'
           END AS performance_tier
    FROM RankedParts p
)
SELECT tp.performance_tier, 
       COUNT(tp.p_partkey) AS part_count, 
       SUM(tp.total_sales) AS total_sales_amount, 
       SUM(tp.total_returns) AS total_returns_amount,
       AVG(tp.total_sales) AS avg_sales_per_part
FROM TieredParts tp
GROUP BY tp.performance_tier
ORDER BY CASE tp.performance_tier 
             WHEN 'Top Performer' THEN 1 
             WHEN 'Average Performer' THEN 2 
             ELSE 3 
         END;
