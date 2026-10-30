
WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal,
           CONCAT('Supplier ', s.s_name, ' from nation ', n.n_name) AS supplier_info,
           CASE 
               WHEN s.s_acctbal > 10000 THEN 'High Value' 
               WHEN s.s_acctbal BETWEEN 5000 AND 10000 THEN 'Medium Value' 
               ELSE 'Low Value' 
           END AS account_status
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
), PartsStatistics AS (
    SELECT p.p_partkey, p.p_name, COUNT(ps.ps_suppkey) AS supplier_count,
           AVG(ps.ps_supplycost) AS avg_supplycost,
           SUM(ps.ps_availqty) AS total_availqty,
           CONCAT(p.p_name, ': ', COUNT(ps.ps_suppkey), ' suppliers, Avg Cost: ', 
                  ROUND(AVG(ps.ps_supplycost), 2), ', Total Qty: ', SUM(ps.ps_availqty)) AS part_summary
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name
), Combined AS (
    SELECT s.s_suppkey, s.s_name, ps.part_summary
    FROM SupplierDetails s
    JOIN PartsStatistics ps ON s.s_suppkey = ps.p_partkey
)
SELECT supplier_info, account_status, part_summary
FROM Combined
JOIN SupplierDetails sd ON Combined.s_suppkey = sd.s_suppkey
WHERE sd.account_status = 'High Value'
ORDER BY sd.s_suppkey;
