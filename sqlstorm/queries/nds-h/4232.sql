WITH TopSuppliers AS (
    SELECT s.s_suppkey, s.s_name, SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyCost
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
    HAVING SUM(ps.ps_supplycost * ps.ps_availqty) > (
        SELECT AVG(TotalCost)
        FROM (
            SELECT SUM(ps_supplycost * ps_availqty) AS TotalCost
            FROM supplier s
            JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
            GROUP BY s.s_suppkey
        ) AS avg_cost
    )
), RecentOrders AS (
    SELECT o.o_orderkey, o.o_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '1 year'
    GROUP BY o.o_orderkey, o.o_custkey
), CustomerOrderCount AS (
    SELECT c.c_custkey, COUNT(o.o_orderkey) AS OrderCount
    FROM customer c
    LEFT JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey
), RankedCustomers AS (
    SELECT c.c_custkey, c.c_name, COALESCE(coc.OrderCount, 0) AS OrderCount,
           RANK() OVER (ORDER BY COALESCE(coc.OrderCount, 0) DESC) AS Rank
    FROM customer c
    LEFT JOIN CustomerOrderCount coc ON c.c_custkey = coc.c_custkey
)
SELECT rc.c_custkey, rc.c_name, rc.OrderCount, tu.TotalSupplyCost
FROM RankedCustomers rc
LEFT JOIN TopSuppliers tu ON rc.c_custkey = (
    SELECT DISTINCT ps.ps_suppkey
    FROM partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    WHERE s.s_name LIKE '%Supply%' AND ps.ps_availqty > 100
    LIMIT 1
)
WHERE rc.Rank <= 10 AND (rc.OrderCount > 5 OR tu.TotalSupplyCost IS NOT NULL)
ORDER BY rc.OrderCount DESC, tu.TotalSupplyCost DESC;