WITH RankedParts AS (
    SELECT p.p_partkey, p.p_name, p.p_brand, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost
    FROM part p
    JOIN partsupp ps ON p.p_partkey = ps.ps_partkey
    GROUP BY p.p_partkey, p.p_name, p.p_brand
),
TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS supplier_cost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
    ORDER BY supplier_cost DESC
    LIMIT 5
),
HighValueOrders AS (
    SELECT o.o_orderkey, o.o_custkey, o.o_totalprice, c.c_name
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_totalprice > 1000
),
FinalReport AS (
    SELECT 
        r.r_name AS region, 
        n.n_name AS nation,
        t.s_name AS supplier_name,
        rp.p_name AS part_name,
        rp.total_cost AS part_total_cost,
        hvo.o_orderkey AS order_key,
        hvo.o_totalprice AS high_value_order_total
    FROM TopSuppliers t
    JOIN region r ON t.n_name = r.r_name
    JOIN nation n ON t.n_name = n.n_name
    JOIN RankedParts rp ON t.s_suppkey = rp.p_partkey 
    JOIN HighValueOrders hvo ON hvo.o_custkey = t.s_suppkey 
)

SELECT *
FROM FinalReport
ORDER BY region, nation, part_total_cost DESC;
