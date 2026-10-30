WITH  cte_customer_orders AS (
    SELECT c.c_custkey, c.c_name, o.o_orderkey, o.o_orderdate, o.o_totalprice,
           ROW_NUMBER() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) as order_rank
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
), 
cte_order_details AS (
    SELECT co.c_custkey, co.c_name, co.o_orderkey, co.o_orderdate, co.o_totalprice,
           SUM(li.l_extendedprice * (1 - li.l_discount)) OVER (PARTITION BY co.o_orderkey) AS total_lineitem_price
    FROM cte_customer_orders co
    LEFT JOIN lineitem li ON co.o_orderkey = li.l_orderkey
    WHERE co.order_rank <= 10 
),
cte_supplier_parts AS (
    SELECT ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name, SUM(ps.ps_availqty) AS total_available_qty,
           COUNT(DISTINCT s.s_suppkey) AS supplier_count
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY ps.ps_partkey, ps.ps_suppkey, p.p_name, s.s_name
)
SELECT co.c_name, co.o_orderdate, co.o_totalprice, co.total_lineitem_price, 
       sp.p_name, sp.total_available_qty, sp.supplier_count
FROM cte_order_details co
FULL OUTER JOIN cte_supplier_parts sp ON co.o_orderkey = sp.ps_partkey
WHERE (co.o_totalprice IS NOT NULL OR sp.total_available_qty IS NOT NULL)
  AND (co.total_lineitem_price > 1000 OR sp.supplier_count > 5)
ORDER BY co.o_orderdate DESC NULLS LAST
LIMIT 100;