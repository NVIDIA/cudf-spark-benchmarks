
WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
ProductDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        p.p_retailprice 
    FROM 
        part p
    WHERE 
        p.p_type LIKE '%brass%'
),
OrderAggregates AS (
    SELECT 
        o.o_orderkey,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS revenue,
        COUNT(DISTINCT l.l_suppkey) AS supplier_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS product_name,
    pd.p_brand AS product_brand,
    pd.p_retailprice AS price,
    SUM(oa.revenue) AS total_revenue,
    COUNT(DISTINCT oa.o_orderkey) AS order_count,
    sd.region_name
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    ProductDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderAggregates oa ON sd.s_suppkey = oa.o_orderkey
WHERE 
    sd.s_name LIKE '%Corp%'
GROUP BY 
    sd.s_name, pd.p_name, pd.p_brand, pd.p_retailprice, sd.region_name
ORDER BY 
    total_revenue DESC, order_count DESC;
