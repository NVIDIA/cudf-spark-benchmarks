WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, rs.total_supply_cost,
           RANK() OVER (ORDER BY rs.total_supply_cost DESC) as supplier_rank
    FROM RankedSuppliers rs
    JOIN supplier s ON s.s_suppkey = rs.s_suppkey
    WHERE rs.total_supply_cost > 100000
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, 
           c.c_custkey, c.c_name, c.c_mktsegment
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 50000
)
SELECT hvo.o_orderkey, hvo.o_totalprice, hvo.o_orderdate, 
       ts.s_suppkey, ts.s_name, ts.total_supply_cost, 
       hvo.c_custkey, hvo.c_name, hvo.c_mktsegment
FROM HighValueOrders hvo
JOIN lineitem li ON hvo.o_orderkey = li.l_orderkey
JOIN TopSuppliers ts ON li.l_suppkey = ts.s_suppkey
WHERE li.l_returnflag = 'N' AND 
      li.l_shipdate BETWEEN '1997-01-01' AND '1997-12-31'
ORDER BY ts.total_supply_cost DESC, hvo.o_totalprice DESC
LIMIT 100;