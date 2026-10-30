
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS SupplierRank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE p.p_size BETWEEN 10 AND 30
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey, n.n_regionkey
),
AggregateOrders AS (
    SELECT
        o.o_orderkey,
        o.o_totalprice,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS NetRevenue,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY o.o_orderkey, o.o_totalprice, o.o_orderdate
)
SELECT
    r.r_name AS Region,
    rs.s_name AS SupplierName,
    ao.o_orderkey,
    ao.NetRevenue,
    ao.LineItemCount
FROM RankedSuppliers rs
JOIN nation n ON rs.s_nationkey = n.n_nationkey
JOIN region r ON n.n_regionkey = r.r_regionkey
JOIN AggregateOrders ao ON rs.s_suppkey IN (
    SELECT ps.ps_suppkey
    FROM partsupp ps
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE p.p_type = 'Metal'
)
WHERE rs.SupplierRank <= 5
ORDER BY r.r_name, ao.NetRevenue DESC;
