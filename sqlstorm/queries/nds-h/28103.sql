
WITH supplier_aggregate AS (
    SELECT s.s_suppkey, s.s_name, COUNT(ps.ps_partkey) AS total_parts, SUM(ps.ps_supplycost) AS total_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
customer_order_summary AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS total_orders, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
region_nation AS (
    SELECT r.r_regionkey, r.r_name AS region_name, n.n_name AS nation_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
),
string_benchmark AS (
    SELECT 
        CONCAT(sas.s_name, ' - ', ras.region_name, ' (', ras.nation_name, ')') AS supplier_region_nation,
        sas.total_parts,
        sas.total_supplycost,
        cos.total_orders,
        cos.total_spent
    FROM supplier_aggregate sas
    JOIN customer_order_summary cos ON sas.total_supplycost > cos.total_spent
    JOIN region_nation ras ON ras.region_name LIKE '%North%'
)
SELECT 
    supplier_region_nation,
    total_parts,
    total_supplycost,
    total_orders,
    total_spent,
    LENGTH(supplier_region_nation) AS supplier_region_nation_length,
    LEFT(supplier_region_nation, 15) AS short_name,
    TRIM(supplier_region_nation) AS trimmed_supplier_region_nation
FROM string_benchmark
ORDER BY total_spent DESC 
LIMIT 100;
