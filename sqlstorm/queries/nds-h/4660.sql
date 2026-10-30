
WITH RankedOrders AS (
    SELECT
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT c.c_custkey) AS num_customers,
        ROW_NUMBER() OVER (PARTITION BY o.o_orderstatus ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS rank
    FROM
        orders o
    JOIN
        lineitem l ON o.o_orderkey = l.l_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    WHERE
        o.o_orderdate >= DATE '1995-01-01'
        AND o.o_orderdate < DATE '1996-01-01'
    GROUP BY
        o.o_orderkey, o.o_orderstatus
), OrdersWithExtra AS (
    SELECT
        r.n_name AS nation_name,
        ro.o_orderkey,
        ro.total_revenue,
        ro.num_customers,
        CASE WHEN ro.num_customers > 0 THEN ro.total_revenue / ro.num_customers ELSE NULL END AS avg_revenue_per_customer
    FROM 
        RankedOrders ro
    LEFT JOIN 
        customer c ON ro.o_orderkey = c.c_custkey
    LEFT JOIN 
        nation r ON c.c_nationkey = r.n_nationkey
), FilteredOrders AS (
    SELECT
        nation_name,
        SUM(total_revenue) AS total_revenue_by_nation,
        AVG(avg_revenue_per_customer) AS avg_revenue
    FROM 
        OrdersWithExtra
    WHERE
        nation_name IS NOT NULL
    GROUP BY 
        nation_name
)
SELECT
    f.nation_name,
    f.total_revenue_by_nation,
    f.avg_revenue
FROM 
    FilteredOrders f
WHERE 
    f.total_revenue_by_nation > (
        SELECT AVG(total_revenue_by_nation)
        FROM FilteredOrders
    )
ORDER BY 
    f.total_revenue_by_nation DESC
LIMIT 10;
