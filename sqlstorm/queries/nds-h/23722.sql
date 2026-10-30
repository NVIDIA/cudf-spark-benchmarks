
WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (PARTITION BY s.s_nationkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rnk
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, s.s_nationkey
),
TopSuppliers AS (
    SELECT
        r.r_name,
        rs.s_name,
        rs.total_cost
    FROM
        RankedSuppliers rs
    JOIN
        nation n ON rs.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        rs.rnk = 1
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        DENSE_RANK() OVER (PARTITION BY c.c_custkey ORDER BY o.o_orderdate DESC) AS order_rank
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    WHERE
        o.o_totalprice > (
            SELECT AVG(o2.o_totalprice)
            FROM orders o2
            WHERE o2.o_orderdate > DATE '1998-10-01' - INTERVAL '1 year'
        )
)
SELECT
    c.c_name,
    COALESCE(ts.r_name, 'Unknown Region') AS region,
    ts.total_cost,
    COUNT(co.o_orderkey) AS total_orders,
    STRING_AGG(DISTINCT CAST(co.o_orderkey AS STRING), ', ') AS order_ids
FROM
    CustomerOrders co
LEFT JOIN
    TopSuppliers ts ON ts.s_name LIKE '%' || co.c_name || '%'
LEFT JOIN
    customer c ON co.c_custkey = c.c_custkey
WHERE
    co.order_rank <= 5
GROUP BY
    c.c_name, ts.r_name, ts.total_cost
HAVING
    SUM(co.o_totalprice) > (
        SELECT SUM(o3.o_totalprice)
        FROM orders o3
        WHERE o3.o_orderdate < DATE '1998-10-01' - INTERVAL '2 year'
    ) OR ts.total_cost IS NULL
ORDER BY
    region, total_orders DESC, c.c_name;
