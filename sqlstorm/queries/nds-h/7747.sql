
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN customer c ON s.s_nationkey = c.c_nationkey
    WHERE p.p_size > 10 AND s.s_acctbal > 5000
    GROUP BY s.s_suppkey, s.s_name, s.s_acctbal, c.c_mktsegment
), TopSuppliers AS (
    SELECT 
        r.r_name AS region,
        ns.n_name AS nation,
        rs.s_name AS supplier_name,
        rs.total_cost
    FROM RankedSuppliers rs
    JOIN nation ns ON rs.s_suppkey = ns.n_nationkey
    JOIN region r ON ns.n_regionkey = r.r_regionkey
    WHERE rs.supplier_rank <= 5
)
SELECT 
    region, 
    nation, 
    supplier_name, 
    total_cost
FROM TopSuppliers
ORDER BY region, nation, total_cost DESC;
