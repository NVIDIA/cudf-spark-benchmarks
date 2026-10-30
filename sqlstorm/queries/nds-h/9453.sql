WITH supplier_part AS (
    SELECT s.s_suppkey, s.s_name, p.p_partkey, p.p_name, ps.ps_availqty, ps.ps_supplycost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), 
customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    AND o.o_orderdate >= DATE '1996-01-01'
    AND o.o_orderdate < DATE '1997-01-01'
), 
region_nation_supplier AS (
    SELECT r.r_name AS region_name, n.n_name AS nation_name, s.s_suppkey
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
)
SELECT rp.region_name, rp.nation_name, cp.c_name AS customer_name, cp.o_orderkey, 
       SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost, 
       COUNT(DISTINCT cp.o_orderkey) AS order_count
FROM region_nation_supplier rp
JOIN supplier_part sp ON rp.s_suppkey = sp.s_suppkey
JOIN customer_orders cp ON sp.s_suppkey = cp.o_orderkey
GROUP BY rp.region_name, rp.nation_name, cp.c_name, cp.o_orderkey
ORDER BY total_supply_cost DESC, order_count DESC
LIMIT 10;