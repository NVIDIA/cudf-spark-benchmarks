WITH nation_supplier AS (
    SELECT n.n_name AS nation_name, 
           COUNT(s.s_suppkey) AS supplier_count, 
           SUM(s.s_acctbal) AS total_acctbal 
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey 
    GROUP BY n.n_name
), 
part_supplier AS (
    SELECT p.p_name AS part_name, 
           COUNT(ps.ps_suppkey) AS part_supplier_count 
    FROM part p 
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey 
    GROUP BY p.p_name
),
combined AS (
    SELECT ns.nation_name, 
           ps.part_name, 
           ns.supplier_count, 
           ps.part_supplier_count, 
           CONCAT(ns.nation_name, ' | ', ps.part_name) AS combined_name 
    FROM nation_supplier ns 
    JOIN part_supplier ps ON ns.nation_name LIKE '%land%' OR ps.part_name LIKE '%brass%'
)
SELECT combined_name, 
       supplier_count, 
       part_supplier_count, 
       CONCAT('Nation: ', nation_name, ', Suppliers: ', supplier_count, ', Part: ', part_name, ', Part Suppliers: ', part_supplier_count) AS detailed_info 
FROM combined 
WHERE supplier_count > 5 AND part_supplier_count > 3 
ORDER BY nation_name, part_name;
