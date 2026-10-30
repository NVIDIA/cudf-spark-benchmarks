WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, r.r_name AS region_name, 
           s.s_acctbal, LENGTH(s.s_comment) AS comment_length,
           CASE 
               WHEN s.s_acctbal > 10000 THEN 'High'
               WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium'
               ELSE 'Low'
           END AS acctbal_category
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
),
PartSuppliers AS (
    SELECT ps.ps_partkey, COUNT(DISTINCT ps.ps_suppkey) AS supplier_count, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           MAX(sd.acctbal_category) AS max_acctbal_category
    FROM partsupp ps
    JOIN SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
    GROUP BY ps.ps_partkey
)
SELECT p.p_name, ps.supplier_count, ps.total_avail_qty, 
       ps.max_acctbal_category,
       CONCAT('Part ', p.p_partkey, ' contains ', ps.supplier_count, ' suppliers with ', 
              ps.total_avail_qty, ' total available quantity, categorized as ', 
              ps.max_acctbal_category) AS summary
FROM part p
JOIN PartSuppliers ps ON p.p_partkey = ps.ps_partkey
WHERE ps.supplier_count > 1
ORDER BY ps.total_avail_qty DESC, p.p_name;
