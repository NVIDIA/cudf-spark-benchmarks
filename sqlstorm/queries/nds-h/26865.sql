WITH  supplier_part_info AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           CONCAT(p.p_name, ' - ', s.s_name) AS part_supplier_details
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE s.s_acctbal > 5000.00
    UNION ALL
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost,
           CONCAT(ps.ps_availqty, ' available of ', p.p_name, ' from ', s.s_name) AS part_supplier_details
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE ps.ps_supplycost < (SELECT AVG(ps_supplycost) FROM partsupp)
)
SELECT n.n_name AS nation, COUNT(DISTINCT spi.part_supplier_details) AS unique_part_supplier_count,
       SUM(spi.ps_supplycost) AS total_supply_cost
FROM supplier_part_info spi
JOIN nation n ON n.n_nationkey = spi.s_suppkey
GROUP BY n.n_name
HAVING COUNT(DISTINCT spi.part_supplier_details) > 2
ORDER BY total_supply_cost DESC
LIMIT 10;
