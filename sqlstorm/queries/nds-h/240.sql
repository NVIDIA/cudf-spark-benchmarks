WITH SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
OrderLineStats AS (
    SELECT
        o.o_orderkey,
        COUNT(l.l_orderkey) AS line_count,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    LEFT JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' 
    GROUP BY
        o.o_orderkey
),
CustomerRegion AS (
    SELECT
        c.c_custkey,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        c.c_acctbal
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    cr.region_name,
    cr.nation_name,
    SUM(ols.total_revenue) AS total_sales,
    COUNT(DISTINCT cr.c_custkey) AS unique_customers,
    MAX(ss.avg_supply_cost) AS max_avg_supply_cost,
    MIN(ss.total_available) AS min_total_available
FROM
    CustomerRegion cr
LEFT JOIN
    OrderLineStats ols ON cr.c_custkey = ols.o_orderkey 
LEFT JOIN
    SupplierStats ss ON ss.s_suppkey IN (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderstatus = 'O')
    )
GROUP BY
    cr.region_name, cr.nation_name
HAVING
    SUM(ols.total_revenue) > 10000
ORDER BY
    total_sales DESC,
    unique_customers ASC;