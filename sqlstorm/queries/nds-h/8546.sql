WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS TotalSupplyValue,
        COUNT(DISTINCT ps.ps_partkey) AS UniquePartsSupplied
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
OrderStats AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalOrderValue,
        COUNT(l.l_orderkey) AS TotalLineItems
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey
),
CustomerOrderStats AS (
    SELECT 
        c.c_custkey,
        c.c_name,
        SUM(os.TotalOrderValue) AS TotalSpent,
        COUNT(os.o_orderkey) AS TotalOrders
    FROM customer c
    JOIN OrderStats os ON c.c_custkey = os.o_custkey
    GROUP BY c.c_custkey, c.c_name
)
SELECT 
    rs.r_name AS Region,
    COUNT(DISTINCT cs.c_custkey) AS UniqueCustomers,
    SUM(cs.TotalSpent) AS TotalRevenue,
    COUNT(DISTINCT ss.s_suppkey) AS UniqueSuppliers,
    AVG(cs.TotalOrders) AS AvgOrdersPerCustomer
FROM region rs
JOIN nation n ON rs.r_regionkey = n.n_regionkey
JOIN customer c ON n.n_nationkey = c.c_nationkey
JOIN CustomerOrderStats cs ON c.c_custkey = cs.c_custkey
JOIN SupplierStats ss ON ss.TotalSupplyValue > 100000
GROUP BY rs.r_name
ORDER BY TotalRevenue DESC;