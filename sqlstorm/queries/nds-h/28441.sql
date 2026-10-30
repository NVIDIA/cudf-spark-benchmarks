WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name, 
        s.s_address, 
        n.n_name AS nation_name,
        CONCAT(s.s_name, ' ', s.s_address, ' ', n.n_name) AS full_supplier_info,
        CASE 
            WHEN s.s_acctbal < 10000 THEN 'Low'
            WHEN s.s_acctbal BETWEEN 10000 AND 50000 THEN 'Medium'
            ELSE 'High'
        END AS account_balance_category
    FROM
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
),
PartDetails AS (
    SELECT 
        p.p_partkey, 
        p.p_name, 
        p.p_brand, 
        p.p_retailprice,
        REPLACE(p.p_comment, 'cheap', 'affordable') AS modified_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    GROUP BY 
        o.o_orderkey
)
SELECT 
    sd.s_name, 
    pd.p_name, 
    os.total_revenue,
    sd.account_balance_category,
    LENGTH(sd.full_supplier_info) AS supplier_info_length,
    SUBSTRING(sd.full_supplier_info, 1, 30) AS short_supplier_info,
    UPPER(pd.modified_comment) AS uppercase_comment
FROM 
    SupplierDetails sd
JOIN 
    PartDetails pd ON sd.s_suppkey = pd.p_partkey
JOIN 
    OrderSummary os ON os.total_revenue > 1000
WHERE 
    sd.account_balance_category = 'High'
ORDER BY 
    os.total_revenue DESC
LIMIT 100;
