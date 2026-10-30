WITH RankedSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        n.n_name AS supplier_nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_supply_cost,
        RANK() OVER (PARTITION BY n.n_regionkey ORDER BY SUM(ps.ps_supplycost * ps.ps_availqty) DESC) AS rank_in_region
    FROM
        supplier s
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name, n.n_name, n.n_regionkey
),
HighValueOrders AS (
    SELECT
        o.o_orderkey,
        o.o_custkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_order_value,
        o.o_orderdate,
        o.o_orderstatus
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE
        o.o_orderdate >= '1997-01-01'
    GROUP BY
        o.o_orderkey, o.o_custkey, o.o_orderdate, o.o_orderstatus
    HAVING
        SUM(l.l_extendedprice * (1 - l.l_discount)) > 10000
)
SELECT
    r.r_name AS region_name,
    COUNT(DISTINCT o.o_orderkey) AS order_count,
    SUM(o.net_order_value) AS total_net_value,
    COUNT(DISTINCT s.s_suppkey) AS supplier_count,
    MAX(s.total_supply_cost) AS max_supplier_cost
FROM
    RankedSuppliers s
JOIN
    nation n ON s.supplier_nation = n.n_name
JOIN
    HighValueOrders o ON n.n_nationkey = o.o_custkey
JOIN
    region r ON n.n_regionkey = r.r_regionkey
GROUP BY
    r.r_name
ORDER BY
    total_net_value DESC;