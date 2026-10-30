WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        n.n_name AS nation_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
HighValueOrders AS (
    SELECT
        ro.customer_name,
        ro.nation_name,
        SUM(ro.o_totalprice) AS total_spent
    FROM
        RankedOrders ro
    WHERE
        ro.order_rank <= 10
    GROUP BY
        ro.customer_name, ro.nation_name
),
PartSupplier AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_quantity,
        SUM(ps.ps_supplycost) AS total_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
ProductsWithSuppliers AS (
    SELECT
        p.p_name,
        p.p_brand,
        ps.total_quantity,
        ps.total_cost
    FROM
        part p
    JOIN
        PartSupplier ps ON p.p_partkey = ps.ps_partkey
)
SELECT
    hvo.customer_name,
    hvo.nation_name,
    pws.p_name,
    pws.p_brand,
    pws.total_quantity,
    pws.total_cost,
    hvo.total_spent
FROM
    HighValueOrders hvo
JOIN
    ProductsWithSuppliers pws ON hvo.nation_name = pws.p_brand
ORDER BY
    hvo.total_spent DESC, pws.total_quantity DESC
LIMIT 50;