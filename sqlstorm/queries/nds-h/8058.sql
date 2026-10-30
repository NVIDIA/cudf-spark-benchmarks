WITH SupplierSummary AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           SUM(ps.ps_availqty) AS total_avail_qty, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal
), 
TopSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           s.s_acctbal, 
           s.total_avail_qty, 
           s.total_supply_cost,
           RANK() OVER (ORDER BY s.total_supply_cost DESC) AS rank
    FROM SupplierSummary s
)
SELECT c.c_name, 
       c.c_acctbal, 
       sum(o.o_totalprice) AS total_order_value, 
       ts.total_supply_cost
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN TopSuppliers ts ON l.l_suppkey = ts.s_suppkey
WHERE o.o_orderstatus = 'O' 
  AND ts.rank <= 10
GROUP BY c.c_name, c.c_acctbal, ts.total_supply_cost
ORDER BY total_order_value DESC, c.c_name;
