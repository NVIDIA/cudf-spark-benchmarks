
WITH  order_summary AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_spent,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        RANK() OVER (PARTITION BY EXTRACT(YEAR FROM o.o_orderdate) ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank_spent
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    GROUP BY
        o.o_orderkey, o.o_orderdate
),
top_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        os.total_spent,
        os.unique_customers,
        n.n_name AS nation_name
    FROM
        order_summary os
    JOIN
        orders o ON os.o_orderkey = o.o_orderkey
    LEFT JOIN
        supplier s ON s.s_suppkey IN (SELECT ps.ps_suppkey FROM partsupp ps JOIN part p ON ps.ps_partkey = p.p_partkey WHERE p.p_container = 'SM CASE' AND ps.ps_availqty IS NOT NULL)
    LEFT JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE
        os.rank_spent <= 10
    ORDER BY
        os.total_spent DESC
)
SELECT
    top.o_orderkey,
    top.o_orderdate,
    COALESCE(top.total_spent, 0) AS spent_amount,
    COALESCE(top.unique_customers, 0) AS cust_count,
    COUNT(DISTINCT l.l_linenumber) AS line_count,
    SUM(l.l_quantity) AS total_quantity,
    STRING_AGG(DISTINCT p.p_name) AS product_names
FROM
    top_orders top
LEFT JOIN
    lineitem l ON top.o_orderkey = l.l_orderkey
LEFT JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
LEFT JOIN
    part p ON ps.ps_partkey = p.p_partkey
GROUP BY
    top.o_orderkey, top.o_orderdate, top.total_spent, top.unique_customers
HAVING
    SUM(l.l_extendedprice) IS NOT NULL
ORDER BY
    top.o_orderdate DESC, spent_amount DESC;
