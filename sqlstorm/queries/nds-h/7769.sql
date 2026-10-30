WITH  supplier_details AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, s.s_acctbal, p.p_partkey, p.p_name, 
           ps.ps_availqty, ps.ps_supplycost, 
           ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY ps.ps_supplycost DESC) AS rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_retailprice > 100.00
),
top_suppliers AS (
    SELECT sd.s_suppkey, sd.s_name, sd.s_acctbal, 
           SUM(sd.ps_supplycost * sd.ps_availqty) AS total_value
    FROM supplier_details sd
    WHERE sd.rank <= 3
    GROUP BY sd.s_suppkey, sd.s_name, sd.s_acctbal
)
SELECT ts.s_suppkey, ts.s_name, ts.s_acctbal, ts.total_value,
       n.n_name AS nation, r.r_name AS region
FROM top_suppliers ts
JOIN supplier s ON ts.s_suppkey = s.s_suppkey
JOIN nation n ON s.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
WHERE ts.total_value > 1000.00
ORDER BY ts.total_value DESC
LIMIT 10;
