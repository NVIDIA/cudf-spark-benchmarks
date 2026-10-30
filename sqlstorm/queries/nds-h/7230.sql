
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS supplier_rank,
        n.n_regionkey
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_regionkey
),
SalesData AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        EXTRACT(YEAR FROM o.o_orderdate) AS order_year,
        n.n_regionkey
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    GROUP BY
        o.o_orderkey, EXTRACT(YEAR FROM o.o_orderdate), n.n_regionkey
)
SELECT
    sd.order_year,
    rs.s_name,
    rs.total_cost,
    sd.total_sales,
    sd.total_sales - rs.total_cost AS profit
FROM
    SalesData sd
JOIN
    RankedSuppliers rs ON sd.n_regionkey = rs.n_regionkey
WHERE
    rs.supplier_rank <= 5
ORDER BY
    sd.order_year, profit DESC;
