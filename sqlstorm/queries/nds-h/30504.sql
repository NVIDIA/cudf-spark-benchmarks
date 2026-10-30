WITH  supplier_revenue AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY s.s_suppkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rn
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        s.s_suppkey, s.s_name
),
top_suppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        COALESCE(sr.total_revenue, 0) AS total_revenue
    FROM
        supplier s
    LEFT JOIN
        (SELECT s_suppkey, total_revenue FROM supplier_revenue WHERE rn = 1) sr ON s.s_suppkey = sr.s_suppkey
),
regions_with_orders AS (
    SELECT
        n.n_regionkey,
        SUM(o.o_totalprice) AS region_order_total
    FROM
        nation n
    JOIN
        customer c ON n.n_nationkey = c.c_nationkey
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        n.n_regionkey
),
supplier_performance AS (
    SELECT
        ts.s_suppkey,
        ts.s_name,
        ts.s_acctbal,
        ts.total_revenue,
        COALESCE(rw.region_order_total, 0) AS total_region_order
    FROM
        top_suppliers ts
    LEFT JOIN
        regions_with_orders rw ON ts.s_suppkey = rw.n_regionkey
)
SELECT
    sp.s_suppkey,
    sp.s_name,
    sp.s_acctbal,
    sp.total_revenue,
    sp.total_region_order,
    CASE 
        WHEN sp.total_revenue > 100000 THEN 'High Revenue'
        WHEN sp.total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM
    supplier_performance sp
WHERE
    sp.total_region_order IS NOT NULL
ORDER BY
    sp.total_revenue DESC NULLS LAST;
