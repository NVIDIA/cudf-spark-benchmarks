WITH  top_suppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > 10000
    ORDER BY total_supply_cost DESC
    LIMIT 5
),
customer_orders AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) IS NOT NULL AND COUNT(o.o_orderkey) > 0
),
line_items_extended AS (
    SELECT l.*, 
           ROUND(l.l_extendedprice * (1 - l.l_discount), 2) AS net_price,
           CASE 
               WHEN l.l_returnflag = 'Y' THEN 'Returned'
               ELSE 'Not Returned'
           END AS return_status,
           ROW_NUMBER() OVER (PARTITION BY l.l_orderkey ORDER BY l.l_linenumber) AS item_row
    FROM lineitem l
)
SELECT c.c_name, 
       SUM(li.net_price) AS total_net_spent,
       COUNT(DISTINCT o.o_orderkey) AS total_orders,
       max(s.s_name) AS max_supplier_name,
       CASE 
           WHEN SUM(li.net_price) > (SELECT AVG(total_spent) FROM customer_orders) THEN 'Above Average'
           ELSE 'Below Average'
       END AS spending_status
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN line_items_extended li ON o.o_orderkey = li.l_orderkey
LEFT JOIN top_suppliers s ON li.l_suppkey = s.s_suppkey
GROUP BY c.c_custkey, c.c_name
HAVING COUNT(DISTINCT o.o_orderkey) > 5 
   AND SUM(li.net_price) IS NOT NULL
ORDER BY total_net_spent DESC
LIMIT 10;
