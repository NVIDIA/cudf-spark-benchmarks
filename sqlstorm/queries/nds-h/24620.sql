WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS SupplierRank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
FilteredCustomers AS (
    SELECT 
        c.c_custkey, 
        c.c_name, 
        c.c_acctbal, 
        c.c_mktsegment
    FROM customer c
    WHERE c.c_acctbal > (
        SELECT AVG(c2.c_acctbal) 
        FROM customer c2 
        WHERE c2.c_mktsegment = c.c_mktsegment
    )
),
NationParts AS (
    SELECT 
        n.n_nationkey,
        n.n_name, 
        COUNT(DISTINCT p.p_partkey) AS PartCount
    FROM nation n
    LEFT JOIN supplier s ON n.n_nationkey = s.s_nationkey
    LEFT JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    LEFT JOIN part p ON ps.ps_partkey = p.p_partkey
    GROUP BY n.n_nationkey, n.n_name
)
SELECT 
    c.c_name AS CustomerName,
    s.s_name AS SupplierName,
    np.n_name AS NationName,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
    CASE 
        WHEN COUNT(DISTINCT ps.ps_partkey) IS NULL THEN 'No Parts'
        ELSE 'Parts Available'
    END AS PartAvailability,
    RANK() OVER (ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS RevenueRank
FROM orders o
JOIN lineitem l ON o.o_orderkey = l.l_orderkey
JOIN FilteredCustomers c ON o.o_custkey = c.c_custkey
JOIN RankedSuppliers s ON l.l_suppkey = s.s_suppkey AND s.SupplierRank = 1
JOIN NationParts np ON s.s_suppkey = np.n_nationkey
LEFT JOIN partsupp ps ON l.l_partkey = ps.ps_partkey 
GROUP BY c.c_name, s.s_name, np.n_name
HAVING SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
ORDER BY RevenueRank, c.c_name;
