WITH SupplierDetails AS (
    SELECT 
        s.s_suppkey,
        s.s_name,
        s.s_address,
        n.n_name AS nation_name,
        r.r_name AS region_name,
        s.s_acctbal,
        s.s_comment
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
        p.p_brand,
        p.p_type,
        p.p_size,
        p.p_retailprice,
        p.p_comment
    FROM 
        part p
    WHERE 
        p.p_retailprice > 50.00 AND p.p_size BETWEEN 10 AND 30
),
OrderInfo AS (
    SELECT 
        o.o_orderkey,
        o.o_orderstatus,
        o.o_totalprice,
        o.o_orderdate,
        c.c_name AS customer_name,
        c.c_acctbal AS customer_acctbal,
        c.c_mktsegment
    FROM 
        orders o
    JOIN 
        customer c ON o.o_custkey = c.c_custkey
    WHERE 
        o.o_orderstatus IN ('O', 'F') AND o.o_totalprice > 100.00
)
SELECT 
    sd.s_name,
    sd.nation_name,
    sd.region_name,
    pd.p_name,
    oi.o_orderkey,
    oi.o_orderdate,
    oi.o_totalprice,
    oi.customer_name,
    CONCAT(sd.s_comment, ' | ', oi.c_mktsegment) AS extended_comment
FROM 
    SupplierDetails sd
JOIN 
    partsupp ps ON sd.s_suppkey = ps.ps_suppkey
JOIN 
    PartDetails pd ON ps.ps_partkey = pd.p_partkey
JOIN 
    lineitem li ON ps.ps_partkey = li.l_partkey
JOIN 
    OrderInfo oi ON li.l_orderkey = oi.o_orderkey
WHERE 
    sd.s_acctbal > 5000.00
ORDER BY 
    sd.region_name, oi.o_orderdate DESC;
