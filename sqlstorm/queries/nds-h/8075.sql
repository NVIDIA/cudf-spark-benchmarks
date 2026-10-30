WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        RANK() OVER (ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CustomerOrders AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS total_orders,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
)
SELECT
    c.c_custkey,
    c.c_name,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_extendedprice END), 0) AS total_returns,
    COALESCE(SUM(CASE WHEN l.l_returnflag = 'N' THEN l.l_extendedprice END), 0) AS total_sales,
    r.total_available,
    r.total_cost
FROM
    CustomerOrders c
LEFT JOIN
    lineitem l ON c.c_custkey = l.l_orderkey
LEFT JOIN
    RankedSuppliers r ON r.rank <= 10
WHERE
    c.total_orders > 5
GROUP BY
    c.c_custkey, c.c_name, r.total_available, r.total_cost
ORDER BY
    total_sales DESC, total_returns ASC;
