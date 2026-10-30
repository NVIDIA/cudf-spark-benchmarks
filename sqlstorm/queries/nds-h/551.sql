WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY c.c_mktsegment ORDER BY o.o_totalprice DESC) AS total_price_rank,
        c.c_name,
        c.c_nationkey
    FROM
        orders o
    JOIN customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND
        o.o_orderdate < DATE '1997-01-01'
),
SupplierPartDetails AS (
    SELECT
        ps.ps_partkey,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        p.p_retailprice,
        p.p_name
    FROM
        partsupp ps
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN part p ON ps.ps_partkey = p.p_partkey
    WHERE
        s.s_acctbal > 1000.00
),
AggregateLineitem AS (
    SELECT
        l.l_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_line_price
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= DATE '1996-01-01' AND
        l.l_shipdate < DATE '1997-01-01'
    GROUP BY
        l.l_orderkey
)
SELECT
    ro.o_orderkey,
    ro.o_orderdate,
    ro.o_totalprice,
    spd.s_name,
    spd.p_name,
    spd.p_retailprice,
    ro.c_name AS customer_name,
    ro.total_price_rank,
    al.total_line_price,
    (SELECT COUNT(*) FROM lineitem l WHERE l.l_orderkey = ro.o_orderkey) AS lineitem_count
FROM
    RankedOrders ro
LEFT JOIN AggregateLineitem al ON ro.o_orderkey = al.l_orderkey
LEFT JOIN SupplierPartDetails spd ON spd.ps_partkey IN (
    SELECT ps_partkey FROM partsupp WHERE ps_supplycost < 50.00
)
WHERE
    ro.total_price_rank = 1
ORDER BY
    ro.o_orderdate DESC, ro.o_totalprice DESC;