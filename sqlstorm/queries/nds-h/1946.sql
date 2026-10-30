
WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT o.o_orderkey) AS total_orders
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        n.n_name
),
SalesRank AS (
    SELECT
        nation_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        RegionalSales
),
TopNations AS (
    SELECT
        nation_name,
        total_sales
    FROM
        SalesRank
    WHERE
        sales_rank <= 5
)
SELECT
    tn.nation_name,
    tn.total_sales,
    COALESCE((SELECT AVG(total_sales) FROM TopNations), 0) AS avg_top_sales,
    (SELECT COUNT(*) FROM orders o WHERE o.o_orderdate >= DATE '1997-01-01') AS total_orders_1997,
    EXISTS (
        SELECT 1
        FROM part p
        WHERE p.p_brand = 'Brand#19'
        AND EXISTS (
            SELECT 1
            FROM partsupp ps
            WHERE ps.ps_partkey = p.p_partkey AND ps.ps_availqty > 0
        )
    ) AS part_availability
FROM
    TopNations tn
LEFT JOIN
    region r ON tn.nation_name = (
        SELECT n.n_name
        FROM nation n
        WHERE n.n_nationkey = (
            SELECT s.s_nationkey
            FROM supplier s
            WHERE s.s_suppkey = (
                SELECT l.l_suppkey
                FROM lineitem l
                WHERE l.l_orderkey IN (
                    SELECT o.o_orderkey
                    FROM orders o
                    WHERE o.o_totalprice > 10000
                )
                LIMIT 1
            )
            LIMIT 1
        )
    )
ORDER BY
    tn.total_sales DESC;
