WITH RegionalSales AS (
    SELECT
        n.n_name AS nation_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS sales_rank
    FROM
        nation n
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        part p ON ps.ps_partkey = p.p_partkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        n.n_name
),
TopRegions AS (
    SELECT
        nation_name
    FROM
        RegionalSales
    WHERE
        sales_rank <= 3
),
OrderDetails AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_order_price,
        COUNT(l.l_orderkey) AS item_count,
        n.n_name AS nation_name
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
    GROUP BY
        o.o_orderkey, n.n_name
),
FinalReport AS (
    SELECT
        od.o_orderkey,
        od.total_order_price,
        od.item_count,
        od.nation_name,
        CASE
            WHEN od.total_order_price > 1000 THEN 'High Value'
            ELSE 'Standard Value'
        END AS order_value_category
    FROM
        OrderDetails od
    WHERE
        od.nation_name IN (SELECT nation_name FROM TopRegions)
)
SELECT
    fr.order_value_category,
    COUNT(*) AS num_orders,
    AVG(fr.total_order_price) AS avg_order_value,
    SUM(fr.item_count) AS total_items
FROM
    FinalReport fr
GROUP BY
    fr.order_value_category
HAVING
    SUM(fr.total_order_price) IS NOT NULL
ORDER BY
    order_value_category ASC
LIMIT 5 OFFSET 0;