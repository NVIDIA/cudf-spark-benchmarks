WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_nationkey, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name, s.s_nationkey
),
CustomerOrderSummary AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS TotalOrders, SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderstatus = 'O'
    GROUP BY c.c_custkey
),
NationSummary AS (
    SELECT n.n_nationkey, n.n_name, COUNT(c.c_custkey) AS CustomerCount, SUM(cs.TotalSpent) AS TotalSpentByNation
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    LEFT JOIN CustomerOrderSummary cs ON c.c_custkey = cs.c_custkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT r.r_regionkey, r.r_name, ns.CustomerCount, ns.TotalSpentByNation, rs.s_suppkey, rs.s_name, rs.TotalCost
FROM region r
JOIN nation n ON r.r_regionkey = n.n_regionkey
JOIN NationSummary ns ON n.n_nationkey = ns.n_nationkey
JOIN RankedSuppliers rs ON n.n_nationkey = rs.s_nationkey
WHERE ns.TotalSpentByNation > 1000000
ORDER BY r.r_regionkey, ns.TotalSpentByNation DESC, rs.TotalCost DESC;
