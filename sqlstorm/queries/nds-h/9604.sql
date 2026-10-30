
WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT rs.s_suppkey, rs.s_name, d.c_name, d.o_orderdate, rs.TotalSupplyCost,
           RANK() OVER (PARTITION BY d.o_orderdate ORDER BY rs.TotalSupplyCost DESC) AS SupplyRank
    FROM RankedSuppliers rs
    JOIN (
        SELECT o.o_orderkey, o.o_orderdate, c.c_name
        FROM orders o
        JOIN customer c ON o.o_custkey = c.c_custkey
    ) d ON d.o_orderkey = (
        SELECT l.l_orderkey 
        FROM lineitem l 
        WHERE l.l_partkey IN (
            SELECT p.p_partkey 
            FROM part p 
            WHERE p.p_retailprice < 100
        )
        AND l.l_returnflag = 'N'
        ORDER BY l.l_extendedprice DESC
        LIMIT 1
    )
)
SELECT ts.s_name, ts.c_name, ts.o_orderdate, ts.TotalSupplyCost
FROM TopSuppliers ts
WHERE ts.SupplyRank <= 5
ORDER BY ts.o_orderdate, ts.TotalSupplyCost DESC;
