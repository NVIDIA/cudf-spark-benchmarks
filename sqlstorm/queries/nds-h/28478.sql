WITH supplier_info AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, 
           CONCAT(s.s_name, ' from ', n.n_name) AS supplier_location,
           CASE 
               WHEN s.s_acctbal < 1000 THEN 'Low'
               WHEN s.s_acctbal BETWEEN 1000 AND 5000 THEN 'Medium'
               ELSE 'High'
           END AS acctbal_category
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
part_supply AS (
    SELECT ps.ps_partkey, SUM(ps.ps_availqty) AS total_available_qty, 
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    GROUP BY ps.ps_partkey
),
benchmark AS (
    SELECT p.p_name, p.p_brand, p.p_type, p.p_size, p.p_container,
           si.supplier_location, si.acctbal_category,
           ps.total_available_qty, ps.avg_supply_cost
    FROM part p
    JOIN part_supply ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier_info si ON si.s_suppkey = ps.ps_partkey
    WHERE p.p_size > 20 AND ps.total_available_qty > 50
)
SELECT benchmark.*, 
       CONCAT('Part: ', benchmark.p_name, 
              ', Brand: ', benchmark.p_brand, 
              ', Type: ', benchmark.p_type, 
              ', Size:', benchmark.p_size, 
              ', Container: ', benchmark.p_container, 
              ', Supplier: ', benchmark.supplier_location, 
              ', Account Balance Category: ', benchmark.acctbal_category, 
              ', Available Quantity: ', benchmark.total_available_qty, 
              ', Average Supply Cost: $', ROUND(benchmark.avg_supply_cost, 2)) AS detailed_info
FROM benchmark
ORDER BY benchmark.total_available_qty DESC;
