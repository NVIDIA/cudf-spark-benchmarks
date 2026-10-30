WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey, o.o_orderstatus
),
TopCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts_supplied
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
)
SELECT
    r.r_name AS region,
    COUNT(DISTINCT n.n_nationkey) AS total_nations,
    COUNT(DISTINCT c.c_custkey) AS total_customers,
    SUM(CASE WHEN r.r_regionkey IN (SELECT DISTINCT n.n_regionkey FROM nation n) THEN 1 ELSE 0 END) AS valid_regions,
    COALESCE(SUM(t.total_spent), 0) AS total_revenue_from_top_customers,
    s.total_parts_supplied
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    customer c ON n.n_nationkey = c.c_nationkey
LEFT JOIN
    TopCustomers t ON c.c_custkey = t.c_custkey
JOIN
    SupplierStats s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps)
GROUP BY
    r.r_name, s.total_parts_supplied
ORDER BY
    total_revenue_from_top_customers DESC, region;
