WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        RANK() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rank_order
    FROM
        orders o
    WHERE
        o.o_orderdate >= '1997-01-01'
        AND o.o_orderdate <= '1997-12-31'
),
SupplierParts AS (
    SELECT
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_avail_qty,
        SUM(ps.ps_supplycost) AS total_supply_cost
    FROM
        partsupp ps
    GROUP BY
        ps.ps_partkey, ps.ps_suppkey
),
TotalSales AS (
    SELECT
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales
    FROM
        lineitem l
    JOIN
        RankedOrders ro ON l.l_orderkey = ro.o_orderkey
    GROUP BY
        l.l_partkey
)
SELECT
    p.p_partkey,
    p.p_name,
    COALESCE(ts.total_sales, 0) AS total_sales,
    COALESCE(sp.total_avail_qty, 0) AS total_available_quantity,
    COALESCE(sp.total_supply_cost, 0) AS total_supply_cost
FROM
    part p
LEFT JOIN
    TotalSales ts ON p.p_partkey = ts.l_partkey
LEFT JOIN
    SupplierParts sp ON p.p_partkey = sp.ps_partkey
WHERE
    p.p_size > 10
    AND (p.p_retailprice - COALESCE(sp.total_supply_cost, 0)) > 5.00
ORDER BY
    total_sales DESC, p.p_name ASC
LIMIT 100;