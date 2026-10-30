WITH SupplierInfo AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_nationkey,
        TRIM(s.s_address) AS formatted_address,
        LENGTH(s.s_comment) AS comment_length
    FROM 
        supplier s
    WHERE 
        s.s_acctbal > 0
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        REPLACE(p.p_comment, 'outdated', 'updated') AS updated_comment,
        SUBSTRING(p.p_mfgr, 1, 10) AS mfgr_short
    FROM 
        part p
    WHERE 
        p.p_retailprice BETWEEN 10.00 AND 100.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        COUNT(l.l_orderkey) AS lineitem_count,
        SUM(l.l_extendedprice - l.l_discount) AS total_line_sales
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01'
    GROUP BY 
        o.o_orderkey, o.o_orderstatus, o.o_totalprice
)
SELECT 
    si.s_name,
    pd.p_name,
    os.o_orderkey,
    os.total_line_sales,
    os.lineitem_count,
    r.r_name AS region_name,
    pd.updated_comment,
    si.formatted_address,
    si.comment_length
FROM 
    SupplierInfo si
JOIN 
    PartDetails pd ON si.s_nationkey = pd.p_partkey
JOIN 
    OrderSummary os ON si.s_suppkey = os.o_orderkey
JOIN 
    nation n ON si.s_nationkey = n.n_nationkey
JOIN 
    region r ON n.n_regionkey = r.r_regionkey
WHERE 
    LENGTH(si.formatted_address) < 40
ORDER BY 
    os.total_line_sales DESC, si.s_name ASC;