WITH  cust_orders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate) AS order_seq
    FROM orders o
    WHERE o.o_orderdate >= '1997-01-01' 
),

supplier_info AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),

part_details AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice, AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM part p
    LEFT JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_retailprice
),

customer_ranks AS (
    SELECT c.c_custkey, c.c_name, c.c_acctbal,
           RANK() OVER (ORDER BY c.c_acctbal DESC) AS cust_rank
    FROM customer c
    WHERE c.c_acctbal IS NOT NULL
),

final_result AS (
    SELECT co.o_orderkey, co.o_custkey, co.o_orderdate, co.o_totalprice,
           pi.p_name, pi.avg_supply_cost, ci.cust_rank
    FROM cust_orders co
    JOIN part_details pi ON co.o_orderkey IN (
        SELECT lo.l_orderkey
        FROM lineitem lo
        WHERE lo.l_partkey IN (
            SELECT ps.ps_partkey
            FROM partsupp ps
            WHERE ps.ps_availqty > 100
        )
    )
    JOIN customer_ranks ci ON co.o_custkey = ci.c_custkey
)

SELECT fr.o_orderkey, fr.o_custkey, fr.o_orderdate, fr.o_totalprice,
       fr.p_name, fr.avg_supply_cost, fr.cust_rank
FROM final_result fr
WHERE fr.avg_supply_cost IS NOT NULL AND fr.o_totalprice > 500
ORDER BY fr.o_orderdate DESC, fr.cust_rank ASC;