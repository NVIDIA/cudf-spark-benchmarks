
WITH  part_supplier_info AS (
    SELECT
        p.p_partkey,
        p.p_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY ps.ps_supplycost DESC) AS rn
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    WHERE
        ps.ps_availqty > 0
),
filtered_orders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
        AND o.o_totalprice > 1000
),
total_sales AS (
    SELECT
        lo.l_orderkey,
        SUM(lo.l_extendedprice * (1 - lo.l_discount)) AS total
    FROM
        lineitem lo
    GROUP BY
        lo.l_orderkey
),
nation_sales AS (
    SELECT
        n.n_nationkey,
        SUM(ts.total) AS nation_total
    FROM
        nation n
    LEFT JOIN
        filtered_orders fo ON n.n_nationkey = fo.c_nationkey
    LEFT JOIN
        total_sales ts ON fo.o_orderkey = ts.l_orderkey
    GROUP BY
        n.n_nationkey
),
ranked_sales AS (
    SELECT
        ns.nation_total,
        RANK() OVER (ORDER BY ns.nation_total DESC) AS sales_rank
    FROM
        nation_sales ns
)
SELECT
    COALESCE(s.nation_total, 0) AS total_sales,
    ps.p_name,
    ps.rn
FROM
    part_supplier_info ps
LEFT JOIN
    ranked_sales s ON s.sales_rank = ps.rn
WHERE
    (ps.ps_availqty > 10 OR ps.ps_supplycost IS NULL)
    AND ps.rn <= 5
ORDER BY
    total_sales DESC,
    ps.p_name 
LIMIT 10 OFFSET 0;
