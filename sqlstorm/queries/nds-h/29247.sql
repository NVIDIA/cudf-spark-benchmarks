WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        s.s_phone,
        COALESCE(NULLIF(LOWER(s.s_comment), ''), 'No Comment') AS adjusted_comment
    FROM 
        supplier s
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_retailprice,
        LENGTH(REPLACE(LOWER(p.p_comment), ' ', '')) AS non_space_comment_length
    FROM 
        part p
),
OrderSummaries AS (
    SELECT 
        o.o_orderkey,
        o.o_totalprice,
        COUNT(li.l_orderkey) AS total_lineitems,
        SUM(li.l_quantity) AS total_quantity,
        SUM(li.l_extendedprice) AS total_extended_price
    FROM 
        orders o
    JOIN 
        lineitem li ON o.o_orderkey = li.l_orderkey
    GROUP BY 
        o.o_orderkey, o.o_totalprice
)
SELECT 
    sd.s_name AS supplier_name,
    pd.p_name AS part_name,
    os.total_lineitems,
    os.total_quantity,
    os.total_extended_price,
    pd.non_space_comment_length,
    sd.adjusted_comment
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummaries os ON os.o_orderkey = ps.ps_partkey  
WHERE 
    pd.p_retailprice > 100.00
ORDER BY 
    os.total_extended_price DESC
LIMIT 100;