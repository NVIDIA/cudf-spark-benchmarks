WITH QuantitySummary AS (
    SELECT 
        p.p_partkey,
        SUM(l.l_quantity) AS total_quantity,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS net_revenue
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    WHERE 
        l.l_shipdate >= DATE '1996-01-01' 
        AND l.l_shipdate < DATE '1997-01-01'
    GROUP BY 
        p.p_partkey
),
SupplierSummary AS (
    SELECT 
        ps.ps_partkey,
        COUNT(DISTINCT ps.ps_suppkey) AS supplier_count,
        AVG(s.s_acctbal) AS avg_supplier_balance
    FROM 
        partsupp ps
    JOIN 
        supplier s ON ps.ps_suppkey = s.s_suppkey
    GROUP BY 
        ps.ps_partkey
),
FinalSummary AS (
    SELECT 
        qs.p_partkey,
        qs.total_quantity,
        qs.net_revenue,
        ss.supplier_count,
        ss.avg_supplier_balance
    FROM 
        QuantitySummary qs
    JOIN 
        SupplierSummary ss ON qs.p_partkey = ss.ps_partkey
)
SELECT 
    p.p_name,
    fs.total_quantity,
    fs.net_revenue,
    fs.supplier_count,
    fs.avg_supplier_balance,
    ROUND(fs.net_revenue / NULLIF(fs.total_quantity, 0), 2) AS revenue_per_unit
FROM 
    FinalSummary fs
JOIN 
    part p ON fs.p_partkey = p.p_partkey
ORDER BY 
    fs.net_revenue DESC
LIMIT 10;