WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name,
        c.c_acctbal,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        COUNT(DISTINCT ps.ps_partkey) AS part_count
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
HighValueSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name
    FROM
        SupplierStats s
    WHERE
        s.total_supply_cost > (SELECT AVG(total_supply_cost) FROM SupplierStats)
)
SELECT
    r.r_name AS region,
    n.n_name AS nation,
    COUNT(DISTINCT o.o_orderkey) AS total_orders,
    SUM(o.o_totalprice) AS total_revenue,
    AVG(c.c_acctbal) AS average_customer_balance
FROM
    RankedOrders o
JOIN
    customer c ON o.c_name = c.c_name
JOIN
    nation n ON c.c_nationkey = n.n_nationkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
JOIN
    lineitem l ON o.o_orderkey = l.l_orderkey
WHERE
    o.order_rank <= 10 AND
    l.l_returnflag = 'N' AND
    EXISTS (SELECT 1 FROM HighValueSuppliers h WHERE h.s_suppkey = l.l_suppkey)
GROUP BY
    r.r_name, n.n_name
ORDER BY
    total_revenue DESC;