WITH  CustomerOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        c.c_custkey,
        c.c_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1998-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderdate, c.c_custkey, c.c_name
),
SuspiciousOrders AS (
    SELECT
        cust.c_name,
        COUNT(DISTINCT co.o_orderkey) AS order_count,
        SUM(co.total_revenue) AS total_revenue
    FROM
        CustomerOrders co
    JOIN
        customer cust ON co.c_custkey = cust.c_custkey
    GROUP BY
        cust.c_name
    HAVING
        COUNT(DISTINCT co.o_orderkey) > 10 AND SUM(co.total_revenue) > 10000
),
FrequentNations AS (
    SELECT
        n.n_name,
        COUNT(s.s_suppkey) AS supplier_count
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    GROUP BY
        n.n_name
    HAVING
        COUNT(s.s_suppkey) > 5
)
SELECT
    cu.c_name AS customer_name,
    so.order_count,
    so.total_revenue,
    fn.n_name AS frequent_supplier_nation
FROM
    SuspiciousOrders so
FULL OUTER JOIN
    FrequentNations fn ON so.order_count > 10
JOIN
    customer cu ON cu.c_name = so.c_name
WHERE
    so.total_revenue IS NOT NULL OR fn.supplier_count > 0
ORDER BY
    so.total_revenue DESC,
    cu.c_name ASC;