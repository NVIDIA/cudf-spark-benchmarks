WITH supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_address, n.n_name AS nation_name, s.s_phone, s.s_acctbal, 
           CONCAT(s.s_name, ' ', s.s_address) AS full_description
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
),
sales_summary AS (
    SELECT o.o_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY o.o_orderkey
),
part_supplier AS (
    SELECT p.p_partkey, p.p_name, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           CONCAT(p.p_name, ' (Key: ', p.p_partkey, ')') AS part_description
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
),
final_benchmark AS (
    SELECT sd.s_name, sd.nation_name, SUM(ss.total_sales) AS total_sales,
           COUNT(DISTINCT ps.part_description) AS unique_parts_supplied
    FROM supplier_details sd
    JOIN sales_summary ss ON sd.s_suppkey = ss.o_orderkey
    JOIN part_supplier ps ON sd.s_suppkey = ps.ps_suppkey
    GROUP BY sd.s_name, sd.nation_name
)
SELECT s_name, nation_name, total_sales, unique_parts_supplied
FROM final_benchmark
WHERE total_sales > 10000
ORDER BY total_sales DESC, unique_parts_supplied ASC;
