WITH SupplyChain AS (
    SELECT
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        ps.ps_supplycost,
        ps.ps_availqty,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM
        part p
    JOIN
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN
        region r ON n.n_regionkey = r.r_regionkey
    JOIN
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE
        l.l_shipdate >= DATE '1997-01-01'
        AND l.l_shipdate < DATE '1997-10-01'
    GROUP BY
        p.p_partkey, p.p_name, s.s_name, ps.ps_supplycost, ps.ps_availqty, n.n_name, r.r_name
),
Ranking AS (
    SELECT
        *,
        RANK() OVER (PARTITION BY region_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM
        SupplyChain
)
SELECT
    region_name,
    p_partkey,
    p_name,
    supplier_name,
    ps_supplycost,
    ps_availqty,
    total_revenue,
    revenue_rank
FROM
    Ranking
WHERE
    revenue_rank <= 10
ORDER BY
    region_name, total_revenue DESC;