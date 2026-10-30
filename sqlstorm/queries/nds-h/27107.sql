WITH RankedParts AS (
    SELECT 
        p.p_partkey,
        p.p_name,
        p.p_brand,
        p.p_type,
        SUBSTRING(CAST(p.p_comment AS STRING), 1, 30) AS truncated_comment,
        RANK() OVER (PARTITION BY p.p_type ORDER BY p.p_retailprice DESC) AS price_rank
    FROM 
        part p
), SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        n.n_name AS nation_name,
        s.s_acctbal,
        CASE 
            WHEN s.s_acctbal > 1000 THEN 'High'
            WHEN s.s_acctbal BETWEEN 500 AND 1000 THEN 'Medium'
            ELSE 'Low'
        END AS account_category
    FROM 
        supplier s
    JOIN 
        nation n ON s.s_nationkey = n.n_nationkey
), OrdersSummary AS (
    SELECT 
        o.o_orderkey,
        o.o_orderdate,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_revenue,
        COUNT(l.l_orderkey) AS line_item_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderstatus = 'F'
    GROUP BY 
        o.o_orderkey, o.o_orderdate
)
SELECT 
    rp.p_name,
    rp.p_brand,
    sd.nation_name,
    sd.account_category,
    os.total_revenue,
    os.line_item_count,
    rp.truncated_comment
FROM 
    RankedParts rp
JOIN 
    partsupp ps ON rp.p_partkey = ps.ps_partkey
JOIN 
    SupplierDetails sd ON ps.ps_suppkey = sd.s_suppkey
JOIN 
    OrdersSummary os ON os.o_orderkey = ps.ps_partkey
WHERE 
    rp.price_rank <= 5
ORDER BY 
    os.total_revenue DESC, rp.p_name;
