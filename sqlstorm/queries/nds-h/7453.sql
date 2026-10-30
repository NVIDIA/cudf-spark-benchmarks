WITH TotalSales AS (
    SELECT
        n.n_name AS nation,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        lineitem l
        JOIN orders o ON l.l_orderkey = o.o_orderkey
        JOIN customer c ON o.o_custkey = c.c_custkey
        JOIN nation n ON c.c_nationkey = n.n_nationkey
    WHERE
        o.o_orderdate >= DATE '1996-01-01' AND o.o_orderdate < DATE '1996-01-01' + INTERVAL '1 year'
        AND l.l_returnflag = 'N'
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
    rs.nation,
    rs.total_revenue,
    COUNT(s.s_suppkey) AS supplier_count,
    MIN(s.s_acctbal) AS min_account_balance,
    MAX(s.s_acctbal) AS max_account_balance,
    AVG(s.s_acctbal) AS avg_account_balance
FROM
    RankedSales rs
    JOIN partsupp ps ON ps.ps_partkey IN (SELECT p.p_partkey FROM part p WHERE p.p_brand = 'Brand#23')
    JOIN supplier s ON ps.ps_suppkey = s.s_suppkey
WHERE
    rs.revenue_rank <= 10
GROUP BY
    rs.nation, rs.total_revenue
ORDER BY
    rs.total_revenue DESC;
