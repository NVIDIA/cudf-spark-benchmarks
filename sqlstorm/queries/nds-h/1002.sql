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
RecentOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_total,
        ROW_NUMBER() OVER (PARTITION BY o.o_custkey ORDER BY o.o_orderdate DESC) AS rn
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= cast('1998-10-01' as date) - INTERVAL '90 days'
    GROUP BY
        o.o_orderkey, o.o_custkey, o.o_orderdate
)
SELECT
    r.r_name,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(COALESCE(rs.total_available, 0)) AS total_available_parts,
    AVG(COALESCE(rs.avg_supply_cost, 0)) AS avg_supply_cost,
    SUM(roi.order_total) AS total_recent_order_value
FROM
    region r
LEFT JOIN
    nation n ON r.r_regionkey = n.n_regionkey
LEFT JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    SupplierStats rs ON rs.s_suppkey IN (
        SELECT ps.ps_suppkey FROM partsupp ps
        JOIN lineitem l ON ps.ps_partkey = l.l_partkey
        WHERE l.l_quantity > 10
    )
LEFT JOIN
    RecentOrders roi ON roi.o_custkey = c.c_custkey
WHERE
    r.r_name LIKE 'North%'
    AND c.c_acctbal > 1000
GROUP BY
    r.r_name
ORDER BY
    total_recent_order_value DESC;