WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supplycost,
        ROW_NUMBER() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
HighValueCustomers AS (
    SELECT
        c.c_custkey,
        c.c_name,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
    GROUP BY
        c.c_custkey, c.c_name
    HAVING
        SUM(o.o_totalprice) > 10000
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS order_revenue
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY
        o.o_orderkey
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 5000
),
TopSuppliers AS (
    SELECT
        rs.s_suppkey,
        rs.s_name,
        r.r_name
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        rs.rank <= 5
),
TopCustomers AS (
    SELECT
        hvc.c_custkey,
        hvc.c_name
    FROM
        HighValueCustomers hvc
    WHERE
        hvc.total_spent > 20000
)
SELECT
    s.s_name AS supplier_name,
    sum(l.l_extendedprice) AS total_revenue,
    count(o.o_orderkey) AS total_orders,
    c.c_name AS customer_name
FROM
    lineitem l
JOIN
    orders o ON l.l_orderkey = o.o_orderkey
JOIN
    TopSuppliers s ON l.l_suppkey = s.s_suppkey
JOIN
    TopCustomers c ON o.o_custkey = c.c_custkey
WHERE
    l.l_shipmode = 'AIR' AND
    o.o_orderdate BETWEEN DATE '1997-01-01' AND DATE '1997-12-31'
GROUP BY
    s.s_name, c.c_name
ORDER BY
    total_revenue DESC
LIMIT 10;