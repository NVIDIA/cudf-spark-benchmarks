WITH TotalRevenue AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        l.l_shipdate >= DATE '1994-01-01'
        AND l.l_shipdate < DATE '1995-01-01'
    GROUP BY
        c.c_custkey, c.c_name
),
AverageRevenue AS (
    SELECT
        AVG(total_revenue) AS avg_revenue
    FROM
        TotalRevenue
),
HighValueCustomers AS (
    SELECT
        tr.c_custkey,
        tr.c_name,
        tr.total_revenue
    FROM
        TotalRevenue tr
    JOIN
        AverageRevenue ar ON tr.total_revenue > ar.avg_revenue
)

SELECT
    hvc.c_custkey,
    hvc.c_name,
    hvc.total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
FROM
    HighValueCustomers hvc
JOIN
    orders o ON hvc.c_custkey = o.o_custkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE
    o.o_orderstatus = 'F'
GROUP BY
    hvc.c_custkey, hvc.c_name, hvc.total_revenue
ORDER BY
    total_sales DESC
LIMIT 10;
