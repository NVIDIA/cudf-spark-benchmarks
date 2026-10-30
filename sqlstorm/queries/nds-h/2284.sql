WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        o.o_orderdate,
        o.o_totalprice,
        o.o_orderstatus,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY o.o_totalprice DESC) AS rn
    FROM
        orders o
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1997-01-01'
),
CustomerStats AS (
    SELECT
        c.c_custkey,
        c.c_name,
        COUNT(o.o_orderkey) AS order_count,
        SUM(o.o_totalprice) AS total_spent
    FROM
        customer c
    LEFT JOIN
        orders o ON c.c_custkey = o.o_custkey
    GROUP BY
        c.c_custkey, c.c_name
),
SupplierPartSummary AS (
    SELECT
        s.s_suppkey,
        s.s_name,
        SUM(ps.ps_availqty) AS total_available,
        AVG(ps.ps_supplycost) AS avg_supply_cost
    FROM
        supplier s
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        s.s_suppkey, s.s_name
),
CompositeData AS (
    SELECT
        r.r_name AS region,
        n.n_name AS nation,
        SUM(ps.ps_supplycost * ps.ps_availqty) AS total_cost,
        AVG(ps.ps_supplycost) AS average_cost
    FROM
        region r
    JOIN
        nation n ON r.r_regionkey = n.n_regionkey
    JOIN
        supplier s ON n.n_nationkey = s.s_nationkey
    JOIN
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
    GROUP BY
        r.r_name, n.n_name
)

SELECT
    co.region,
    co.nation,
    COALESCE(cs.order_count, 0) AS customer_order_count,
    COALESCE(cs.total_spent, 0) AS customer_total_spent,
    rs.o_orderkey,
    rs.o_orderdate,
    rs.o_totalprice,
    ss.total_available,
    ss.avg_supply_cost,
    COALESCE(NULLIF(rs.o_orderstatus, 'O'), 'N/A') AS order_status_altered
FROM
    CompositeData co
LEFT JOIN
    CustomerStats cs ON cs.c_custkey = (
        SELECT MIN(c.c_custkey)
        FROM customer c
        JOIN orders o ON c.c_custkey = o.o_custkey
        WHERE o.o_orderstatus = 'O'
        LIMIT 1
    )
LEFT JOIN
    RankedOrders rs ON rs.rn = 1
LEFT JOIN
    SupplierPartSummary ss ON ss.s_suppkey = (
        SELECT ps.ps_suppkey
        FROM partsupp ps
        ORDER BY ps.ps_availqty DESC
        LIMIT 1
    )
ORDER BY
    co.region, co.nation;