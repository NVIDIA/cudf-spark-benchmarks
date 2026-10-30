WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_nationkey,
        RANK() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate BETWEEN '1995-01-01' AND '1995-12-31'
),
TopOrders AS (
    SELECT
        ro.o_orderkey,
        ro.o_orderdate,
        ro.o_totalprice,
        ro.c_name
    FROM
        RankedOrders ro
    WHERE
        ro.rank <= 5
)
SELECT
    t.o_orderkey,
    t.o_orderdate,
    t.o_totalprice,
    SUM(l.l_quantity) AS total_quantity,
    SUM(l.l_extendedprice) AS total_revenue,
    AVG(s.s_acctbal) AS avg_supplier_balance
FROM
    TopOrders t
JOIN
    lineitem l ON t.o_orderkey = l.l_orderkey
JOIN
    partsupp ps ON l.l_partkey = ps.ps_partkey
JOIN
    supplier s ON ps.ps_suppkey = s.s_suppkey
GROUP BY
    t.o_orderkey, t.o_orderdate, t.o_totalprice, t.c_name
ORDER BY
    total_revenue DESC
LIMIT 10;