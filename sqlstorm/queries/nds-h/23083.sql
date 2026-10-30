
WITH RankedParts AS (
    SELECT p.p_partkey, 
           p.p_name, 
           p.p_brand, 
           p.p_retailprice, 
           ROW_NUMBER() OVER (PARTITION BY p.p_brand ORDER BY p.p_retailprice DESC) AS brand_rank
    FROM part p
    WHERE p.p_size IN (SELECT DISTINCT ps.ps_partkey 
                       FROM partsupp ps 
                       WHERE ps.ps_availqty > 0)
),
SupplierSummary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_value,
           COUNT(DISTINCT CASE WHEN s.s_acctbal IS NULL THEN 1 END) AS null_acctbal_count
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrdersWithDetails AS (
    SELECT o.o_orderkey, 
           o.o_custkey, 
           o.o_orderstatus, 
           o.o_totalprice, 
           COALESCE(SUM(l.l_extendedprice * (1 - l.l_discount)), 0) AS net_revenue,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM orders o
    LEFT JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1995-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderstatus, o.o_totalprice
)
SELECT p.p_name, 
       p.p_brand, 
       p.p_retailprice, 
       COALESCE(ss.total_supply_value, 0) AS total_supply_value, 
       COALESCE(o.net_revenue, 0) AS net_revenue, 
       COALESCE(o.return_count, 0) AS return_count,
       CASE 
           WHEN p.p_retailprice IS NULL THEN 'Price Unknown' 
           ELSE CASE 
                  WHEN p.p_retailprice < 100 THEN 'Budget' 
                  WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Mid-Range' 
                  ELSE 'Premium' 
                END 
        END AS price_category,
       RANK() OVER (PARTITION BY 
           CASE 
               WHEN p.p_retailprice IS NULL THEN 'Price Unknown' 
               ELSE CASE 
                      WHEN p.p_retailprice < 100 THEN 'Budget' 
                      WHEN p.p_retailprice BETWEEN 100 AND 500 THEN 'Mid-Range' 
                      ELSE 'Premium' 
                    END 
           END ORDER BY p.p_retailprice DESC) AS price_rank
FROM RankedParts p
LEFT JOIN SupplierSummary ss ON p.p_partkey = ss.s_suppkey
FULL OUTER JOIN OrdersWithDetails o ON p.p_partkey = o.o_custkey
WHERE (p.brand_rank <= 5 OR COALESCE(o.return_count, 0) > 0)
  AND (ss.total_supply_value IS NOT NULL OR o.o_orderstatus = 'F')
ORDER BY p.brand_rank, COALESCE(o.return_count, 0) DESC, p.p_retailprice;
