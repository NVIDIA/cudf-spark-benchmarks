
WITH ranked_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
top_customers AS (
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
    WHERE
        o.o_orderdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY
        c.c_custkey, c.c_name
    ORDER BY
        total_spent DESC
    LIMIT 10
)
SELECT
    r.r_name,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    COUNT(DISTINCT tc.c_custkey) AS customer_count,
    SUM(l.l_extendedprice) AS total_sales
FROM
    region r
JOIN
    nation n ON r.r_regionkey = n.n_regionkey
JOIN
    supplier s ON n.n_nationkey = s.s_nationkey
JOIN
    partsupp ps ON s.s_suppkey = ps.ps_suppkey
JOIN
    part p ON ps.ps_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    ranked_orders ro ON l.l_orderkey = ro.o_orderkey
JOIN
    top_customers tc ON l.l_orderkey = tc.c_custkey
GROUP BY
    r.r_name
HAVING
    COUNT(DISTINCT tc.c_custkey) > 5
ORDER BY
    total_sales DESC;
