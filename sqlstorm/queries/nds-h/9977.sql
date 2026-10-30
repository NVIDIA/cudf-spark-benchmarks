WITH regional_sales AS (
    SELECT
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
    GROUP BY
        r.r_name
),
supplier_part_cost AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
ranked_sales AS (
    SELECT
        region_name,
        total_sales,
        RANK() OVER (ORDER BY total_sales DESC) AS sales_rank
    FROM
        regional_sales
)
SELECT
    rs.region_name,
    rs.total_sales,
    spc.total_supply_cost,
    (rs.total_sales - COALESCE(spc.total_supply_cost, 0)) AS profit_margin
FROM
    ranked_sales rs
LEFT JOIN
    supplier_part_cost spc ON rs.sales_rank = spc.s_suppkey
WHERE
    rs.total_sales > 1000000
ORDER BY
    profit_margin DESC;