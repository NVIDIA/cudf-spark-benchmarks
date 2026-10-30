WITH Summary AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        SUM(l.l_extendedprice * (1 - l.l_discount) * (1 + l.l_tax)) AS total_taxed_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name = 'ASIA' 
        AND o.o_orderdate BETWEEN '1997-01-01' AND '1997-12-31'
    GROUP BY 
        p.p_partkey
),
RankedSummary AS (
    SELECT 
        s.p_partkey,
        s.total_quantity,
        s.total_revenue,
        s.total_taxed_revenue,
        s.order_count,
        RANK() OVER (ORDER BY s.total_revenue DESC) AS revenue_rank
    FROM 
        Summary s
)
SELECT 
    r.p_partkey,
    r.total_quantity,
    r.total_revenue,
    r.total_taxed_revenue,
    r.order_count
FROM 
    RankedSummary r
WHERE 
    r.revenue_rank <= 10
ORDER BY 
    r.total_revenue DESC;