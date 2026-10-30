WITH PartSupplierRevenue AS (
    SELECT 
        p.p_name AS part_name,
        s.s_name AS supplier_name,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        part p
    JOIN 
        partsupp ps ON p.p_partkey = ps.ps_partkey
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1997-01-01' AND l.l_shipdate < DATE '1997-10-01'
    GROUP BY 
        p.p_name, s.s_name
), RankedRevenue AS (
    SELECT 
        part_name,
        supplier_name,
        total_revenue,
        RANK() OVER (PARTITION BY part_name ORDER BY total_revenue DESC) AS revenue_rank
    FROM 
        PartSupplierRevenue
)
SELECT 
    part_name,
    supplier_name,
    total_revenue
FROM 
    RankedRevenue
WHERE 
    revenue_rank = 1
ORDER BY 
    part_name, total_revenue DESC;