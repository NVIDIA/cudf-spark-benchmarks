WITH TotalSales AS (
    SELECT 
        l_partkey,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue
    FROM 
        lineitem
    WHERE 
        l_shipdate >= DATE '1996-01-01' AND l_shipdate < DATE '1997-01-01'
    GROUP BY 
        l_partkey
), SupplierStats AS (
    SELECT 
        ps_partkey,
        COUNT(DISTINCT ps_suppkey) AS supplier_count,
        AVG(ps_supplycost) AS average_cost
    FROM 
        partsupp
    GROUP BY 
        ps_partkey
), PartDetail AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COALESCE(ts.total_revenue, 0) AS total_revenue,
        COALESCE(ss.supplier_count, 0) AS supplier_count,
        COALESCE(ss.average_cost, 0) AS average_cost
    FROM 
        part p
    LEFT JOIN TotalSales ts ON p.p_partkey = ts.l_partkey
    LEFT JOIN SupplierStats ss ON p.p_partkey = ss.ps_partkey
), RankedParts AS (
    SELECT 
        p.*,
        ROW_NUMBER() OVER (ORDER BY p.total_revenue DESC) AS revenue_rank,
        RANK() OVER (ORDER BY p.average_cost DESC) AS cost_rank
    FROM 
        PartDetail p
)
SELECT 
    rp.p_partkey,
    rp.p_name,
    rp.p_brand,
    rp.total_revenue,
    rp.supplier_count,
    rp.average_cost,
    CASE 
        WHEN rp.revenue_rank <= 10 THEN 'Top Revenue'
        WHEN rp.cost_rank <= 10 THEN 'Top Cost'
        ELSE 'Regular'
    END AS classification
FROM 
    RankedParts rp
WHERE 
    rp.supplier_count > 0
ORDER BY 
    rp.total_revenue DESC, rp.average_cost ASC;