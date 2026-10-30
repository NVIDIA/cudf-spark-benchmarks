WITH SupplierInfo AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_address, 
           n.n_name AS nation_name,
           r.r_name AS region_name,
           s.s_acctbal,
           LENGTH(s.s_comment) AS comment_length
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
), 
PartSupplier AS (
    SELECT ps.ps_partkey, 
           ps.ps_suppkey, 
           p.p_name, 
           p.p_type, 
           ps.ps_availqty, 
           ps.ps_supplycost,
           LENGTH(ps.ps_comment) AS ps_comment_length
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
)
SELECT si.s_name, 
       si.nation_name, 
       si.region_name, 
       COUNT(DISTINCT ps.ps_partkey) AS part_count, 
       SUM(ps.ps_availqty) AS total_availability, 
       SUM(ps.ps_supplycost) AS total_supply_cost, 
       AVG(si.comment_length) AS avg_supplier_comment_length,
       AVG(ps.ps_comment_length) AS avg_part_comment_length
FROM SupplierInfo si
JOIN PartSupplier ps ON si.s_suppkey = ps.ps_suppkey
GROUP BY si.s_name, 
         si.nation_name, 
         si.region_name
HAVING COUNT(DISTINCT ps.ps_partkey) > 5
ORDER BY total_availability DESC, 
         si.s_name ASC;
