WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        CONCAT(s.s_name, ' ', s.s_address) AS full_info,
        r.r_name AS region_name
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
), PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_mfgr, 
        p.p_brand, 
        UPPER(p.p_type) AS type_upper,
        p.p_size, 
        p.p_container,
        p.p_retailprice,
        LENGTH(p.p_comment) AS comment_length
    FROM 
        part p
), LineItemAggregates AS (
    SELECT 
        l.l_partkey, 
        SUM(l.l_quantity) AS total_quantity,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        lineitem l
    GROUP BY 
        l.l_partkey
)
SELECT 
    sd.full_info,
    pd.p_name, 
    pd.type_upper, 
    la.total_quantity,
    la.order_count,
    pd.comment_length,
    CAST(pd.p_retailprice AS DECIMAL(10,2)) AS formatted_price
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    LineItemAggregates la ON pd.p_partkey = la.l_partkey
WHERE 
    la.total_quantity > 100
ORDER BY 
    la.order_count DESC, 
    pd.comment_length ASC;
