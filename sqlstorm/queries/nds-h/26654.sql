WITH SupplierOrders AS (
    SELECT 
        s.s_name AS supplier_name,
        s.s_nationkey AS supplier_nationkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_name, s.s_nationkey
),
NationRevenue AS (
    SELECT 
        n.n_name AS nation_name,
        SUM(so.total_revenue) AS total_nation_revenue,
        COUNT(DISTINCT so.supplier_name) AS supplier_count
    FROM nation n
    JOIN SupplierOrders so ON n.n_nationkey = so.supplier_nationkey
    GROUP BY n.n_name
)
SELECT 
    nr.nation_name,
    nr.total_nation_revenue,
    nr.supplier_count,
    CASE 
        WHEN nr.total_nation_revenue > 100000 THEN 'High Revenue'
        WHEN nr.total_nation_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM NationRevenue nr
ORDER BY nr.total_nation_revenue DESC;
