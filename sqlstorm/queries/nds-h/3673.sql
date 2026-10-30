WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderdate ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
        AND o.o_orderstatus = 'O'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
supplier_summary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
customer_orders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        MAX(o.o_totalprice) AS max_order_total
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
combined_data AS (
    SELECT
        r.o_orderkey,
        r.total_revenue,
        co.max_order_total,
        su.total_supplycost
    FROM
        ranked_orders r
    LEFT JOIN
        customer_orders co ON r.o_orderkey = co.c_custkey
    FULL OUTER JOIN
        supplier_summary su ON r.o_orderkey IS NULL AND su.s_suppkey IS NOT NULL
    WHERE
        r.revenue_rank <= 10
)
SELECT
    COUNT(*) AS total_records,
    AVG(total_revenue) AS avg_revenue,
    SUM(total_supplycost) AS total_supply_cost
FROM
    combined_data
WHERE
    total_revenue IS NOT NULL
    AND total_supplycost IS NOT NULL
    AND (total_revenue > 5000 OR total_supplycost < 1000)
ORDER BY
    avg_revenue DESC;