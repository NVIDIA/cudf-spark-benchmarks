WITH RevenueSummary AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        MIN(o.o_orderdate) AS first_order_date,
        MAX(o.o_orderdate) AS last_order_date
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY
        c.c_custkey, c.c_name
),
TopCustomers AS (
    SELECT
        r.r_name AS region,
        c.c_name AS customer_name,
        rs.total_revenue,
        ROW_NUMBER() OVER (PARTITION BY r.r_name ORDER BY rs.total_revenue DESC) AS rank
    FROM
        RevenueSummary rs
    JOIN
        customer c ON rs.c_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
)
SELECT
    region,
    customer_name,
    total_revenue
FROM
    TopCustomers
WHERE
    rank <= 5
ORDER BY
    region, total_revenue DESC;