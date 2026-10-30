
WITH TotalRevenue AS (
    SELECT
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate < DATE '1997-12-31'
    GROUP BY
        n.n_name
),
RankedRevenue AS (
    SELECT
        nation,
        revenue,
        RANK() OVER (ORDER BY revenue DESC) AS revenue_rank
    FROM
        TotalRevenue
)
SELECT
    r.r_name AS region_name,
    rr.nation,
    rr.revenue,
    rr.revenue_rank
FROM
    RankedRevenue rr
JOIN
    nation n ON rr.nation = n.n_name
JOIN
    region r ON n.n_regionkey = r.r_regionkey
WHERE
    rr.revenue_rank <= 10
ORDER BY
    r.r_name ASC, rr.revenue DESC;
