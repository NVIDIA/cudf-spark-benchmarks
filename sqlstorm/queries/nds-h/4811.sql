WITH RegionalSuppliers AS (
    SELECT
        n.n_name AS nation_name,
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        n.n_name, s.s_suppkey, s.s_name, s.s_acctbal
), FilteredOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_price
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderstatus IN ('O', 'F')
    GROUP BY
        o.o_orderkey, o.o_custkey
), CustomerRanked AS (
    SELECT
        c.c_custkey,
        c.c_name,
        c.c_acctbal,
        RANK() OVER (ORDER BY c.c_acctbal DESC) AS rank
    FROM
        customer c
    WHERE
        c.c_acctbal > 1000
)
SELECT
    r.nation_name,
    r.s_name,
    r.total_avail_qty,
    r.total_supply_cost,
    coalesce(co.total_price, 0) AS total_order_value,
    c.rank
FROM
    RegionalSuppliers r
LEFT JOIN
    FilteredOrders co ON r.s_suppkey = co.o_custkey
LEFT JOIN
    CustomerRanked c ON co.o_custkey = c.c_custkey
WHERE
    r.total_avail_qty > 0
ORDER BY
    r.nation_name, r.total_supply_cost DESC;