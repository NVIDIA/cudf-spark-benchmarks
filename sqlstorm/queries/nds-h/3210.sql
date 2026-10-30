
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        c.c_name AS customer_name,
        ROW_NUMBER() OVER (PARTITION BY c.c_nationkey ORDER BY o.o_totalprice DESC) AS rank_by_price
    FROM
        orders o
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01'
        AND o.o_orderdate < DATE '1997-01-01'
),
SupplierStats AS (
    SELECT
        s.s_suppkey,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS average_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey
),
FilteredParts AS (
    SELECT
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        COALESCE(NULLIF(p.p_comment, ''), 'No Comment') AS part_comment
    FROM
        part p
    WHERE
        p.p_size BETWEEN 10 AND 20
        AND p.p_retailprice > (
            SELECT AVG(p2.p_retailprice) FROM part p2 WHERE p2.p_size <= 15
        )
),
OrderLineDetails AS (
    SELECT
        l.l_orderkey,
        COUNT(*) AS total_lines,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    WHERE
        l.l_shipdate > DATE '1998-10-01' - INTERVAL '1 year'
    GROUP BY
        l.l_orderkey
)
SELECT
    ro.o_orderkey,
    ro.customer_name,
    ro.o_totalprice,
    ro.o_orderdate,
    p.part_comment,
    COALESCE(ss.average_supply_cost, 0) AS avg_supply_cost,
    ol.total_lines,
    ol.total_revenue
FROM
    RankedOrders ro
LEFT JOIN 
    FilteredParts p ON ro.o_orderkey = (
        SELECT MAX(l.l_orderkey)
        FROM lineitem l
        WHERE l.l_orderkey IN (
            SELECT l2.l_orderkey
            FROM lineitem l2
            WHERE l2.l_partkey IN (SELECT p_partkey FROM FilteredParts)
        )
    )
LEFT JOIN 
    SupplierStats ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        WHERE ps.ps_partkey IN (SELECT p_partkey FROM FilteredParts)
        LIMIT 1
    )
JOIN 
    OrderLineDetails ol ON ol.l_orderkey = ro.o_orderkey
WHERE
    ro.rank_by_price <= 5
ORDER BY
    ro.o_orderdate DESC, ro.o_totalprice DESC;
