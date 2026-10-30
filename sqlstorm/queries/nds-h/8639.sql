WITH supplier_part AS (
    SELECT s.s_suppkey, s.s_name, ps.ps_partkey, p.p_name, ps.ps_supplycost, ps.ps_availqty
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
), customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
), line_item_summary AS (
    SELECT lo.l_orderkey, SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total_revenue
    FROM lineitem lo
    GROUP BY lo.l_orderkey
), supplier_performance AS (
    SELECT sp.s_suppkey, SUM(sp.ps_supplycost * sp.ps_availqty) AS total_supply_cost
    FROM supplier_part sp
    GROUP BY sp.s_suppkey
)
SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice, 
       lis.total_revenue, sp.total_supply_cost
FROM customer_orders co
JOIN line_item_summary lis ON co.o_orderkey = lis.l_orderkey
JOIN supplier_performance sp ON sp.s_suppkey = (SELECT ps.ps_suppkey 
                                                FROM partsupp ps 
                                                JOIN supplier s ON ps.ps_suppkey = s.s_suppkey 
                                                WHERE ps.ps_availqty > 0 
                                                LIMIT 1)
WHERE co.o_totalprice > (SELECT AVG(o_totalprice) FROM orders)
ORDER BY co.o_orderdate DESC, co.o_totalprice DESC;