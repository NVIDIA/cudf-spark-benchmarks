
WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_acctbal, 
        RANK() OVER (PARTITION BY ps.ps_partkey ORDER BY s.s_acctbal DESC) AS supplier_rank,
        ps.ps_partkey
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
PartSummary AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(DISTINCT o.o_orderkey) AS order_count,
        AVG(l.l_quantity) AS avg_quantity
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    JOIN 
        orders o ON l.l_orderkey = o.o_orderkey
    GROUP BY 
        p.p_partkey, p.p_name
),
PartsWithSupplier AS (
    SELECT 
        ps.ps_partkey, 
        ps.ps_supplycost, 
        rs.s_name, 
        ps.ps_availqty
    FROM 
        partsupp ps
    LEFT JOIN 
        RankedSuppliers rs ON ps.ps_partkey = rs.ps_partkey AND rs.supplier_rank = 1
)
SELECT 
    ps.p_partkey,
    ps.p_name,
    ps.total_revenue,
    ps.order_count,
    ps.avg_quantity,
    COALESCE(psw.s_name, 'No Supplier') AS top_supplier_name,
    CASE 
        WHEN psw.ps_supplycost IS NULL THEN 'Insufficient Data'
        WHEN psw.ps_supplycost < 100 THEN 'Low Cost'
        ELSE 'High Cost'
    END AS cost_category
FROM 
    PartSummary ps
LEFT JOIN 
    PartsWithSupplier psw ON ps.p_partkey = psw.ps_partkey
WHERE 
    ps.total_revenue > 1000
    AND ps.avg_quantity IS NOT NULL
ORDER BY 
    ps.total_revenue DESC, ps.order_count ASC;
