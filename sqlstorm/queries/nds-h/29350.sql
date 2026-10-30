WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation,
        r.r_name AS region
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
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        LENGTH(p.p_name) > 20 AND
        p.p_retailprice BETWEEN 10.00 AND 100.00
),
OrderAggregation AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        SUM(l.l_extendedprice * (1 - l.l_discount)) AS total_sales,
        COUNT(DISTINCT l.l_orderkey) AS order_count
    FROM 
        orders o
    JOIN 
        lineitem l ON o.o_orderkey = l.l_orderkey
    WHERE 
        o.o_orderdate >= '1997-01-01' AND 
        o.o_orderdate < '1998-01-01'
    GROUP BY 
        o.o_orderkey,
        o.o_orderstatus
)
SELECT 
    sd.s_name,
    pd.p_name,
    oa.o_orderstatus,
    oa.total_sales,
    oa.order_count,
    CONCAT(sd.s_address, ', ', sd.nation, ', ', sd.region) AS full_address
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    OrderAggregation oa ON oa.o_orderkey = ps.ps_partkey
WHERE 
    sd.region = 'ASIA' AND 
    oa.total_sales > 50000 
ORDER BY 
    oa.total_sales DESC, 
    sd.s_name ASC;