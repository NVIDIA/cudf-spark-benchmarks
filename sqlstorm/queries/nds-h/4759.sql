
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_nationkey,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
HighValueSuppliers AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(sp.total_supply_cost) AS total_cost
    FROM
        supplier s
    LEFT JOIN
        SupplierParts sp ON s.s_suppkey = sp.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
    HAVING
        SUM(sp.total_supply_cost) > (SELECT AVG(total_supply_cost) FROM SupplierParts)
),
JoinedData AS (
    SELECT
        r.r_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        l.l_shipdate BETWEEN DATE '1995-01-01' AND DATE '1995-12-31'
    GROUP BY
        r.r_name
)
SELECT
    j.r_name,
    j.revenue,
    j.order_count,
    COALESCE(s.s_name, 'No Supplier') AS supplier_name,
    o.o_orderdate,
    o.o_totalprice
FROM
    JoinedData j
LEFT JOIN
    HighValueSuppliers s ON j.order_count > 5
LEFT JOIN
    RankedOrders o ON j.order_count = o.rn
ORDER BY
    j.revenue DESC, j.order_count DESC
LIMIT 10;
