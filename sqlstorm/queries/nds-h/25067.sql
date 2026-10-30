WITH PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_brand,
        p.p_type,
        p.p_container,
        p.p_retailprice,
        p.p_comment,
        s.s_name AS supplier_name,
        c.c_name AS customer_name,
        o.o_orderkey,
        l.l_quantity,
        l.l_extendedprice,
        l.l_discount,
        l.l_tax,
        l.l_shipdate
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
    WHERE 
        p.p_name LIKE '%bolt%'
    AND 
        o.o_orderdate BETWEEN '1996-01-01' AND '1997-12-31'
),
AggregatedData AS (
    SELECT 
        p_brand,
        SUM(l_quantity) AS total_quantity,
        SUM(l_extendedprice * (1 - l_discount)) AS total_revenue,
        AVG(l_tax) AS avg_tax_rate,
        COUNT(DISTINCT customer_name) AS unique_customers
    FROM 
        PartDetails
    GROUP BY 
        p_brand
)
SELECT 
    p_brand,
    total_quantity,
    total_revenue,
    avg_tax_rate,
    unique_customers,
    CASE 
        WHEN total_revenue > 100000 THEN 'High Revenue'
        WHEN total_revenue BETWEEN 50000 AND 100000 THEN 'Medium Revenue'
        ELSE 'Low Revenue'
    END AS revenue_category
FROM 
    AggregatedData
ORDER BY 
    total_revenue DESC;