
WITH  MonthlySales AS (
    SELECT
        EXTRACT(YEAR FROM o_orderdate) AS year,
        EXTRACT(MONTH FROM o_orderdate) AS month,
        SUM(l_extendedprice * (1 - l_discount)) AS total_sales
    FROM
        orders AS o
    JOIN
        lineitem AS l ON o.o_orderkey = l.l_orderkey
    WHERE
        o_orderdate >= CURRENT_DATE - INTERVAL '12 months'
    GROUP BY
        EXTRACT(YEAR FROM o_orderdate), EXTRACT(MONTH FROM o_orderdate)
),
SupplierPerformance AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM
        supplier AS s
    JOIN
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
TopRegions AS (
    SELECT
        n.n_regionkey,
        SUM(l_extendedprice * (1 - l_discount)) AS region_sales
    FROM
        nation AS n
    JOIN
        supplier AS s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp AS ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem AS l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders AS o ON l.l_orderkey = o.o_orderkey
    WHERE
        l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY
        n.n_regionkey
    HAVING
        SUM(l_extendedprice * (1 - l_discount)) > 100000
),
SalesGrowth AS (
    SELECT
        m1.year,
        m1.month,
        (m1.total_sales - COALESCE(m2.total_sales, 0)) / NULLIF(m2.total_sales, 0) AS growth_rate
    FROM
        MonthlySales m1
    LEFT JOIN
        MonthlySales m2 ON m1.year = m2.year AND m1.month = m2.month + 1
)
SELECT
    r.r_name,
    COALESCE(t.region_sales, 0) AS total_region_sales,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost,
    COALESCE(pg.growth_rate, 0) AS monthly_growth_rate
FROM
    region AS r
LEFT JOIN
    TopRegions AS t ON r.r_regionkey = t.n_regionkey
LEFT JOIN
    SupplierPerformance AS sp ON sp.part_count > 10 
LEFT JOIN
    SalesGrowth AS pg ON pg.year = EXTRACT(YEAR FROM CURRENT_DATE) AND pg.month = EXTRACT(MONTH FROM CURRENT_DATE)
WHERE
    r.r_name IS NOT NULL
ORDER BY
    total_region_sales DESC, total_supply_cost DESC, monthly_growth_rate DESC;
