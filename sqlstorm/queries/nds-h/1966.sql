WITH HighValueOrders AS (
    SELECT o.o_orderkey, o.o_totalprice, o.o_orderdate, c.c_name, c.c_nationkey,
           ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE o.o_orderstatus = 'O' AND o.o_totalprice > 500
),
NationsWithSuppliers AS (
    SELECT n.n_name, AVG(s.s_acctbal) AS avg_account_balance
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY n.n_name
),
TotalSales AS (
    SELECT l.l_orderkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM lineitem l
    GROUP BY l.l_orderkey
)
SELECT r.r_name, n.n_name, h.o_orderkey, h.o_totalprice, t.total_sales
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN HighValueOrders h ON n.n_nationkey = h.c_nationkey
LEFT JOIN TotalSales t ON h.o_orderkey = t.l_orderkey
WHERE h.rn <= 5 OR t.total_sales IS NULL
ORDER BY r.r_name, n.n_name, h.o_orderkey;
