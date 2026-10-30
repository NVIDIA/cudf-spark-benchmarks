WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) as Rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(li.l_extendedprice * (1 - li.l_discount)) AS TotalSales,
        COUNT(DISTINCT li.l_partkey) AS DistinctPartsSold
    FROM orders o
    JOIN lineitem li ON o.o_orderkey = li.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_orderdate
),
TopCustomers AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS TotalSpent
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    GROUP BY c.c_custkey, c.c_name
    HAVING SUM(o.o_totalprice) > 10000
)
SELECT 
    r.r_name,
    ps.ps_partkey,
    COUNT(s.s_suppkey) AS SupplierCount,
    AVG(s.s_acctbal) AS AverageAccountBalance,
    COALESCE(SUM(os.TotalSales), 0) AS TotalSales,
    COALESCE(MAX(t.TotalSpent), 0) AS MaxCustomerSpent
FROM region r
LEFT JOIN nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
LEFT JOIN OrderSummary os ON ps.ps_partkey = os.o_orderkey
LEFT JOIN TopCustomers t ON ps.ps_partkey = t.c_custkey
GROUP BY r.r_name, ps.ps_partkey
HAVING COUNT(s.s_suppkey) > 0 AND AVG(s.s_acctbal) > 500.00
ORDER BY r.r_name, ps.ps_partkey;