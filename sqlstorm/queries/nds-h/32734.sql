
WITH  part_supply AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, ps.ps_availqty, ps.ps_supplycost,
           ROW_NUMBER() OVER (PARTITION BY ps.ps_partkey ORDER BY ps.ps_supplycost ASC) as rank
    FROM partsupp ps
    WHERE ps.ps_availqty > 0
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_orderdate >= DATE '1996-01-01'
    GROUP BY c.c_custkey, c.c_name
),
high_value_customers AS (
    SELECT c.c_custkey, c.c_name, c.c_mktsegment
    FROM customer c
    JOIN customer_orders co ON c.c_custkey = co.c_custkey
    WHERE co.total_spent > (SELECT AVG(total_spent) FROM customer_orders)
),
region_nation AS (
    SELECT r.r_regionkey, r.r_name, n.n_nationkey, n.n_name
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
)

SELECT pp.p_name AS part_name,
       pp.p_retailprice,
       COALESCE(SUM(li.l_quantity), 0) AS total_quantity,
       COALESCE(COUNT(DISTINCT so.o_orderkey), 0) AS total_orders,
       COALESCE(c.c_name, '') AS customer_name,
       rc.r_name AS region_name,
       COALESCE(SUM(li.l_extendedprice * (1 - li.l_discount)), 0) AS total_sales
FROM part pp
LEFT JOIN lineitem li ON pp.p_partkey = li.l_partkey
LEFT JOIN orders so ON li.l_orderkey = so.o_orderkey
LEFT JOIN customer c ON so.o_custkey = c.c_custkey
LEFT JOIN high_value_customers hv ON c.c_custkey = hv.c_custkey
LEFT JOIN region_nation rn ON c.c_nationkey = rn.n_nationkey
LEFT JOIN region rc ON rn.r_regionkey = rc.r_regionkey
WHERE pp.p_retailprice > 10.00
GROUP BY pp.p_name, pp.p_retailprice, c.c_name, rc.r_name
HAVING COUNT(DISTINCT li.l_linenumber) > 5
ORDER BY total_sales DESC, pp.p_retailprice ASC;
