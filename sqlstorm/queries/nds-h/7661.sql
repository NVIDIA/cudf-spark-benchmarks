
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, 
           s.s_name, 
           n.n_name AS nation_name, 
           SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT s.s_suppkey AS suppkey, 
           s.s_name AS name, 
           s.nation_name, 
           s.total_supply_cost,
           RANK() OVER (PARTITION BY s.nation_name ORDER BY s.total_supply_cost DESC) AS rank
    FROM RankedSuppliers s
)
SELECT c.c_name AS customer_name, 
       o.o_orderkey AS order_key, 
       li.l_quantity AS quantity_ordered, 
       ts.name AS supplier_name, 
       ts.total_supply_cost AS supplier_cost
FROM orders o
JOIN customer c ON o.o_custkey = c.c_custkey
JOIN lineitem li ON o.o_orderkey = li.l_orderkey
JOIN TopSuppliers ts ON li.l_suppkey = ts.suppkey
WHERE ts.rank <= 3
  AND o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
ORDER BY c.c_name, o.o_orderkey, ts.total_supply_cost DESC;
