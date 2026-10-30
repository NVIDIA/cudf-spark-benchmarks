WITH TotalSales AS (
    SELECT
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
    JOIN
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN
        customer c ON o.o_custkey = c.c_custkey
    JOIN
        nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate >= DATE '1997-01-01' AND o.o_orderdate < DATE '1998-01-01'
    GROUP BY
        n.n_name
), 
RankedSales AS (
    SELECT
        nation,
        total_revenue,
        RANK() OVER (ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        TotalSales
)

SELECT
    r.n_name,
    SUM(CASE WHEN l.l_returnflag = 'R' THEN l.l_quantity ELSE 0 END) AS returned_quantity,
    AVG(s.total_revenue) AS avg_total_revenue
FROM
    RankedSales s
JOIN
    nation r ON r.n_name = s.nation
JOIN
    lineitem l ON l.l_orderkey IN (SELECT o.o_orderkey FROM orders o WHERE o.o_orderdate >= DATE '1997-01-01')
WHERE
    s.revenue_rank <= 5
GROUP BY
    r.n_name
ORDER BY
    avg_total_revenue DESC;