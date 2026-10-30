WITH SupplierOrderStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(o.o_totalprice) AS avg_order_value,
        SUM(l.l_quantity) AS total_quantity
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    JOIN
        lineitem l ON ps.ps_partkey = l.l_partkey
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1997-10-01'
    GROUP BY
        s.s_suppkey, s.s_name
),
TopSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        total_revenue,
        order_count,
        avg_order_value,
        total_quantity,
        RANK() OVER (ORDER BY total_revenue DESC) AS rank
    FROM
        SupplierOrderStats s
)
SELECT
    t.s_suppkey,
    t.s_name,
    t.total_revenue,
    t.order_count,
    t.avg_order_value,
    t.total_quantity
FROM
    TopSuppliers t
WHERE
    t.rank <= 10
ORDER BY
    t.total_revenue DESC;