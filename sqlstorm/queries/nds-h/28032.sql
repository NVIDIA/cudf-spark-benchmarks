WITH RankedSuppliers AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_acctbal,
        RANK() OVER (PARTITION BY ps_partkey ORDER BY s.s_acctbal DESC) AS rank
    FROM 
        supplier s
    JOIN 
        partsupp ps ON s.s_suppkey = ps.ps_suppkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        COUNT(DISTINCT l.l_orderkey) AS order_count,
        SUM(l.l_quantity) AS total_quantity
    FROM 
        part p
    JOIN 
        lineitem l ON p.p_partkey = l.l_partkey
    GROUP BY 
        p.p_partkey, p.p_name, p.p_brand
),
SupplierPerformance AS (
    SELECT 
        r.r_name AS region_name,
        pd.p_name,
        pd.p_brand,
        AVG(ss.s_acctbal) AS avg_supplier_balance,
        SUM(pd.total_quantity) AS total_quantity_supplied
    FROM 
        RankedSuppliers ss
    JOIN 
        PartDetails pd ON ss.s_suppkey = pd.p_partkey
    JOIN 
        supplier s ON ss.s_suppkey = s.s_suppkey
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
    WHERE 
        ss.rank = 1
    GROUP BY 
        r.r_name, pd.p_name, pd.p_brand
)
SELECT 
    region_name,
    p_name,
    p_brand,
    avg_supplier_balance,
    total_quantity_supplied
FROM 
    SupplierPerformance
ORDER BY 
    region_name, avg_supplier_balance DESC;
