
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        ROW_NUMBER() OVER (PARTITION BY n.n_name ORDER BY s.s_acctbal DESC) AS rn,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal IS NOT NULL AND s.s_acctbal > 1000
),
HighValueParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_retailprice,
        CASE 
            WHEN p.p_retailprice * 0.1 > 100 THEN 'High Margin' 
            ELSE 'Low Margin' 
        END AS margin_type
    FROM 
        part p
    WHERE 
        p.p_retailprice IS NOT NULL
),
TotalSales AS (
    SELECT 
        l.l_partkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        lineitem l
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        l.l_partkey
),
SupplierPartAvailability AS (
    SELECT 
        ps.ps_partkey,
        ps.ps_suppkey,
        SUM(ps.ps_availqty) AS total_available
    FROM 
        partsupp ps
    WHERE 
        ps.ps_availqty > 0
    GROUP BY 
        ps.ps_partkey, ps.ps_suppkey
)
SELECT 
    hp.p_name,
    COALESCE(sp.total_available, 0) AS total_available_qty,
    COALESCE(ts.total_revenue, 0) AS total_sales_revenue,
    rs.s_name AS top_supplier_name,
    rs.s_acctbal AS top_supplier_balance,
    hp.margin_type
FROM 
    HighValueParts hp
LEFT JOIN 
    SupplierPartAvailability sp ON hp.p_partkey = sp.ps_partkey
LEFT JOIN 
    TotalSales ts ON hp.p_partkey = ts.l_partkey
LEFT JOIN 
    RankedSuppliers rs ON sp.ps_suppkey = rs.s_suppkey AND rs.rn = 1
WHERE 
    (hp.margin_type = 'High Margin' OR COALESCE(ts.total_revenue, 0) > 5000) 
    AND COALESCE(sp.total_available, 0) > 0
ORDER BY 
    total_sales_revenue DESC, top_supplier_balance DESC
LIMIT 10;
