WITH RankedSales AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        RANK() OVER (PARTITION BY p.p_partkey ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS revenue_rank
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
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
        AND l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey, p.p_name
),
TopSellingParts AS (
    SELECT 
        p_partkey, 
        p_name,
        total_revenue
    FROM 
        RankedSales
    WHERE 
        revenue_rank <= 10
)
SELECT 
    tsp.p_partkey,
    tsp.p_name,
    tsp.total_revenue,
    s.s_name AS supplier_name,
    s.s_acctbal AS supplier_account_balance,
    n.n_name AS nation_name
FROM 
    TopSellingParts tsp
JOIN 
    partsupp ps ON tsp.p_partkey = ps.ps_partkey
JOIN 
    supplier s ON ps.ps_suppkey = s.s_suppkey
JOIN 
    nation n ON s.s_nationkey = n.n_nationkey
ORDER BY 
    tsp.total_revenue DESC;