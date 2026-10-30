WITH OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS unique_customers,
        r.r_name AS region,
        n.n_name AS nation
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        supplier s ON l.l_suppkey = s.s_suppkey
    JOIN
        partsupp ps ON l.l_partkey = ps.ps_partkey AND s.s_suppkey = ps.ps_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    WHERE
        o.o_orderdate BETWEEN DATE '1994-01-01' AND DATE '1997-12-31'
    GROUP BY
        o.o_orderkey, o.o_orderdate, r.r_name, n.n_name
),
RankedOrders AS (
    SELECT
        os.*,
        RANK() OVER (PARTITION BY os.region ORDER BY os.total_revenue DESC) AS revenue_rank
    FROM
        OrderSummary os
)

SELECT 
    ro.o_orderkey,
    ro.o_orderdate,
    ro.total_revenue,
    ro.unique_customers,
    ro.region,
    ro.nation
FROM
    RankedOrders ro
WHERE
    ro.revenue_rank <= 10
ORDER BY
    ro.region, ro.total_revenue DESC;
