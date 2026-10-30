WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        RANK() OVER (PARTITION BY o.o_orderdate ORDER BY o.o_totalprice DESC) AS rank_price
    FROM
        orders o
    WHERE
        o.o_orderdate >= '1996-01-01'
        AND o.o_orderdate <= '1996-12-31'
),
SupplierStats AS (
    SELECT
        ps.ps_partkey,
        s.s_nationkey,
        AVG(ps.ps_supplycost) AS avg_supply_cost,
        SUM(ps.ps_availqty) AS total_available_qty
    FROM
        partsupp ps
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY
        ps.ps_partkey, s.s_nationkey
),
CustomerPerformance AS (
    SELECT
        c.c_custkey,
        COUNT(DISTINCT o.o_orderkey) AS total_orders,
        SUM(i.l_extendedprice * (1 - i.l_discount)) AS total_revenue
    FROM
        customer c
    JOIN
        orders o ON c.c_custkey = o.o_custkey
    JOIN
        lineitem i ON o.o_orderkey = i.l_orderkey
    GROUP BY
        c.c_custkey
),
FinalReport AS (
    SELECT
        p.p_partkey,
        p.p_name,
        COALESCE(CS.total_orders, 0) AS total_orders,
        COALESCE(CS.total_revenue, 0) AS total_revenue,
        RS.rank_price
    FROM
        part p
    LEFT JOIN
        CustomerPerformance CS ON p.p_partkey = CS.c_custkey
    LEFT JOIN
        RankedOrders RS ON p.p_partkey = RS.o_orderkey
    WHERE
        p.p_retailprice > (
            SELECT AVG(avg_supply_cost) FROM SupplierStats
            WHERE s_nationkey IN (SELECT n_nationkey FROM nation WHERE n_name = 'USA')
        )
    ORDER BY
        total_revenue DESC
)
SELECT
    f.p_partkey,
    f.p_name,
    f.total_orders,
    f.total_revenue,
    f.rank_price
FROM
    FinalReport f
WHERE
    f.total_orders > 5
    OR f.total_revenue > 5000.00
ORDER BY
    f.rank_price DESC, f.total_revenue DESC;