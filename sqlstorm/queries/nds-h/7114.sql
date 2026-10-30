WITH RankedSuppliers AS (
    SELECT s.s_suppkey, s.s_name, s.s_acctbal,
           ROW_NUMBER() OVER (PARTITION BY n.n_nationkey ORDER BY s.s_acctbal DESC) AS rnk
    FROM supplier s
    JOIN nation n ON s.s_nationkey = n.n_nationkey
    WHERE s.s_acctbal > 10000
),
TopSuppliers AS (
    SELECT s_suppkey, s_name, s_acctbal
    FROM RankedSuppliers
    WHERE rnk <= 5
),
RevenueSummary AS (
    SELECT c.c_custkey, SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
RegionRevenue AS (
    SELECT r.r_name, SUM(rs.total_revenue) AS region_total_revenue
    FROM region r
    JOIN nation n ON r.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN RevenueSummary rs ON c.c_custkey = rs.c_custkey
    GROUP BY r.r_name
)
SELECT r.r_name, r.region_total_revenue, ts.s_name, ts.s_acctbal
FROM RegionRevenue r
JOIN TopSuppliers ts ON r.region_total_revenue > 500000
ORDER BY r.region_total_revenue DESC, ts.s_acctbal DESC;
