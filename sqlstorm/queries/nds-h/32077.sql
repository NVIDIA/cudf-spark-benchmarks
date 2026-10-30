WITH  sales_ranking AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent,
        ROW_NUMBER() OVER (ORDER BY SUM(o.o_totalprice) DESC) AS rank
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01'
    GROUP BY
        c.c_custkey, c.c_name
),
supplier_summary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        COUNT(DISTINCT ps.ps_partkey) AS total_parts,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
part_details AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        COALESCE(SUM(l.l_quantity), 0) AS total_sold,
        ROW_NUMBER() OVER (PARTITION BY p.p_partkey ORDER BY COALESCE(SUM(l.l_quantity), 0) DESC) AS part_rank
    FROM
        part p
    LEFT JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY
        p.p_partkey, p.p_name, p.p_retailprice
),
country_sales AS (
    SELECT
        n.n_name,
        SUM(o.o_totalprice) AS total_revenue
    FROM
        nation n
    LEFT JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderstatus = 'F'
    GROUP BY
        n.n_name
)
SELECT
    s.c_custkey,
    s.c_name,
    COALESCE(p.total_sold, 0) AS total_parts_sold,
    ss.total_parts AS total_parts_supplied,
    ss.avg_supply_cost AS average_supply_cost,
    cs.total_revenue AS total_income_from_country
FROM
    sales_ranking s
LEFT JOIN
    part_details p ON s.c_custkey = p.p_partkey
LEFT JOIN
    supplier_summary ss ON ss.total_parts > 10
LEFT JOIN
    country_sales cs ON cs.total_revenue IS NOT NULL
WHERE
    s.rank <= 10
ORDER BY
    total_income_from_country DESC;