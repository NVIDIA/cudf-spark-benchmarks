WITH SupplierDetails AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, s.s_acctbal,
           CONCAT(s.s_name, ' - ', s.s_address) AS full_supplier_info
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
RegionStatistics AS (
    SELECT r.r_name AS region_name, COUNT(DISTINCT n.n_nationkey) AS nation_count,
           SUM(s.s_acctbal) AS total_account_balance
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    GROUP BY r.r_name
),
EdgedProducts AS (
    SELECT p.p_partkey, p.p_name, p.p_size, p.p_retailprice, 
           LOWER(REPLACE(p.p_comment, ' ', '')) AS trimmed_comment 
    FROM part p
    WHERE p.p_size BETWEEN 1 AND 50 AND p.p_retailprice > 100.00
),
ProductSuppliers AS (
    SELECT ps.ps_partkey, s.s_suppkey, s.s_name, p.p_retailprice, 
           COUNT(ps.ps_availqty) AS total_available_qty,
           MAX(s.s_acctbal) AS max_supplier_balance
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_partkey, s.s_suppkey, s.s_name, p.p_retailprice
)
SELECT r.region_name, COUNT(DISTINCT ed.p_partkey) AS product_count,
       SUM(ps.total_available_qty) AS total_available_quantity,
       AVG(ps.max_supplier_balance) AS avg_supplier_balance
FROM RegionStatistics r
JOIN EdgedProducts ed ON ed.p_size > 20
JOIN ProductSuppliers ps ON ed.p_partkey = ps.ps_partkey
GROUP BY r.region_name
ORDER BY product_count DESC, total_available_quantity DESC;
