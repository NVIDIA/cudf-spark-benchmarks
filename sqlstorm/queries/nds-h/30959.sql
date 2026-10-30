WITH  OrderHierarchy AS (
    SELECT o_orderkey, o_custkey, o_orderstatus, o_orderdate, o_totalprice, 
           ROW_NUMBER() OVER (PARTITION BY o_custkey ORDER BY o_orderdate DESC) AS order_rank
    FROM orders
    WHERE o_orderstatus IN ('O', 'P')
),
CustomerStats AS (
    SELECT c.c_custkey, 
           c.c_name, 
           SUM(o.o_totalprice) AS total_spent,
           COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
),
SupplierParts AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
LineItemStats AS (
    SELECT l.l_orderkey, 
           SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_lineprice,
           AVG(l.l_tax) AS avg_tax,
           COUNT(CASE WHEN l.l_returnflag = 'R' THEN 1 END) AS return_count
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT ch.o_orderkey, 
       cs.c_name, 
       lp.total_lineprice, 
       sp.total_supply_cost, 
       ch.order_rank,
       CASE 
           WHEN ch.o_orderdate < cast('1998-10-01' as date) - INTERVAL '1 year' THEN 'Old Order'
           ELSE 'Recent Order' 
       END AS order_age,
       (lp.total_lineprice - sp.total_supply_cost) AS profit_margin
FROM OrderHierarchy ch
JOIN CustomerStats cs ON ch.o_custkey = cs.c_custkey
JOIN LineItemStats lp ON ch.o_orderkey = lp.l_orderkey
LEFT JOIN SupplierParts sp ON lp.total_lineprice > sp.total_supply_cost
ORDER BY profit_margin DESC NULLS LAST
LIMIT 10;