WITH SupplierStats AS (
    SELECT 
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM supplier s
    JOIN partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY s.s_suppkey
),
CustomerStats AS (
    SELECT 
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM customer c
    JOIN orders o ON c.c_custkey = o.o_custkey
    JOIN lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY c.c_custkey
),
RegionPerformance AS (
    SELECT 
        reg.r_name,
        COUNT(DISTINCT c.c_custkey) AS number_of_customers,
        SUM(cs.total_revenue) AS total_revenue_from_customers,
        SUM(ss.total_revenue) AS total_revenue_from_suppliers
    FROM region reg
    JOIN nation n ON reg.r_regionkey = n.n_regionkey
    JOIN customer c ON n.n_nationkey = c.c_nationkey
    JOIN CustomerStats cs ON cs.c_custkey = c.c_custkey
    JOIN SupplierStats ss ON ss.total_orders > 0
    GROUP BY reg.r_name
)
SELECT
    r.r_name,
    rp.number_of_customers,
    rp.total_revenue_from_customers,
    rp.total_revenue_from_suppliers,
    (rp.total_revenue_from_customers + rp.total_revenue_from_suppliers) AS total_combined_revenue
FROM regionPerformance rp
JOIN region r ON r.r_name = rp.r_name
ORDER BY total_combined_revenue DESC;
