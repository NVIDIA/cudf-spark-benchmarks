WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        s.s_nationkey,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
),
TopSuppliers AS (
    SELECT 
        r.r_name, 
        COUNT(DISTINCT rs.s_suppkey) AS supplier_count,
        SUM(rs.s_acctbal) AS total_acctbal
    FROM RankedSuppliers rs
    JOIN nation n ON rs.s_nationkey = n.n_nationkey
    JOIN region r ON n.n_regionkey = r.r_regionkey
    WHERE rs.rnk <= 5
    GROUP BY r.r_name
),
CustomerOrders AS (
    SELECT 
        c.c_custkey, 
        o.o_orderkey, 
        o.o_orderdate, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= DATE '1997-01-01' 
      AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY c.c_custkey, o.o_orderkey, o.o_orderdate
),
RevenueAnalysis AS (
    SELECT 
        c.c_custkey,
        SUM(co.revenue) AS total_revenue,
        ROW_NUMBER() OVER (ORDER BY SUM(co.revenue) DESC) AS revenue_rank
    FROM CustomerOrders co
    JOIN customer c ON co.c_custkey = c.c_custkey
    GROUP BY c.c_custkey
)
SELECT 
    ta.r_name,
    ta.supplier_count,
    ta.total_acctbal,
    ra.total_revenue,
    ra.revenue_rank
FROM TopSuppliers ta
JOIN RevenueAnalysis ra ON ta.supplier_count > (SELECT AVG(supplier_count) FROM TopSuppliers)
ORDER BY ta.total_acctbal DESC, ra.total_revenue DESC
LIMIT 10;