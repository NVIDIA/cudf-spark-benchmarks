WITH CountryOrders AS (
    SELECT n.n_name AS Nation, COUNT(o.o_orderkey) AS TotalOrders, SUM(o.o_totalprice) AS TotalRevenue
    FROM nation n
    JOIN supplier s ON n.n_nationkey = s.s_nationkey
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    JOIN lineitem l ON p.p_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY n.n_name
),
RankedOrders AS (
    SELECT Nation, TotalOrders, TotalRevenue,
           DENSE_RANK() OVER (ORDER BY TotalRevenue DESC) AS RevenueRank,
           DENSE_RANK() OVER (ORDER BY TotalOrders DESC) AS OrderRank
    FROM CountryOrders
)
SELECT Nation, TotalOrders, TotalRevenue, RevenueRank, OrderRank
FROM RankedOrders
WHERE RevenueRank <= 5 AND OrderRank <= 5
ORDER BY RevenueRank, OrderRank;
