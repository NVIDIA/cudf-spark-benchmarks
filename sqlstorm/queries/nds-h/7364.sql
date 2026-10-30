WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, n.n_name AS nation_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value,
           RANK() OVER (PARTITION BY n.n_name ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
), 
TopSuppliers AS (
    SELECT * FROM RankedSuppliers WHERE supplier_rank <= 5
), 
CustomerOrderValues AS (
    SELECT c.c_custkey, c.c_name, SUM(o.o_totalprice) AS total_order_value
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT ts.nation_name, ts.s_name, cov.c_name AS top_customer, cov.total_order_value
FROM TopSuppliers ts
JOIN CustomerOrderValues cov ON ts.s_suppkey IN (
    SELECT ps.ps_suppkey 
    FROM partsupp ps 
    JOIN part p ON ps.ps_partkey = p.p_partkey 
    WHERE p.p_brand = 'BrandX'
)
ORDER BY ts.nation_name, ts.total_value DESC, cov.total_order_value DESC;
