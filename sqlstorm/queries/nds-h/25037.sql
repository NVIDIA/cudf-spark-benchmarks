WITH AggregatedData AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        s.s_name AS supplier_name,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        r.r_name AS region_name
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    JOIN 
        nation n ON c.c_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        r.r_name LIKE '%West%' 
        AND l.l_shipdate BETWEEN DATE '1996-01-01' AND DATE '1996-12-31'
    GROUP BY 
        p.p_partkey, p.p_name, s.s_name, r.r_name
), RankedData AS (
    SELECT 
        *,
        RANK() OVER (PARTITION BY region_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        AggregatedData
)
SELECT 
    p_partkey,
    p_name,
    supplier_name,
    total_quantity,
    total_revenue,
    order_count,
    region_name
FROM 
    RankedData
WHERE 
    revenue_rank <= 5
ORDER BY 
    region_name, total_revenue DESC;