WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        CONCAT(s.s_address, ' - ', s.s_phone) AS SupplierInfo,
        r.r_name AS RegionName,
        s.s_acctbal
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
    JOIN 
        region r ON n.n_regionkey = r.r_regionkey
),
PartDetails AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_mfgr,
        p.p_retailprice,
        LENGTH(p.p_comment) AS CommentLength
    FROM 
        part p
    WHERE 
        p.p_retailprice > 100.00
),
OrderSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS TotalRevenue,
        COUNT(l.l_orderkey) AS LineItemCount
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'O'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    sd.SupplierInfo,
    pd.p_name,
    pd.p_mfgr,
    os.TotalRevenue,
    os.LineItemCount,
    pd.CommentLength
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderSummary os ON os.o_orderkey = ps.ps_partkey
ORDER BY 
    os.TotalRevenue DESC, sd.SupplierInfo;
