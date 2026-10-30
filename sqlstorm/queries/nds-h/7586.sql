WITH RankedOrders AS (
    SELECT o.o_orderkey, o.o_orderdate, o.o_totalprice, c.c_name, c.c_acctbal,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS OrderRank
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
),
TopNations AS (
    SELECT n.n_nationkey, n.n_name, SUM(o.o_totalprice) AS TotalRevenue
    FROM nation n
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN orders o ON c.c_custkey = o.o_custkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY n.n_nationkey, n.n_name
    ORDER BY TotalRevenue DESC
    LIMIT 5
)
SELECT r.r_name, COALESCE(RO.o_orderkey, 0) AS TopOrderKey, COALESCE(RO.o_totalprice, 0) AS TopOrderPrice, TN.TotalRevenue
FROM region r
LEFT JOIN TopNations TN ON r.r_regionkey = TN.n_nationkey
LEFT JOIN RankedOrders RO ON TN.n_nationkey = RO.o_orderkey
WHERE RO.OrderRank = 1
ORDER BY TN.TotalRevenue DESC, r.r_name;