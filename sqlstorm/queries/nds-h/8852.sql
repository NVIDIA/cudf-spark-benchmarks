WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderpriority,
        DENSE_RANK() OVER (PARTITION BY o.o_orderpriority ORDER BY o.o_totalprice DESC) AS order_rank
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1995-01-01' AND o.o_orderdate < DATE '1996-01-01'
),
SupplierDetails AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
FilteredLineItems AS (
    SELECT
        l.l_orderkey,
        l.l_partkey,
        l.l_suppkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_value
    FROM
        lineitem l
    WHERE
        l.l_shipdate >= DATE '1995-01-01' AND l.l_shipdate < DATE '1996-01-01'
    GROUP BY
        l.l_orderkey, l.l_partkey, l.l_suppkey
)
SELECT
    r.o_orderkey,
    r.o_orderstatus,
    r.o_totalprice,
    r.o_orderdate,
    r.o_orderpriority,
    COALESCE(SD.total_supply_cost, 0) AS supplier_cost,
    COALESCE(FLI.total_quantity, 0) AS item_quantity,
    COALESCE(FLI.total_value, 0) AS item_value
FROM
    RankedOrders r
LEFT JOIN
    SupplierDetails SD ON r.o_orderkey = SD.s_suppkey
LEFT JOIN
    FilteredLineItems FLI ON r.o_orderkey = FLI.l_orderkey
WHERE
    r.order_rank <= 10
ORDER BY
    r.o_orderdate ASC, r.o_orderpriority DESC, r.o_totalprice DESC;
