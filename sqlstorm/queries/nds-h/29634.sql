WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    ORDER BY total_supply_cost DESC
    LIMIT 10
), CustomerStats AS (
    SELECT c.c_custkey, c.c_name, COUNT(o.o_orderkey) AS order_count, SUM(o.o_totalprice) AS total_spent
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
), DetailedLineItems AS (
    SELECT l.l_orderkey, l.l_partkey, l.l_quantity, l.l_extendedprice, l.l_discount, l.l_tax,
           l.l_returnflag, l.l_linestatus, p.p_name, s.s_name AS supplier_name
    FROM lineitem l
    JOIN part p ON l.l_partkey = p.p_partkey
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
)
SELECT cs.c_name AS Customer_Name, cs.order_count AS Total_Orders, cs.total_spent AS Total_Spent,
       ds.l_orderkey, ds.l_partkey, ds.l_quantity, ds.l_extendedprice,
       ds.l_discount, ds.l_tax, ds.l_returnflag, ds.l_linestatus,
       ds.p_name AS Part_Name, ts.s_name AS Top_Supplier_Name, ts.total_supply_cost
FROM CustomerStats cs
JOIN DetailedLineItems ds ON cs.c_custkey = ds.l_orderkey
JOIN TopSuppliers ts ON ds.supplier_name = ts.s_name
WHERE cs.total_spent > 1000 AND ds.l_discount > 0.1
ORDER BY cs.total_spent DESC, ts.total_supply_cost DESC;
