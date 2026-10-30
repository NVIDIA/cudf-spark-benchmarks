WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) as order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1997-01-01'
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_availqty,
        SUM(ps.ps_supplycost) AS total_supplycost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
CustomerNation AS (
    SELECT
        c.c_custkey,
        n.n_name AS nation_name,
        c.c_acctbal
    FROM
        customer c
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        c.c_acctbal > 10000
),
LineItemStats AS (
    SELECT
        l.l_orderkey,
        COUNT(*) AS line_count,
        AVG(l.l_extendedprice * (1 - l.l_discount)) AS avg_line_price
    FROM
        lineitem l
    GROUP BY
        l.l_orderkey
    HAVING
        AVG(l.l_extendedprice * (1 - l.l_discount)) > 500
)
SELECT
    cn.nation_name,
    COUNT(DISTINCT co.o_orderkey) AS order_count,
    SUM(ps.total_supplycost) AS total_supplier_cost,
    SUM(ls.line_count) AS total_line_items,
    AVG(ls.avg_line_price) AS avg_price_per_line
FROM
    CustomerNation cn
LEFT JOIN
    RankedOrders co ON cn.c_custkey = co.o_orderkey
LEFT JOIN
    SupplierParts ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_size > 10)
LEFT JOIN
    LineItemStats ls ON co.o_orderkey = ls.l_orderkey
WHERE
    ps.total_availqty IS NOT NULL
    AND cn.c_acctbal IS NOT NULL
GROUP BY
    cn.nation_name
HAVING
    COUNT(DISTINCT co.o_orderkey) > 5
ORDER BY
    total_supplier_cost DESC;