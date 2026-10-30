WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_value
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, n.n_name
),
TopSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.nation,
        s.total_parts,
        s.total_value,
        RANK() OVER (ORDER BY s.total_value DESC) AS supplier_rank
    FROM SupplierStats s
)
SELECT 
    c.c_custkey,
    c.c_name,
    o.o_orderkey,
    o.o_orderdate,
    ts.s_suppkey,
    ts.s_name,
    ts.total_value,
    ts.total_parts,
    d.avg_price,
    d.order_count
FROM customer c
JOIN orders o ON c.c_custkey = o.o_custkey
JOIN TopSuppliers ts ON o.o_orderkey % 10 = ts.s_suppkey % 10  
JOIN (
    SELECT 
        l.l_orderkey,
        AVG(l.l_extendedprice) AS avg_price,
        COUNT(*) AS order_count
    FROM lineitem l
    GROUP BY l.l_orderkey
) d ON o.o_orderkey = d.l_orderkey
WHERE ts.supplier_rank <= 10
ORDER BY ts.total_value DESC, o.o_orderdate DESC;