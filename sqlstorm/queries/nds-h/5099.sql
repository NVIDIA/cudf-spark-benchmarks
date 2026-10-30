WITH RankedSales AS (
    SELECT
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        part p
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        r.r_name = 'EUROPE'
        AND l.l_shipdate BETWEEN '1996-01-01' AND '1996-12-31'
    GROUP BY
        p.p_partkey, p.p_name
),
TopProducts AS (
    SELECT
        p_partkey,
        total_revenue
    FROM
        RankedSales
    WHERE
        sales_rank <= 10
)
SELECT
    tp.p_partkey,
    p.p_name,
    tp.total_revenue,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(l.l_quantity) AS total_quantity
FROM
    TopProducts tp
JOIN
    part p ON tp.p_partkey = p.p_partkey
JOIN
    lineitem l ON p.p_partkey = l.l_partkey
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
GROUP BY
    tp.p_partkey, p.p_name, tp.total_revenue
ORDER BY
    tp.total_revenue DESC;