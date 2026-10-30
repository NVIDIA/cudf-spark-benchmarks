WITH  supplier_hierarchy AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal, 
           ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) as rn
    FROM supplier s
    WHERE s.s_acctbal > (SELECT AVG(s1.s_acctbal) FROM supplier s1)
),
high_value_parts AS (
    SELECT p.p_partkey, p.p_name, p.p_retailprice,
           PS.ps_availqty * PS.ps_supplycost AS total_value
    FROM part p 
    JOIN partsupp PS ON p.p_partkey = PS.ps_partkey
    WHERE PS.ps_availqty > 100
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY c.c_custkey, c.c_name
),
nation_max AS (
    SELECT n.n_name, MAX(c.total_spent) AS max_spent
    FROM nation n
    JOIN customer_orders c ON n.n_nationkey = c.c_custkey
    GROUP BY n.n_name
)
SELECT nh.s_name, nh.s_acctbal, hvp.p_name, hvp.total_value
FROM supplier_hierarchy nh
LEFT JOIN high_value_parts hvp ON hvp.p_partkey = (
    SELECT hp.p_partkey
    FROM high_value_parts hp 
    WHERE hp.total_value >= (
        SELECT AVG(hv.total_value) FROM high_value_parts hv
    )
    ORDER BY hp.total_value DESC
    LIMIT 1
)
LEFT JOIN nation_max nm ON nm.max_spent = nh.s_acctbal
WHERE nh.rn <= 5 AND nm.n_name IS NOT NULL
ORDER BY nh.s_acctbal DESC, hvp.total_value DESC;