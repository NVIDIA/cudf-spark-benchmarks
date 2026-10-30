WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        DENSE_RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY s.s_suppkey, s.s_name
),
RecentOrders AS (
    SELECT 
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM orders o
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE o.o_orderdate >= '1997-01-01'
    GROUP BY o.o_orderkey, o.o_custkey, o.o_orderdate
),
SupplierRevenue AS (
    SELECT 
        r.r_name,
        SUM(RO.total_revenue) AS revenue
    FROM RecentOrders RO
    JOIN customer c ON RO.o_custkey = c.c_custkey
    JOIN supplier s ON s.s_nationkey = c.c_nationkey
    JOIN nation n ON n.n_nationkey = s.s_nationkey
    JOIN region r ON r.r_regionkey = n.n_regionkey
    GROUP BY r.r_name
)
SELECT 
    r.r_name,
    COALESCE(SR.revenue, 0) AS total_revenue,
    COALESCE(RS.total_cost, 0) AS supplier_total_cost,
    (COALESCE(SR.revenue, 0) - COALESCE(RS.total_cost, 0)) AS profit
FROM region r
LEFT JOIN SupplierRevenue SR ON r.r_name = SR.r_name
LEFT JOIN RankedSuppliers RS ON RS.supplier_rank <= 5
WHERE r.r_name IS NOT NULL
ORDER BY profit DESC;