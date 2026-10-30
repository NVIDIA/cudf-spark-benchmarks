WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (ORDER BY s.s_acctbal DESC) AS rn
    FROM supplier s
    WHERE s.s_acctbal IS NOT NULL
), 
order_summary AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice,
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
           COUNT(DISTINCT l.l_linenumber) AS line_count
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1996-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate, o.o_totalprice
), 
customer_summary AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           COUNT(o.o_orderkey) as order_count,
           SUM(o.o_totalprice) AS total_spent,
           AVG(o.o_totalprice) AS avg_order_value
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name, c.c_acctbal
),
supplier_part_info AS (
    SELECT ps.ps_suppkey, p.p_name, p.p_brand,
           SUM(ps.ps_availqty) AS total_available_qty,
           AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY ps.ps_suppkey, p.p_name, p.p_brand
)
SELECT cu.c_name AS customer_name, 
       cu.total_spent, 
       cu.order_count, 
       cu.avg_order_value,
       supp.s_name AS supplier_name,
       spi.total_available_qty,
       spi.avg_supply_cost,
       os.total_revenue,
       os.line_count,
       RANK() OVER (PARTITION BY cu.c_custkey ORDER BY cu.total_spent DESC) as spender_rank
FROM customer_summary cu
JOIN top_suppliers supp ON cu.c_custkey = supp.s_suppkey 
LEFT JOIN supplier_part_info spi ON supp.s_suppkey = spi.ps_suppkey 
JOIN order_summary os ON cu.order_count = os.o_orderkey
WHERE cu.total_spent IS NOT NULL
  AND supp.rn <= 5
ORDER BY cu.total_spent DESC, supp.s_acctbal DESC;