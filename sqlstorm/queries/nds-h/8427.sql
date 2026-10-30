
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
), FilteredOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE l.l_shipdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
), TopSuppliers AS (
    SELECT r.*, ROW_NUMBER() OVER (PARTITION BY r.nation_name ORDER BY r.total_supply_cost DESC) AS rank
    FROM RankedSuppliers r
)
SELECT 
    f.o_orderkey, 
    f.o_custkey, 
    ts.s_name, 
    ts.nation_name, 
    f.total_price, 
    MAX(ts.total_supply_cost) AS max_supply_cost
FROM 
    FilteredOrders f
JOIN 
    TopSuppliers ts ON f.o_custkey = ts.s_suppkey
WHERE 
    ts.rank <= 5
GROUP BY 
    f.o_orderkey, f.o_custkey, ts.s_name, ts.nation_name, f.total_price
ORDER BY 
    f.total_price DESC;
