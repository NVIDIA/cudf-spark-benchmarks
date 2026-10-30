WITH FilteredParts AS (
    SELECT 
        p_partkey, 
        p_name, 
        p_brand, 
        p_type, 
        p_size, 
        p_retailprice, 
        p_comment
    FROM 
        part
    WHERE 
        p_type LIKE '%steel%'
        AND p_size BETWEEN 1 AND 10
),
SupplierDetails AS (
    SELECT 
        s.s_suppkey, 
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        s.s_comment
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    WHERE 
        s.s_acctbal > 50000
),
OrderSummary AS (
    SELECT 
        o.o_orderkey, 
        o.o_orderstatus, 
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS total_items
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND o.o_orderdate < '1997-12-31'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus
)
SELECT 
    fp.p_partkey,
    fp.p_name,
    fp.p_brand,
    fp.p_type,
    sd.s_name AS supplier_name,
    os.o_orderstatus,
    os.total_sales,
    os.total_items,
    CONCAT('This part, ', fp.p_name, ', supplied by ', sd.s_name, ', has total sales of $', ROUND(os.total_sales, 2), ' from ', os.total_items, ' orders.') AS summary_comment
FROM 
    FilteredParts fp
LEFT JOIN 
    partsupp ps ON fp.p_partkey = ps.ps_partkey
LEFT JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
LEFT JOIN 
    OrderSummary os ON fp.p_partkey = os.o_orderkey
WHERE 
    sd.nation_name IS NOT NULL
ORDER BY 
    fp.p_retailprice DESC, 
    os.total_sales DESC;