WITH RankedItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        DENSE_RANK() OVER (PARTITION BY p.p_brand ORDER BY SUM(l.l_extendedprice * (1 - l.l_discount)) DESC) AS brand_rank
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
    WHERE 
        n.n_regionkey IN (SELECT r.r_regionkey FROM region r WHERE r.r_name = 'ASIA')
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand, p.p_type
),
TopSellingItems AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        t.total_quantity,
        t.total_revenue
    FROM 
        RankedItems t
    JOIN 
        part p ON t.p_partkey = p.p_partkey
    WHERE 
        t.brand_rank <= 5
)
SELECT 
    t.p_brand,
    COUNT(*) AS num_items,
    SUM(t.total_quantity) AS sum_quantity,
    SUM(t.total_revenue) AS sum_revenue,
    AVG(t.total_revenue) AS avg_revenue_per_item
FROM 
    TopSellingItems t
GROUP BY 
    t.p_brand
ORDER BY 
    sum_revenue DESC
LIMIT 10;
